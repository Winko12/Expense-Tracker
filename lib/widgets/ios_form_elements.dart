import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 1. Reusable iOS Style Text Field
class IOSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType keyboardType;

  const IOSTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// 2. Reusable iOS Style Dropdown
class IOSDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final Function(String?) onChanged;

  const IOSDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Colors.grey,
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(item, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
