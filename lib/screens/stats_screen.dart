import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.purple;
      case 'Bills':
        return Colors.redAccent;
      case 'Entertainment':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Opens the Calendar so you can pick Start & End dates!
  Future<void> _pickDateRange(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.statsDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setStatsDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final categoryData = provider.statsCategoryExpenses;
        final currencyFormat = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        );

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
              // 1. DATE RANGE PICKER BUTTON
              ElevatedButton.icon(
                onPressed: () => _pickDateRange(context, provider),
                icon: const Icon(Icons.date_range),
                label: Text(dateText, style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 20),

              // 2. INCOME VS EXPENSE SUMMARY CARDS
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      provider.t('Income'),
                      provider.statsTotalIncome,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      provider.t('Expense'),
                      provider.statsTotalExpense,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ).animate().fade(delay: 100.ms).scale(),

              const SizedBox(height: 30),

              Text(
                provider.t('Expense Breakdown'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 20),

              // 3. ANIMATED PIE CHART
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
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: categoryData.entries.map((entry) {
                            final percentage =
                                (entry.value / provider.statsTotalExpense) *
                                100;
                            return PieChartSectionData(
                              color: _getCategoryColor(entry.key),
                              value: entry.value,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                    .animate()
                    .fade(delay: 300.ms)
                    .scale(curve: Curves.easeOutBack),

                const SizedBox(height: 30),

                // 4. DETAILED CATEGORY LIST
                ...categoryData.entries.map((entry) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(entry.key),
                    ),
                    title: Text(
                      provider.t(entry.key),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ), // Translate category if needed
                    trailing: Text(
                      currencyFormat.format(entry.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fade(delay: 400.ms).slideX(begin: 0.2);
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
