import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../utils/pdf_font_utils.dart';
import '../utils/debt_description_utils.dart';

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
      
      // Check if customer has pending debts
      final hasPendingDebts = sortedDebts.any((debt) => !debt.isFullyPaid);
      
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
        final fileSize = await file.length();
        return file;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      margin: pw.EdgeInsets.zero,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    'Bechaalany Connect',
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    _formatDateTime(DateTime.now()),
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),
          
          // Customer Information
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'CUSTOMER INFORMATION',
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 2),
                PdfFontUtils.createGracefulText(
                  sanitizedCustomerName,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                if (sanitizedCustomerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  PdfFontUtils.createGracefulText(
                    sanitizedCustomerPhone,
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF424242),
                  ),
                ],
                pw.SizedBox(height: 1),
                PdfFontUtils.createGracefulText(
                  'ID: $sanitizedCustomerId',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),
          
          // Date filter info if applicable
          if (specificDate != null) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3F2FD),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: PdfFontUtils.createGracefulText(
                'Receipt for: ${_formatDateTime(specificDate)}',
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1976D2),
              ),
            ),
            pw.SizedBox(height: 2),
          ],
          
          // All Transactions Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: PdfFontUtils.createGracefulText(
              'TRANSACTION HISTORY',
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF424242),
            ),
          ),
          pw.SizedBox(height: 2),
          
          // All transactions (debts and payments)
          ...allItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLastItem = index == allItems.length - 1;
            final isPayment = item['type'] == 'partial_payment' || item['type'] == 'payment_activity';
            
            return pw.Container(
              width: double.infinity,
              margin: pw.EdgeInsets.only(
                bottom: isLastItem ? 0 : 8,
              ),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: isPayment 
                    ? PdfColor.fromInt(0xFFE8F5E8) // Light green for payments
                    : PdfColor.fromInt(0xFFE3F2FD), // Light blue for products/debts
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(
                  color: isPayment 
                      ? PdfColor.fromInt(0xFF4CAF50) // Green border for payments
                      : PdfColor.fromInt(0xFF3B82F6), // Blue border for debts
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
                          fontSize: 14, // Increased from 13px
                          fontWeight: pw.FontWeight.bold,
                          color: isPayment 
                              ? PdfColor.fromInt(0xFF2E7D32) // Green for payments
                              : PdfColor.fromInt(0xFF1E40AF), // Blue for products/debts
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(item['amount']),
                        fontSize: 14, // Increased from 13px
                        fontWeight: pw.FontWeight.bold,
                        color: isPayment 
                            ? PdfColor.fromInt(0xFF2E7D32) // Green for payments
                            : PdfColor.fromInt(0xFF1E40AF), // Dark blue for debts
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: PdfFontUtils.createGracefulText(
                          _formatDateTime(item['date']),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.normal,
                          color: isPayment 
                              ? PdfColor.fromInt(0xFF2E7D32) // Green for payments
                              : PdfColor.fromInt(0xFF3B82F6), // Blue for debts
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          
          // Summary Section
          pw.SizedBox(height: 8),
          
          // Summary Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9), // Very light grey background
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: PdfFontUtils.createGracefulText(
                'ACCOUNT SUMMARY',
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF475569), // Slate color
              ),
            ),
          ),
          
          pw.SizedBox(height: 6),
          
          // Total Original Amount
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3F4F6), // Light grey background
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: PdfFontUtils.createGracefulText(
                    'TOTAL ORIGINAL AMOUNT',
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal, // Changed from bold to normal
                    color: PdfColor.fromInt(0xFF6B7280), // Lighter grey
                  ),
                ),
                PdfFontUtils.createGracefulText(
                  _formatCurrency(totalOriginalAmount),
                  fontSize: 15, // Increased from 14px
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF374151), // Darker grey
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 6),
          
          // Total Paid Amount
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8F5E8), // Light green background for paid amount
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: PdfFontUtils.createGracefulText(
                    'TOTAL PAID AMOUNT',
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal, // Changed from bold to normal
                    color: PdfColor.fromInt(0xFF059669), // Lighter green
                  ),
                ),
                PdfFontUtils.createGracefulText(
                  _formatCurrency(totalPaidAmount),
                  fontSize: 15, // Increased from 14px
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF047857), // Darker green
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 6),
          
          // Total Remaining Amount
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFEBEE), // Light red background for remaining amount
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: PdfFontUtils.createGracefulText(
                    'TOTAL REMAINING AMOUNT',
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal, // Changed from bold to normal
                    color: PdfColor.fromInt(0xFFDC2626), // Lighter red
                  ),
                ),
                PdfFontUtils.createGracefulText(
                  _formatCurrency(remainingAmount),
                  fontSize: 16, // Increased from 14px to emphasize this important amount
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFB91C1C), // Darker red
                ),
              ],
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
}
