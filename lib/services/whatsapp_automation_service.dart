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
      return canLaunch;
    } catch (e) {
      return false;
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
      // Check if customer has WhatsApp
      if (!await hasWhatsApp(customer.phone)) {
        throw Exception('Customer does not have WhatsApp available');
      }

      // Build the complete message
      final message = _buildSettlementMessage(
        customer: customer,
        settledDebts: settledDebts,
        partialPayments: partialPayments,
        customMessage: customMessage,
        settlementDate: settlementDate,
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
      return false;
    }
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
      return '• $cleanedDescription: \$${debt.amount.toStringAsFixed(2)} ✅';
    }).join('\n');
    
    // Build the complete message
    final message = '''
${customMessage.isNotEmpty ? customMessage : '🎉 Thank you for your business! 🎉'}

---
Products Settled:
$productsList

Settled on: $dateStr at $timeStr
Total Amount: \$${totalAmount.toStringAsFixed(2)}

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
