import 'dart:ui'; // NEW: For Glassmorphism

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
  final ScrollController _scrollController = ScrollController();
  int _limit = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        setState(() => _limit += 15);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allFilteredTx = provider.statsTransactions
        .where(
          (tx) =>
              tx.category == widget.categoryName &&
              tx.isExpense == widget.isExpense,
        )
        .toList();

    final hasMore = allFilteredTx.length > _limit;
    final displayedTx = allFilteredTx.take(_limit).toList();

    // 1. THE BEAUTIFUL PALE GRADIENT WRAPPER
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF000000)]
              : [const Color(0xFFEBF4FF), const Color(0xFFFFFFFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let gradient shine
        extendBodyBehindAppBar: true, // Scroll under AppBar
        // 2. GLASSMORPHISM APP BAR
        appBar: AppBar(
          title: Text(
            provider.t(widget.categoryName),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                    : const Color(0xFFEBF4FF).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),

        // 3. THE LIST
        body: displayedTx.isEmpty
            ? Center(
                child: Text(
                  provider.t('No transactions found.'),
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                // PUSH CONTENT DOWN BUT ALLOW SCROLLING UNDER GLASS
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                itemCount: displayedTx.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedTx.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return TransactionTile(
                    tx: displayedTx[index],
                    provider: provider,
                  ).animate().fade().slideX(begin: 0.05, end: 0);
                },
              ),
      ),
    );
  }
}
