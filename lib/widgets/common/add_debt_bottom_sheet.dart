import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/debt_item.dart';
import '../../providers/expense_provider.dart';
import 'ios_form_elements.dart';

void showAddDebtBottomSheet(BuildContext context, ExpenseProvider provider) {
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
