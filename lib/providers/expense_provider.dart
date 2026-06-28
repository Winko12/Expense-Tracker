import 'package:expense_tracker/models/category_item.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _boxName = 'transactionsBox';
  List<Transaction> _transactions = [];

  // 1. LANGUAGE
  bool _isBurmese = false;
  String _currencySymbol = 'Ks';

  bool get isBurmese => _isBurmese;
  String get currencySymbol => _currencySymbol;

  ExpenseProvider() {
    var settingsBox = Hive.box('settingsBox');
    _isBurmese = settingsBox.get('isBurmese', defaultValue: false);
    _currencySymbol = settingsBox.get(
      'currencySymbol',
      defaultValue: 'Ks',
    ); // Load from memory
  }

  List<String> get uniqueTitles {
    return _transactions.map((tx) => tx.title).toSet().toList();
  }

  void toggleLanguage() {
    _isBurmese = !_isBurmese;
    Hive.box(
      'settingsBox',
    ).put('isBurmese', _isBurmese); // NEW: Save to memory instantly!
    notifyListeners();
  }

  void updateCurrencySymbol(String symbol) {
    _currencySymbol = symbol;
    Hive.box('settingsBox').put('currencySymbol', symbol);
    notifyListeners();
  }

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
      'Stats': 'စာရင်းဇယား',
      'Expense Breakdown': 'အသုံးစရိတ် ခွဲခြမ်းစိတ်ဖြာမှု',
      'All Time': 'အချိန်အားလုံး',
      'No transactions found.': 'စာရင်း မရှိပါ။',
      'Load More': 'ထပ်မံကြည့်ရှုရန်',
      'Edit Transaction': 'စာရင်းပြင်ရန်',
      'Title': 'အကြောင်းအရာ',
      'Amount': 'ပမာဏ',
      'Category': 'အမျိုးအစား',
      'Wallet': 'ပိုက်ဆံ',
      'Save': 'သိမ်းဆည်းပါ',
      'Delete': 'ဖျက်ပါ',
      'Settings': 'ဆက်တင်များ', // NEW
      'Language': 'ဘာသာစကား', // NEW
      'Export Data (CSV)': 'ဒေတာထုတ်ယူရန် (CSV)', // NEW
      'Clear All Data': 'ဒေတာအားလုံးဖျက်ရန်', // NEW
      'Add Transaction': 'စာရင်းသွင်းရန်',
      'Manage Categories': 'အမျိုးအစားများစီမံရန်',
      'Add Category': 'အမျိုးအစားထည့်ရန်',
      'Edit Category': 'အမျိုးအစားပြင်ရန်',
      'Category Name': 'အမျိုးအစားအမည်',
      'Are you sure?': 'သေချာပါသလား?',
      'Cancel': 'မလုပ်တော့ပါ',
      'This action cannot be undone.': 'ဤလုပ်ဆောင်ချက်ကို ပြန်ပြင်၍မရပါ။',
      'Currency Symbol': 'ငွေကြေးသင်္ကေတ',
      'Contact Me': 'ဆက်သွယ်ရန်',
    };
    return myDict[enText] ?? enText;
  }

  // 2. FILTERS & PAGINATION
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay; // NEW: Specific day filter!
  String _searchQuery = '';
  DateTimeRange? _statsDateRange;

  int _displayedLimit = 15; // NEW: Pagination limit!

  DateTime get selectedMonth => _selectedMonth;
  DateTime? get selectedDay => _selectedDay;
  String get searchQuery => _searchQuery;
  DateTimeRange? get statsDateRange => _statsDateRange;
  bool get hasMore => filteredTransactions.length > _displayedLimit;

  List<Transaction> get transactions => _transactions;

  // 3. FILTERED & PAGINATED LISTS
  List<Transaction> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesMonth =
          tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
      final matchesDay =
          _selectedDay == null ||
          (tx.date.day == _selectedDay!.day &&
              tx.date.month == _selectedDay!.month &&
              tx.date.year == _selectedDay!.year);
      final matchesSearch =
          _searchQuery.isEmpty ||
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesMonth && matchesDay && matchesSearch;
    }).toList();
  }

  // Returns only the top 15 (or 30, 45...) items for high performance!
  List<Transaction> get paginatedTransactions =>
      filteredTransactions.take(_displayedLimit).toList();

  // 4. DYNAMIC MATH (Reacts to Month OR Day selection!)
  double get monthlyIncome => filteredTransactions
      .where((tx) => !tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);
  double get monthlyExpense => filteredTransactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get monthlyBalance => monthlyIncome - monthlyExpense;

  double get monthlyAverage {
    if (_selectedDay != null) {
      return monthlyExpense; // If viewing 1 day, average is just that day's cost
    }
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

  // Stats Screen Math
  void setStatsDateRange(DateTimeRange? range) {
    _statsDateRange = range;
    notifyListeners();
  }

  List<Transaction> get statsTransactions {
    if (_statsDateRange == null) return _transactions;
    return _transactions
        .where(
          (tx) =>
              tx.date.isAfter(
                _statsDateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              tx.date.isBefore(
                _statsDateRange!.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
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
      if (tx.isExpense) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  Map<String, double> getStatsCategoryData(bool isExpense) {
    Map<String, double> data = {};
    for (var tx in statsTransactions) {
      if (tx.isExpense == isExpense) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  // 5. ACTIONS
  void changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    _selectedDay = null; // Reset day filter
    _displayedLimit = 15; // Reset pagination
    notifyListeners();
  }

  void pickDay(DateTime? day) {
    _selectedDay = day;
    _displayedLimit = 15;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _displayedLimit = 15;
    notifyListeners();
  }

  void loadMore() {
    _displayedLimit += 15;
    notifyListeners();
  }

  void loadTransactions() {
    _transactions = Hive.box<Transaction>(_boxName).values.toList();
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

  // ==========================================
  // 6. CATEGORY CRUD
  // ==========================================
  List<CategoryItem> _categories = [];

  // Get string lists for the Dropdown menus
  List<String> get expenseCategories =>
      _categories.where((c) => c.isExpense).map((c) => c.name).toList();
  List<String> get incomeCategories =>
      _categories.where((c) => !c.isExpense).map((c) => c.name).toList();
  List<CategoryItem> get rawCategories => _categories;

  void loadCategories() {
    var box = Hive.box<CategoryItem>('categoriesBox');
    if (box.isEmpty) {
      // Create defaults if it's the first time
      box.addAll([
        CategoryItem(id: '1', name: 'Food', isExpense: true),
        CategoryItem(id: '2', name: 'Transport', isExpense: true),
        CategoryItem(id: '3', name: 'Shopping', isExpense: true),
        CategoryItem(id: '4', name: 'Bills', isExpense: true),
        CategoryItem(id: '5', name: 'Entertainment', isExpense: true),
        CategoryItem(id: '6', name: 'Other', isExpense: true),
        CategoryItem(id: '7', name: 'Salary', isExpense: false),
        CategoryItem(id: '8', name: 'Gift', isExpense: false),
        CategoryItem(id: '9', name: 'Investment', isExpense: false),
      ]);
    }
    _categories = box.values.toList();
    notifyListeners();
  }

  void addCategory(CategoryItem category) {
    Hive.box<CategoryItem>('categoriesBox').add(category);
    loadCategories();
  }

  void updateCategory(CategoryItem category, String newName) {
    category.name = newName;
    category.save();
    loadCategories();
  }

  void deleteCategory(CategoryItem category) {
    category.delete();
    loadCategories();
  }

  void clearAllData() {
    Hive.box<Transaction>(_boxName).clear(); // Wipes the whole database
    loadTransactions(); // Refreshes the UI to show 0 balance
  }
}
