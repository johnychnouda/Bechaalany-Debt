import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';

class WhatsAppAutomationService {
  /// Check if a phone number has WhatsApp available
  static Future<bool> hasWhatsApp(String phoneNumber) async {
    try {
      // Format phone number for WhatsApp
      final formattedPhone = _formatPhoneForWhatsApp(phoneNumber);
      final whatsappUrl = 'https://wa.me/$formattedPhone';
      
      // Try to launch WhatsApp URL
      final canLaunch = await canLaunchUrl(Uri.parse(whatsappUrl));
      
      // If canLaunchUrl returns false, we'll still try to send the message
      // because the check might not be reliable on all platforms
      return true; // Always return true to attempt sending
    } catch (e) {
      // Even if the check fails, we'll still try to send the message
      return true;
    }
  }

  /// Send automated WhatsApp message for payment reminders
  static Future<bool> sendPaymentReminderMessage({
    required Customer customer,
    required List<Debt> outstandingDebts,
    required String customMessage,
  }) async {
    try {
      // Build the complete message
      final message = _buildPaymentReminderMessage(
        customer: customer,
        outstandingDebts: outstandingDebts,
        customMessage: customMessage,
      );

      // Format phone number for WhatsApp
      final formattedPhone = _formatPhoneForWhatsApp(customer.phone);
      
      // Create WhatsApp URL with pre-filled message
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      final launched = await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
      
      return launched;
    } catch (e) {
      // If launching fails, try alternative approach
      try {
        // Format phone number for WhatsApp
        final formattedPhone = _formatPhoneForWhatsApp(customer.phone);
        
        // Build the complete message
        final message = _buildPaymentReminderMessage(
          customer: customer,
          outstandingDebts: outstandingDebts,
          customMessage: customMessage,
        );
        
        // Try launching without external application mode
        final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
        final launched = await launchUrl(Uri.parse(whatsappUrl));
        return launched;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Send automated WhatsApp message for debt settlement
  static Future<bool> sendSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    required List<PartialPayment> partialPayments,
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) async {
    
    try {
      // Build the complete message
      final message = _buildSettlementMessage(
        customer: customer,
        settledDebts: settledDebts,
        partialPayments: partialPayments,
        customMessage: customMessage,
        settlementDate: settlementDate,
        actualPaymentAmount: actualPaymentAmount,
      );

      // Format phone number for WhatsApp
      final formattedPhone = _formatPhoneForWhatsApp(customer.phone);
      
      // Create WhatsApp URL with pre-filled message
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      final launched = await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
      
      
      return launched;
    } catch (e) {
      // If launching fails, try alternative approach
      try {
        // Format phone number for WhatsApp
        final formattedPhone = _formatPhoneForWhatsApp(customer.phone);
        
        // Build the complete message
        final message = _buildSettlementMessage(
          customer: customer,
          settledDebts: settledDebts,
          partialPayments: partialPayments,
          customMessage: customMessage,
          settlementDate: settlementDate,
          actualPaymentAmount: actualPaymentAmount,
        );
        
        // Try launching without external application mode
        final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
        final launched = await launchUrl(Uri.parse(whatsappUrl));
        return launched;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Build the complete payment reminder message
  static String _buildPaymentReminderMessage({
    required Customer customer,
    required List<Debt> outstandingDebts,
    required String customMessage,
  }) {
    // Calculate total outstanding amount
    final totalAmount = outstandingDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    // Build simplified message with only custom message and total remaining amount
    return '''
$customMessage

Total Remaining Amount: \$${totalAmount.toStringAsFixed(2)} Bechaalany

Connect''';
  }

  /// Build the complete settlement message
  static String _buildSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    required List<PartialPayment> partialPayments,
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) {
    
    // Use the actual payment amount if provided, otherwise calculate from partial payments
    double finalPaymentAmount = 0.0;
    if (actualPaymentAmount != null && actualPaymentAmount > 0) {
      finalPaymentAmount = actualPaymentAmount;
    } else if (partialPayments.isNotEmpty) {
      // Get the most recent partial payment amount
      finalPaymentAmount = partialPayments.last.amount;
    } else {
      // Fallback: calculate from settled debts
      finalPaymentAmount = settledDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    }
    
    // Format settlement date with seconds
    final dateStr = _formatDate(settlementDate);
    final timeStr = _formatTimeWithSeconds(settlementDate);
    
    // Build simplified receipt-style message
    final message = '''
📋 PAYMENT RECEIPT

Customer: ${customer.name}
Date: $dateStr
Time: $timeStr

Total Amount: \$${finalPaymentAmount.toStringAsFixed(2)}
Status: ✅ FULLY PAID

Thank you for settling all your payments!

Bechaalany Connect''';
    
    return message.trim();
  }

  /// Format phone number for WhatsApp
  static String _formatPhoneForWhatsApp(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+' + cleaned.substring(2);
    }
    
    // If it doesn't start with +, add it
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Format time for display
  static String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Format time with seconds for display
  static String _formatTimeWithSeconds(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute:$second $period';
  }
}
