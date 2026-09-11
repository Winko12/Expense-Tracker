import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/expense_provider.dart';

// 1. PRIVACY BLUR WIDGET
class ObscurableAmount extends StatefulWidget {
  final String amountText;
  final TextStyle style;
  const ObscurableAmount({
    super.key,
    required this.amountText,
    required this.style,
  });

  @override
  State<ObscurableAmount> createState() => _ObscurableAmountState();
}

class _ObscurableAmountState extends State<ObscurableAmount> {
  bool _isObscured = true;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isObscured = !_isObscured),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: _isObscured ? 6.0 : 0.0,
          sigmaY: _isObscured ? 6.0 : 0.0,
        ),
        child: Text(widget.amountText, style: widget.style),
      ),
    );
  }
}

// 2. MAIN ALLOWANCE CARD WIDGET
class DailyAllowanceCard extends StatelessWidget {
  final ExpenseProvider provider;
  const DailyAllowanceCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );
    final isSafe = provider.realRemainingBalance > 0;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSafe
              ? [const Color(0xFF34C759), const Color(0xFF28A745)]
              : [const Color(0xFFFF3B30), const Color(0xFFD70015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isSafe ? Colors.green : Colors.red).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isSafe
                ? CupertinoIcons.checkmark_shield_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.white.withOpacity(0.8),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            provider.t(isSafe ? 'You can safely spend' : 'Overspent!'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ObscurableAmount(
            amountText: format.format(provider.safeDailyLimit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            provider.t('per day'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fade().scale(curve: Curves.easeOutBack, duration: 600.ms);
  }
}

// 3. MATH ROW HELPER
class MathRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const MathRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: ObscurableAmount(
        amountText: value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
