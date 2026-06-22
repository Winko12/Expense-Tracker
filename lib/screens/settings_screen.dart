import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW: For animations!
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/expense_provider.dart';
import 'category_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportAndShareCSV(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    final transactions = provider.transactions;
    if (transactions.isEmpty) return;
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
    await File(path).writeAsString(csvString);
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

  void _confirmClearData(BuildContext context, ExpenseProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(provider.t('Are you sure?')),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(provider.t('This action cannot be undone.')),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(provider.t('Cancel')),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(ctx);
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
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // GROUP 1: PREFERENCES
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'PREFERENCES',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildIOSListTile(
                    icon: CupertinoIcons.globe,
                    iconColor: Colors.blue,
                    title: provider.t('Language'),
                    trailingText: provider.isBurmese ? 'မြန်မာ' : 'English',
                    onTap: () => provider.toggleLanguage(),
                  ),
                  const Divider(height: 0, indent: 56), // iOS Divider spacing
                  _buildIOSListTile(
                    icon: CupertinoIcons.square_list_fill,
                    iconColor: Colors.orange,
                    title: provider.t('Manage Categories'),
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const CategorySettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fade(delay: 50.ms)
            .slideY(begin: 0.1, end: 0), // Smooth slide up!

        const SizedBox(height: 35),

        // GROUP 2: DATA & EXPORT
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'DATA',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildIOSListTile(
                icon: CupertinoIcons.share_up,
                iconColor: Colors.green,
                title: provider.t('Export Data (CSV)'),
                onTap: () => _exportAndShareCSV(context, provider),
              ),
              const Divider(height: 0, indent: 56),
              _buildIOSListTile(
                icon: CupertinoIcons.trash_fill,
                iconColor: CupertinoColors.destructiveRed,
                title: provider.t('Clear All Data'),
                isDestructive: true,
                onTap: () => _confirmClearData(context, provider),
              ),
            ],
          ),
        ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // Custom helper to make exact iOS style ListTiles
  Widget _buildIOSListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: isDestructive ? CupertinoColors.destructiveRed : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: Colors.grey,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
