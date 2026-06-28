import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import 'category_transactions_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // NEW: Toggle state for the Donut Chart
  bool _showExpense = true;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFF9500);
      case 'Transport':
        return const Color(0xFF007AFF);
      case 'Shopping':
        return const Color(0xFFAF52DE);
      case 'Bills':
        return const Color(0xFFFF3B30);
      case 'Entertainment':
        return const Color(0xFF5856D6);
      case 'Salary':
        return const Color(0xFF34C759); // Green for Salary
      case 'Gift':
        return const Color(0xFFFF2D55); // Pink for Gift
      case 'Investment':
        return const Color(0xFF5AC8FA); // Light Blue
      default:
        return const Color(0xFF8E8E93);
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
        // Fetch data based on the toggle!
        final categoryData = provider.getStatsCategoryData(_showExpense);
        final format = NumberFormat.currency(
          symbol: '${provider.currencySymbol} ',
          decimalDigits: 0,
        );
        final totalAmountForChart = _showExpense
            ? provider.statsTotalExpense
            : provider.statsTotalIncome;

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
              Row(
                children: [
                  Expanded(
                    child: _buildGradientStatCard(
                      provider.t('Income'),
                      provider.statsTotalIncome,
                      const [Color(0xFF34C759), Color(0xFF28A745)],
                      provider.currencySymbol,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildGradientStatCard(
                      provider.t('Expense'),
                      provider.statsTotalExpense,
                      const [Color(0xFFFF3B30), Color(0xFFD70015)],
                      provider.currencySymbol,
                    ),
                  ),
                ],
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 35),

              // NEW: iOS Toggle for Income/Expense Breakdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _showExpense,
                  children: {
                    true: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(provider.t('Expense')),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(provider.t('Income')),
                    ),
                  },
                  onValueChanged: (val) => setState(() => _showExpense = val!),
                ),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 20),

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
                                format.format(totalAmountForChart),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 80,
                              sections: categoryData.entries.map((entry) {
                                final percentage =
                                    (entry.value / totalAmountForChart) * 100;
                                return PieChartSectionData(
                                  color: _getCategoryColor(entry.key),
                                  value: entry.value,
                                  title: percentage >= 5
                                      ? '${percentage.toStringAsFixed(0)}%'
                                      : '',
                                  radius: 25,
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

                ...categoryData.entries.map((entry) {
                  final percentage = (entry.value / totalAmountForChart) * 100;
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the drill-down screen!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTransactionsScreen(
                            categoryName: entry.key,
                            isExpense: _showExpense,
                          ),
                        ),
                      );
                    },
                    child: Container(
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
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
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

  Widget _buildGradientStatCard(
    String title,
    double amount,
    List<Color> colors,
    String currencySymbol,
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
              symbol: '$currencySymbol ',
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
