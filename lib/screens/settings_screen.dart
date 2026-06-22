import 'dart:io';

import 'package:csv/csv.dart';
import 'package:expense_tracker/screens/category_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/expense_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Export Logic Moved Here!
  Future<void> _exportAndShareCSV(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    final transactions = provider.transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<List<dynamic>> csvData = [
      ['Date', 'Title', 'Category', 'Wallet', 'Type', 'Amount'],
    ];
    for (var tx in transactions) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        tx.title,
        tx.category,
        tx.paymentMethod,
        tx.isExpense ? 'Expense' : 'Income',
        tx.amount,
      ]);
    }

    String csvString = Csv().encode(csvData);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/My_Expenses_Report.csv';
    final file = File(path);
    await file.writeAsString(csvString);

    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Here is my latest expense report!',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  // Danger Zone confirmation dialog
  void _confirmClearData(BuildContext context, ExpenseProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'This will permanently delete all your transactions. You cannot undo this action.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared!')),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // GROUP 1: PREFERENCES
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'PREFERENCES',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 0, indent: 50),
        ListTile(
          leading: const Icon(CupertinoIcons.square_list, color: Colors.orange),
          title: Text(
            provider.t('Manage Categories'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: Colors.grey,
          ),
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const CategorySettingsScreen(),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(CupertinoIcons.globe, color: Colors.blue),
            title: Text(
              provider.t('Language'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.isBurmese ? 'မြန်မာ' : 'English',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
            onTap: () => provider.toggleLanguage(),
          ),
        ),

        const SizedBox(height: 30),

        // GROUP 2: DATA & EXPORT
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'DATA',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  CupertinoIcons.share_up,
                  color: Colors.green,
                ),
                title: Text(
                  provider.t('Export Data (CSV)'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () => _exportAndShareCSV(context, provider),
              ),
              const Divider(height: 0, indent: 50),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                title: Text(
                  provider.t('Clear All Data'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _confirmClearData(context, provider),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
