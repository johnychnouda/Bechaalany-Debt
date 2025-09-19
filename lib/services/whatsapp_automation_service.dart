import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';

class WhatsAppAutomationService {
  static Future<bool> sendSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    required List<PartialPayment> partialPayments,
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) async {
    try {
      // Format the settlement message
      String message = _formatSettlementMessage(
        customer: customer,
        settledDebts: settledDebts,
        partialPayments: partialPayments,
        customMessage: customMessage,
        settlementDate: settlementDate,
        actualPaymentAmount: actualPaymentAmount,
      );

      // Format phone number for WhatsApp
      String phoneNumber = _formatPhoneForWhatsApp(customer.phone);
      
      // Create WhatsApp URL
      String whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendPaymentReminderMessage({
    required Customer customer,
    required List<Debt> outstandingDebts,
    required String customMessage,
  }) async {
    try {
      // Format the payment reminder message
      String message = _formatPaymentReminderMessage(
        customer: customer,
        outstandingDebts: outstandingDebts,
        customMessage: customMessage,
      );

      // Format phone number for WhatsApp
      String phoneNumber = _formatPhoneForWhatsApp(customer.phone);
      
      // Create WhatsApp URL
      String whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static String _formatSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    required List<PartialPayment> partialPayments,
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) {
    StringBuffer message = StringBuffer();
    
    // Customer greeting
    message.writeln('Hello ${customer.name},');
    message.writeln();
    
    // Settlement details
    message.writeln('*Settlement Details:*');
    message.writeln('Date/time: ${_formatDateTime(settlementDate)}');
    
    if (actualPaymentAmount != null && actualPaymentAmount > 0) {
      message.writeln('Amount Paid: \$${actualPaymentAmount.toStringAsFixed(2)} ✅');
    }
    
    message.writeln();
    
    // Footer
    message.writeln('If you have any questions, please don\'t hesitate to contact us.');
    
    return message.toString();
  }

  static String _formatPaymentReminderMessage({
    required Customer customer,
    required List<Debt> outstandingDebts,
    required String customMessage,
  }) {
    StringBuffer message = StringBuffer();
    
    // Custom message
    message.writeln(customMessage);
    message.writeln();
    
    // Total amount owed
    if (outstandingDebts.isNotEmpty) {
      double totalAmount = 0;
      for (var debt in outstandingDebts) {
        totalAmount += debt.remainingAmount;
      }
      message.writeln('*Total Outstanding: \$${totalAmount.toStringAsFixed(2)}*');
      message.writeln();
    }
    
    // Request to contact for payment arrangements
    message.writeln('Please contact us to arrange payment at your earliest convenience.');
    
    return message.toString();
  }

  static String _formatPhoneForWhatsApp(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }
    
    // If it doesn't start with +, add it
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
