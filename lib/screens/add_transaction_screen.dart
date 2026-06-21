import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction; // If passed = EDIT MODE!
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

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];
  final List<String> _incomeCategories = [
    'Salary',
    'Gift',
    'Investment',
    'Other',
  ];
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
    // If we are editing, fill the text boxes with the existing data!
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

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  void _saveTransaction() {
    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0)
      return;

    if (widget.existingTransaction != null) {
      // EDIT MODE: Update existing Hive object
      final tx = widget.existingTransaction!;
      tx.title = enteredTitle;
      tx.amount = enteredAmount;
      tx.date = _selectedDate;
      tx.isExpense = _isExpense;
      tx.category = _selectedCategory;
      tx.paymentMethod = _selectedPaymentMethod;
      tx.save(); // Hive saves changes automatically!
      Provider.of<ExpenseProvider>(context, listen: false).loadTransactions();
    } else {
      // ADD MODE: Create new object
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
        ? _expenseCategories
        : _incomeCategories;
    if (!currentCategories.contains(_selectedCategory))
      _selectedCategory = currentCategories.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTransaction != null
              ? provider.t('Edit Transaction')
              : provider.t('Add Transaction'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (val) =>
                  setState(() => _isExpense = val.first),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: provider.t('Title'),
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: provider.t('Amount'),
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: provider.t('Category'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: currentCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: provider.t('Wallet'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _paymentMethods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPaymentMethod = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _presentDatePicker,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(
                provider.t('Save'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.existingTransaction != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).deleteTransaction(widget.existingTransaction!);
                  Navigator.pop(context);
                },
                icon: const Icon(CupertinoIcons.trash),
                label: Text(provider.t('Delete')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B30),
                ), // iOS Red
              ),
            ],
          ],
        ).animate().fade().slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
