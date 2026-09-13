import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/expense_provider.dart';

class HomeBalanceHeader extends StatefulWidget {
  final ExpenseProvider provider;
  const HomeBalanceHeader({super.key, required this.provider});

  @override
  State<HomeBalanceHeader> createState() => _HomeBalanceHeaderState();
}

class _HomeBalanceHeaderState extends State<HomeBalanceHeader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    // If searching or day-picking, we freeze the swipe and show the specific math
    if (provider.searchQuery.isNotEmpty || provider.selectedDay != null) {
      String headerTitle = provider.searchQuery.isNotEmpty
          ? provider.t('Search Results')
          : provider.t('Day Expense');
      double headerAmount = provider.searchQuery.isNotEmpty
          ? provider.searchNetBalance
          : provider.selectedDayExpense;

      return SliverToBoxAdapter(
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
              Text(
                format.format(headerAmount),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (provider.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPill(
                        format.format(provider.searchTotalIncome),
                        CupertinoIcons.arrow_down_left,
                        CupertinoColors.activeGreen,
                      ),
                      const SizedBox(width: 12),
                      _buildPill(
                        format.format(provider.searchTotalExpense),
                        CupertinoIcons.arrow_up_right,
                        CupertinoColors.destructiveRed,
                      ),
                    ],
                  ),
                ),
            ],
          ).animate().fade().slideY(begin: -0.1, end: 0),
        ),
      );
    }

    // ==========================================
    // THE SWIPEABLE DIGITAL WALLET CAROUSEL
    // ==========================================

    // Build the list of pages (Page 0 = Total, Page 1..N = Wallets)
    List<Widget> carouselPages = [];

    // PAGE 0: Total Balance
    carouselPages.add(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              _buildPill(
                format.format(provider.monthlyIncome),
                CupertinoIcons.arrow_down_left,
                CupertinoColors.activeGreen,
              ),
              const SizedBox(width: 12),
              _buildPill(
                format.format(provider.monthlyExpense),
                CupertinoIcons.arrow_up_right,
                CupertinoColors.destructiveRed,
              ),
            ],
          ),
        ],
      ),
    );

    // PAGE 1..N: Individual Wallet Balances
    for (String wallet in provider.activeWallets) {
      double bal = provider.walletBalance(wallet);
      // Only show wallets that have been used (balance != 0) to keep it clean
      if (bal != 0) {
        carouselPages.add(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.creditcard_fill,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$wallet ${provider.t('Balance')}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                format.format(bal),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Column(
          children: [
            // Swipeable Pages
            SizedBox(
              height:
                  140, // Perfect height to hold the text without taking too much screen space
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: carouselPages,
              ),
            ).animate().fade().slideY(begin: -0.1, end: 0),

            // iOS Style Page Indicator Dots
            if (carouselPages.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(carouselPages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentPage == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ).animate().fade(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
