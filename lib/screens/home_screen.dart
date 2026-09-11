import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false; // NEW: Controls the Search Bar visibility
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
        provider.search(''); // Clear search when closing
      } else {
        Future.delayed(100.ms, () => _searchFocusNode.requestFocus());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final format = NumberFormat.currency(
          symbol: '${provider.currencySymbol} ',
          decimalDigits: 0,
        );

        // Calculate the Date text for the Header
        String dateText = provider.selectedDay != null
            ? DateFormat('MMMM dd, yyyy').format(provider.selectedDay!)
            : DateFormat('MMMM yyyy').format(provider.selectedMonth);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ==========================================
            // 1. SMART MORPHING APP BAR
            // ==========================================
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              // If searching, show Autocomplete. If not, show Date Picker!
              title: _isSearching
                  ? Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty)
                          return const Iterable<String>.empty();
                        return provider.searchSuggestions.where(
                          (option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (String selection) {
                        provider.search(selection);
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            return CupertinoTextField(
                              controller: controller,
                              focusNode: _searchFocusNode,
                              placeholder: provider.t('Search...'),
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  CupertinoIcons.search,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged: (val) => provider.search(val),
                            );
                          },
                    )
                  : GestureDetector(
                      onTap: () async {
                        if (provider.selectedDay != null) {
                          provider.pickDay(null); // Reset day
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: provider.selectedMonth,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) provider.pickDay(picked);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            provider.selectedDay != null
                                ? CupertinoIcons.xmark_circle_fill
                                : CupertinoIcons.chevron_down,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching
                        ? CupertinoIcons.clear_thick
                        : CupertinoIcons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => _toggleSearch(provider),
                ),
              ],
            ),

            // ==========================================
            // 2. TRUE BALANCE HEADER (Centered, Apple Style)
            // ==========================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      provider.t('Available Balance'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // This is the TRUE spendable balance (Rollover + Income - Savings - Expense)
                    Text(
                      format.format(provider.filteredSpendableBalance),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_down_left,
                                color: CupertinoColors.activeGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                format.format(provider.monthlyIncome),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: CupertinoColors.activeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.destructiveRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_up_right,
                                color: CupertinoColors.destructiveRed,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                format.format(provider.monthlyExpense),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fade().slideY(begin: -0.1, end: 0),
              ),
            ),

            // ==========================================
            // 3. TRANSACTION LIST
            // ==========================================
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
                      if (index == provider.paginatedTransactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      }
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
