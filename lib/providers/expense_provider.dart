import 'package:expense_tracker/models/category_item.dart';
import 'package:expense_tracker/models/debt_item.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _boxName = 'transactionsBox';
  List<Transaction> _transactions = [];

  // 1. LANGUAGE
  bool _isBurmese = false;
  String _currencySymbol = 'Ks';
  double _savingsValue = 20.0;
  bool _isSavingsPercentage = true;
  // int? _customRemainingDays;
  // int? get customRemainingDays => _customRemainingDays;
  // NEW: Save the target date instead of a static number!
  DateTime? _customTargetDate;
  bool get hasCustomDays => _customTargetDate != null; // Helper for UI

  bool get isBurmese => _isBurmese;
  String get currencySymbol => _currencySymbol;

  double get savingsValue => _savingsValue;
  bool get isSavingsPercentage => _isSavingsPercentage;

  int _reminderHour = 20; // Default 8 PM (20:00)
  int _reminderMinute = 0;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  ExpenseProvider() {
    var settingsBox = Hive.box('settingsBox');
    _isBurmese = settingsBox.get('isBurmese', defaultValue: false);
    _currencySymbol = settingsBox.get(
      'currencySymbol',
      defaultValue: 'Ks',
    ); // Kept your default 'Ks'
    _savingsValue = settingsBox.get('savingsValue', defaultValue: 20.0);
    _isSavingsPercentage = settingsBox.get(
      'isSavingsPercentage',
      defaultValue: true,
    );

    _reminderHour = settingsBox.get('reminderHour', defaultValue: 20);
    _reminderMinute = settingsBox.get('reminderMinute', defaultValue: 0);

    // 1. Load saved Stats Date Range
    int? startMs = settingsBox.get('statsStartDate');
    int? endMs = settingsBox.get('statsEndDate');
    if (startMs != null && endMs != null) {
      _statsDateRange = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(startMs),
        end: DateTime.fromMillisecondsSinceEpoch(endMs),
      );
    }

    // 2. THE FIX: Load the custom target date (Instead of the old _customRemainingDays)
    int? targetMs = settingsBox.get('customTargetDateMs');
    if (targetMs != null) {
      _customTargetDate = DateTime.fromMillisecondsSinceEpoch(targetMs);
      DateTime today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      // If the target date has passed, clear it out!
      if (_customTargetDate!.isBefore(today) ||
          _customTargetDate!.isAtSameMomentAs(today)) {
        _customTargetDate = null;
        settingsBox.delete('customTargetDateMs');
      }
    }
  }

  // NEW: Update Custom Days (Caps at 31)
  void updateCustomRemainingDays(int? days) {
    if (days == null || days <= 0) {
      _customTargetDate = null;
      Hive.box('settingsBox').delete('customTargetDateMs');
    } else {
      if (days > 31) days = 31; // Cap at 31
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // The Target Date is exactly 'N' days from today
      _customTargetDate = today.add(Duration(days: days));
      Hive.box(
        'settingsBox',
      ).put('customTargetDateMs', _customTargetDate!.millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  void updateReminderTime(int hour, int minute) {
    _reminderHour = hour;
    _reminderMinute = minute;
    Hive.box('settingsBox').put('reminderHour', hour);
    Hive.box('settingsBox').put('reminderMinute', minute);
    notifyListeners();
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

  void updateSavings(double value, bool isPercentage) {
    _savingsValue = value;
    _isSavingsPercentage = isPercentage;
    Hive.box('settingsBox').put('savingsValue', value);
    Hive.box('settingsBox').put('isSavingsPercentage', isPercentage);
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
      'Date': 'ရက်စွဲ',
      'Close': 'ပိတ်မည်',
      'Budget': 'ဘတ်ဂျက်',
      'Daily Limit': 'နေ့စဉ်သုံးစွဲခွင့်',
      'Remaining Days': 'ကျန်ရှိသောရက်များ',
      'Remaining Balance': 'လက်ကျန်ငွေ',
      'You can safely spend': 'ယနေ့အတွက် သုံးစွဲနိုင်သော ပမာဏ',
      'per day': 'တစ်ရက်လျှင်',
      'Overspent!': 'သုံးစရိတ်ပိုနေပါသည်!',
      'This Month': 'ယခုလ',
      'Savings Goal': 'စုဆောင်းငွေ ရည်မှန်းချက်',
      'Locked Savings': 'ဖယ်ထားသော စုဆောင်းငွေ',
      'Spendable Income': 'သုံးစွဲနိုင်သော ဝင်ငွေ',
      'Percentage': 'ရာခိုင်နှုန်း',
      'Export PDF': 'PDF ထုတ်ယူရန်',
      'Daily Reminder': 'နေ့စဉ် သတိပေးချက်',
      'Warning: Exceeds safe daily limit!':
          'သတိပေးချက် - နေ့စဉ်သုံးစွဲခွင့်ထက် ကျော်လွန်နေပါသည်!',
      'Transaction saved!': 'မှတ်တမ်းတင်ပြီးပါပြီ!',
      'Today Spent': 'ယနေ့သုံးစရိတ်',
      'Available Balance': 'သုံးစွဲနိုင်သော လက်ကျန်ငွေ',
      'Rollover Balance': 'ယခင်လမှလက်ကျန်',
      'Total Available': 'စုစုပေါင်းရရှိနိုင်သောငွေ',
      'Net Balance': 'အသားတင် လက်ကျန်ငွေ',
      'Day Expense': 'တစ်ရက်တာ သုံးစရိတ်',
      'Search Results': 'ရှာဖွေမှု ရလဒ်များ',
      'Debts': 'အကြွေးစာရင်း',
      'Lent (They owe me)': 'ချေးပေးထားသောငွေ (ရရန်ရှိ)',
      'Borrowed (I owe them)': 'ချေးယူထားသောငွေ (ပေးရန်ရှိ)',
      'Add Debt': 'အကြွေးမှတ်မည်',
      'Person Name': 'နာမည်',
      'Settle': 'ရှင်းလင်းမည်',
      'Settled': 'ရှင်းလင်းပြီး',
      'Active': 'လက်ရှိ',
      'Unsettle': 'ပြန်လည်သက်ဝင်စေမည်', // Unsettle
      'Mark as Active': 'လက်ရှိစာရင်းသို့ပြောင်းမည်', // Mark as Active
    };
    return myDict[enText] ?? enText;
  }

  // 2. FILTERS & PAGINATION
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  String _searchQuery = '';
  DateTimeRange? _statsDateRange;

  int _displayedLimit = 15;

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

  // NEW: Calculates the exact Income and Expense of the Search Results!
  double get searchTotalIncome => filteredTransactions
      .where((tx) => !tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);
  double get searchTotalExpense => filteredTransactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  // This will show a negative number if the search is mostly expenses (like searching "Food")
  double get searchNetBalance => searchTotalIncome - searchTotalExpense;

  double _calculateRollover(DateTime targetMonth) {
    DateTime firstDayOfTarget = DateTime(
      targetMonth.year,
      targetMonth.month,
      1,
    );
    double rollover = 0.0;
    for (var tx in _transactions) {
      if (tx.date.isBefore(firstDayOfTarget)) {
        rollover += tx.isExpense ? -tx.amount : tx.amount;
      }
    }
    return rollover;
  }

  // NEW: Calculate exactly how much was spent on the specifically selected day
  double get selectedDayExpense {
    if (_selectedDay == null) return 0;
    return _transactions
        .where(
          (tx) =>
              tx.isExpense &&
              tx.date.year == _selectedDay!.year &&
              tx.date.month == _selectedDay!.month &&
              tx.date.day == _selectedDay!.day,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // NEW: Calculate savings for the specifically selected month on the dashboard
  double get filteredLockedSavings {
    double locked = _isSavingsPercentage
        ? monthlyIncome * (_savingsValue / 100)
        : _savingsValue;

    if (locked > monthlyIncome) return monthlyIncome;
    if (locked < 0) return 0;
    return locked;
  }

  // NEW: The true balance you are allowed to spend on the Dashboard!
  double get filteredSpendableBalance {
    double rollover = _calculateRollover(_selectedMonth);
    return rollover + monthlyIncome - filteredLockedSavings - monthlyExpense;
  }

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

  // ==========================================
  // 5. DYNAMIC DAILY BUDGET LOGIC (Current Month Only)
  // ==========================================

  // 1. Get exact income for the REAL current month
  double get realCurrentMonthIncome {
    DateTime now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              !tx.isExpense &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // 2. Get exact expense for the REAL current month
  double get realCurrentMonthExpense {
    DateTime now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.isExpense &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get realRollover => _calculateRollover(DateTime.now());

  double get totalAvailableFunds => realRollover + realCurrentMonthIncome;

  // NEW: Get exact expense for TODAY only!
  double get todayExpense {
    DateTime now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.isExpense &&
              tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get lockedSavings {
    // Savings is calculated based on CURRENT month income (so we don't re-tax old money!)
    double locked = _isSavingsPercentage
        ? realCurrentMonthIncome * (_savingsValue / 100)
        : _savingsValue;
    // BUT we cap it at totalAvailableFunds in case they want to save their rollover money too.
    if (locked > totalAvailableFunds) return totalAvailableFunds;
    if (locked < 0) return 0;
    return locked;
  }

  double get spendableIncome => totalAvailableFunds - lockedSavings;

  // 3. How much money is left this month?
  double get realRemainingBalance => spendableIncome - realCurrentMonthExpense;

  // 4. How many days are left in this month? (Including today)
  // REPLACED: Now checks if you typed a custom number first!
  int get effectiveRemainingDays {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (_customTargetDate != null) {
      int daysLeft = _customTargetDate!.difference(today).inDays;
      if (daysLeft > 0) return daysLeft;
    }

    // Default fallback: Days left in the current real month
    int totalDays = DateTime(now.year, now.month + 1, 0).day;
    return totalDays - now.day + 1;
  }

  // UPDATED: Now divides by the effective days!
  double get safeDailyLimit {
    if (realRemainingBalance <= 0) return 0;
    return realRemainingBalance / effectiveRemainingDays;
  }

  // Stats Screen Math
  void setStatsDateRange(DateTimeRange? range) {
    _statsDateRange = range;
    var box = Hive.box('settingsBox');
    if (range == null) {
      box.delete('statsStartDate');
      box.delete('statsEndDate');
    } else {
      box.put('statsStartDate', range.start.millisecondsSinceEpoch);
      box.put('statsEndDate', range.end.millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  List<String> get searchSuggestions {
    final Set<String> suggestions = {};
    suggestions.addAll(uniqueTitles); // Past titles (Netflix, KFC, etc)
    suggestions.addAll(
      rawCategories.map((c) => c.name),
    ); // Categories (Food, Transport)
    suggestions.addAll(
      _transactions.map((tx) => tx.paymentMethod),
    ); // Wallets (KBZPay)
    return suggestions.toList();
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
    if (day != null) {
      // FIX: Sync the selected month with the picked day so the list doesn't go blank!
      _selectedMonth = DateTime(day.year, day.month, 1);
    }
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

  // ==========================================
  // 7. DEBT TRACKER LOGIC
  // ==========================================
  List<DebtItem> _debts = [];
  List<DebtItem> get activeDebts => _debts.where((d) => !d.isSettled).toList();
  List<DebtItem> get settledDebts => _debts.where((d) => d.isSettled).toList();

  void loadDebts() {
    var box = Hive.box<DebtItem>('debtsBox');
    _debts = box.values.toList();
    _debts.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void addDebt(DebtItem debt) {
    Hive.box<DebtItem>('debtsBox').add(debt);
    loadDebts();
  }

  // MAGIC: Settling a debt automatically generates a transaction!
  void settleDebt(DebtItem debt) {
    debt.isSettled = true;
    debt.save();

    // If they owed me, settling means I got my money back (Income).
    // If I owed them, settling means I paid them back (Expense).
    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: debt.isOwedToMe
          ? '${debt.personName} paid me back'
          : 'I paid back ${debt.personName}',
      amount: debt.amount,
      date: DateTime.now(),
      isExpense: !debt.isOwedToMe,
      category: 'Other',
      paymentMethod: 'Cash', // Defaults to cash, user can edit later
    );

    addTransaction(tx); // Add to the main ledger!
    loadDebts();
  }

  void deleteDebt(DebtItem debt) {
    debt.delete();
    loadDebts();
  }

  // NEW: Move a debt back to Active!
  void unsettleDebt(DebtItem debt) {
    debt.isSettled = false;
    debt.save();
    loadDebts();
  }
}
