import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/expense_provider.dart';
import 'add_transaction_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const HomeScreen(), const StatsScreen()];

  // --- UPDATED: Export and Share Logic for the latest share_plus ---
  Future<void> _exportAndShareCSV(BuildContext context) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final transactions = provider.filteredTransactions;

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Create the CSV Header Row
    List<List<dynamic>> csvData = [
      ['Date', 'Title', 'Category', 'Type', 'Amount'],
    ];

    // 2. Add all transactions to the CSV
    for (var tx in transactions) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        tx.title,
        tx.category,
        tx.isExpense ? 'Expense' : 'Income',
        tx.amount,
      ]);
    }

    // 3. Convert List to CSV String
    String csvString = Csv().encode(csvData);

    // 4. Find a temporary directory on the phone to save the file
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/My_Expenses_Report.csv';
    final file = File(path);

    // 5. Write the file
    await file.writeAsString(csvString);

    // 6. Calculate position for iPads and newer iOS versions to prevent crashing
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;

    // 7. Trigger the phone's Share menu using the newest SharePlus API!
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)], // Attach our CSV file
        text: 'Here is my latest expense report!',
        // This is highly recommended in the latest docs for iPad/iOS support
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the provider here so the AppBar updates instantly when language changes!
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? provider.t('Dashboard')
              : provider.t('Statistics'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // THE NEW LANGUAGE TOGGLE BUTTON
          TextButton(
            onPressed: () => provider.toggleLanguage(),
            child: Text(
              provider.isBurmese ? 'ENG' : 'မြန်မာ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _exportAndShareCSV(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: provider.t('Home'), // Translated Label
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: provider.t('Stats'), // Translated Label
          ),
        ],
      ),
    );
  }
}
