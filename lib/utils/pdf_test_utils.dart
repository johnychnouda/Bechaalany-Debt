import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_font_utils.dart';
import 'pdf_icon_utils.dart';

class PdfTestUtils {
  /// Test PDF generation with Unicode characters
  static Future<String> testUnicodePdfGeneration() async {
    try {
      final pdf = PdfFontUtils.createDocumentWithFonts();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Test header with Unicode
                PdfFontUtils.createGracefulText(
                  'Unicode Test PDF',
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
                pw.SizedBox(height: 20),
                
                // Test various Unicode characters
                PdfFontUtils.createGracefulText(
                  'Testing Unicode Support:',
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 10),
                
                // Test safe Unicode characters
                PdfFontUtils.createGracefulText('● Person icon'),
                PdfFontUtils.createGracefulText('☎ Phone icon'),
                PdfFontUtils.createGracefulText('✉ Email icon'),
                PdfFontUtils.createGracefulText('ℹ Info icon'),
                PdfFontUtils.createGracefulText('⚠ Warning icon'),
                PdfFontUtils.createGracefulText('💰 Money icon'),
                PdfFontUtils.createGracefulText('💳 Payment icon'),
                PdfFontUtils.createGracefulText('📅 Calendar icon'),
                PdfFontUtils.createGracefulText('✅ Success icon'),
                PdfFontUtils.createGracefulText('❌ Error icon'),
                
                pw.SizedBox(height: 20),
                
                // Test icon widgets
                PdfIconUtils.createIconTextRow(
                  icon: Icons.person,
                  text: 'Customer Name',
                  iconSize: 16,
                  spacing: 8,
                  useSymbol: false,
                ),
                pw.SizedBox(height: 8),
                PdfIconUtils.createIconTextRow(
                  icon: Icons.phone,
                  text: 'Phone Number',
                  iconSize: 16,
                  spacing: 8,
                  useSymbol: false,
                ),
                pw.SizedBox(height: 8),
                PdfIconUtils.createIconTextRow(
                  icon: Icons.label,
                  text: 'Customer ID',
                  iconSize: 16,
                  spacing: 8,
                  useSymbol: false,
                ),
                
                pw.SizedBox(height: 20),
                
                // Test text with potential Unicode issues
                PdfFontUtils.createGracefulText(
                  'Text with special characters: á é í ó ú ñ',
                  fontSize: 14,
                ),
                PdfFontUtils.createGracefulText(
                  'Text with numbers: 1234567890',
                  fontSize: 14,
                ),
                PdfFontUtils.createGracefulText(
                  'Text with symbols: @#$%^&*()',
                  fontSize: 14,
                ),
              ],
            );
          },
        ),
      );
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/unicode_test.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to generate test PDF: $e');
    }
  }

  /// Test PDF generation with customer data
  static Future<String> testCustomerPdfGeneration({
    required String customerName,
    required String customerPhone,
    required String customerId,
  }) async {
    try {
      final pdf = PdfFontUtils.createDocumentWithFonts();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                PdfFontUtils.createGracefulText(
                  'Customer Receipt',
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
                pw.SizedBox(height: 20),
                
                // Customer Information
                PdfFontUtils.createGracefulText(
                  'CUSTOMER INFORMATION',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: pw.Colors.grey,
                ),
                pw.SizedBox(height: 12),
                
                // Customer details with icons
                PdfIconUtils.createIconTextRow(
                  icon: Icons.person,
                  text: customerName,
                  iconSize: 16,
                  spacing: 8,
                  iconColor: PdfColor.fromInt(0xFF424242),
                  textStyle: PdfFontUtils.createGracefulTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  useSymbol: false,
                ),
                pw.SizedBox(height: 8),
                PdfIconUtils.createIconTextRow(
                  icon: Icons.phone,
                  text: customerPhone,
                  iconSize: 16,
                  spacing: 8,
                  iconColor: PdfColor.fromInt(0xFF424242),
                  textStyle: PdfFontUtils.createGracefulTextStyle(
                    fontSize: 13,
                    color: PdfColor.fromInt(0xFF424242),
                  ),
                  useSymbol: false,
                ),
                pw.SizedBox(height: 8),
                PdfIconUtils.createIconTextRow(
                  icon: Icons.label,
                  text: 'ID: $customerId',
                  iconSize: 16,
                  spacing: 8,
                  iconColor: PdfColor.fromInt(0xFF424242),
                  textStyle: PdfFontUtils.createGracefulTextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  useSymbol: false,
                ),
              ],
            );
          },
        ),
      );
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/customer_test.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to generate customer PDF: $e');
    }
  }

  /// Get a list of test Unicode characters
  static List<String> getTestUnicodeCharacters() {
    return [
      '●', '☎', '✉', 'ℹ', '⚠', // Basic symbols
      '💰', '💳', '🧾', '🏦', // Financial icons
      '📈', '📉', '📅', '⏰', // Chart and time icons
      '✅', '❌', '🔔', // Status icons
    ];
  }

  /// Test if a Unicode character is supported
  static bool testUnicodeCharacter(String character) {
    try {
      // Try to create a simple PDF with the character
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return PdfFontUtils.createGracefulText(
              'Test: $character',
              fontSize: 12,
            );
          },
        ),
      );
      
      // Try to save the PDF
      pdf.save();
      return true;
    } catch (e) {
      return false;
    }
  }
} 