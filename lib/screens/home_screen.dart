import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/common/transaction_tile.dart'; // Make sure this path is correct!
import '../widgets/home/home_balance_header.dart'; // NEW
import '../widgets/home/home_sliver_app_bar.dart'; // NEW

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        final provider = Provider.of<ExpenseProvider>(context, listen: false);
        if (provider.hasMore) provider.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch(ExpenseProvider provider) {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        provider.search('');
      } else {
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _searchFocusNode.requestFocus(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1. EXTRACTED APP BAR
            HomeSliverAppBar(
              provider: provider,
              isSearching: _isSearching,
              searchFocusNode: _searchFocusNode,
              onToggleSearch: () => _toggleSearch(provider),
            ),

            // 2. EXTRACTED DYNAMIC HEADER
            HomeBalanceHeader(provider: provider),

            // 3. TRANSACTION LIST
            if (provider.paginatedTransactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    provider.t('No transactions found.'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == provider.paginatedTransactions.length)
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      return TransactionTile(
                        tx: provider.paginatedTransactions[index],
                        provider: provider,
                      );
                    },
                    childCount:
                        provider.paginatedTransactions.length +
                        (provider.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
