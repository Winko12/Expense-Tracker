import 'dart:ui'; // NEW: For Glassmorphism blur

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
        return const Color(0xFF34C759);
      case 'Gift':
        return const Color(0xFFFF2D55);
      case 'Investment':
        return const Color(0xFF5AC8FA);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
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

        return CustomScrollView(
          slivers: [
            // ==========================================
            // 1. GLASSMORPHISM APP BAR WITH DATE PICKER!
            // ==========================================
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                        : const Color(0xFFEBF4FF).withValues(alpha: 0.6),
                  ),
                ),
              ),
              centerTitle: true,
              // Tap the title to open the Date Range Picker!
              title: GestureDetector(
                onTap: () => _pickDateRange(context, provider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.statsDateRange != null
                          ? CupertinoIcons.calendar_today
                          : CupertinoIcons.calendar,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              // Clear Date button if a date is picked
              actions: [
                if (provider.statsDateRange != null)
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.clear_thick,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => provider.setStatsDateRange(null),
                  ),
              ],
            ),

            // ==========================================
            // 2. CHARTS & CARDS
            // ==========================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                        onValueChanged: (val) =>
                            setState(() => _showExpense = val!),
                      ),
                    ).animate().fade(delay: 200.ms),

                    const SizedBox(height: 30),

                    if (categoryData.isNotEmpty)
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
                                          (entry.value / totalAmountForChart) *
                                          100;
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
                  ],
                ),
              ),
            ),

            // ==========================================
            // 3. CATEGORY LIST
            // ==========================================
            if (categoryData.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      provider.t('No transactions found.'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ).copyWith(bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = categoryData.entries.elementAt(index);
                    final percentage =
                        (entry.value / totalAmountForChart) * 100;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTransactionsScreen(
                            categoryName: entry.key,
                            isExpense: _showExpense,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
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
                  }, childCount: categoryData.length),
                ),
              ),
          ],
        );
      },
    );
  }
}
