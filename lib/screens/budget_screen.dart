import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );
    final isSafe = provider.realRemainingBalance > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. THE MAIN ALLOWANCE CARD
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSafe
                    ? [const Color(0xFF34C759), const Color(0xFF28A745)]
                    : [const Color(0xFFFF3B30), const Color(0xFFD70015)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isSafe ? Colors.green : Colors.red).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isSafe
                      ? CupertinoIcons.checkmark_shield_fill
                      : CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.white.withOpacity(0.8),
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.t(isSafe ? 'You can safely spend' : 'Overspent!'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  format.format(provider.safeDailyLimit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  provider.t('per day'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fade().scale(curve: Curves.easeOutBack, duration: 600.ms),

          const SizedBox(height: 35),

          // 2. SAVINGS GOAL SLIDER (NEW!)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.t('Savings Goal').toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${provider.savingsPercentage}%',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 100.ms),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.lock_shield_fill, color: Colors.blue),
                Expanded(
                  child: CupertinoSlider(
                    value: provider.savingsPercentage.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: Colors.blue,
                    onChanged: (val) =>
                        provider.updateSavingsPercentage(val.toInt()),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 35),

          // 3. THE MATH BREAKDOWN
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              provider.t('This Month').toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fade(delay: 200.ms),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildMathRow(
                  context,
                  provider.t('Income'),
                  format.format(provider.realCurrentMonthIncome),
                  CupertinoIcons.arrow_down_left_circle_fill,
                  Colors.green,
                ),
                const Divider(height: 0, indent: 56),

                // NEW: Show how much is locked!
                _buildMathRow(
                  context,
                  provider.t('Locked Savings'),
                  '- ${format.format(provider.lockedSavings)}',
                  CupertinoIcons.lock_fill,
                  Colors.blue,
                ),
                const Divider(height: 0, indent: 56),

                _buildMathRow(
                  context,
                  provider.t('Spendable Income'),
                  format.format(provider.spendableIncome),
                  CupertinoIcons.money_dollar_circle,
                  Colors.orange,
                ),
                const Divider(height: 0, indent: 56),

                _buildMathRow(
                  context,
                  provider.t('Expense'),
                  '- ${format.format(provider.realCurrentMonthExpense)}',
                  CupertinoIcons.arrow_up_right_circle_fill,
                  Colors.red,
                ),
                const Divider(height: 0, indent: 56),

                _buildMathRow(
                  context,
                  provider.t('Remaining Balance'),
                  format.format(provider.realRemainingBalance),
                  CupertinoIcons.checkmark_seal_fill,
                  Colors.teal,
                ),
                const Divider(height: 0, indent: 56),

                _buildMathRow(
                  context,
                  provider.t('Remaining Days'),
                  '${provider.remainingDaysInMonth}',
                  CupertinoIcons.calendar,
                  Colors.purple,
                ),
              ],
            ),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildMathRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
