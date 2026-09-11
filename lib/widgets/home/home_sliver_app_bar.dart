import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../providers/expense_provider.dart';

class HomeSliverAppBar extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isSearching;
  final FocusNode searchFocusNode;
  final VoidCallback onToggleSearch;

  const HomeSliverAppBar({
    super.key,
    required this.provider,
    required this.isSearching,
    required this.searchFocusNode,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String dateText = provider.selectedDay != null
        ? DateFormat('MMM dd, yyyy').format(provider.selectedDay!)
        : DateFormat('MMMM yyyy').format(provider.selectedMonth);

    return SliverAppBar(
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
      title: isSearching
          ? Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return provider.searchSuggestions.where(
                  (option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                provider.search(selection);
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    return CupertinoTextField(
                      controller: controller,
                      focusNode: searchFocusNode,
                      placeholder: provider.t('Search...'),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          CupertinoIcons.search,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (val) => provider.search(val),
                    );
                  },
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    CupertinoIcons.chevron_left,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => provider.changeMonth(-1),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    if (provider.selectedDay != null) {
                      provider.pickDay(null);
                    } else {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: provider.selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) provider.pickDay(picked);
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        dateText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        provider.selectedDay != null
                            ? CupertinoIcons.xmark_circle_fill
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => provider.changeMonth(1),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? CupertinoIcons.clear_thick : CupertinoIcons.search,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: onToggleSearch,
        ),
      ],
    );
  }
}
