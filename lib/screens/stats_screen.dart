import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // Apple-inspired vibrant colors
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFF9500); // Orange
      case 'Transport':
        return const Color(0xFF007AFF); // Blue
      case 'Shopping':
        return const Color(0xFFAF52DE); // Purple
      case 'Bills':
        return const Color(0xFFFF3B30); // Red
      case 'Entertainment':
        return const Color(0xFF5856D6); // Indigo
      default:
        return const Color(0xFF8E8E93); // Gray
    }
  }

  Future<void> _pickDateRange(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.statsDateRange,
    );
    if (picked != null) provider.setStatsDateRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final categoryData = provider.statsCategoryExpenses;
        final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        String dateText = provider.t('All Time');
        if (provider.statsDateRange != null) {
          dateText =
              '${DateFormat('MMM dd').format(provider.statsDateRange!.start)} - ${DateFormat('MMM dd').format(provider.statsDateRange!.end)}';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Center Pill Button for Date (Apple Style)
              Center(
                child: GestureDetector(
                  onTap: () => _pickDateRange(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 25),

              // 2. Soft Gradient Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildGradientStatCard(
                      provider.t('Income'),
                      provider.statsTotalIncome,
                      const [Color(0xFF34C759), Color(0xFF28A745)],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildGradientStatCard(
                      provider.t('Expense'),
                      provider.statsTotalExpense,
                      const [Color(0xFFFF3B30), Color(0xFFD70015)],
                    ),
                  ),
                ],
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 35),
              Text(
                provider.t('Expense Breakdown'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 20),

              // 3. Precision Donut Chart (Apple Health Style)
              if (categoryData.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      provider.t('No transactions found.'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Text in the middle of the Donut
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.t('Total'),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                format.format(provider.statsTotalExpense),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2, // Tiny gap for sleekness
                              centerSpaceRadius:
                                  80, // Large center makes it a Donut chart
                              sections: categoryData.entries.map((entry) {
                                final percentage =
                                    (entry.value / provider.statsTotalExpense) *
                                    100;
                                return PieChartSectionData(
                                  color: _getCategoryColor(entry.key),
                                  value: entry.value,
                                  title: percentage >= 5
                                      ? '${percentage.toStringAsFixed(0)}%'
                                      : '', // Only show % if it fits
                                  radius: 25, // Thin ring
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fade(delay: 300.ms)
                    .scale(curve: Curves.easeOutBack),

                const SizedBox(height: 30),

                // 4. Apple Wallet Style Category List
                ...categoryData.entries.map((entry) {
                  final percentage =
                      (entry.value / provider.statsTotalExpense) * 100;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            provider.t(entry.key),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              format.format(entry.value),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 400.ms).slideX(begin: 0.1);
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // Soft Gradient Cards
  Widget _buildGradientStatCard(
    String title,
    double amount,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
