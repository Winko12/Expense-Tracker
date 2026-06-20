import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper method to pick the right icon for the category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie;
      case 'Salary':
        return Icons.work;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Investment':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildBalanceCard(context, provider.totalBalance),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = provider.transactions[index];
                        return _buildTransactionTile(context, tx, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(balance),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction tx,
    ExpenseProvider provider,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteTransaction(tx);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tx.isExpense
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          // NEW: We now use the category icon here!
          child: Icon(
            _getCategoryIcon(tx.category),
            color: tx.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // NEW: Show the category name next to the date
        subtitle: Text('${tx.category} • ${dateFormat.format(tx.date)}'),
        trailing: Text(
          '${tx.isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: tx.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
      ),
    );
  }
}
