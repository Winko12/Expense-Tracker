import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/transaction_tile.dart';

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryName;
  final bool isExpense;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    // Filter stats transactions to ONLY match this specific category
    final filteredTx = provider.statsTransactions
        .where((tx) => tx.category == categoryName && tx.isExpense == isExpense)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          provider.t(categoryName),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: filteredTx.isEmpty
          ? Center(
              child: Text(
                provider.t('No transactions found.'),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: filteredTx.length,
              itemBuilder: (context, index) {
                return TransactionTile(
                  tx: filteredTx[index],
                  provider: provider,
                );
              },
            ),
    );
  }
}
