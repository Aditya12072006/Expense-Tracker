import 'dart:io';

import 'package:expensetracker/core/storage/hive_boxes.dart';
import 'package:expensetracker/features/history/history_screen.dart';
import 'package:expensetracker/features/root/root_shell.dart';
import 'package:expensetracker/features/subscription/providers/subscription_provider.dart';
import 'package:expensetracker/features/transactions/models/expense_transaction.dart';
import 'package:expensetracker/shared/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('expense_tracker_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(TransactionTypeAdapter.typeIdValue)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(ExpenseTransactionAdapter.typeIdValue)) {
      Hive.registerAdapter(ExpenseTransactionAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    await Hive.openBox<ExpenseTransaction>(HiveBoxes.transactions);
    await Hive.openBox<dynamic>(HiveBoxes.settings);

    final txBox = Hive.box<ExpenseTransaction>(HiveBoxes.transactions);
    final settingsBox = Hive.box<dynamic>(HiveBoxes.settings);

    await txBox.clear();
    await settingsBox.clear();

    final now = DateTime.now();
    for (var i = 0; i < 8; i++) {
      await txBox.put(
        'tx_$i',
        ExpenseTransaction(
          id: 'tx_$i',
          title: 'Tx$i',
          amount: 10 + i.toDouble(),
          date: now.subtract(Duration(days: i)),
          category: 'Food',
          type: TransactionType.expense,
        ),
      );
    }
  });

  tearDown(() async {
    await Hive.box<ExpenseTransaction>(HiveBoxes.transactions).close();
    await Hive.box<dynamic>(HiveBoxes.settings).close();
  });

  testWidgets('History is locked to 5 items for free users', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Build and reveal the premium lock card on smaller viewports.
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pump();

    expect(find.byType(TransactionTile), findsNWidgets(5));
    expect(find.text('Premium Locked'), findsOneWidget);
    expect(find.text('Tx5'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History is fully visible for Pro users', (tester) async {
    await Hive.box<dynamic>(HiveBoxes.settings).put(
      SubscriptionService.purchaseDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await Hive.box<dynamic>(HiveBoxes.settings).put(
      SubscriptionService.isProActiveKey,
      true,
    );

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TransactionTile), findsNWidgets(8));
    expect(find.text('Premium Locked'), findsNothing);
    expect(find.text('Tx7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Root shell renders on iPhone size without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const RootShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Subscription deep-link parser accepts iOS success callback', () {
    final service = SubscriptionService(Hive.box<dynamic>(HiveBoxes.settings));

    expect(service.isPaidSuccessLink(Uri.parse('expensetracker://success')), true);
    expect(
      service.isPaidSuccessLink(Uri.parse('expensetracker://success?status=paid')),
      true,
    );
    expect(
      service.isPaidSuccessLink(Uri.parse('expensetracker://success?status=failed')),
      false,
    );
  });
}
