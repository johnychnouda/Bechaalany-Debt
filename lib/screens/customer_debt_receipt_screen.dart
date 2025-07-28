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
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
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
            color: Colors.black.withAlpha(26),
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
    List<Widget> allItems = [];
    
    for (Debt debt in sortedDebts) {
      if (_isCombinedDebt(debt.description)) {
        // Split combined debt into separate entries
        final items = _splitDescription(debt.description);
        final amountPerItem = debt.amount / items.length;
        final paidAmountPerItem = debt.paidAmount / items.length;
        
        for (int i = 0; i < items.length; i++) {
          final splitDebt = debt.copyWith(
            id: '${debt.id}_split_$i',
            description: items[i].trim(),
            amount: amountPerItem,
            paidAmount: paidAmountPerItem,
          );
          allItems.add(_buildDebtItem(splitDebt));
        }
      } else {
        allItems.add(_buildDebtItem(debt));
      }
      
      final partialPayments = _getPartialPaymentsForDebt(debt.id);
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
            color: Colors.black.withAlpha(8),
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
                  color: AppColors.primary.withAlpha(26),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
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
    final payments = widget.partialPayments
        .where((payment) => payment.debtId == debtId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return payments;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[600]!.withAlpha(26),
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
    return description.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  bool _isCombinedDebt(String description) {
    return description.contains(' + ') || description.contains(' & ') || description.contains('+');
  }



  List<String> _splitDescription(String description) {
    if (description.contains(' + ')) {
      return description.split(' + ');
    } else if (description.contains(' & ')) {
      return description.split(' & ');
    } else if (description.contains('+')) {
      return description.split('+');
    } else if (description.contains('&')) {
      return description.split('&');
    } else {
      final patterns = [
        RegExp(r'([^,]+?)\s*\+\s*([^,]+)'),
        RegExp(r'([^,]+?)\s*&\s*([^,]+)'),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(description);
        if (match != null) {
          return [match.group(1)!, match.group(2)!];
        }
      }
      
      return [description];
    }
  }

  Widget _buildTotalAmount(double remainingAmount) {
    final totalOriginalAmount = widget.customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    final partiallyPaidAmount = widget.customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    final hasPendingOrPartiallyPaid = widget.customerDebts.any((debt) => !debt.isFullyPaid);
    final allDebtsFullyPaid = remainingAmount == 0 && widget.customerDebts.isNotEmpty;
    
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
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Amount:',
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

  void _shareReceipt() async {
    try {
      await _exportAsPDF();
    } catch (e) {
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Share Error',
        body: 'Failed to share receipt: $e',
      );
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      final pdf = PdfFontUtils.createDocumentWithFonts();
      await _buildMultiPagePDF(pdf);
      
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month}-${now.year}';
      final fileName = '${widget.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')}_${dateStr}_ID"${widget.customer.id}".pdf';
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('${directory.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles([XFile(file.path)]);
      
      final notificationService = NotificationService();
      await notificationService.showSuccessNotification(
        title: 'PDF Exported',
        body: 'Receipt has been exported as PDF',
      );
    } catch (e) {
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'PDF Export Error',
        body: 'Failed to export PDF: $e',
      );
    }
  }

  Future<void> _buildMultiPagePDF(pw.Document pdf) async {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    final sanitizedCustomerName = PdfFontUtils.sanitizeText(widget.customer.name);
    final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(widget.customer.phone);
    final sanitizedCustomerId = PdfFontUtils.sanitizeText(widget.customer.id);
    
    const int maxDebtsPerPage = 4;
    
    final List<List<Debt>> debtPages = [];
    for (int i = 0; i < sortedDebts.length; i += maxDebtsPerPage) {
      debtPages.add(sortedDebts.skip(i).take(maxDebtsPerPage).toList());
    }
    
    for (int pageIndex = 0; pageIndex < debtPages.length; pageIndex++) {
      final pageDebts = debtPages[pageIndex];
      final isLastPage = pageIndex == debtPages.length - 1;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPDFPage(
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
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
        ] else ...[
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
                  color: PdfColor.fromInt(0xFF0175C2),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ],
        
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
                    color: PdfColor.fromInt(0xFF424242),
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
        
        if (pageIndex == 0) ...[
          PdfFontUtils.createGracefulText(
            'DEBT DETAILS',
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF424242),
          ),
          pw.SizedBox(height: 16),
        ],
        
        ...pageDebts.map((debt) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFE0E0E0),
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
                      color: PdfColor.fromInt(0xFF0175C2),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              PdfFontUtils.createGracefulText(
                _formatDateTime(debt.createdAt),
                fontSize: 12,
                fontWeight: pw.FontWeight.normal,
                color: PdfColor.fromInt(0xFF1976D2),
              ),
            ],
          ),
        )).toList(),
        
        ...pageDebts
            .expand((debt) => _getPartialPaymentsForDebt(debt.id))
            .map((payment) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFE0E0E0),
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
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        _formatCurrency(payment.amount),
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF4CAF50),
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
                      color: PdfColor.fromInt(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            )).toList(),
        
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
                        color: PdfColor.fromInt(0xFF4CAF50),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                ],
                
                if (remainingAmount == 0 && allDebts.isNotEmpty) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Debts Fully Paid',
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50),
                      ),
                      pw.Text(
                        '✓',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
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
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Remaining Amount:',
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey,
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(remainingAmount),
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        
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
    return '\$${amount.toStringAsFixed(2)} USD';
  }
} 