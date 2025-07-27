import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/logo_utils.dart';
import '../utils/pdf_font_utils.dart';

class CustomerDebtReceiptScreen extends StatefulWidget {
  final Customer customer;
  final List<Debt> customerDebts;

  const CustomerDebtReceiptScreen({
    super.key,
    required this.customer,
    required this.customerDebts,
  });

  @override
  State<CustomerDebtReceiptScreen> createState() => _CustomerDebtReceiptScreenState();
}

class _CustomerDebtReceiptScreenState extends State<CustomerDebtReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Debt Receipt'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _shareReceipt(),
            child: const Icon(
              CupertinoIcons.share,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Receipt Header
            _buildReceiptHeader(),
            const SizedBox(height: 24),
            
            // Customer Information
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            
            // Debt Details
            _buildDebtDetails(sortedDebts),
            const SizedBox(height: 24),
            
            // Total Amount (last element)
            _buildTotalAmount(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo (same as dashboard)
          LogoUtils.buildLogo(
            context: context,
            width: 32,
            height: 32,
            placeholder: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          // App Name
          Text(
            'Bechaalany Connect',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.customer.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.customer.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tag, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${widget.customer.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetails(List<Debt> sortedDebts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8), // Very subtle shadow
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26), // 0.1 * 255
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DEBT DETAILS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedDebts.map((debt) => _buildDebtItem(debt)).toList(),
        ],
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description and Amount on same line
          Row(
            children: [
              Expanded(
                child: Text(
                  _cleanDescription(debt.description),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, debt.amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date with time at the bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDateTime(debt.createdAt),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanDescription(String description) {
    // Remove category information in parentheses
    // This will remove "(Mobile internet)" or any other category in parentheses
    return description.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  Widget _buildTotalAmount(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            CurrencyFormatter.formatAmount(context, totalAmount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at $displayHour:$displayMinute $period';
  }

  void _shareReceipt() async {
    try {
      // Always export as PDF only
      await _exportAsPDF();
    } catch (e) {
      // Show error notification
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Share Error',
        body: 'Failed to share receipt: $e',
      );
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      print('Starting PDF export...');
      
      // Generate PDF document with proper font configuration
      final pdf = PdfFontUtils.createDocumentWithFonts();
      
      // Build multi-page PDF content
      await _buildMultiPagePDF(pdf);
      print('PDF pages added');
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      print('Temp directory: ${directory.path}');
      
      // Create proper filename with customer name, ID, and date
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month}-${now.year}';
      final fileName = '${widget.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')}_${dateStr}_ID"${widget.customer.id}".pdf';
      print('Filename: $fileName');
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('${directory.path}/$fileName');
      
      // Save PDF to file
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      print('PDF saved to: ${file.path}');
      
      // Share only the PDF file (no text)
      await Share.shareXFiles(
        [XFile(file.path)],
      );
      print('Share dialog opened');
      
      // Show success notification
      final notificationService = NotificationService();
      await notificationService.showSuccessNotification(
        title: 'PDF Exported',
        body: 'Receipt has been exported as PDF',
      );
      print('Success notification shown');
    } catch (e) {
      print('PDF export error: $e');
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'PDF Export Error',
        body: 'Failed to export PDF: $e',
      );
    }
  }

  Future<void> _buildMultiPagePDF(pw.Document pdf) async {
    print('PDF Debug: widget.customerDebts.length: ${widget.customerDebts.length}');
    
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final totalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    
    print('PDF Debug: Total debts: ${sortedDebts.length}');
    print('PDF Debug: Total amount: $totalAmount');
    
    // Debug: Print all debts
    for (int i = 0; i < sortedDebts.length; i++) {
      final debt = sortedDebts[i];
      print('PDF Debug: Debt ${i + 1}: ${debt.description} - \$${debt.amount} - ${debt.createdAt}');
    }
    
    // Sanitize customer data to avoid Unicode issues
    final sanitizedCustomerName = PdfFontUtils.sanitizeText(widget.customer.name);
    final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(widget.customer.phone);
    final sanitizedCustomerId = PdfFontUtils.sanitizeText(widget.customer.id);
    
    // Calculate how many debts can fit per page
    // Each debt item takes approximately 80-100 points of vertical space
    // A4 page has about 800 points available after margins and headers
    const int maxDebtsPerPage = 4; // Balanced for readability and pagination
    
    // Split debts into pages
    final List<List<Debt>> debtPages = [];
    for (int i = 0; i < sortedDebts.length; i += maxDebtsPerPage) {
      debtPages.add(sortedDebts.skip(i).take(maxDebtsPerPage).toList());
    }
    
    print('PDF Debug: Number of pages: ${debtPages.length}');
    for (int i = 0; i < debtPages.length; i++) {
      print('PDF Debug: Page ${i + 1} has ${debtPages[i].length} debts');
    }
    
    // Generate pages
    for (int pageIndex = 0; pageIndex < debtPages.length; pageIndex++) {
      final pageDebts = debtPages[pageIndex];
      final isLastPage = pageIndex == debtPages.length - 1;
      
      print('PDF Debug: Adding page ${pageIndex + 1} with ${pageDebts.length} debts');
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPDFPage(
              pageDebts: pageDebts,
              allDebts: sortedDebts,
              totalAmount: totalAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              pageIndex: pageIndex,
              totalPages: debtPages.length,
              isLastPage: isLastPage,
            );
          },
        ),
      );
    }
  }

  pw.Widget _buildPDFPage({
    required List<Debt> pageDebts,
    required List<Debt> allDebts,
    required double totalAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    required int pageIndex,
    required int totalPages,
    required bool isLastPage,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header - Simple title without logo (only on first page)
        if (pageIndex == 0) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    'Bechaalany Connect',
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    _formatDateTime(DateTime.now()),
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF666666), // Medium grey
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
        ] else ...[
          // Page header for subsequent pages
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    PdfFontUtils.createGracefulText(
                      'Bechaalany Connect',
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    PdfFontUtils.createGracefulText(
                      'Page ${pageIndex + 1} of $totalPages',
                      fontSize: 12,
                      color: PdfColor.fromInt(0xFF666666),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  height: 2,
                  color: PdfColor.fromInt(0xFF0175C2), // Blue line
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ],
        
        // Customer Information (only on first page)
        if (pageIndex == 0) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'CUSTOMER INFORMATION',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 12),
                // Customer name
                PdfFontUtils.createGracefulText(
                  sanitizedCustomerName,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                if (sanitizedCustomerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  PdfFontUtils.createGracefulText(
                    sanitizedCustomerPhone,
                    fontSize: 13,
                    color: PdfColor.fromInt(0xFF424242), // Dark grey
                  ),
                ],
                pw.SizedBox(height: 8),
                PdfFontUtils.createGracefulText(
                  'ID: $sanitizedCustomerId',
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
        ],
        
        // Debt Details Header (only on first page)
        if (pageIndex == 0) ...[
          PdfFontUtils.createGracefulText(
            'DEBT DETAILS',
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF424242), // Dark grey
          ),
          
          pw.SizedBox(height: 16),
        ],
        
        // Debt Items for this page
        ...pageDebts.map((debt) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5), // Colors.grey[50]
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFE0E0E0), // Colors.grey[200]
              width: 0.5,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfFontUtils.createGracefulText(
                      _cleanDescription(debt.description),
                      fontSize: 15,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    _formatCurrency(debt.amount),
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0175C2), // AppColors.primary
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0), // Colors.grey[200]
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: PdfFontUtils.createGracefulText(
                  _formatDateTime(debt.createdAt),
                  fontSize: 12,
                  fontWeight: pw.FontWeight.normal,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ),
        )).toList(),
        
        // Total Amount (only on last page)
        if (isLastPage) ...[
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfFontUtils.createGracefulText(
                  'Total Amount:',
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                PdfFontUtils.createGracefulText(
                  _formatCurrency(totalAmount),
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFD32F2F), // Colors.red[600]
                ),
              ],
            ),
          ),
        ],
        
        // Page footer
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Center(
            child: PdfFontUtils.createGracefulText(
              'Page ${pageIndex + 1} of $totalPages',
              fontSize: 10,
              color: PdfColor.fromInt(0xFF999999),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    // Simple currency formatting for PDF
    return '\$${amount.toStringAsFixed(2)} USD';
  }
} 