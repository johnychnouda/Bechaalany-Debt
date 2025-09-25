import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class WhatsAppAutomationService {
  static Future<bool> sendSettlementMessage({
    required Customer customer,
    required List<Debt> settledDebts,
    // Note: Partial payments are now handled as activities only
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) async {
    try {
      // Format the settlement message
      String message = _formatSettlementMessage(
        customer: customer,
        settledDebts: settledDebts,
        // Note: Partial payments are now handled as activities only
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
    // Note: Partial payments are now handled as activities only
    required String customMessage,
    required DateTime settlementDate,
    double? actualPaymentAmount,
  }) {
    StringBuffer message = StringBuffer();
    
    // 1. English greeting
    message.writeln('👋 Hello ${customer.name},');
    message.writeln();
    
    // 2. English settlement details
    message.writeln('✅ *Settlement Details:*');
    message.writeln('📅 Date/time: ${_formatDateTime(settlementDate)}');
    
    if (actualPaymentAmount != null && actualPaymentAmount > 0) {
      message.writeln('Amount Paid: ${actualPaymentAmount.toStringAsFixed(2)}\$ 💰');
    }
    
    message.writeln();
    
    // 3. English footer
    message.writeln('📞 If you have any questions, please don\'t hesitate to contact us.');
    message.writeln();
    
    // 4. Arabic greeting
    message.writeln('👋 مرحباً ${customer.name}،');
    message.writeln();
    
    // 5. Arabic settlement details
    message.writeln('✅ *تفاصيل التسوية:*');
    message.writeln('📅 التاريخ/الوقت: ${_formatDateTimeArabic(settlementDate)}');
    
    if (actualPaymentAmount != null && actualPaymentAmount > 0) {
      message.writeln('المبلغ المدفوع: \$${_convertToEasternArabicNumerals(actualPaymentAmount.toStringAsFixed(2))} 💰');
    }
    
    message.writeln();
    
    // 6. Arabic footer
    message.writeln('📞 إذا كان لديك أي أسئلة، فلا تتردد في التواصل معنا.');
    
    return message.toString();
  }

  static String _formatPaymentReminderMessage({
    required Customer customer,
    required List<Debt> outstandingDebts,
    required String customMessage,
  }) {
    StringBuffer message = StringBuffer();
    
    // 1. Custom message
    message.writeln(customMessage);
    message.writeln();
    
    // Total amount owed
    if (outstandingDebts.isNotEmpty) {
      double totalAmount = 0;
      for (var debt in outstandingDebts) {
        totalAmount += debt.remainingAmount;
      }
      
      // 2. English amount
      message.writeln('💳 *Total Outstanding: ${totalAmount.toStringAsFixed(2)}\$* 💰');
      
      // 3. English contact instruction
      message.writeln('📞💬 Please contact us to arrange payment at your earliest convenience.');
      message.writeln();
      
      // 4. Arabic amount
      message.writeln('💳 *المبلغ المستحق: \$${_convertToEasternArabicNumerals(totalAmount.toStringAsFixed(2))}* 💰');
      
      // 5. Arabic contact instruction
      message.writeln('📱💬 تواصل معنا لترتيب الدفع في أقرب وقت ممكن');
    }
    
    return message.toString();
  }

  static String _convertToEasternArabicNumerals(String number) {
    const Map<String, String> arabicNumerals = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    
    String result = number;
    arabicNumerals.forEach((western, arabic) {
      result = result.replaceAll(western, arabic);
    });
    
    return result;
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
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${date.day}/${date.month}/${date.year} at $displayHour:$minute $period';
  }

  static String _formatDateTimeArabic(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص'; // م for PM, ص for AM
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${_convertToEasternArabicNumerals(date.day.toString())}/${_convertToEasternArabicNumerals(date.month.toString())}/${_convertToEasternArabicNumerals(date.year.toString())} في ${_convertToEasternArabicNumerals(displayHour.toString())}:${_convertToEasternArabicNumerals(minute)} $period';
  }
}
