import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cross_file/cross_file.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';
import '../models/activity.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/pdf_font_utils.dart';
import '../utils/logo_utils.dart';
import '../utils/debt_description_utils.dart';

class CustomerDebtReceiptScreen extends StatefulWidget {
  final Customer customer;
  final List<Debt> customerDebts;
  final List<PartialPayment> partialPayments;
  final List<Activity> activities;

  const CustomerDebtReceiptScreen({
    super.key,
    required this.customer,
    required this.customerDebts,
    required this.partialPayments,
    required this.activities,
  });

  @override
  State<CustomerDebtReceiptScreen> createState() => _CustomerDebtReceiptScreenState();
}

class _CustomerDebtReceiptScreenState extends State<CustomerDebtReceiptScreen> {
  
  List<Debt> _getRelevantDebts(List<Debt> allCustomerDebts) {
    // Include all active debts (not fully paid) and fully paid debts
    // This ensures new debts are included even if they were created after payments
    return allCustomerDebts.where((debt) {
      // Include all debts that are not fully paid (pending or partially paid)
      if (!debt.isFullyPaid) {
        return true;
      }
      
      // Include fully paid debts for historical reference
      return debt.isFullyPaid;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    // Filter debts to only include those relevant to the payment being viewed
    // This excludes new debts that were created after the payment was completed
    final relevantDebts = _getRelevantDebts(widget.customerDebts);
    
    final sortedDebts = List<Debt>.from(relevantDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
            _buildReceiptHeader(),
            const SizedBox(height: 24),
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            _buildDebtDetails(sortedDebts),
            const SizedBox(height: 24),
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
    List<Map<String, dynamic>> allItems = [];
    
    for (Debt debt in sortedDebts) {
      final cleanedDescription = DebtDescriptionUtils.cleanDescription(debt.description);
      
      // Always show the debt/product
      allItems.add({
        'type': 'debt',
        'description': cleanedDescription,
        'amount': debt.amount,
        'date': debt.createdAt,
        'debt': debt,
      });
    }
    
    // Add payment activities for this customer that are relevant to the debts being viewed
    final customerPaymentActivities = widget.activities
        .where((activity) => 
            activity.type == ActivityType.payment && 
            activity.customerId == widget.customer.id)
        .toList();
    
    for (Activity activity in customerPaymentActivities) {
      // Check if this activity is relevant to any of the debts being viewed
      bool isRelevant = false;
      
      for (Debt debt in sortedDebts) {
        // If activity has a specific debt ID, check if it matches
        if (activity.debtId != null) {
          if (activity.debtId == debt.id) {
            isRelevant = true;
            break;
          }
        } else {
          // If activity doesn't have a specific debt ID (cross-debt payment),
          // check if the activity date is after the debt creation date
          if (activity.date.isAfter(debt.createdAt)) {
            isRelevant = true;
            break;
          }
        }
      }
      
      if (isRelevant) {
        allItems.add({
          'type': 'payment_activity',
          'description': activity.paymentAmount == activity.amount ? 'Payment completed' : 'Partial payment',
          'amount': activity.paymentAmount ?? 0,
          'date': activity.date,
          'activity': activity,
        });
      }
    }
    
    allItems.sort((a, b) => b['date'].compareTo(a['date']));
    
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
          ...allItems.map((item) {
            if (item['type'] == 'debt') {
              return _buildDebtItem(item['debt']);
            } else if (item['type'] == 'payment_activity') {
              return _buildPaymentActivityItem(item['activity']);
            } else {
              return _buildPartialPaymentItem(item['payment']);
            }
          }).toList(),
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
                  DebtDescriptionUtils.cleanDescription(debt.description),
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

  Widget _buildPaymentActivityItem(Activity activity) {
    final isFullPayment = activity.paymentAmount == activity.amount;
    
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
                  color: (isFullPayment ? Colors.green[600] : Colors.orange[600])?.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFullPayment ? Icons.check_circle : Icons.payment,
                  size: 14,
                  color: isFullPayment ? Colors.green[600] : Colors.orange[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.paymentAmount == activity.amount ? 'Payment completed' : 'Partial payment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, activity.paymentAmount ?? 0),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isFullPayment ? Colors.green[600] : Colors.orange[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(activity.date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isFullPayment ? Colors.green[600] : Colors.orange[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
                  color: (Colors.green[600] ?? Colors.green).withAlpha(26),
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

  Widget _buildTotalAmount(double remainingAmount) {
    final totalOriginalAmount = widget.customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    final partiallyPaidAmount = widget.customerDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    
    // Determine the payment status for the relevant debts
    final hasPartialPayments = partiallyPaidAmount > 0;
    final allDebtsFullyPaid = remainingAmount == 0 && widget.customerDebts.isNotEmpty;
    final hasNewDebts = widget.customerDebts.any((debt) => debt.paidAmount == 0 && !debt.isFullyPaid);
    
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
          // Case 1: New debt (no payments) - show only remaining amount
          if (hasNewDebts && !hasPartialPayments && !allDebtsFullyPaid) ...[
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
          
          // Case 2: Partial payments made - show partially paid amount and remaining amount
          if (hasPartialPayments && !allDebtsFullyPaid) ...[
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
          
          // Case 3: Fully paid - show full paid amount status
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
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(context, totalOriginalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 24,
                    ),
                  ],
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
          ],
        ],
      ),
    );
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
      
      await Share.shareFiles([file.path]);
      
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
    
    List<Map<String, dynamic>> allItems = [];
    
    for (Debt debt in sortedDebts) {
      final cleanedDescription = DebtDescriptionUtils.cleanDescription(debt.description);
      
      allItems.add({
        'type': 'debt',
        'description': cleanedDescription,
        'amount': debt.amount,
        'date': debt.createdAt,
        'debt': debt,
      });
      
      final partialPayments = _getPartialPaymentsForDebt(debt.id);
      for (PartialPayment payment in partialPayments) {
        allItems.add({
          'type': 'partial_payment',
          'description': 'Partial Payment',
          'amount': payment.amount,
          'date': payment.paidAt,
        });
      }
    }
    
    allItems.sort((a, b) => b['date'].compareTo(a['date']));
    
    const int itemsPerPage = 6;
    const int firstPageItemCount = 12;
    
    if (allItems.length <= firstPageItemCount) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return _buildPDFPage(
              pageItems: allItems,
              allItems: allItems,
              remainingAmount: remainingAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              pageIndex: 0,
              totalPages: 1,
              isFirstPage: true,
              isLastPage: true,
            );
          },
        ),
      );
    } else {
      int currentIndex = 0;
      int pageIndex = 0;
      
      final remainingItemsAfterFirstPage = allItems.length - firstPageItemCount;
      final additionalPagesNeeded = (remainingItemsAfterFirstPage / itemsPerPage).ceil();
      final totalPages = 1 + additionalPagesNeeded;
      
      final firstPageItems = allItems.take(firstPageItemCount).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return _buildPDFPage(
              pageItems: firstPageItems,
              allItems: allItems,
              remainingAmount: remainingAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              pageIndex: pageIndex,
              totalPages: totalPages,
              isFirstPage: true,
              isLastPage: totalPages == 1,
            );
          },
        ),
      );
      
      currentIndex = firstPageItemCount;
      pageIndex++;
      
      while (currentIndex < allItems.length) {
        final pageItems = allItems.skip(currentIndex).take(itemsPerPage).toList();
        final isLastPage = pageIndex == totalPages - 1;
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(8),
            build: (pw.Context context) {
              return _buildPDFPage(
                pageItems: pageItems,
                allItems: allItems,
                remainingAmount: remainingAmount,
                sanitizedCustomerName: sanitizedCustomerName,
                sanitizedCustomerPhone: sanitizedCustomerPhone,
                sanitizedCustomerId: sanitizedCustomerId,
                pageIndex: pageIndex,
                totalPages: totalPages,
                isFirstPage: false,
                isLastPage: isLastPage,
              );
            },
          ),
        );
        
        currentIndex += itemsPerPage;
        pageIndex++;
      }
    }
  }

  pw.Widget _buildPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required List<Map<String, dynamic>> allItems,
    required double remainingAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    required int pageIndex,
    required int totalPages,
    required bool isFirstPage,
    required bool isLastPage,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (isFirstPage) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    'Bechaalany Connect',
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    _formatDateTime(DateTime.now()),
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'CUSTOMER INFORMATION',
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 4),
                PdfFontUtils.createGracefulText(
                  sanitizedCustomerName,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                if (sanitizedCustomerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  PdfFontUtils.createGracefulText(
                    sanitizedCustomerPhone,
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF424242),
                  ),
                ],
                pw.SizedBox(height: 2),
                PdfFontUtils.createGracefulText(
                  'ID: $sanitizedCustomerId',
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          
          PdfFontUtils.createGracefulText(
            'DEBT DETAILS',
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF424242),
          ),
          pw.SizedBox(height: 6),
        ],
        
        ...pageItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLastItem = index == pageItems.length - 1;
          
          return pw.Container(
            margin: pw.EdgeInsets.only(
              bottom: isLastItem ? 0 : 4,
            ),
            padding: const pw.EdgeInsets.all(8),
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
                        item['description'],
                        fontSize: 11,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    PdfFontUtils.createGracefulText(
                      _formatCurrency(item['amount']),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: item['type'] == 'partial_payment' 
                          ? PdfColor.fromInt(0xFF4CAF50)
                          : PdfColor.fromInt(0xFF0175C2),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                PdfFontUtils.createGracefulText(
                  _formatDateTime(item['date']),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.normal,
                  color: item['type'] == 'partial_payment' 
                      ? PdfColor.fromInt(0xFF4CAF50)
                      : PdfColor.fromInt(0xFF1976D2),
                ),
              ],
            ),
          );
        }).toList(),
        
        if (isLastPage) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty
                  ? PdfColor.fromInt(0xFFE8F5E8) // Light green background for fully paid
                  : PdfColor.fromInt(0xFFFFEBEE), // Light red background for not fully paid
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'SUMMARY',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF424242),
                ),
                pw.SizedBox(height: 6),
                
                if (remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Debts Fully Paid',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(allItems
                            .where((item) => item['type'] == 'debt')
                            .fold<double>(0, (sum, item) => sum + item['amount'])),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F), // Red color for amount
                      ),
                    ],
                  ),
                ] else ...[
                  // Calculate partially paid amount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Partially Paid Amount:',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(allItems
                            .where((item) => item['type'] == 'partial_payment')
                            .fold<double>(0, (sum, item) => sum + item['amount'])),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50), // Green color for partially paid
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Remaining Amount:',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(remainingAmount),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F), // Red color for remaining amount
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(
              child: PdfFontUtils.createGracefulText(
                'Page ${pageIndex + 1} of $totalPages',
                fontSize: 7,
                color: PdfColor.fromInt(0xFF999999),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} USD';
  }
} 