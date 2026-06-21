import 'package:flutter/cupertino.dart'; // NEW: For iOS style icons
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import 'add_transaction_screen.dart';

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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.local_mall_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Salary':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 1. iOS Style Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // iOS standard radius
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

            // 2. iOS Style Month/Day Pill Picker (Much cleaner than arrows)
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: provider.selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) provider.pickDay(picked);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
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

            // 3. The "Apple Card" Gradient Summary
            _buildAppleStyleCard(context, provider),

            const SizedBox(height: 15),

            // 4. iOS Clean List
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
                        return _buildIOSListTile(
                          context,
                          provider.paginatedTransactions[index],
                          provider,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // THE APPLE CARD DESIGN
  Widget _buildAppleStyleCard(BuildContext context, ExpenseProvider provider) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        // Stunning Premium Gradient (Blue to Purple)
        gradient: const LinearGradient(
          colors: [Color(0xFF3A82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        // Soft glowing shadow
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.t('Total Balance'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            format.format(provider.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardMiniStat(
                provider.t('Income'),
                format.format(provider.monthlyIncome),
                CupertinoIcons.arrow_down_left_circle_fill,
                Colors.greenAccent,
              ),
              _buildCardMiniStat(
                provider.t('Expense'),
                format.format(provider.monthlyExpense),
                CupertinoIcons.arrow_up_right_circle_fill,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCardMiniStat(
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // APPLE WALLET STYLE LIST TILE
  Widget _buildIOSListTile(
    BuildContext context,
    Transaction tx,
    ExpenseProvider provider,
  ) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final color = tx.isExpense
        ? const Color(0xFFFF3B30)
        : const Color(0xFF34C759); // Apple exact colors

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionScreen(existingTransaction: tx),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Soft background icon (very iOS)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(tx.category),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.paymentMethod} • ${DateFormat('MMM dd').format(tx.date)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${tx.isExpense ? '-' : '+'}${format.format(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideX(begin: 0.05, end: 0);
  }
}
