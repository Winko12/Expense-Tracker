import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) => provider.search(val),
                  decoration: InputDecoration(
                    hintText: provider.t('Search...'),
                    icon: const Icon(CupertinoIcons.search, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // FIXED: Month/Day Navigation with Arrows!
            Padding(
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
                  ), // Go back a month

                  GestureDetector(
                    onTap: () async {
                      if (provider.selectedDay != null) {
                        provider.pickDay(null); // Click to clear day filter
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
                  ), // Go forward a month
                ],
              ),
            ),

            // Extracted Widget!
            SummaryCard(provider: provider),

            const SizedBox(height: 15),

            // Paginating List with Extracted Widget!
            Expanded(
              child: provider.paginatedTransactions.isEmpty
                  ? Center(
                      child: Text(
                        provider.t('No transactions found.'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          provider.paginatedTransactions.length +
                          (provider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
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
                    ),
            ),
          ],
        );
      },
    );
  }
}
