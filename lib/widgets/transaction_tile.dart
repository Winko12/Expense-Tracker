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

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final color = tx.isExpense
        ? const Color(0xFFFF3B30)
        : const Color(0xFF34C759);

    // BRINGING BACK SWIPE TO DELETE
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
                onPressed: () =>
                    Navigator.pop(ctx, false), // Returns false, cancels swipe
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () =>
                    Navigator.pop(ctx, true), // Returns true, deletes item
                child: Text(provider.t('Delete')),
              ),
            ],
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => provider.deleteTransaction(tx),
      child: GestureDetector(
        onTap: () {
          // THIS IS THE iOS MAGIC ANIMATION!
          Navigator.push(
            context,
            CupertinoPageRoute(
              fullscreenDialog: true, // Makes it slide up from the bottom!
              builder: (context) =>
                  AddTransactionScreen(existingTransaction: tx),
            ),
          );
        },
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
              Container(
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
                '${tx.isExpense ? '-' : '+'}${format.format(tx.amount)}',
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
