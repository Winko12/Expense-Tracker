import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../widgets/ios_form_elements.dart'; // IMPORT EXTRACTED WIDGETS!

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;
  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'Cash';

  final List<String> _paymentMethods = [
    'Cash',
    'KBZPay',
    'AYA Pay',
    'CB Pay',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _selectedDate = tx.date;
      _isExpense = tx.isExpense;
      _selectedCategory = tx.category;
      _selectedPaymentMethod = tx.paymentMethod;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      return;
    }

    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      tx.title = enteredTitle;
      tx.amount = enteredAmount;
      tx.date = _selectedDate;
      tx.isExpense = _isExpense;
      tx.category = _selectedCategory;
      tx.paymentMethod = _selectedPaymentMethod;
      tx.save();
      Provider.of<ExpenseProvider>(context, listen: false).loadTransactions();
    } else {
      final newTx = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: enteredTitle,
        amount: enteredAmount,
        date: _selectedDate,
        isExpense: _isExpense,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
      );
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).addTransaction(newTx);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final currentCategories = _isExpense
        ? provider.expenseCategories
        : provider.incomeCategories;
    if (currentCategories.isEmpty) {
      currentCategories.add('Default'); // Safety fallback
    }

    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = currentCategories.first;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7), // iOS Background Color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.existingTransaction != null
              ? provider.t('Edit Transaction')
              : provider.t('Add Transaction'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: TextButton(
          // iOS "Cancel" button on the left
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        leadingWidth: 80,
        actions: [
          // iOS "Save" button on the right
          TextButton(
            onPressed: _saveTransaction,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // iOS Style Segmented Control
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
                groupValue: _isExpense,
                children: const {
                  true: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Expense'),
                  ),
                  false: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Income'),
                  ),
                },
                onValueChanged: (val) => setState(() => _isExpense = val!),
              ),
            ),
            const SizedBox(height: 24),

            // USING OUR NEW EXTRACTED WIDGETS!
            // NEW: SMART AUTO-COMPLETE TITLE FIELD
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty)
                  return const Iterable<String>.empty();
                // Filter past titles that match what we are typing
                return provider.uniqueTitles.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                _titleController.text = selection; // Auto-fill!
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                // If the user isn't using auto-suggest, keep tracking what they type manually
                _titleController.text = controller.text;
                controller.addListener(() {
                  _titleController.text = controller.text;
                });

                // If it's an existing transaction, pre-fill the autocomplete box
                if (widget.existingTransaction != null &&
                    controller.text.isEmpty) {
                  controller.text = widget.existingTransaction!.title;
                }

                return IOSTextField(
                  controller: controller,
                  focusNode: focusNode,
                  placeholder: 'Title (e.g. Netflix)',
                  icon: CupertinoIcons.doc_text,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                // Beautiful floating suggestions box
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width -
                          32, // Match screen width padding
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            leading: const Icon(
                              CupertinoIcons.clock,
                              color: Colors.grey,
                              size: 18,
                            ),
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            IOSTextField(
              controller: _amountController,
              placeholder: 'Amount',
              icon: CupertinoIcons.money_dollar,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            IOSDropdown(
              value: _selectedCategory,
              items: currentCategories,
              icon: CupertinoIcons.folder,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            IOSDropdown(
              value: _selectedPaymentMethod,
              items: _paymentMethods,
              icon: CupertinoIcons.creditcard,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
            ),

            // iOS Date Picker Button
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                      'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Delete Button (Only shows when editing)
            if (widget.existingTransaction != null)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  // NEW: Double Confirmation logic
                  onPressed: () async {
                    final provider = Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    );
                    final confirm = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: Text(provider.t('Are you sure?')),
                        content: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            provider.t('This action cannot be undone.'),
                          ),
                        ),
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

                    // If user clicked 'Delete', then we delete and close the screen
                    if (confirm == true) {
                      provider.deleteTransaction(widget.existingTransaction!);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      provider.t('Delete'),
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
