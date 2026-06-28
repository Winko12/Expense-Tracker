import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart'; // NEW
import 'home_screen.dart';
import 'settings_screen.dart'; // NEW
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 1. We now have 4 separate pages!
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const BudgetScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    // Determine title based on selected tab
    String appBarTitle = provider.t('Dashboard');
    if (_currentIndex == 1) appBarTitle = provider.t('Stats');
    if (_currentIndex == 2) appBarTitle = provider.t('Budget');
    if (_currentIndex == 3) appBarTitle = provider.t('Settings');

    final safeIndex = _currentIndex < _screens.length ? _currentIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        // 2. We completely removed the cluttered App Bar actions! Everything is in Settings now.
      ),
      body: _screens[safeIndex],

      // Floating button disappears on Settings tab to look cleaner
      floatingActionButton: _currentIndex != 3
          ? FloatingActionButton(
              onPressed: () {
                // THIS IS THE iOS MAGIC ANIMATION!
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    fullscreenDialog:
                        true, // Makes it slide up from the bottom!
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(CupertinoIcons.add),
            )
          : null,

      // 3. Updated Bottom Navigation Bar with 3 tabs
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(CupertinoIcons.home),
            selectedIcon: const Icon(CupertinoIcons.house_fill),
            label: provider.t('Home'),
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.chart_pie),
            selectedIcon: const Icon(CupertinoIcons.chart_pie_fill),
            label: provider.t('Stats'),
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.creditcard),
            selectedIcon: const Icon(CupertinoIcons.creditcard_fill),
            label: provider.t('Budget'),
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.gear_alt),
            selectedIcon: const Icon(CupertinoIcons.gear_alt_fill),
            label: provider.t('Settings'),
          ),
        ],
      ),
    );
  }
}
