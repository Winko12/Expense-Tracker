import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _boxName = 'transactionsBox';
  List<Transaction> _transactions = [];

  // A getter to let the UI read our transactions
  List<Transaction> get transactions => _transactions;

  // Automatically calculate the total balance!
  double get totalBalance {
    double balance = 0;
    for (var tx in _transactions) {
      if (tx.isExpense) {
        balance -= tx.amount;
      } else {
        balance += tx.amount;
      }
    }
    return balance;
  }

  Map<String, double> get categoryExpenses {
    Map<String, double> data = {};
    for (var tx in _transactions) {
      if (tx.isExpense) {
        if (data.containsKey(tx.category)) {
          data[tx.category] = data[tx.category]! + tx.amount;
        } else {
          data[tx.category] = tx.amount;
        }
      }
    }
    return data;
  }

  // Load all saved data from the phone's storage
  void loadTransactions() {
    var box = Hive.box<Transaction>(_boxName);
    _transactions = box.values.toList();

    // Sort transactions so the newest ones show at the top
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    // Tell the UI to refresh
    notifyListeners();
  }

  // Save a new transaction
  void addTransaction(Transaction transaction) {
    var box = Hive.box<Transaction>(_boxName);
    box.add(transaction);
    loadTransactions(); // Reload the list
  }

  // Delete a transaction
  void deleteTransaction(Transaction transaction) {
    transaction.delete(); // Hive makes deletion this easy!
    loadTransactions(); // Reload the list
  }
}
