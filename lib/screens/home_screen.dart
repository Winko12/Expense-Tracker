import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/expense_provider.dart';
import '../models/transaction.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // 1. NEW: Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (value) => provider.search(value),
                decoration: InputDecoration(
                  hintText: 'Search by title, KBZPay, Cash...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0, duration: 400.ms),
            ),

            // 2. NEW: Month Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => provider.changeMonth(-1),
                ),
                Text(
                      DateFormat('MMMM yyyy').format(provider.selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate(target: 1)
                    .scale(duration: 200.ms), // Subtle animation on change
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => provider.changeMonth(1),
                ),
              ],
            ),

            // 3. UPDATED: Monthly Summary Card
            _buildSummaryCard(context, provider)
                .animate()
                .fade(delay: 100.ms)
                .scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. UPDATED: Animated Transaction List
            Expanded(
              child: provider.filteredTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = provider.filteredTransactions[index];
                        return _buildTransactionTile(context, tx, provider)
                            .animate()
                            .fade(
                              delay: (50 * index).ms,
                            ) // Staggered list animation!
                            .slideX(begin: 0.1, end: 0);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, ExpenseProvider provider) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    format.format(provider.totalBalance),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Daily Avg',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    format.format(provider.monthlyAverage),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Income
              Row(
                children: [
                  const Icon(Icons.arrow_circle_up, color: Colors.green),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        format.format(provider.monthlyIncome),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Expense
              Row(
                children: [
                  const Icon(Icons.arrow_circle_down, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        format.format(provider.monthlyExpense),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
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
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteTransaction(tx),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tx.isExpense
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(tx.category),
            color: tx.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // NEW: Show wallet (KBZPay) next to the date!
        subtitle: Text(
          '${tx.paymentMethod} • ${DateFormat('MMM dd').format(tx.date)}',
        ),
        trailing: Text(
          '${tx.isExpense ? '-' : '+'}${format.format(tx.amount)}',
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
