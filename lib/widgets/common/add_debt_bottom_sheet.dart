import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/debt_item.dart';
import '../../providers/expense_provider.dart';
import 'ios_form_elements.dart';

void showAddDebtBottomSheet(
  BuildContext context,
  ExpenseProvider provider, {
  DebtItem? existingDebt,
}) {
  final nameController = TextEditingController(
    text: existingDebt?.personName ?? '',
  );
  final amountController = TextEditingController(
    text: existingDebt != null ? existingDebt.amount.toString() : '',
  );
  bool isOwedToMe = existingDebt?.isOwedToMe ?? true;
  DateTime selectedDate = existingDebt?.date ?? DateTime.now();

  // NEW: Wallet Logic
  String selectedPaymentMethod = existingDebt?.paymentMethod ?? 'Cash';
  final List<String> paymentMethods = [
    'Cash',
    'KBZPay',
    'AYA Pay',
    'CB Pay',
    'Bank Transfer',
  ];

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    provider.t(existingDebt != null ? 'Edit Debt' : 'Add Debt'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

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

                  // NEW: WALLET SELECTOR
                  IOSDropdown(
                    value: selectedPaymentMethod,
                    items: paymentMethods,
                    icon: CupertinoIcons.creditcard,
                    onChanged: (v) =>
                        setModalState(() => selectedPaymentMethod = v!),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1C1C1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.calendar,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  CupertinoButton.filled(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final amount = double.tryParse(amountController.text);
                      if (name.isNotEmpty && amount != null && amount > 0) {
                        if (existingDebt != null) {
                          // FIXED: Now saves the Wallet choice!
                          provider.updateDebt(
                            existingDebt,
                            name,
                            amount,
                            isOwedToMe,
                            selectedDate,
                            selectedPaymentMethod,
                          );
                        } else {
                          provider.addDebt(
                            DebtItem(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              personName: name,
                              amount: amount,
                              date: selectedDate,
                              isOwedToMe: isOwedToMe,
                              paymentMethod:
                                  selectedPaymentMethod, // Saves wallet!
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (existingDebt != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (ctx2) => CupertinoAlertDialog(
                            title: Text(provider.t('Are you sure?')),
                            actions: [
                              CupertinoDialogAction(
                                child: Text(provider.t('Cancel')),
                                onPressed: () => Navigator.pop(ctx2, false),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () => Navigator.pop(ctx2, true),
                                child: Text(provider.t('Delete')),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.deleteDebt(existingDebt);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(CupertinoIcons.trash),
                      label: Text(provider.t('Delete Debt')),
                      style: TextButton.styleFrom(
                        foregroundColor: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
