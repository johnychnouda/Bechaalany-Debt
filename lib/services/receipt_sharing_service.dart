import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';
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
    List<PartialPayment> partialPayments,
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        customer, 
        customerDebts, 
        partialPayments, 
        activities, 
        specificDate, 
        specificDebtId
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
        
        // Note: WhatsApp Web doesn't support file attachments via URL
        // The PDF will be available in the app's share sheet for manual attachment
        return launched;
      }
      return false;
    } catch (e) {
      print('Error sharing receipt via WhatsApp: $e');
      return false;
    }
  }
  
  /// Share receipt via email
  static Future<bool> shareReceiptViaEmail(
    Customer customer,
    List<Debt> customerDebts,
    List<PartialPayment> partialPayments,
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        customer, 
        customerDebts, 
        partialPayments, 
        activities, 
        specificDate, 
        specificDebtId
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
      print('Error sharing receipt via email: $e');
      return false;
    }
  }
  
  /// Share receipt via SMS (for customers without WhatsApp)
  static Future<bool> shareReceiptViaSMS(
    Customer customer,
    List<Debt> customerDebts,
    List<PartialPayment> partialPayments,
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
      print('Error sharing receipt via SMS: $e');
      return false;
    }
  }
  
  /// Generate PDF receipt for sharing
  static Future<File?> generateReceiptPDF(
    Customer customer,
    List<Debt> customerDebts,
    List<PartialPayment> partialPayments,
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      print('Starting PDF generation for customer: ${customer.name}');
      print('Customer debts count: ${customerDebts.length}');
      print('Partial payments count: ${partialPayments.length}');
      print('Activities count: ${activities.length}');
      
      final pdf = PdfFontUtils.createDocumentWithFonts();
      print('PDF document created successfully');
      
      await buildReceiptPDF(pdf, customer, customerDebts, partialPayments, activities, specificDate, specificDebtId);
      print('PDF content built successfully');
      
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month}-${now.year}';
      final fileName = '${customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')}_Receipt_${dateStr}_ID${customer.id}.pdf';
      
      print('Saving PDF to: ${directory.path}/$fileName');
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Directory created successfully');
      }
      
      final file = File('${directory.path}/$fileName');
      final pdfBytes = await pdf.save();
      print('PDF saved to bytes, size: ${pdfBytes.length}');
      
      await file.writeAsBytes(pdfBytes);
      print('PDF file written successfully to: ${file.path}');
      
      return file;
    } catch (e, stackTrace) {
      print('Error generating PDF receipt: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Build the PDF receipt content
  static Future<void> buildReceiptPDF(
    pw.Document pdf,
    Customer customer,
    List<Debt> customerDebts,
    List<PartialPayment> partialPayments,
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    // Filter debts based on parameters
    List<Debt> relevantDebts = customerDebts;
    if (specificDebtId != null) {
      relevantDebts = customerDebts.where((debt) => debt.id == specificDebtId).toList();
    } else if (specificDate != null) {
      relevantDebts = customerDebts.where((debt) => 
        debt.createdAt.year == specificDate.year &&
        debt.createdAt.month == specificDate.month &&
        debt.createdAt.day == specificDate.day
      ).toList();
    }
    
    final sortedDebts = List<Debt>.from(relevantDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    final sanitizedCustomerName = PdfFontUtils.sanitizeText(customer.name);
    final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(customer.phone);
    final sanitizedCustomerId = PdfFontUtils.sanitizeText(customer.id);
    
    // Build items list for PDF
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
      
      // Add partial payments for this debt
      final debtPartialPayments = partialPayments.where((p) => p.debtId == debt.id).toList();
      for (PartialPayment payment in debtPartialPayments) {
        allItems.add({
          'type': 'partial_payment',
          'description': 'Partial Payment',
          'amount': payment.amount,
          'date': payment.paidAt,
        });
      }
    }
    
    allItems.sort((a, b) => b['date'].compareTo(a['date']));
    
    // Add PDF page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return buildPDFPage(
            pageItems: allItems,
            allItems: allItems,
            remainingAmount: remainingAmount,
            sanitizedCustomerName: sanitizedCustomerName,
            sanitizedCustomerPhone: sanitizedCustomerPhone,
            sanitizedCustomerId: sanitizedCustomerId,
            specificDate: specificDate,
          );
        },
      ),
    );
  }
  
  /// Build PDF page content
  static pw.Widget buildPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required List<Map<String, dynamic>> allItems,
    required double remainingAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    DateTime? specificDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
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
        
        // Customer Information
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
        
        // Date filter info if applicable
        if (specificDate != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3F2FD),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'Receipt for: ${_formatDateTime(specificDate)}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1976D2),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        
        // Debt Details Header
        PdfFontUtils.createGracefulText(
          'DEBT DETAILS',
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF424242),
        ),
        pw.SizedBox(height: 6),
        
        // Debt items
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
        
        // Total Amount
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
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfFontUtils.createGracefulText(
                      remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty
                          ? 'ALL DEBTS FULLY PAID'
                          : 'TOTAL REMAINING AMOUNT',
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty
                          ? PdfColor.fromInt(0xFF2E7D32)
                          : PdfColor.fromInt(0xFFD32F2F),
                    ),
                  ),
                  PdfFontUtils.createGracefulText(
                    _formatCurrency(remainingAmount),
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty
                        ? PdfColor.fromInt(0xFF2E7D32)
                        : PdfColor.fromInt(0xFFD32F2F),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Footer
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'This receipt was generated on ${_formatDateTime(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF666666),
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thank you for your business with Bechaalany Connect',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF666666),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
