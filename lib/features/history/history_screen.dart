import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/animated_tap_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../settings/providers/currency_provider.dart';
import '../subscription/checkout_webview_screen.dart';
import '../subscription/providers/subscription_provider.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../transactions/models/expense_transaction.dart';
import '../transactions/providers/transaction_notifier.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final isProAsync = ref.watch(subscriptionProvider);
    final double topInset = MediaQuery.of(context).viewPadding.top;
    final double bottomPadding =
        MediaQuery.of(context).viewPadding.bottom > 0 ? 160 : 130;
    final isPro =
        isProAsync.valueOrNull ??
        ref.read(subscriptionServiceProvider).isProActive;
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filteredTransactions = allTransactions
      .where(
        (t) => t.title.toLowerCase().contains(normalizedQuery),
      )
        .toList(growable: false);

    final visibleTransactions = isPro
        ? filteredTransactions
        : filteredTransactions.take(5).toList(growable: false);
    final showPremiumLock = !isPro && filteredTransactions.length > 5;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.7,
          colors: [Color(0xFF12131A), AppColors.background],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 0),
        child: _HistoryList(
          transactions: visibleTransactions,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
          showPremiumLock: showPremiumLock,
          bottomPadding: bottomPadding,
          searchQuery: _searchQuery,
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onGoPro: () async {
            final paid = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const CheckoutWebViewScreen(),
              ),
            );

            if (!context.mounted || paid == null) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  paid
                      ? 'Premium activated for 30 days. Full history unlocked.'
                      : 'Payment was cancelled or not completed.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({
    required this.transactions,
    required this.currencyCode,
    required this.currencySymbol,
    required this.showPremiumLock,
    required this.bottomPadding,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onGoPro,
  });

  final List<ExpenseTransaction> transactions;
  final String currencyCode;
  final String currencySymbol;
  final bool showPremiumLock;
  final double bottomPadding;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onGoPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = _groupByMonthAndDay(transactions);

    var tileIndex = 0;
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 12),
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by title',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              searchQuery.isEmpty
                  ? 'No transactions found'
                  : 'No matching transactions found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 15,
              ),
            ),
          ),
        ...grouped.entries.map((monthEntry) {
          final monthTitle = monthEntry.key;
          final days = monthEntry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  monthTitle,
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...days.entries.map((dayEntry) {
                final dayTitle = dayEntry.key;
                final items = dayEntry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 2),
                      child: Text(
                        dayTitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...items.map((tx) {
                      final index = tileIndex;
                      tileIndex += 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            TransactionTile(
                                  transaction: tx,
                                  currencyCode: currencyCode,
                                  currencySymbol: currencySymbol,
                                  onDelete: () {
                                    ref
                                        .read(transactionsProvider.notifier)
                                        .deleteTransaction(tx.id);
                                  },
                                )
                                .animate(delay: (70 * index).ms)
                                .fadeIn(duration: 420.ms)
                                .slideY(begin: 0.16, end: 0),
                      );
                    }),
                  ],
                );
              }),
            ],
          );
        }),
        if (showPremiumLock) ...[
          const SizedBox(height: 14),
          _PremiumLockedCard(onGoPro: onGoPro),
        ],
      ],
    );
  }

  Map<String, Map<String, List<ExpenseTransaction>>> _groupByMonthAndDay(
    List<ExpenseTransaction> list,
  ) {
    final output = <String, Map<String, List<ExpenseTransaction>>>{};

    for (final tx in list) {
      final month = DateFormat('MMMM yyyy').format(tx.date);
      final day = DateFormat('EEEE, d MMM').format(tx.date);
      final monthGroup = output.putIfAbsent(
        month,
        () => <String, List<ExpenseTransaction>>{},
      );
      final dayGroup = monthGroup.putIfAbsent(
        day,
        () => <ExpenseTransaction>[],
      );
      dayGroup.add(tx);
    }
    return output;
  }
}

class _PremiumLockedCard extends StatelessWidget {
  const _PremiumLockedCard({required this.onGoPro});

  final Future<void> Function() onGoPro;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.accent.withValues(alpha: 0.20),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Premium Locked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You are viewing the first 5 transactions. Start your 1-month free trial to unlock full history. Access returns to 5 transactions when the period ends unless you upgrade again.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedTapButton(
            onTap: onGoPro,
            child:
                Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Unlock History',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 1800.ms,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
          ),
        ],
      ),
    );
  }
}
