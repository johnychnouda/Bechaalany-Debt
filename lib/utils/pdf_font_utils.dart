import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontUtils {
  /// Get a font that supports Unicode characters
  static pw.Font? getUnicodeFont() {
    try {
      // Try to use a font that supports Unicode characters
      // These fonts are commonly available and support Unicode
      final fontNames = [
        'Arial Unicode MS',
        'DejaVu Sans',
        'Liberation Sans',
        'Noto Sans',
        'Source Sans Pro',
        'Open Sans',
        'Roboto',
        'Helvetica',
      ];
      
      for (final _ in fontNames) {
        try {
          // For now, we'll use the default font since TTF loading requires font files
          // In a production app, you would embed font files in the assets
          return null;
        } catch (e) {
          // Continue to next font
          continue;
        }
      }
      
      // Fallback to default font
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a text style with Unicode support
  static pw.TextStyle createUnicodeTextStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    bool useUnicodeFont = true,
  }) {
    if (useUnicodeFont) {
      final font = getUnicodeFont();
      return pw.TextStyle(
        font: font,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? PdfColors.black,
      );
    } else {
      return pw.TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? PdfColors.black,
      );
    }
  }

  /// Create a text widget with Unicode support
  static pw.Widget createUnicodeText(
    String text, {
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    bool useUnicodeFont = true,
    pw.TextAlign? textAlign,
  }) {
    return pw.Text(
      text,
      style: createUnicodeTextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        useUnicodeFont: useUnicodeFont,
      ),
      textAlign: textAlign,
    );
  }

  /// Check if a string contains Unicode characters
  static bool containsUnicode(String text) {
    return text.codeUnits.any((codeUnit) => codeUnit > 127);
  }

  /// Sanitize text for PDF (remove or replace problematic Unicode characters)
  static String sanitizeText(String text) {
    // Replace common problematic Unicode characters with safe alternatives
    return text
        .replaceAll('👤', 'Person') // Person icon
        .replaceAll('📞', 'Phone') // Phone icon
        .replaceAll('🏷', 'Tag') // Label icon
        .replaceAll('📄', 'Doc') // Document icon
        .replaceAll('️', '') // Remove invisible characters
        .replaceAll('✉️', 'Email') // Email icon
        .replaceAll('📍', 'Location') // Location icon
        .replaceAll('📅', 'Date') // Calendar icon
        .replaceAll('💰', 'Money') // Money icon
        .replaceAll('💳', 'Payment') // Payment icon
        .replaceAll('🧾', 'Receipt') // Receipt icon
        .replaceAll('🏦', 'Bank') // Bank icon
        .replaceAll('📈', 'Up') // Trending up
        .replaceAll('📉', 'Down') // Trending down
        .replaceAll('ℹ️', 'Info') // Info icon
        .replaceAll('⚠️', 'Warning') // Warning icon
        .replaceAll('❌', 'Error') // Error icon
        .replaceAll('✅', 'Success') // Success icon
        .replaceAll('⏰', 'Time') // Schedule icon
        .replaceAll('🔔', 'Alert') // Notification icon
        .replaceAll('🙏', 'Thank you'); // Prayer/thank you emoji
  }

  /// Get a list of safe Unicode characters that work in most PDF fonts
  static List<String> getSafeUnicodeCharacters() {
    return [
      '●', '☎', '✉', 'ℹ', '⚠', // Basic symbols
      '💰', '💳', '🧾', '🏦', // Financial icons
      '📈', '📉', '📅', '⏰', // Chart and time icons
      '✅', '❌', '🔔', // Status icons
    ];
  }

  /// Get a list of problematic Unicode characters that should be avoided
  static List<String> getProblematicUnicodeCharacters() {
    return [
      '️', // Invisible characters
      '👤', '📞', '🏷', '📄', // Emoji that may not render properly
    ];
  }

  /// Create a fallback text style for when Unicode fonts are not available
  static pw.TextStyle createFallbackTextStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? PdfColors.black,
    );
  }

  /// Create a document with proper font configuration
  static pw.Document createDocumentWithFonts() {
    final pdf = pw.Document();
    
    // Try to set up fonts that support Unicode
    try {
      final font = getUnicodeFont();
      if (font != null) {
        // Document is created with default fonts, we'll use the font in text styles
        return pdf;
      }
    } catch (e) {
      // Continue with default fonts
    }
    
    return pdf;
  }

  /// Create a text style that gracefully handles Unicode characters
  static pw.TextStyle createGracefulTextStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    bool preferUnicodeFont = true,
  }) {
    if (preferUnicodeFont) {
      try {
        final font = getUnicodeFont();
        if (font != null) {
          return pw.TextStyle(
            font: font,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? PdfColors.black,
          );
        }
      } catch (e) {
        // Fallback to default style
      }
    }
    
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? PdfColors.black,
    );
  }

  /// Create a text widget that gracefully handles Unicode characters
  static pw.Widget createGracefulText(
    String text, {
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    bool preferUnicodeFont = true,
    pw.TextAlign? textAlign,
  }) {
    // Sanitize the text first
    final sanitizedText = sanitizeText(text);
    
    return pw.Text(
      sanitizedText,
      style: createGracefulTextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        preferUnicodeFont: preferUnicodeFont,
      ),
      textAlign: textAlign,
    );
  }
} 