import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../settings/providers/currency_provider.dart';
import '../../shared/widgets/animated_tap_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../transactions/models/expense_transaction.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/providers/transaction_notifier.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = kTransactionCategories.first.name;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final selectedDay = DateUtils.dateOnly(_selectedDate);
    final today = DateUtils.dateOnly(DateTime.now());
    if (selectedDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Future dates are not allowed for transactions.'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0')),
      );
      return;
    }

    ref
        .read(transactionsProvider.notifier)
        .addTransaction(
          ExpenseTransaction(
            id: const Uuid().v4(),
            title: title,
            amount: amount,
            date: _selectedDate,
            category: _selectedCategory,
            type: _type,
          ),
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 28 + keyboardInset),
            children: [
              GlassCard(
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.income,
                      icon: Icon(Icons.south_west_rounded),
                      label: Text('Income'),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      icon: Icon(Icons.north_east_rounded),
                      label: Text('Expense'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() => _type = selection.first);
                  },
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 40,
                  color: _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${currency.symbol} ',
                  hintText: '0.00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.12, end: 0),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Dinner with team, Metro card, Salary...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.12, end: 0),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    AnimatedTapButton(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 170.ms).slideY(begin: 0.14, end: 0),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kTransactionCategories.map((category) {
                  final selected = category.name == _selectedCategory;

                  return AnimatedTapButton(
                    onTap: () =>
                        setState(() => _selectedCategory = category.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.17)
                            : Colors.white.withValues(alpha: 0.03),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 17),
                          const SizedBox(width: 7),
                          Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 240.ms),
              const SizedBox(height: 22),
              AnimatedTapButton(
                onTap: _save,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save Transaction',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.18, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
