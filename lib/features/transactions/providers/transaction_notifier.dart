import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../models/expense_transaction.dart';

class DailyExpensePoint {
  const DailyExpensePoint({required this.day, required this.total});

  final DateTime day;
  final double total;
}

class TransactionNotifier extends Notifier<List<ExpenseTransaction>> {
  Box<ExpenseTransaction> get _box =>
      Hive.box<ExpenseTransaction>(HiveBoxes.transactions);

  @override
  List<ExpenseTransaction> build() {
    return _sorted(_box.values.toList(growable: false));
  }

  void addTransaction(ExpenseTransaction transaction) {
    final normalizedTitle = transaction.title.trim();
    if (normalizedTitle.isEmpty) {
      return;
    }

    _box.put(transaction.id, transaction);
    state = _sorted(_box.values.toList(growable: false));
  }

  void deleteTransaction(String id) {
    _box.delete(id);
    state = _sorted(_box.values.toList(growable: false));
  }

  Future<void> clearAllTransactions() async {
    await _box.clear();
    state = const <ExpenseTransaction>[];
  }

  List<ExpenseTransaction> _sorted(List<ExpenseTransaction> transactions) {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }
}

final transactionsProvider =
    NotifierProvider<TransactionNotifier, List<ExpenseTransaction>>(
      TransactionNotifier.new,
    );

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0, (sum, tx) => sum + tx.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0, (sum, tx) => sum + tx.amount);
});

final balanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

final recentTransactionsProvider = Provider<List<ExpenseTransaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  final todaysTransactions = transactions.where((tx) {
    final localDate = tx.date.toLocal();
    return !localDate.isBefore(todayStart) && localDate.isBefore(tomorrowStart);
  });

  return todaysTransactions.take(6).toList(growable: false);
});

final weeklyExpenseProvider = Provider<List<DailyExpensePoint>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final totals = List<double>.filled(7, 0);

  for (final tx in transactions) {
    if (tx.type != TransactionType.expense) {
      continue;
    }
    final localDate = tx.date.toLocal();
    final txDay = DateTime(localDate.year, localDate.month, localDate.day);
    final diff = txDay.difference(start).inDays;
    if (diff >= 0 && diff < 7) {
      totals[diff] += tx.amount.abs();
    }
  }

  return List.generate(7, (index) {
    return DailyExpensePoint(
      day: start.add(Duration(days: index)),
      total: totals[index],
    );
  });
});

final categoryExpenseProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final totals = <String, double>{};
  for (final tx in transactions) {
    if (tx.type != TransactionType.expense) {
      continue;
    }
    totals.update(
      tx.category,
      (value) => value + tx.amount,
      ifAbsent: () => tx.amount,
    );
  }

  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries.take(5));
});
