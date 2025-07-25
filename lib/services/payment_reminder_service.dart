import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/customer.dart';
import '../models/debt.dart';

class PaymentReminderService {
  static const String _whatsappBaseUrl = 'https://wa.me/';
  
  /// Send payment reminder via WhatsApp
  static Future<bool> sendWhatsAppReminder(
    Customer customer,
    List<Debt> debts,
    String message,
  ) async {
    try {
      final phoneNumber = _formatPhoneNumber(customer.phone);
      final formattedMessage = _formatReminderMessage(customer, debts, message);
      final encodedMessage = Uri.encodeComponent(formattedMessage);
      final whatsappUrl = '$_whatsappBaseUrl$phoneNumber?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error sending WhatsApp reminder: $e');
      return false;
    }
  }

  /// Generate PDF payment reminder
  static Future<File?> generatePaymentReminderPDF(
    Customer customer,
    List<Debt> debts,
    String message,
  ) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Reminder',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Customer Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
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
                      pw.SizedBox(height: 8),
                      pw.Text('Name: ${customer.name}'),
                      pw.Text('Phone: ${customer.phone}'),
                      if (customer.email != null) pw.Text('Email: ${customer.email}'),
                      if (customer.address != null) pw.Text('Address: ${customer.address}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Outstanding Debts
                pw.Text(
                  'Outstanding Debts',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...debts.map((debt) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        debt.description,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Amount: \$${debt.amount.toStringAsFixed(2)}'),
                          pw.Text('Created: ${_formatDate(debt.createdAt)}'),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
                pw.SizedBox(height: 20),
                
                // Total Amount
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Outstanding:',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '\$${debts.fold<double>(0, (sum, debt) => sum + debt.amount).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Message
                if (message.isNotEmpty) ...[
                  pw.Text(
                    'Message:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    message,
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
                
                pw.SizedBox(height: 30),
                
                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    'This is an automated payment reminder. Please contact us if you have any questions.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/payment_reminder_${customer.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }

  /// Send payment reminder with PDF attachment
  static Future<bool> sendPaymentReminderWithPDF(
    Customer customer,
    List<Debt> debts,
    String message,
  ) async {
    try {
      // Generate PDF
      final pdfFile = await generatePaymentReminderPDF(customer, debts, message);
      if (pdfFile == null) return false;
      
      // Send via WhatsApp with PDF
      final phoneNumber = _formatPhoneNumber(customer.phone);
      final shortMessage = 'Payment reminder attached. Please check the PDF for details.';
      final encodedMessage = Uri.encodeComponent(shortMessage);
      final whatsappUrl = '$_whatsappBaseUrl$phoneNumber?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error sending payment reminder with PDF: $e');
      return false;
    }
  }

  /// Bulk send payment reminders
  static Future<Map<String, bool>> sendBulkReminders(
    List<Customer> customers,
    List<Debt> debts,
    String message,
  ) async {
    final results = <String, bool>{};
    
    for (final customer in customers) {
      final customerDebts = debts.where((d) => d.customerId == customer.id).toList();
      if (customerDebts.isNotEmpty) {
        final success = await sendWhatsAppReminder(customer, customerDebts, message);
        results[customer.id] = success;
      }
    }
    
    return results;
  }

  /// Format phone number for WhatsApp
  static String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present (assuming +1 for US)
    if (!cleaned.startsWith('1') && cleaned.length == 10) {
      cleaned = '1$cleaned';
    }
    
    return cleaned;
  }

  /// Format reminder message
  static String _formatReminderMessage(
    Customer customer,
    List<Debt> debts,
    String customMessage,
  ) {
    final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
    
    String message = 'Hello ${customer.name},\n\n';
    message += 'This is a payment reminder for your outstanding debts.\n\n';
    
    message += 'Total outstanding amount: \$${totalAmount.toStringAsFixed(2)}\n\n';
    
    if (customMessage.isNotEmpty) {
      message += '$customMessage\n\n';
    }
    
    message += 'Please contact us if you have any questions.\n';
    message += 'Thank you for your business!';
    
    return message;
  }

  /// Format date for PDF
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 