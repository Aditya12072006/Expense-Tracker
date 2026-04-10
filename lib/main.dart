import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/storage/hive_boxes.dart';
import 'features/transactions/models/expense_transaction.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  _registerAdapters();
  await Hive.openBox<ExpenseTransaction>(HiveBoxes.transactions);
  await Hive.openBox<dynamic>(HiveBoxes.settings);

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(TransactionTypeAdapter.typeIdValue)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(ExpenseTransactionAdapter.typeIdValue)) {
    Hive.registerAdapter(ExpenseTransactionAdapter());
  }
}
