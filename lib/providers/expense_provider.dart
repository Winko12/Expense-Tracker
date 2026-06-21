import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _boxName = 'transactionsBox';
  List<Transaction> _transactions = [];

  // ==========================================
  // 1. LANGUAGE SUPPORT (English / Burmese)
  // ==========================================
  bool _isBurmese = false;
  bool get isBurmese => _isBurmese;

  void toggleLanguage() {
    _isBurmese = !_isBurmese;
    notifyListeners();
  }

  // The built-in Translation Dictionary!
  String t(String enText) {
    if (!_isBurmese) return enText;
    const myDict = {
      'Dashboard': 'ပင်မစာမျက်နှာ',
      'Statistics': 'စာရင်းဇယား',
      'Total Balance': 'လက်ကျန်ငွေ',
      'Daily Avg': 'နေ့စဉ်ပျမ်းမျှ',
      'Income': 'ဝင်ငွေ',
      'Expense': 'ထွက်ငွေ',
      'Transactions': 'စာရင်းများ',
      'Search...': 'ရှာဖွေရန်...',
      'Home': 'အိမ်',
      'Stats': 'စာရင်း',
      'Expense Breakdown': 'အသုံးစရိတ် ခွဲခြမ်းစိတ်ဖြာမှု',
      'All Time': 'အချိန်အားလုံး',
      'No transactions found.': 'စာရင်း မရှိပါ။',
    };
    return myDict[enText] ?? enText;
  }

  // ==========================================
  // 2. STATE & FILTERS
  // ==========================================
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';
  DateTimeRange? _statsDateRange; // NEW: Custom Date Range for Stats Screen

  DateTime get selectedMonth => _selectedMonth;
  String get searchQuery => _searchQuery;
  DateTimeRange? get statsDateRange => _statsDateRange;
  List<Transaction> get transactions => _transactions;

  // ==========================================
  // 3. HOME SCREEN LOGIC
  // ==========================================
  List<Transaction> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesMonth =
          tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
      final matchesSearch =
          _searchQuery.isEmpty ||
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesMonth && matchesSearch;
    }).toList();
  }

  double get monthlyIncome => _transactions
      .where(
        (tx) =>
            !tx.isExpense &&
            tx.date.year == _selectedMonth.year &&
            tx.date.month == _selectedMonth.month,
      )
      .fold(0.0, (sum, tx) => sum + tx.amount);
  double get monthlyExpense => _transactions
      .where(
        (tx) =>
            tx.isExpense &&
            tx.date.year == _selectedMonth.year &&
            tx.date.month == _selectedMonth.month,
      )
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get monthlyAverage {
    int daysPassed =
        (_selectedMonth.year == DateTime.now().year &&
            _selectedMonth.month == DateTime.now().month)
        ? DateTime.now().day
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    if (daysPassed == 0) return 0;
    return monthlyExpense / daysPassed;
  }

  double get totalBalance => _transactions.fold(
    0.0,
    (sum, tx) => tx.isExpense ? sum - tx.amount : sum + tx.amount,
  );

  // ==========================================
  // 4. STATS SCREEN LOGIC (Date Range)
  // ==========================================
  void setStatsDateRange(DateTimeRange? range) {
    _statsDateRange = range;
    notifyListeners();
  }

  List<Transaction> get statsTransactions {
    if (_statsDateRange == null)
      return _transactions; // Show all if no range selected
    return _transactions.where((tx) {
      return tx.date.isAfter(
            _statsDateRange!.start.subtract(const Duration(days: 1)),
          ) &&
          tx.date.isBefore(_statsDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  double get statsTotalIncome => statsTransactions
      .where((tx) => !tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);
  double get statsTotalExpense => statsTransactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  Map<String, double> get statsCategoryExpenses {
    Map<String, double> data = {};
    for (var tx in statsTransactions) {
      if (tx.isExpense)
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
    }
    return data;
  }

  // ==========================================
  // 5. ACTIONS
  // ==========================================
  void changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    notifyListeners();
  }

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
    Hive.box<Transaction>(_boxName).add(transaction);
    loadTransactions();
  }

  void deleteTransaction(Transaction transaction) {
    transaction.delete();
    loadTransactions();
  }
}
