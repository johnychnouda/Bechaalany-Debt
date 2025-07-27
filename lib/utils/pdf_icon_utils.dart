import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';

class PdfIconUtils {
  /// Convert Flutter icon to PDF-compatible text symbol
  static String getIconSymbol(IconData icon) {
    // Map common Flutter icons to Unicode symbols that work in PDFs
    if (icon == Icons.person) return '●'; // Person icon
    if (icon == Icons.phone) return '☎'; // Phone icon
    if (icon == Icons.label) return '🏷'; // Label icon
    if (icon == Icons.description) return '📄'; // Document icon
    if (icon == Icons.email) return '✉'; // Email icon
    if (icon == Icons.location_on) return '📍'; // Location icon
    if (icon == Icons.calendar_today) return '📅'; // Calendar icon
    if (icon == Icons.attach_money) return '💰'; // Money icon
    if (icon == Icons.payment) return '💳'; // Payment icon
    if (icon == Icons.receipt) return '🧾'; // Receipt icon
    if (icon == Icons.account_balance) return '🏦'; // Bank icon
    if (icon == Icons.trending_up) return '📈'; // Trending up
    if (icon == Icons.trending_down) return '📉'; // Trending down
    if (icon == Icons.info) return 'ℹ'; // Info icon
    if (icon == Icons.warning) return '⚠'; // Warning icon
    if (icon == Icons.error) return '❌'; // Error icon
    if (icon == Icons.check_circle) return '✅'; // Success icon
    if (icon == Icons.schedule) return '⏰'; // Schedule icon
    if (icon == Icons.notifications) return '🔔'; // Notification icon
    
    // Default fallback
    return '●';
  }

  /// Create a PDF-compatible icon widget
  static pw.Widget createIconWidget(IconData icon, {
    double size = 16,
    PdfColor? color,
    bool useSymbol = true,
  }) {
    if (useSymbol) {
      return pw.Container(
        width: size,
        height: size,
        child: pw.Center(
          child: pw.Text(
            getIconSymbol(icon),
            style: pw.TextStyle(
              fontSize: size * 0.8,
              color: color ?? PdfColors.black,
            ),
          ),
        ),
      );
    } else {
      // Create a simple geometric icon as fallback
      return _createGeometricIcon(icon, size, color);
    }
  }

  /// Create geometric icon as fallback when Unicode symbols don't work
  static pw.Widget _createGeometricIcon(IconData icon, double size, PdfColor? color) {
    final iconColor = color ?? PdfColors.black;
    
    if (icon == Icons.person) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          color: iconColor,
          shape: pw.BoxShape.circle,
        ),
                    child: pw.Center(
              child: pw.Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
      );
    }
    
    if (icon == Icons.phone) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          color: iconColor,
          shape: pw.BoxShape.circle,
        ),
                    child: pw.Center(
              child: pw.Container(
                width: size * 0.5,
                height: size * 0.3,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
            ),
      );
    }
    
    if (icon == Icons.label || icon == Icons.description) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          color: iconColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
                    child: pw.Center(
              child: pw.Container(
                width: size * 0.6,
                height: size * 0.4,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1)),
                ),
              ),
            ),
      );
    }
    
    // Default geometric icon
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: iconColor,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  /// Create a row with icon and text for PDF
  static pw.Widget createIconTextRow({
    required IconData icon,
    required String text,
    double iconSize = 16,
    double spacing = 8,
    PdfColor? iconColor,
    pw.TextStyle? textStyle,
    bool useSymbol = true,
  }) {
    return pw.Row(
      children: [
        createIconWidget(icon, size: iconSize, color: iconColor, useSymbol: useSymbol),
        pw.SizedBox(width: spacing),
        pw.Expanded(
          child: pw.Text(
            text,
            style: textStyle ?? pw.TextStyle(
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Get a list of supported icon symbols
  static Map<String, String> getSupportedSymbols() {
    return {
      'person': '●',
      'phone': '☎',
      'label': '🏷',
      'description': '📄',
      'email': '✉',
      'location': '📍',
      'calendar': '📅',
      'money': '💰',
      'payment': '💳',
      'receipt': '🧾',
      'bank': '🏦',
      'trending_up': '📈',
      'trending_down': '📉',
      'info': 'ℹ',
      'warning': '⚠',
      'error': '❌',
      'success': '✅',
      'schedule': '⏰',
      'notification': '🔔',
    };
  }
} 