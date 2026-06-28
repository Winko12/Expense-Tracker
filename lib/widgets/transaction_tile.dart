import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../screens/add_transaction_screen.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final ExpenseProvider provider;

  const TransactionTile({super.key, required this.tx, required this.provider});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.local_mall_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Salary':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // NEW: A beautiful iOS-style View Popup!
  void _showViewDetails(BuildContext context) {
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          tx.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        message: Column(
          children: [
            Text(
              '${tx.isExpense ? 'Expense' : 'Income'}: ${format.format(tx.amount)}',
              style: TextStyle(
                fontSize: 18,
                color: tx.isExpense
                    ? CupertinoColors.destructiveRed
                    : CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Date: ${DateFormat('MMMM dd, yyyy').format(tx.date)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Category: ${provider.t(tx.category)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Wallet: ${tx.paymentMethod}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );
    final color = tx.isExpense
        ? const Color(0xFFFF3B30)
        : const Color(0xFF34C759);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(provider.t('Are you sure?')),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(provider.t('This action cannot be undone.')),
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
      },
      onDismissed: (_) => provider.deleteTransaction(tx),
      child: GestureDetector(
        // CLICKING THE TEXT/ROW OPENS EDIT
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => AddTransactionScreen(existingTransaction: tx),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // CLICKING THE ICON OPENS VIEW DETAILS
              GestureDetector(
                onTap: () => _showViewDetails(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(tx.category),
                    color: color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.paymentMethod} • ${DateFormat('MMM dd').format(tx.date)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '${tx.isExpense ? '- ' : '+ '}${format.format(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade().slideX(begin: 0.05, end: 0);
  }
}
