import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../settings/models/currency_option.dart';
import '../settings/providers/currency_provider.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/summary_card.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../transactions/providers/transaction_notifier.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final weekly = ref.watch(weeklyExpenseProvider);
    final categoryTotals = ref.watch(categoryExpenseProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final currency = ref.watch(currencyProvider);
    final bottomFloatingSpace = 160 + MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.7,
          colors: [Color(0xFF12131A), AppColors.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomFloatingSpace),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _CurrencyButton(
                  selected: currency,
                  onTap: () => _showCurrencyPicker(context, ref, currency),
                ),
              ],
            ).animate().fadeIn(duration: 450.ms),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: balance),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  formatMoney(
                    value,
                    currencyCode: currency.code,
                    currencySymbol: currency.symbol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                );
              },
            ).animate().fadeIn(duration: 650.ms).slideY(begin: 0.15, end: 0),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'Income',
                    amount: income,
                    icon: Icons.south_west_rounded,
                    color: AppColors.income,
                    currencyCode: currency.code,
                    currencySymbol: currency.symbol,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.16, end: 0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'Expense',
                    amount: expense,
                    icon: Icons.north_east_rounded,
                    color: AppColors.expense,
                    currencyCode: currency.code,
                    currencySymbol: currency.symbol,
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.16, end: 0),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '7-Day Expense Flow',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 200,
                    child: _ExpenseLineChart(
                      points: weekly,
                      currencyCode: currency.code,
                      currencySymbol: currency.symbol,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Split',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 170,
                    child: _CategoryPieChart(data: categoryTotals),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${recentTransactions.length} items',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 380.ms),
            const SizedBox(height: 10),
            if (recentTransactions.isEmpty)
              GlassCard(
                child: Text(
                  'No transactions for today yet. Add one using the + button.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...List.generate(recentTransactions.length, (index) {
                final transaction = recentTransactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child:
                      TransactionTile(
                            transaction: transaction,
                            currencyCode: currency.code,
                            currencySymbol: currency.symbol,
                          )
                          .animate(delay: (420 + (index * 70)).ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.2, end: 0),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ExpenseLineChart extends StatelessWidget {
  const _ExpenseLineChart({
    required this.points,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final List<DailyExpensePoint> points;
  final String currencyCode;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final maxY = max(
      50.0,
      points.fold<double>(
            0,
            (current, p) => p.total > current ? p.total : current,
          ) *
          1.28,
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.08),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.E().format(points[i].day),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1D1D24),
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots
                  .map(
                    (spot) => LineTooltipItem(
                      formatMoney(
                        spot.y,
                        currencyCode: currencyCode,
                        currencySymbol: currencySymbol,
                      ),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 3,
            color: AppColors.expense,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.4,
                  color: AppColors.expense,
                  strokeColor: Colors.black,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.expense.withValues(alpha: 0.35),
                  AppColors.expense.withValues(alpha: 0.00),
                ],
              ),
            ),
            spots: List.generate(points.length, (index) {
              return FlSpot(index.toDouble(), points[index].total);
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No expense data yet',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
        ),
      );
    }

    final colors = <Color>[
      AppColors.expense,
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
    ];
    final total = data.values.fold<double>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
              sections: List.generate(entries.length, (index) {
                final e = entries[index];
                return PieChartSectionData(
                  value: e.value,
                  color: colors[index % colors.length],
                  radius: 42,
                  showTitle: false,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (index) {
              final e = entries[index];
              final percent = total == 0 ? 0 : ((e.value / total) * 100);
              final dot = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dot,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${e.key} ${percent.toStringAsFixed(0)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

void _showCurrencyPicker(
  BuildContext context,
  WidgetRef ref,
  CurrencyOption selected,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.42,
        maxChildSize: 0.90,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF14141A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: ListView.builder(
              controller: controller,
              padding: EdgeInsets.fromLTRB(20, 14, 20, 10 + bottomPadding),
              itemCount: kCurrencyOptions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Select Currency',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final item = kCurrencyOptions[index - 1];
                final isSelected = item.code == selected.code;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item.symbol} ${item.code}'),
                  subtitle: Text(item.label),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(item.code);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({required this.selected, required this.onTap});

  final CurrencyOption selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Text(
          '${selected.symbol} ${selected.code}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
