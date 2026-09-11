import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/expense_provider.dart';

class PdfService {
  static Future<void> exportBudgetReport(ExpenseProvider provider) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(
      symbol: '${provider.currencySymbol} ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
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
                'Today Spent',
                format.format(provider.todayExpense),
                isBold: true,
              ),
              _buildPdfRow(
                'Remaining Days',
                '${provider.effectiveRemainingDays} Days',
              ),
            ],
          );
        },
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Budget_Report.pdf',
    );
  }

  static pw.Widget _buildPdfRow(
    String title,
    String value, {
    bool isBold = false,
  }) {
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
}
