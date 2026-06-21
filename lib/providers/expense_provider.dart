import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _boxName = 'transactionsBox';
  List<Transaction> _transactions = [];

  // --- NEW: Filter Variables ---
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';

  DateTime get selectedMonth => _selectedMonth;
  String get searchQuery => _searchQuery;

  // --- NEW: Filtered Transactions (By Month & Search) ---
  List<Transaction> get filteredTransactions {
    return _transactions.where((tx) {
      // 1. Does it match the selected month?
      final matchesMonth =
          tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;

      // 2. Does it match the search bar? (Checks title, category, and wallet)
      final matchesSearch =
          _searchQuery.isEmpty ||
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesMonth && matchesSearch;
    }).toList();
  }

  // --- NEW: Advanced Monthly Math ---
  double get monthlyIncome {
    return _transactions
        .where(
          (tx) =>
              !tx.isExpense &&
              tx.date.year == _selectedMonth.year &&
              tx.date.month == _selectedMonth.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpense {
    return _transactions
        .where(
          (tx) =>
              tx.isExpense &&
              tx.date.year == _selectedMonth.year &&
              tx.date.month == _selectedMonth.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyAverage {
    // If it's the current month, divide by days passed. If past month, divide by total days in that month.
    int daysPassed =
        (_selectedMonth.year == DateTime.now().year &&
            _selectedMonth.month == DateTime.now().month)
        ? DateTime.now().day
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    if (daysPassed == 0) return 0;
    return monthlyExpense / daysPassed;
  }

  // Calculate Total All-Time Balance
  double get totalBalance {
    double balance = 0;
    for (var tx in _transactions) {
      if (tx.isExpense)
        balance -= tx.amount;
      else
        balance += tx.amount;
    }
    return balance;
  }

  // Category Math for Stats Page
  Map<String, double> get categoryExpenses {
    Map<String, double> data = {};
    for (var tx in filteredTransactions) {
      // Only show stats for filtered month
      if (tx.isExpense) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  // --- ACTIONS ---

  // Change the month using the arrows
  void changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    notifyListeners();
  }

  // Update search query
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void loadTransactions() {
    var box = Hive.box<Transaction>(_boxName);
    _transactions = box.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    var box = Hive.box<Transaction>(_boxName);
    box.add(transaction);
    loadTransactions();
  }

  void deleteTransaction(Transaction transaction) {
    transaction.delete();
    loadTransactions();
  }
}
