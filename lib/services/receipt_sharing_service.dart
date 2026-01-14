import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../utils/pdf_font_utils.dart';

class ReceiptSharingService {
  static const String _whatsappBaseUrl = 'https://wa.me/';
  static const String _emailSubject = 'Your Debt Receipt from Bechaalany Connect';
  
  /// Share receipt via WhatsApp
  static Future<bool> shareReceiptViaWhatsApp(
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        customer: customer,
        debts: customerDebts,
        // Note: Partial payments are now handled as activities only
        activities: activities,
        specificDate: specificDate,
        specificDebtId: specificDebtId,
      );
      
      if (pdfFile == null) return false;
      
      // Format phone number for WhatsApp
      final phoneNumber = _formatPhoneNumber(customer.phone);
      
      // Create WhatsApp message
      final message = _createWhatsAppMessage(customer, specificDate);
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL with PDF attachment
      final whatsappUrl = '$_whatsappBaseUrl$phoneNumber?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        // Launch WhatsApp
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // The PDF will be available in the app's share sheet for manual attachment
        return launched;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Share receipt via email
  static Future<bool> shareReceiptViaEmail(
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        customer: customer,
        debts: customerDebts,
        // Note: Partial payments are now handled as activities only
        activities: activities,
        specificDate: specificDate,
        specificDebtId: specificDebtId,
      );
      
      if (pdfFile == null) return false;
      
      // Create email body
      final emailBody = _createEmailBody(customer, specificDate);
      
      // Create email URI
      final emailUri = Uri(
        scheme: 'mailto',
        path: customer.email,
        queryParameters: {
          'subject': _emailSubject,
          'body': emailBody,
        },
      );
      
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Share receipt via SMS (for customers without WhatsApp)
  static Future<bool> shareReceiptViaSMS(
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Create SMS message
      final message = _createSMSMessage(customer, specificDate);
      
      // Create SMS URI
      final smsUri = Uri(
        scheme: 'sms',
        path: customer.phone,
        queryParameters: {
          'body': message,
        },
      );
      
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate and save PDF receipt for a customer
  static Future<File?> generateReceiptPDF({
    required Customer customer,
    required List<Debt> debts,
    // Note: Partial payments are now handled as activities only
    required List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  }) async {
    try {
      // Filter debts to only include those relevant to the payment being viewed
      final relevantDebts = _getRelevantDebts(debts, activities, customer, specificDate, specificDebtId);
      final sortedDebts = List<Debt>.from(relevantDebts);
      sortedDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Check if customer has pending debts (for future use)
      // final hasPendingDebts = sortedDebts.any((debt) => !debt.isFullyPaid);
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Build PDF content
      final allItems = <Map<String, dynamic>>[];
      
      // Add debts for this customer
      for (Debt debt in sortedDebts) {
        allItems.add({
          'type': 'debt',
          'description': debt.description,
          'amount': debt.amount,
          'date': debt.createdAt,
          'debt': debt,
        });
      }
      
      // Filter partial payments to only include those relevant to the debts being shown
      // Note: Partial payments are now handled as payment activities below
      
      // Filter payment activities to only include those relevant to the debts being shown
      final relevantPaymentActivities = _getRelevantPaymentActivities(activities, sortedDebts, customer, specificDate, specificDebtId);
      
      // Add relevant payment activities (these are the actual partial payments shown in Activity History)
      for (Activity activity in relevantPaymentActivities) {
        // Only add payment activities that have a payment amount
        if (activity.paymentAmount != null && activity.paymentAmount! > 0) {
          allItems.add({
            'type': 'payment_activity',
            'description': 'Partial Payment',
            'amount': activity.paymentAmount!,
            'date': activity.date,
            'activity': activity,
          });
        }
      }
      
      allItems.sort((a, b) => b['date'].compareTo(a['date']));
      
      // Calculate total paid amount from relevant payment activities
      double totalPaidAmount = relevantPaymentActivities.fold<double>(0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
      
      // Calculate total original amount from relevant debts
      double totalOriginalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      
      final sanitizedCustomerName = PdfFontUtils.sanitizeText(customer.name);
      final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(customer.phone);
      final sanitizedCustomerId = PdfFontUtils.sanitizeText(customer.id);
      
      // Add PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return buildPDFPage(
              pageItems: allItems,
              allItems: allItems,
              remainingAmount: totalOriginalAmount - totalPaidAmount, // Calculate remaining amount
              totalPaidAmount: totalPaidAmount,
              totalOriginalAmount: totalOriginalAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              specificDate: specificDate,
            );
          },
        ),
      );
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = '${customer.name}_Receipt_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_ID${customer.id}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verify file was created
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Build PDF page content
  static pw.Widget buildPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required List<Map<String, dynamic>> allItems,
    required double remainingAmount,
    required double totalPaidAmount,
    required double totalOriginalAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    DateTime? specificDate,
  }) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: PdfColors.white,
      child: pw.Column(
        children: [
          // Ultra Compact Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // App name
                pw.Text(
                  'Bechaalany Connect',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF64748B),
                  ),
                ),
                pw.SizedBox(height: 4),
                
                // Main title
                pw.Text(
                  'Customer Receipt',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 1),
                
                // Generation date
                pw.Text(
                  'Generated on ${_formatDateTime(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          
          // Compact Customer Information Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CUSTOMER INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    sanitizedCustomerName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    ),
                  ),
                  if (sanitizedCustomerPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      sanitizedCustomerPhone,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColor.fromInt(0xFF475569),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'ID: $sanitizedCustomerId',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Date filter info if applicable
          if (specificDate != null) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEFF6FF),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFF3B82F6),
                    width: 1,
                  ),
                ),
                child: pw.Text(
                  'Receipt for: ${_formatDateTime(specificDate)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF3B82F6),
                  ),
                ),
              ),
            ),
          ],
          
          // Transactions Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 16),
            child: pw.Text(
              'TRANSACTION HISTORY',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ),
          
          // All transactions (debts and payments) with modern design
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: pw.ListView.builder(
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  final isPayment = item['type'] == 'partial_payment' || item['type'] == 'payment_activity';
                  
                  PdfColor backgroundColor;
                  PdfColor borderColor;
                  PdfColor textColor;
                  PdfColor amountColor;
                  
                  if (isPayment) {
                    backgroundColor = PdfColor.fromInt(0xFFFFFBEB); // Light orange for payments
                    borderColor = PdfColor.fromInt(0xFFF59E0B); // Orange border
                    textColor = PdfColor.fromInt(0xFF92400E); // Dark orange text
                    amountColor = PdfColor.fromInt(0xFFF59E0B); // Orange amount
                  } else {
                    backgroundColor = PdfColor.fromInt(0xFFF0F4FF); // Light blue for debts
                    borderColor = PdfColor.fromInt(0xFF6366F1); // Blue border
                    textColor = PdfColor.fromInt(0xFF1E40AF); // Dark blue text
                    amountColor = PdfColor.fromInt(0xFF6366F1); // Blue amount
                  }
                  
                  return pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: backgroundColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        // Status indicator dot
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: borderColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                item['description'],
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                _formatDateTime(item['date']),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColor.fromInt(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(item['amount']),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Clean Summary Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Column(
              children: [
                // Summary title
                pw.Text(
                  'Account Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                
                // Clean summary layout - no cards, just clean rows
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Total Original',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(totalOriginalAmount),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Total Paid',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(totalPaidAmount),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Remaining',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(remainingAmount),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Clean Footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Text(
              'Generated by Bechaalany Connect',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF94A3B8),
                letterSpacing: 0.3,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Create WhatsApp message
  static String _createWhatsAppMessage(Customer customer, DateTime? specificDate) {
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Hi ${customer.name}! 

Here's your debt receipt$dateInfo from Bechaalany Connect.

I've attached the detailed PDF receipt showing all your transactions and current balance.

If you have any questions about your account, please don't hesitate to contact us.

Thank you for your business! 💼✨

Best regards,
Bechaalany Connect Team''';
  }
  
  /// Create email body
  static String _createEmailBody(Customer customer, DateTime? specificDate) {
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Dear ${customer.name},

Thank you for requesting your debt receipt$dateInfo from Bechaalany Connect.

Please find attached your detailed receipt in PDF format, which includes:
• All debt transactions
• Payment history
• Current balance status
• Account summary

If you have any questions about your account or need clarification on any transactions, please don't hesitate to reach out to us.

We appreciate your business and look forward to continuing to serve you.

Best regards,
Bechaalany Connect Team

---
This is an automated receipt. Please contact us for any account-related inquiries.''';
  }
  
  /// Create SMS message
  static String _createSMSMessage(Customer customer, DateTime? specificDate) {
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Hi ${customer.name}! Your debt receipt$dateInfo from Bechaalany Connect has been generated. Check your email or WhatsApp for the detailed PDF. Thank you for your business! 💼✨''';
  }
  
  /// Format phone number for WhatsApp
  static String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Ensure it starts with country code
    if (digits.startsWith('0')) {
      digits = '961${digits.substring(1)}'; // Lebanon country code
    } else if (!digits.startsWith('961')) {
      digits = '961$digits'; // Add Lebanon country code if missing
    }
    
    return digits;
  }
  
  /// Format currency
  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} USD';
  }
  
  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Format date and time for display
  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final second = dateTime.second;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} at ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';
  }
  
  /// Get relevant debts based on payment context
  static List<Debt> _getRelevantDebts(
    List<Debt> allCustomerDebts,
    List<Activity> activities,
    Customer customer,
    DateTime? specificDate,
    String? specificDebtId,
  ) {
    // If a specific debt ID is provided, show all debts until partial payment
    if (specificDebtId != null) {
      // Check if any partial payments have been made
      final hasPartialPayments = allCustomerDebts.any((debt) => debt.paidAmount > 0);
      
      if (hasPartialPayments) {
        // If partial payments exist, show only the specific debt
        return allCustomerDebts.where((debt) {
          return debt.id == specificDebtId;
        }).toList();
      } else {
        // If no partial payments, show all debts (accumulate all new debts)
        return allCustomerDebts.where((debt) => debt.paidAmount == 0).toList();
      }
    }
    
    // If a specific date is provided, filter debts to only include those relevant to that date
    if (specificDate != null) {
      final targetDate = specificDate;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return allCustomerDebts.where((debt) {
        // Include debts created within 1 hour of the specific debt time
        return debt.createdAt.isAfter(startTime) && debt.createdAt.isBefore(endTime);
      }).toList();
    }
    
    // If no specific date or debt ID, show only active debts (not fully paid)
    // This excludes old debts that were already paid off
    return allCustomerDebts.where((debt) => !debt.isFullyPaid).toList();
  }
  
  /// Get relevant partial payments based on the debts being shown
  // Note: Partial payments are now handled as activities only
  
  /// Get relevant payment activities based on the debts being shown
  static List<Activity> _getRelevantPaymentActivities(
    List<Activity> allActivities,
    List<Debt> relevantDebts,
    Customer customer,
    DateTime? specificDate,
    String? specificDebtId,
  ) {
    // Filter to only payment activities for this customer
    final customerPaymentActivities = allActivities
        .where((activity) => 
            activity.type == ActivityType.payment && 
            activity.customerId == customer.id)
        .toList();
    
    // If a specific debt ID is provided, only include activities for that debt
    if (specificDebtId != null) {
      return customerPaymentActivities.where((activity) => activity.debtId == specificDebtId).toList();
    }
    
    // If a specific date is provided, only include activities within 1 hour of that date
    if (specificDate != null) {
      final targetDate = specificDate;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return customerPaymentActivities.where((activity) {
        return activity.date.isAfter(startTime) && activity.date.isBefore(endTime);
      }).toList();
    }
    
    // If no specific filters, include only payment activities for the active debts being shown
    // This excludes payments for old debts that were already paid off
    final relevantDebtIds = relevantDebts.map((debt) => debt.id).toSet();
    return customerPaymentActivities.where((activity) {
      // If activity has a specific debt ID, check if it matches
      if (activity.debtId != null) {
        return relevantDebtIds.contains(activity.debtId);
      }
      // If activity doesn't have a specific debt ID (cross-debt payment),
      // check if the activity date is after any of the relevant debts
      return relevantDebts.any((debt) => activity.date.isAfter(debt.createdAt));
    }).toList();
  }

  /// Generate monthly activity PDF report
  static Future<File?> generateMonthlyActivityPDF({
    required List<Activity> monthlyActivities,
    required List<Debt> monthlyDebts,
    required double totalRevenue,
    required double totalPaid,
    required DateTime monthDate,
  }) async {
    try {
      // Create PDF document
      final pdf = pw.Document();
      
      // Build PDF content
      final allItems = <Map<String, dynamic>>[];
      
      // Add all activities for the month - ensure ALL activities are included
      for (Activity activity in monthlyActivities) {
        try {
          // Calculate amount - use paymentAmount if available, otherwise amount, default to 0.0
          final amount = activity.paymentAmount ?? activity.amount ?? 0.0;
          
          // Include ALL activities regardless of amount (some might have 0 amount)
          allItems.add({
            'type': activity.type.toString().split('.').last,
            'description': activity.description ?? '',
            'amount': amount,
            'date': activity.date,
            'activity': activity,
            'customerName': activity.customerName ?? '',
            'customerId': activity.customerId ?? '',
          });
        } catch (e) {
          // If there's an error adding an activity, try to add it with minimal data
          // This ensures we don't lose any transactions
          try {
            allItems.add({
              'type': 'activity',
              'description': activity.description ?? 'Activity',
              'amount': 0.0,
              'date': activity.date,
              'activity': activity,
              'customerName': activity.customerName ?? '',
              'customerId': activity.customerId ?? '',
            });
          } catch (_) {
            // Skip this activity only if we can't add it at all
            // This should rarely happen
          }
        }
      }
      
      // Sort by date (newest first)
      allItems.sort((a, b) => b['date'].compareTo(a['date']));
      
      // Verify we have the correct number of items
      // If not, it means some activities couldn't be added
      // The PDF will still generate with available items
      
      final monthName = _getMonthName(monthDate.month);
      final year = monthDate.year;
      
      // Pagination constants - items per page (adjusted based on actual fit)
      const int itemsPerFirstPage = 10; // Items that fit on first page (with header, summary, footer)
      const int itemsPerPage = 14; // Items that fit on subsequent pages (with header, footer)
      
      // Calculate total pages needed
      int totalPages;
      if (allItems.length <= itemsPerFirstPage) {
        totalPages = 1;
      } else {
        final remainingItems = allItems.length - itemsPerFirstPage;
        // Calculate how many additional pages we need for remaining items
        final additionalPages = (remainingItems / itemsPerPage).ceil();
        totalPages = 1 + additionalPages;
      }
      
      // Generate first page with summary
      final firstPageItems = allItems.take(itemsPerFirstPage).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return buildMonthlyActivityPDFPage(
              pageItems: firstPageItems,
              totalRevenue: totalRevenue,
              totalPaid: totalPaid,
              monthName: monthName,
              year: year,
              totalTransactions: allItems.length, // Use actual allItems length, not monthlyActivities
              pageIndex: 0,
              totalPages: totalPages,
              isFirstPage: true,
              showSummary: true,
            );
          },
        ),
      );
      
      // Generate additional pages if needed
      if (allItems.length > itemsPerFirstPage) {
        int currentIndex = itemsPerFirstPage;
        
        // Calculate how many additional pages we need
        final remainingItems = allItems.length - itemsPerFirstPage;
        final additionalPagesNeeded = (remainingItems / itemsPerPage).ceil();
        
        // Create exactly the number of additional pages needed
        for (int i = 0; i < additionalPagesNeeded && currentIndex < allItems.length; i++) {
          final pageItems = allItems.skip(currentIndex).take(itemsPerPage).toList();
          
          // Only create a page if there are items to show
          if (pageItems.isEmpty) {
            break;
          }
          
          // pageIndex for additional pages: i + 1 (since page 0 is the first page)
          final pageIndex = i + 1;
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return buildMonthlyActivityPDFPage(
                  pageItems: pageItems,
                  totalRevenue: totalRevenue,
                  totalPaid: totalPaid,
                  monthName: monthName,
                  year: year,
                  totalTransactions: allItems.length, // Use actual allItems length
                  pageIndex: pageIndex,
                  totalPages: totalPages,
                  isFirstPage: false,
                  showSummary: false,
                );
              },
            ),
          );
          
          currentIndex += pageItems.length;
        }
      }
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'Monthly_Activity_Report_${monthName}_${year}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verify file was created
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Build monthly activity PDF page content
  static pw.Widget buildMonthlyActivityPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required double totalRevenue,
    required double totalPaid,
    required String monthName,
    required int year,
    required int totalTransactions,
    int pageIndex = 0,
    int totalPages = 1,
    bool isFirstPage = true,
    bool showSummary = true,
  }) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: PdfColors.white,
      child: pw.Column(
        children: [
          // Ultra Compact Header (only on first page)
          if (isFirstPage)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // App name
                  pw.Text(
                    'Bechaalany Connect',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  
                  // Main title
                  pw.Text(
                    'Monthly Activity Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  
                  // Month and year
                  pw.Text(
                    '$monthName $year',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColor.fromInt(0xFF475569),
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  // Generation date (only on first page)
                  pw.Text(
                    'Generated on ${_formatDateForPDF(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          
          // Clean Summary Section (only on first page)
          if (showSummary)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Column(
                children: [
                  // Summary title
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  
                  // Clean summary layout - no cards, just clean rows
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Total Revenue',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            ),
                          ),
                          pw.Text(
                            '\$${totalRevenue.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Total Paid',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            ),
                          ),
                          pw.Text(
                            '\$${totalPaid.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Transactions',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            ),
                          ),
                          pw.Text(
                            '$totalTransactions',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Activities Section with clean design
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Activity Details header (only on first page)
                  if (isFirstPage) ...[
                    pw.Text(
                      'Activity Details',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                  ],
                  pw.Expanded(
                    child: pw.ListView.builder(
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        final item = pageItems[index];
                        return _buildModernActivityPDFItem(item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Clean Footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'Generated by Bechaalany Connect',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFF94A3B8),
                    letterSpacing: 0.3,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                // Page number at bottom (if multiple pages)
                if (totalPages > 1) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Page ${pageIndex + 1} of $totalPages',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern summary card for PDF
  static pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact summary card for PDF
  static pw.Widget _buildCompactSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer summary card for PDF
  static pw.Widget _buildCustomerSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern activity item for PDF
  static pw.Widget _buildModernActivityPDFItem(Map<String, dynamic> item) {
    final activity = item['activity'] as Activity;
    final amount = item['amount'] as double;
    final date = item['date'] as DateTime;
    final customerName = item['customerName'] as String;
    final description = item['description'] as String;
    
    PdfColor statusColor;
    String statusText;
    PdfColor backgroundColor;
    
    switch (activity.type) {
      case ActivityType.payment:
        if (activity.isPaymentCompleted) {
          if (description.startsWith('Fully paid:')) {
            statusColor = PdfColor.fromInt(0xFF10B981);
            statusText = 'Fully Paid';
            backgroundColor = PdfColor.fromInt(0xFFECFDF5);
          } else {
            statusColor = PdfColor.fromInt(0xFF3B82F6);
            statusText = 'Debt Paid';
            backgroundColor = PdfColor.fromInt(0xFFEFF6FF);
          }
        } else {
          statusColor = PdfColor.fromInt(0xFFF59E0B);
          statusText = 'Partial Payment';
          backgroundColor = PdfColor.fromInt(0xFFFFFBEB);
        }
        break;
      case ActivityType.newDebt:
        statusColor = PdfColor.fromInt(0xFF6366F1);
        statusText = 'New Debt';
        backgroundColor = PdfColor.fromInt(0xFFF0F4FF);
        break;
      case ActivityType.debtCleared:
        statusColor = PdfColor.fromInt(0xFF3B82F6);
        statusText = 'Debt Paid';
        backgroundColor = PdfColor.fromInt(0xFFEFF6FF);
        break;
      default:
        statusColor = PdfColor.fromInt(0xFF64748B);
        statusText = 'Activity';
        backgroundColor = PdfColor.fromInt(0xFFF8FAFC);
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 0.5,
        ),
      ),
      child: pw.Row(
        children: [
          // Status indicator dot
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: statusColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 10),
          
          // Main content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Customer name and description in one line
                pw.Text(
                  '$customerName - $description',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 2),
                
                // Date
                pw.Text(
                  _formatActivityDate(date),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          
          // Amount and status in one column
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '\$${amount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: statusColor,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                statusText,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.normal,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual activity item for PDF (legacy method for compatibility)
  static pw.Widget _buildActivityPDFItem(Map<String, dynamic> item) {
    final activity = item['activity'] as Activity;
    final amount = item['amount'] as double;
    final date = item['date'] as DateTime;
    final customerName = item['customerName'] as String;
    final description = item['description'] as String;
    
    PdfColor iconColor;
    String statusText;
    
    switch (activity.type) {
      case ActivityType.payment:
        if (activity.isPaymentCompleted) {
          if (description.startsWith('Fully paid:')) {
            iconColor = PdfColors.green;
            statusText = 'Fully Paid';
          } else {
            iconColor = PdfColors.blue;
            statusText = 'Debt Paid';
          }
        } else {
          iconColor = PdfColors.orange;
          statusText = 'Partial Payment';
        }
        break;
      case ActivityType.newDebt:
        iconColor = PdfColors.blue;
        statusText = 'New Debt';
        break;
      case ActivityType.debtCleared:
        iconColor = PdfColors.blue;
        statusText = 'Debt Paid';
        break;
      default:
        iconColor = PdfColors.grey;
        statusText = 'Activity';
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: iconColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '$statusText: \$${amount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: iconColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _formatActivityDate(date),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get month name from month number
  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Format date for PDF
  static String _formatDateForPDF(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format activity date for PDF
  static String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      return 'Today at ${_formatTime12Hour(date)}';
    } else if (activityDate == yesterday) {
      return 'Yesterday at ${_formatTime12Hour(date)}';
    } else {
      return '${_formatDateForPDF(date)} at ${_formatTime12Hour(date)}';
    }
  }

  /// Format time in 12-hour format for PDF
  static String _formatTime12Hour(DateTime date) {
    int hour = date.hour;
    String period = 'am';
    
    if (hour >= 12) {
      period = 'pm';
      if (hour > 12) {
        hour -= 12;
      }
    }
    if (hour == 0) {
      hour = 12;
    }
    
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  /// Share a PDF file using the system share dialog
  static Future<void> sharePDFFile(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Monthly Activity Report from Bechaalany Connect',
      );
    } catch (e) {
      // Handle error silently
    }
  }
}
