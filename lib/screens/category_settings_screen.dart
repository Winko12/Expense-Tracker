import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/category_item.dart';
import '../providers/expense_provider.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  bool _isExpense = true;

  void _showCategoryDialog(
    BuildContext context,
    ExpenseProvider provider, {
    CategoryItem? existingCategory,
  }) {
    final controller = TextEditingController(
      text: existingCategory?.name ?? '',
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          provider.t(
            existingCategory != null ? 'Edit Category' : 'Add Category',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: CupertinoTextField(
            controller: controller,
            placeholder: provider.t('Category Name'),
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
              if (existingCategory != null) {
                provider.updateCategory(
                  existingCategory,
                  controller.text.trim(),
                );
              } else {
                final newCat = CategoryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                  isExpense: _isExpense,
                );
                provider.addCategory(newCat);
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
    final displayedCategories = provider.rawCategories
        .where((c) => c.isExpense == _isExpense)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          provider.t('Manage Categories'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: Colors.blue),
            onPressed: () => _showCategoryDialog(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: _isExpense,
              children: {
                true: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(provider.t('Expense')),
                ),
                false: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(provider.t('Income')),
                ),
              },
              onValueChanged: (val) => setState(() => _isExpense = val!),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayedCategories.length,
              itemBuilder: (context, index) {
                final cat = displayedCategories[index];
                return Dismissible(
                  key: Key(cat.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showCupertinoDialog<bool>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: Text(provider.t('Are you sure?')),
                        content: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            provider.t('This action cannot be undone.'),
                          ),
                        ),
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
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => provider.deleteCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.pencil,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onTap: () => _showCategoryDialog(
                        context,
                        provider,
                        existingCategory: cat,
                      ),
                    ),
                  ),
                ).animate().fade().slideX();
              },
            ),
          ),
        ],
      ),
    );
  }
}
