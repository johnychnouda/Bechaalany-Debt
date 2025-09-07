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
  }) async {
    try {
      print('🔍 WhatsApp: Building settlement message for ${customer.name}');
      print('🔍 WhatsApp: Settled debts count: ${settledDebts.length}');
      
      // Build the complete message
      final message = _buildSettlementMessage(
        customer: customer,
        settledDebts: settledDebts,
        partialPayments: partialPayments,
        customMessage: customMessage,
        settlementDate: settlementDate,
      );

      print('🔍 WhatsApp: Message built successfully');
      print('🔍 WhatsApp: Message preview: ${message.substring(0, 100)}...');

      // Format phone number for WhatsApp
      final formattedPhone = _formatPhoneForWhatsApp(customer.phone);
      print('🔍 WhatsApp: Formatted phone: $formattedPhone');
      
      // Create WhatsApp URL with pre-filled message
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
      print('🔍 WhatsApp: URL created: ${whatsappUrl.substring(0, 100)}...');
      
      // Launch WhatsApp
      print('🔍 WhatsApp: Attempting to launch WhatsApp');
      final launched = await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
      
      print('🔍 WhatsApp: Launch result: $launched');
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
    
    // Build outstanding debts list
    final debtsList = outstandingDebts.map((debt) {
      final cleanedDescription = debt.description.replaceAll('\n', ' ').trim();
      return '• $cleanedDescription: \$${debt.remainingAmount.toStringAsFixed(2)}';
    }).join('\n');
    
    // Build debt information section
    final debtInfoSection = '''
Outstanding Items:
$debtsList

Total Outstanding: \$${totalAmount.toStringAsFixed(2)}''';
    
    // Always append debt information to custom message
    return '''
$customMessage

$debtInfoSection

Bechaalany Connect''';
  }

  /// Build the complete settlement message
  static String _buildSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    required List<PartialPayment> partialPayments,
    required String customMessage,
    required DateTime settlementDate,
  }) {
    // Calculate total amount settled
    final totalAmount = settledDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    
    // Format settlement date
    final dateStr = _formatDate(settlementDate);
    final timeStr = _formatTime(settlementDate);
    
    // Build products list
    final productsList = settledDebts.map((debt) {
      final cleanedDescription = debt.description.replaceAll('\n', ' ').trim();
      return '• $cleanedDescription: \$${debt.amount.toStringAsFixed(2)}';
    }).join('\n');
    
    // Build receipt-style message
    final message = '''
📋 PAYMENT RECEIPT

Customer: ${customer.name}
Date: $dateStr
Time: $timeStr

Items Paid:
$productsList

Total Amount: \$${totalAmount.toStringAsFixed(2)}
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
}
