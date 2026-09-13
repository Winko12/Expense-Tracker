import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/debt_item.dart';
import '../models/wallet_item.dart';
import '../providers/expense_provider.dart';

class WalletSettingsScreen extends StatelessWidget {
  const WalletSettingsScreen({super.key});

  void _showWalletDialog(
    BuildContext context,
    ExpenseProvider provider, {
    WalletItem? existingWallet,
    DebtItem? existingDebt,
  }) {
    final controller = TextEditingController(text: existingWallet?.name ?? '');

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          provider.t(existingDebt != null ? 'Edit Wallet' : 'Add Wallet'),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: CupertinoTextField(
            controller: controller,
            placeholder: provider.t('Wallet Name'),
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              if (existingWallet != null) {
                provider.updateWallet(existingWallet, controller.text.trim());
              } else {
                provider.addWallet(
                  WalletItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayedWallets =
        provider.activeWallets; // Fetch directly from provider

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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            provider.t('Manage Wallets'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.add, color: Colors.blue),
              onPressed: () => _showWalletDialog(context, provider),
            ),
          ],
        ),
        body: ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          itemCount: displayedWallets.length,
          itemBuilder: (context, index) {
            // Get the actual WalletItem object for CRUD
            final walletObj = provider.rawWallets()[index];

            return Dismissible(
              key: Key(walletObj.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showCupertinoDialog<bool>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: Text(provider.t('Are you sure?')),
                    actions: [
                      CupertinoDialogAction(
                        child: Text(provider.t('Cancel')),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(provider.t('Delete')),
                      ),
                    ],
                  ),
                );
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(CupertinoIcons.trash, color: Colors.white),
              ),
              onDismissed: (_) => provider.deleteWallet(walletObj),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    walletObj.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () => _showWalletDialog(
                    context,
                    provider,
                    existingWallet: walletObj,
                  ),
                ),
              ),
            ).animate().fade().slideX();
          },
        ),
      ),
    );
  }
}
