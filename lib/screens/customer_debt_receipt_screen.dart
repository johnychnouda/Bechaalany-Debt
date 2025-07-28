import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/pdf_font_utils.dart';
import '../utils/logo_utils.dart';

class CustomerDebtReceiptScreen extends StatefulWidget {
  final Customer customer;
  final List<Debt> customerDebts;
  final List<PartialPayment> partialPayments;

  const CustomerDebtReceiptScreen({
    super.key,
    required this.customer,
    required this.customerDebts,
    required this.partialPayments,
  });

  @override
  State<CustomerDebtReceiptScreen> createState() => _CustomerDebtReceiptScreenState();
}

class _CustomerDebtReceiptScreenState extends State<CustomerDebtReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Calculate remaining amount instead of total original amount
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

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
            _buildTotalAmount(remainingAmount),
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
    // Create a list of all items to display (debts + partial payments)
    List<Widget> allItems = [];
    
    for (Debt debt in sortedDebts) {
      // Add the debt item
      allItems.add(_buildDebtItem(debt));
      
      // Get all partial payments for this debt
      final partialPayments = _getPartialPaymentsForDebt(debt.id);
      
      // Add each partial payment as a separate item
      for (PartialPayment payment in partialPayments) {
        allItems.add(_buildPartialPaymentItem(payment));
      }
    }
    
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
          ...allItems,
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26), // Light blue background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
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
          Text(
            _formatDateTime(debt.createdAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  List<PartialPayment> _getPartialPaymentsForDebt(String debtId) {
    return widget.partialPayments
        .where((payment) => payment.debtId == debtId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt)); // Sort by date, newest first
  }

  Widget _buildPartialPaymentItem(PartialPayment payment) {
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
          // Partial Payment and Amount on same line
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[600]!.withAlpha(26), // Light green background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  size: 14,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Partial Payment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, payment.amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date with time at the bottom
          Text(
            _formatDateTime(payment.paidAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green[600],
              letterSpacing: 0.5,
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

  Widget _buildTotalAmount(double remainingAmount) {
    // Calculate partially paid amount
    final partiallyPaidAmount = widget.customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    
    // Check if there are any pending or partially paid debts
    final hasPendingOrPartiallyPaid = widget.customerDebts.any((debt) => !debt.isFullyPaid);
    
    // Check if all debts are fully paid
    final allDebtsFullyPaid = remainingAmount == 0 && widget.customerDebts.isNotEmpty;
    
    // Get the latest payment date when all debts were paid
    DateTime? latestPaymentDate;
    if (allDebtsFullyPaid) {
      latestPaymentDate = widget.customerDebts
          .where((debt) => debt.paidAt != null)
          .map((debt) => debt.paidAt!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
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
      child: Column(
        children: [
          // Partially Paid Amount - only show if there are pending/partially paid debts
          if (partiallyPaidAmount > 0 && hasPendingOrPartiallyPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partially Paid Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(context, partiallyPaidAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Show "Debts Fully Paid" when remaining amount is 0, otherwise show total amount
          if (allDebtsFullyPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Debts Fully Paid',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 24,
                ),
              ],
            ),
            if (latestPaymentDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Paid on ${_formatDateTime(latestPaymentDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ] else ...[
            // Total Amount
            Row(
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
                  CurrencyFormatter.formatAmount(context, remainingAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
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
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at $displayHour:$displayMinute $period';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
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

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();
    
    // Get customer debts and sort by creation date
    final sortedDebts = widget.customerDebts.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Calculate remaining amount instead of total original amount
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    // Create pages with debts (max 10 debts per page)
    final debtPages = <List<Debt>>[];
    for (int i = 0; i < sortedDebts.length; i += 10) {
      final end = (i + 10 < sortedDebts.length) ? i + 10 : sortedDebts.length;
      debtPages.add(sortedDebts.sublist(i, end));
    }
    
    // Add pages to PDF
    for (int pageIndex = 0; pageIndex < debtPages.length; pageIndex++) {
      final pageDebts = debtPages[pageIndex];
      final isFirstPage = pageIndex == 0;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  if (isFirstPage) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'DEBT RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Date: ${_formatDate(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Customer Information
                    pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Customer Information',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text('Name: ${widget.customer.name}'),
                          pw.Text('Phone: ${widget.customer.phone}'),
                          if (widget.customer.email?.isNotEmpty == true)
                            pw.Text('Email: ${widget.customer.email}'),
                          pw.Text('Address: ${widget.customer.address}'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Summary
                    pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor(0.95, 0.95, 0.95),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        children: [
                          // Partially Paid Amount - only show if there are pending/partially paid debts
                          if (sortedDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount) > 0 && 
                              sortedDebts.any((debt) => !debt.isFullyPaid)) ...[
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Partially Paid Amount:',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '\$${sortedDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount).toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(0.2, 0.8, 0.2), // Green
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                          ],
                          
                                                    // Show "Debts Fully Paid" when remaining amount is 0, otherwise show total outstanding debts
                          if (remainingAmount == 0 && sortedDebts.isNotEmpty) ...[
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Debts Fully Paid',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(0.2, 0.8, 0.2), // Green
                                  ),
                                ),
                                pw.Text(
                                  '✓',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(0.2, 0.8, 0.2), // Green
                                  ),
                                ),
                              ],
                            ),
                            // Get the latest payment date when all debts were paid
                            if (sortedDebts.any((debt) => debt.paidAt != null)) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Paid on ${_formatDateTime(sortedDebts.where((debt) => debt.paidAt != null).map((debt) => debt.paidAt!).reduce((a, b) => a.isAfter(b) ? a : b))}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: const PdfColor(0.4, 0.4, 0.4),
                                ),
                              ),
                            ],
                          ] else ...[
                            // Total Outstanding Debts
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Total Outstanding Debts:',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '\$${remainingAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(0.8, 0.2, 0.2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  
                  // Debts List
                  pw.Text(
                    'Debts List',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  
                  // Table Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor(0.9, 0.9, 0.9),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  
                  // Debts
                  ...pageDebts.map((debt) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 5),
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            debt.description,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '\$${debt.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor(0.8, 0.2, 0.2),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _formatDate(debt.createdAt),
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  Future<void> _buildMultiPagePDF(pw.Document pdf) async {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Calculate remaining amount instead of total original amount
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
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
    
    // Generate pages
    for (int pageIndex = 0; pageIndex < debtPages.length; pageIndex++) {
      final pageDebts = debtPages[pageIndex];
      final isLastPage = pageIndex == debtPages.length - 1;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return             _buildPDFPage(
              pageDebts: pageDebts,
              allDebts: sortedDebts,
              remainingAmount: remainingAmount,
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
    required double remainingAmount,
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
              PdfFontUtils.createGracefulText(
                _formatDateTime(debt.createdAt),
                fontSize: 12,
                fontWeight: pw.FontWeight.normal,
                color: PdfColor.fromInt(0xFF1976D2), // Colors.blue[600]
              ),
            ],
          ),
        )).toList(),
        
        // Partial Payment Items for this page
        ...pageDebts
            .expand((debt) => _getPartialPaymentsForDebt(debt.id))
            .map((payment) => pw.Container(
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
                      pw.Text(
                        'Partial Payment',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColors.black, // Colors.black87
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        _formatCurrency(payment.amount),
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF4CAF50), // Colors.green[600]
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    _formatDateTime(payment.paidAt),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColor.fromInt(0xFF4CAF50), // Colors.green[600]
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
            child: pw.Column(
              children: [
                // Partially Paid Amount - only show if there are pending/partially paid debts
                if (allDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount) > 0 && 
                    allDebts.any((debt) => !debt.isFullyPaid)) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Partially Paid Amount:',
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF666666),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(allDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount)),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50), // Colors.green[600]
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                ],
                
                // Show "Debts Fully Paid" when remaining amount is 0, otherwise show total amount
                if (remainingAmount == 0 && allDebts.isNotEmpty) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Debts Fully Paid',
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50), // Colors.green[600]
                      ),
                      pw.Text(
                        '✓',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF4CAF50), // Colors.green[600]
                        ),
                      ),
                    ],
                  ),
                  // Get the latest payment date when all debts were paid
                  if (allDebts.any((debt) => debt.paidAt != null)) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Paid on ${_formatDateTime(allDebts.where((debt) => debt.paidAt != null).map((debt) => debt.paidAt!).reduce((a, b) => a.isAfter(b) ? a : b))}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromInt(0xFF666666),
                      ),
                    ),
                  ],
                ] else ...[
                  // Total Amount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Total Amount:',
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey,
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(remainingAmount),
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F), // Colors.red[600]
                      ),
                    ],
                  ),
                ],
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