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
  // The scroll controller now controls the ENTIRE page, not just the list!
  final ScrollController _scrollController = ScrollController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final format = NumberFormat.currency(
          symbol: '${provider.currencySymbol} ',
          decimalDigits: 0,
        );

        // NEW: CustomScrollView allows the search bar and header to scroll away!
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1. Search Bar (Now inside a Sliver so it scrolls!)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Autocomplete<String>(
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
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => provider.search(val),
                            decoration: InputDecoration(
                              hintText: provider.t('Search...'),
                              icon: const Icon(
                                CupertinoIcons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 40,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2C2C2E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(
                                  CupertinoIcons.search,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Month/Day Navigation (Scrolls away)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_left),
                      onPressed: () => provider.changeMonth(-1),
                    ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              provider.selectedDay != null
                                  ? CupertinoIcons.xmark_circle_fill
                                  : CupertinoIcons.calendar,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.selectedDay != null
                                  ? DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(provider.selectedDay!)
                                  : DateFormat(
                                      'MMMM yyyy',
                                    ).format(provider.selectedMonth),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_right),
                      onPressed: () => provider.changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Minimalist Header (Scrolls away)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.t('Net Balance'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(provider.monthlyBalance),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_down_left_circle_fill,
                              color: CupertinoColors.activeGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              format.format(provider.monthlyIncome),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_up_right_circle_fill,
                              color: CupertinoColors.destructiveRed,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              format.format(provider.monthlyExpense),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ).animate().fade().slideY(begin: 0.1, end: 0),
              ),
            ),

            // 4. Transaction List (Fills the rest of the scroll view)
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
