import 'dart:ui';

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
        Future.delayed(100.ms, () => _searchFocusNode.requestFocus());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final format = NumberFormat.currency(
          symbol: '${provider.currencySymbol} ',
          decimalDigits: 0,
        );

        String dateText = provider.selectedDay != null
            ? DateFormat('MMM dd, yyyy').format(provider.selectedDay!)
            : DateFormat('MMMM yyyy').format(provider.selectedMonth);

        // ==========================================
        // DYNAMIC HEADER LOGIC
        // ==========================================
        String headerTitle;
        double headerAmount;
        bool hidePills = false;
        double pillIncome = provider.monthlyIncome;
        double pillExpense = provider.monthlyExpense;

        if (provider.searchQuery.isNotEmpty) {
          // 1. IF SEARCHING: Show search math!
          headerTitle = provider.t('Search Results');
          headerAmount = provider
              .searchNetBalance; // Will automatically show '-' if mostly expenses!
          pillIncome = provider.searchTotalIncome;
          pillExpense = provider.searchTotalExpense;
          hidePills = false; // Show pills so they see search breakdown
        } else if (provider.selectedDay != null) {
          // 2. IF DAY PICKED: Show day math!
          headerTitle = provider.t('Day Expense');
          headerAmount = provider.selectedDayExpense;
          hidePills = true; // Hide pills for day view
        } else {
          // 3. DEFAULT: Show spendable balance and monthly pills!
          headerTitle = provider.t('Available Balance');
          headerAmount = provider.filteredSpendableBalance;
          hidePills = false;
        }

        // WRAP ENTIRE SCREEN IN A BEAUTIFUL PALE GRADIENT!
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ==========================================
            // 1. SMART MORPHING APP BAR
            // ==========================================
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,

              // Let the gradient shine through!
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 25.0,
                    sigmaY: 25.0,
                  ), // Adjust blur intensity
                  child: Container(
                    // Tint the glass container differently based on dark/light mode
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(
                            alpha: 0.7,
                          ) // Matches your dark slate gradient top
                        : const Color(0xFFEBF4FF).withValues(
                            alpha: 0.6,
                          ), // Matches your light ice-blue gradient top
                  ),
                ),
              ),
              title: _isSearching
                  ? Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
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
                                color: isDark ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged: (val) => provider.search(val),
                            );
                          },
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.chevron_left,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => provider.changeMonth(-1),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            if (provider.selectedDay != null) {
                              provider.pickDay(null);
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
                            children: [
                              Text(
                                dateText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => provider.changeMonth(1),
                        ),
                      ],
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
            // 2. DYNAMIC BALANCE HEADER
            // ==========================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // If net balance is negative, format.format automatically adds a minus sign!
                    Text(
                      format.format(headerAmount),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: hidePills
                          ? const SizedBox(width: double.infinity, height: 0)
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeGreen
                                          .withValues(alpha: 0.15),
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
                                          format.format(pillIncome),
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
                                      color: CupertinoColors.destructiveRed
                                          .withValues(alpha: 0.15),
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
                                          format.format(pillExpense),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color:
                                                CupertinoColors.destructiveRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
