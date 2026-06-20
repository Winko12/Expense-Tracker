import 'package:flutter/material.dart';

import 'add_transaction_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0 = Home, 1 = Stats

  // The screens we can navigate to
  final List<Widget> _screens = [const HomeScreen(), const StatsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Dashboard' : 'Statistics',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),

      // Shows either Home or Stats based on the bottom bar selection
      body: _screens[_currentIndex],

      // The floating action button stays here so it's on all tabs!
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),

      // The modern Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
