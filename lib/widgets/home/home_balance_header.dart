import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/expense_provider.dart';

class HomeBalanceHeader extends StatelessWidget {
  final ExpenseProvider provider;
  const HomeBalanceHeader({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    String headerTitle;
    double headerAmount;
    bool hidePills = false;
    double pillIncome = provider.monthlyIncome;
    double pillExpense = provider.monthlyExpense;

    if (provider.searchQuery.isNotEmpty) {
      headerTitle = provider.t('Search Results');
      headerAmount = provider.searchNetBalance;
      pillIncome = provider.searchTotalIncome;
      pillExpense = provider.searchTotalExpense;
    } else if (provider.selectedDay != null) {
      headerTitle = provider.t('Day Expense');
      headerAmount = provider.selectedDayExpense;
      hidePills = true;
    } else {
      headerTitle = provider.t('Available Balance');
      headerAmount = provider.filteredSpendableBalance;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              headerTitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(headerAmount),
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: hidePills
                  ? const SizedBox(width: double.infinity, height: 0)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPill(
                            format.format(pillIncome),
                            CupertinoIcons.arrow_down_left,
                            CupertinoColors.activeGreen,
                          ),
                          const SizedBox(width: 12),
                          _buildPill(
                            format.format(pillExpense),
                            CupertinoIcons.arrow_up_right,
                            CupertinoColors.destructiveRed,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ).animate().fade().slideY(begin: -0.1, end: 0),
      ),
    );
  }

  Widget _buildPill(String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
