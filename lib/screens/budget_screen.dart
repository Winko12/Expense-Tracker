import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
// NEW: PDF Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late TextEditingController _savingsController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    // Initialize text box with saved value
    _savingsController = TextEditingController(
      text: provider.savingsValue == 0
          ? ''
          : provider.savingsValue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

  // ==========================================
  // MAGIC: GENERATE BEAUTIFUL PDF REPORT
  // ==========================================
  Future<void> _exportToPDF(ExpenseProvider provider, String currency) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 0,
    );

    // We export PDF in English to avoid font encoding issues across different devices
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER
              pw.Text(
                'Monthly Budget Report',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 30),

              // MAIN CARD
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: provider.realRemainingBalance > 0
                      ? PdfColors.green100
                      : PdfColors.red100,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Safe Daily Limit',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      format.format(provider.safeDailyLimit),
                      style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // DATA TABLE
              pw.Text(
                'Financial Breakdown',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              _buildPdfRow(
                'Total Income',
                format.format(provider.realCurrentMonthIncome),
              ),
              _buildPdfRow(
                'Locked Savings',
                '- ${format.format(provider.lockedSavings)}',
              ),
              _buildPdfRow(
                'Spendable Income',
                format.format(provider.spendableIncome),
                isBold: true,
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow(
                'Total Expenses',
                '- ${format.format(provider.realCurrentMonthExpense)}',
              ),
              _buildPdfRow(
                'Remaining Balance',
                format.format(provider.realRemainingBalance),
                isBold: true,
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow(
                'Remaining Days',
                '${provider.remainingDaysInMonth} Days',
              ),
            ],
          );
        },
      ),
    );

    // Share the PDF via Native Share Sheet!
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Budget_Report.pdf',
    );
  }

  pw.Widget _buildPdfRow(String title, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );
    final isSafe = provider.realRemainingBalance > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. THE MAIN ALLOWANCE CARD
          Container(
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
                Text(
                  format.format(provider.safeDailyLimit),
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
          ).animate().fade().scale(curve: Curves.easeOutBack, duration: 600.ms),

          const SizedBox(height: 35),

          // 2. SAVINGS GOAL (TEXT INPUT + PERCENT/AMOUNT TOGGLE)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              provider.t('Savings Goal').toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fade(delay: 100.ms),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // SEGMENTED CONTROL: % vs Amount
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: provider.isSavingsPercentage,
                  children: {
                    true: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(provider.t('Percentage')),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(provider.t('Amount')),
                    ),
                  },
                  onValueChanged: (val) {
                    provider.updateSavings(
                      double.tryParse(_savingsController.text) ?? 0,
                      val!,
                    );
                  },
                ),
                const SizedBox(width: 15),
                // TEXT FIELD
                Expanded(
                  child: CupertinoTextField(
                    controller: _savingsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: '0',
                    textAlign: TextAlign.right,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        provider.isSavingsPercentage
                            ? '%'
                            : provider.currencySymbol,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      provider.updateSavings(
                        double.tryParse(val) ?? 0,
                        provider.isSavingsPercentage,
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 35),

          // 3. THE MATH BREAKDOWN
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              provider.t('This Month').toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fade(delay: 200.ms),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildMathRow(
                  context,
                  provider.t('Income'),
                  format.format(provider.realCurrentMonthIncome),
                  CupertinoIcons.arrow_down_left_circle_fill,
                  Colors.green,
                ),
                const Divider(height: 0, indent: 56),
                _buildMathRow(
                  context,
                  provider.t('Locked Savings'),
                  '- ${format.format(provider.lockedSavings)}',
                  CupertinoIcons.lock_fill,
                  Colors.blue,
                ),
                const Divider(height: 0, indent: 56),
                _buildMathRow(
                  context,
                  provider.t('Spendable Income'),
                  format.format(provider.spendableIncome),
                  CupertinoIcons.money_dollar_circle,
                  Colors.orange,
                ),
                const Divider(height: 0, indent: 56),
                _buildMathRow(
                  context,
                  provider.t('Expense'),
                  '- ${format.format(provider.realCurrentMonthExpense)}',
                  CupertinoIcons.arrow_up_right_circle_fill,
                  Colors.red,
                ),
                const Divider(height: 0, indent: 56),
                _buildMathRow(
                  context,
                  provider.t('Remaining Balance'),
                  format.format(provider.realRemainingBalance),
                  CupertinoIcons.checkmark_seal_fill,
                  Colors.teal,
                ),
                const Divider(height: 0, indent: 56),
                _buildMathRow(
                  context,
                  provider.t('Remaining Days'),
                  '${provider.remainingDaysInMonth}',
                  CupertinoIcons.calendar,
                  Colors.purple,
                ),
              ],
            ),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 30),

          // 4. EXPORT PDF BUTTON!
          ElevatedButton.icon(
            onPressed: () => _exportToPDF(provider, provider.currencySymbol),
            icon: const Icon(CupertinoIcons.doc_text_fill),
            label: Text(
              provider.t('Export PDF'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMathRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
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
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
