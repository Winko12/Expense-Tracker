import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../services/pdf_service.dart'; // Extracted!
import '../widgets/budget/budget_components.dart'; // Extracted!

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late TextEditingController _savingsController;
  late TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    _savingsController = TextEditingController(
      text: provider.savingsValue == 0
          ? ''
          : provider.savingsValue.toStringAsFixed(0),
    );
    _daysController = TextEditingController(
      text: provider.hasCustomDays
          ? provider.effectiveRemainingDays.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _savingsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. EXTRACTED UI COMPONENT
          DailyAllowanceCard(provider: provider),

          const SizedBox(height: 35),

          // 2. SAVINGS INPUT
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              provider.t('Savings Goal').toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: provider.isSavingsPercentage,
                  children: {
                    true: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(provider.t('Percentage')),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(provider.t('Amount')),
                    ),
                  },
                  onValueChanged: (val) {
                    provider.updateSavings(
                      double.tryParse(_savingsController.text) ?? 0,
                      val!,
                    );
                  },
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: CupertinoTextField(
                    controller: _savingsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: '0',
                    textAlign: TextAlign.right,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        provider.isSavingsPercentage
                            ? '%'
                            : provider.currencySymbol,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    onChanged: (val) => provider.updateSavings(
                      double.tryParse(val) ?? 0,
                      provider.isSavingsPercentage,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 35),

          // 3. MATH BREAKDOWN USING EXTRACTED WIDGETS
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
                MathRow(
                  title: provider.t('Income'),
                  value: format.format(provider.realCurrentMonthIncome),
                  icon: CupertinoIcons.arrow_down_left_circle_fill,
                  iconColor: Colors.green,
                ),
                const Divider(height: 0, indent: 56),
                if (provider.realRollover != 0) ...[
                  MathRow(
                    title: provider.t('Rollover Balance'),
                    value: format.format(provider.realRollover),
                    icon: CupertinoIcons.arrow_turn_down_right,
                    iconColor: Colors.indigo,
                  ),
                  const Divider(height: 0, indent: 56),
                ],
                if (provider.realRollover != 0) ...[
                  MathRow(
                    title: provider.t('Total Available'),
                    value: format.format(provider.totalAvailableFunds),
                    icon: CupertinoIcons.sum,
                    iconColor: Colors.blueGrey,
                  ),
                  const Divider(height: 0, indent: 56),
                ],
                MathRow(
                  title: provider.t('Locked Savings'),
                  value: '- ${format.format(provider.lockedSavings)}',
                  icon: CupertinoIcons.lock_fill,
                  iconColor: Colors.blue,
                ),
                const Divider(height: 0, indent: 56),
                MathRow(
                  title: provider.t('Spendable Income'),
                  value: format.format(provider.spendableIncome),
                  icon: CupertinoIcons.money_dollar_circle,
                  iconColor: Colors.orange,
                ),
                const Divider(height: 0, indent: 56),
                MathRow(
                  title: provider.t('Expense'),
                  value: '- ${format.format(provider.realCurrentMonthExpense)}',
                  icon: CupertinoIcons.arrow_up_right_circle_fill,
                  iconColor: Colors.red,
                ),
                const Divider(height: 0, indent: 56),
                MathRow(
                  title: provider.t('Remaining Balance'),
                  value: format.format(provider.realRemainingBalance),
                  icon: CupertinoIcons.checkmark_seal_fill,
                  iconColor: Colors.teal,
                ),
                const Divider(height: 0, indent: 56),
                MathRow(
                  title: provider.t('Today Spent'),
                  value: format.format(provider.todayExpense),
                  icon: CupertinoIcons.cart_fill,
                  iconColor: Colors.pink,
                ),
                const Divider(height: 0, indent: 56),

                // EDITABLE REMAINING DAYS
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    provider.t('Remaining Days'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 70,
                    child: CupertinoTextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      placeholder: '${provider.effectiveRemainingDays}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      onChanged: (val) {
                        if (val.isEmpty) {
                          provider.updateCustomRemainingDays(null);
                        } else {
                          int? days = int.tryParse(val);
                          if (days != null && days > 31) {
                            days = 31;
                            _daysController.text = '31';
                            _daysController.selection =
                                TextSelection.fromPosition(
                                  const TextPosition(offset: 2),
                                );
                          }
                          provider.updateCustomRemainingDays(days);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 30),

          // 4. EXPORT USING SERVICE
          ElevatedButton.icon(
            onPressed: () => PdfService.exportBudgetReport(provider),
            icon: const Icon(CupertinoIcons.doc_text_fill),
            label: Text(
              provider.t('Export PDF'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
