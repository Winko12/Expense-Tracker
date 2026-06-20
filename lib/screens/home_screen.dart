import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      // Consumer listens to our ExpenseProvider and rebuilds when data changes!
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 1. The Total Balance Card
              _buildBalanceCard(context, provider.totalBalance),

              const SizedBox(height: 20),

              // 2. The Transactions List Label
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

              // 3. The List of Transactions
              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
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
      ),
      // 4. Floating Action Button to add an expense
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- UI WIDGETS ---

  // Widget for the top Balance Card
  Widget _buildBalanceCard(BuildContext context, double balance) {
    // Format currency (e.g., $ 1,500.00)
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24), // Nice rounded corners
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

  // Widget for each transaction in the list
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

    // Dismissible gives us that satisfying iOS swipe-to-delete feeling!
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart, // Swipe right to left
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteTransaction(tx);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${tx.title} deleted')));
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tx.isExpense
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: tx.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dateFormat.format(tx.date)),
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
