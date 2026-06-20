import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // Helper method to give each category a specific color
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final categoryData = provider.categoryExpenses;

        if (categoryData.isEmpty) {
          return const Center(
            child: Text(
              'Add some expenses to see your charts!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Breakdown',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // The Pie Chart!
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: categoryData.entries.map((entry) {
                      return PieChartSectionData(
                        color: _getCategoryColor(entry.key),
                        value: entry.value,
                        title:
                            '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
                        radius: 70,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
