import 'dart:ui'; // NEW: Required for ImageFilter (Blur)

import 'package:expense_tracker/screens/debts_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const DebtsScreen(),
    const BudgetScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String appBarTitle = provider.t('Dashboard');
    if (_currentIndex == 1) appBarTitle = provider.t('Stats');
    if (_currentIndex == 2) appBarTitle = provider.t('Debts');
    if (_currentIndex == 3) appBarTitle = provider.t('Budget');
    if (_currentIndex == 4) appBarTitle = provider.t('Settings');

    // 1. WRAP THE ENTIRE APP IN YOUR GRADIENT BACKGROUND
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
        backgroundColor: Colors.transparent, // Let gradient shine through!
        extendBodyBehindAppBar:
            true, // MAGIC: Allows content to scroll UNDER the AppBar!
        // 2. YOUR GLASSMORPHISM APP BAR FOR STATS, BUDGET, SETTINGS!
        appBar: (_currentIndex == 0 || _currentIndex == 1)
            ? null
            : AppBar(
                title: Text(
                  appBarTitle,
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

        // We add extra top padding here so content doesn't get permanently stuck under the glass bar
        body: Padding(
          padding: EdgeInsets.only(
            top: (_currentIndex == 0 || _currentIndex == 1) ? 0 : 0,
          ),
          child: _screens[_currentIndex],
        ),

        floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const AddTransactionScreen(),
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(CupertinoIcons.add),
              )
            : null,

        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) =>
              setState(() => _currentIndex = index),
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
              icon: const Icon(CupertinoIcons.person_2),
              selectedIcon: const Icon(CupertinoIcons.person_2_fill),
              label: provider.t('Debts'),
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
      ),
    );
  }
}
