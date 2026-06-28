import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/transaction_tile.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String categoryName;
  final bool isExpense;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.isExpense,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  // NEW: Pagination Logic!
  final ScrollController _scrollController = ScrollController();
  int _limit = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        setState(() => _limit += 15); // Load 15 more when reaching bottom!
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    // Filter stats transactions to ONLY match this specific category
    final allFilteredTx = provider.statsTransactions
        .where(
          (tx) =>
              tx.category == widget.categoryName &&
              tx.isExpense == widget.isExpense,
        )
        .toList();

    final hasMore = allFilteredTx.length > _limit;
    final displayedTx = allFilteredTx.take(_limit).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          provider.t(widget.categoryName),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: displayedTx.isEmpty
          ? Center(
              child: Text(
                provider.t('No transactions found.'),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: displayedTx.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayedTx.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }
                // ANIMATED TRANSACTION TILES!
                return TransactionTile(
                  tx: displayedTx[index],
                  provider: provider,
                ).animate().fade().slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }
}
