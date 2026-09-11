import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/debt_item.dart';
import '../providers/expense_provider.dart';
import '../widgets/common/ios_form_elements.dart'; // We use our reusable inputs!

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _showActive = true;

  void _showAddDebtDialog(BuildContext context, ExpenseProvider provider) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool isOwedToMe = true;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFFF2F2F7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    provider.t('Add Debt'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Toggle: Lent vs Borrowed
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: isOwedToMe,
                    children: {
                      true: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          provider.t('Lent (They owe me)'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      false: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          provider.t('Borrowed (I owe them)'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    },
                    onValueChanged: (val) =>
                        setModalState(() => isOwedToMe = val!),
                  ),
                  const SizedBox(height: 20),

                  IOSTextField(
                    controller: nameController,
                    placeholder: provider.t('Person Name'),
                    icon: CupertinoIcons.person_fill,
                  ),
                  IOSTextField(
                    controller: amountController,
                    placeholder: provider.t('Amount'),
                    icon: CupertinoIcons.money_dollar,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(height: 10),
                  CupertinoButton.filled(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final amount = double.tryParse(amountController.text);
                      if (name.isNotEmpty && amount != null && amount > 0) {
                        provider.addDebt(
                          DebtItem(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            personName: name,
                            amount: amount,
                            date: DateTime.now(),
                            isOwedToMe: isOwedToMe,
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    final displayList = _showActive
        ? provider.activeDebts
        : provider.settledDebts;

    return CustomScrollView(
      slivers: [
        // 1. GLASSMORPHISM APP BAR
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
          title: Text(
            provider.t('Debts'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.add, color: Colors.blue),
              onPressed: () => _showAddDebtDialog(context, provider),
            ),
          ],
        ),

        // 2. TOGGLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _showActive,
                children: {
                  true: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(provider.t('Active')),
                  ),
                  false: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(provider.t('Settled')),
                  ),
                },
                onValueChanged: (val) => setState(() => _showActive = val!),
              ),
            ),
          ),
        ),

        // 3. DEBT LIST
        if (displayList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                provider.t('No transactions found.'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final debt = displayList[index];
                final color = debt.isOwedToMe
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.destructiveRed;
                final icon = debt.isOwedToMe
                    ? CupertinoIcons.arrow_down_left_circle_fill
                    : CupertinoIcons.arrow_up_right_circle_fill;

                return Dismissible(
                  key: Key(debt.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showCupertinoDialog<bool>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: Text(provider.t('Are you sure?')),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(provider.t('Cancel')),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(provider.t('Delete')),
                          ),
                        ],
                      ),
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => provider.deleteDebt(debt),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                        Icon(icon, color: color, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.personName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(debt.date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              format.format(debt.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!debt.isSettled)
                              GestureDetector(
                                onTap: () {
                                  provider.settleDebt(debt);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Debt settled and added to ledger!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    provider.t('Settle'),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                provider.t('Settled'),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fade().slideX(begin: 0.05, end: 0);
              }, childCount: displayList.length),
            ),
          ),
      ],
    );
  }
}
