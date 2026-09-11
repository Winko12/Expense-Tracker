import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _showActive = true;

  // NEW: Pagination Variables
  final ScrollController _scrollController = ScrollController();
  int _limit = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        setState(() => _limit += 15);
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
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    // Apply pagination
    final fullList = _showActive ? provider.activeDebts : provider.settledDebts;
    final hasMore = fullList.length > _limit;
    final displayList = fullList.take(_limit).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 1. GLASSMORPHISM APP BAR (No + button here anymore!)
        SliverAppBar(
          pinned: true,
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
          title: Text(
            provider.t('Debts'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // 2. TOGGLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _showActive,
                children: {
                  true: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(provider.t('Active')),
                  ),
                  false: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(provider.t('Settled')),
                  ),
                },
                onValueChanged: (val) => setState(() {
                  _showActive = val!;
                  _limit = 15; // Reset pagination when switching tabs
                }),
              ),
            ),
          ),
        ),

        // 3. PAGINATED & SWIPEABLE DEBT LIST
        if (displayList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                provider.t('No transactions found.'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == displayList.length)
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CupertinoActivityIndicator()),
                  );

                final debt = displayList[index];
                final color = debt.isOwedToMe
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.destructiveRed;
                final icon = debt.isOwedToMe
                    ? CupertinoIcons.arrow_down_left_circle_fill
                    : CupertinoIcons.arrow_up_right_circle_fill;

                // BI-DIRECTIONAL SWIPING!
                return Dismissible(
                  key: Key(debt.id),
                  direction:
                      DismissDirection.horizontal, // Allow Swipe Left AND Right
                  // SWIPE RIGHT: Settle / Unsettle
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: Icon(
                      debt.isSettled
                          ? CupertinoIcons.arrow_uturn_left
                          : CupertinoIcons.checkmark_seal_fill,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // SWIPE LEFT: Delete
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      // DELETE CONFIRMATION
                      final confirm = await showCupertinoDialog<bool>(
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
                      if (confirm == true) provider.deleteDebt(debt);
                      return confirm;
                    } else {
                      // SETTLE / UNSETTLE CONFIRMATION
                      final actionText = debt.isSettled
                          ? provider.t('Unsettle')
                          : provider.t('Settle');
                      final confirm = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: Text('$actionText?'),
                          actions: [
                            CupertinoDialogAction(
                              child: Text(provider.t('Cancel')),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(actionText),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if (debt.isSettled) {
                          provider.unsettleDebt(debt);
                        } else {
                          provider.settleDebt(debt);
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.t('Transaction saved!')),
                                backgroundColor: Colors.green,
                              ),
                            );
                        }
                      }
                      return confirm;
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                        Icon(icon, color: color, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.personName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(debt.date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              format.format(debt.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.t(debt.isSettled ? 'Settled' : 'Active'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fade().slideX(begin: 0.05, end: 0);
              }, childCount: displayList.length + (hasMore ? 1 : 0)),
            ),
          ),
      ],
    );
  }
}
