import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;

  // NEW: Category variables
  String _selectedCategory = 'Food';
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTransaction() {
    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid title and amount!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: enteredTitle,
      amount: enteredAmount,
      date: _selectedDate,
      isExpense: _isExpense,
      category: _selectedCategory, // NEW: Save the category!
    );

    Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).addTransaction(newTransaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically change dropdown list based on Income/Expense toggle
    final currentCategories = _isExpense
        ? _expenseCategories
        : _incomeCategories;
    // Make sure the selected category is actually in the current list
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = currentCategories.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
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
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isExpense = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
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
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // NEW: Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: currentCategories.map((String category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: _presentDatePicker,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
