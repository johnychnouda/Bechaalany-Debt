import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared admin/owner contact info and launch helpers.
/// Single source of truth for WhatsApp and call.
class AdminContact {
  AdminContact._();

  static const String phone = '+96171862577';
  static const String whatsApp = '+96171862577';

  static const String _defaultWhatsAppMessage =
      'Hello, I would like to subscribe to the Bechaalany Debt App. Please let me know how to proceed.';

  static Future<void> openWhatsApp(
    BuildContext context, {
    String? message,
  }) async {
    final encoded = Uri.encodeComponent(message ?? _defaultWhatsAppMessage);
    final uri = Uri.parse('https://wa.me/$whatsApp?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        showError(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Error opening WhatsApp: $e');
      }
    }
  }

  static Future<void> call(BuildContext context) async {
    final uri = Uri.parse('tel:$phone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        showError(context, 'Could not open phone app');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Error opening phone: $e');
      }
    }
  }

  static void showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
