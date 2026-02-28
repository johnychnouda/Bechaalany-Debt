import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../utils/pdf_font_utils.dart';
import 'business_name_service.dart';

/// Holds localized strings and formatters for PDF receipt (used when app locale is set).
class _ReceiptStrings {
  final String customerReceipt;
  final String generatedOn;
  final String customerInformation;
  final String accountSummary;
  final String totalOriginal;
  final String totalPaid;
  final String remaining;
  final String transactionHistory;
  final String generatedBy;
  final String receiptFor;
  final String idLabel;
  final String partialPayment;
  final String Function(int current, int total) pageOf;
  final String Function(DateTime) formatDateTime;

  _ReceiptStrings({
    required this.customerReceipt,
    required this.generatedOn,
    required this.customerInformation,
    required this.accountSummary,
    required this.totalOriginal,
    required this.totalPaid,
    required this.remaining,
    required this.transactionHistory,
    required this.generatedBy,
    required this.receiptFor,
    required this.idLabel,
    required this.partialPayment,
    required this.pageOf,
    required this.formatDateTime,
  });
}

/// Localized strings and formatters for the monthly activity report PDF.
class _MonthlyReportStrings {
  final String monthlyActivityReport;
  final String generatedOnLabel;
  final String Function(DateTime) formatGeneratedOn;
  final String reportSummary;
  final String totalRevenue;
  final String totalPaid;
  final String transactionsLabel;
  final String activityDetails;
  final String generatedBy;
  final String Function(int) getMonthName;
  final String Function(DateTime) formatActivityDate;
  final String Function(int, int) pageOf;
  final String newDebt;
  final String partialPayment;
  final String debtPaid;
  final String fullyPaid;
  final String activity;
  /// When true, format numbers with Arabic-Indic numerals in the PDF.
  final bool isArabic;
  final String Function(String) formatNumber;

  _MonthlyReportStrings({
    required this.monthlyActivityReport,
    required this.generatedOnLabel,
    required this.formatGeneratedOn,
    required this.reportSummary,
    required this.totalRevenue,
    required this.totalPaid,
    required this.transactionsLabel,
    required this.activityDetails,
    required this.generatedBy,
    required this.getMonthName,
    required this.formatActivityDate,
    required this.pageOf,
    required this.newDebt,
    required this.partialPayment,
    required this.debtPaid,
    required this.fullyPaid,
    required this.activity,
    this.isArabic = false,
    String Function(String)? formatNumber,
  }) : formatNumber = formatNumber ?? ((String s) => s);
}

class ReceiptSharingService {
  static const String _arabicIndicNumerals = '٠١٢٣٤٥٦٧٨٩';
  static String _toArabicNumerals(String s) {
    return s.replaceAllMapped(RegExp(r'\d'), (m) => _arabicIndicNumerals[int.parse(m.group(0)!)]);
  }

  /// True if [text] contains any character in the Arabic Unicode block (so it should render RTL in PDF).
  static bool _containsArabic(String text) {
    if (text.isEmpty) return false;
    for (final rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) return true;
    }
    return false;
  }

  static _MonthlyReportStrings _buildMonthlyReportStrings(AppLocalizations? l10n) {
    final isArabic = l10n?.localeName.startsWith('ar') ?? false;
    // Time and dates: keep numerals in English (user requested amounts/numbers always in English)
    String formatTime(DateTime dt) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      final period = hour >= 12 ? (l10n?.timePm ?? 'pm') : (l10n?.timeAm ?? 'am');
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:$minute:$second $period';
    }
    String formatGeneratedOn(DateTime date) {
      if (l10n == null) return 'Generated on ${_formatDateForPDFEn(date)}';
      final locale = l10n.localeName;
      final formatted = intl.DateFormat.yMMMd(locale).format(date);
      return '${l10n.generatedOn} $formatted';
    }
    String formatActivityDate(DateTime date) {
      if (l10n == null) return _formatActivityDateEn(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final activityDate = DateTime(date.year, date.month, date.day);
      final timeStr = formatTime(date);
      if (activityDate == today) return l10n.todayAtTime(timeStr);
      if (activityDate == yesterday) return l10n.yesterdayAtTime(timeStr);
      final dateStr = intl.DateFormat.yMMMd(l10n.localeName).format(date);
      return l10n.dateAtTime(dateStr, timeStr);
    }
    String getMonthName(int month) {
      if (l10n == null) return _getMonthNameEn(month);
      const enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      if (!isArabic) return enMonths[month - 1];
      const arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return arMonths[month - 1];
    }
    return _MonthlyReportStrings(
      monthlyActivityReport: l10n?.monthlyActivityReport ?? 'Monthly Activity Report',
      generatedOnLabel: l10n?.generatedOn ?? 'Generated on',
      formatGeneratedOn: formatGeneratedOn,
      reportSummary: l10n?.reportSummary ?? 'Summary',
      totalRevenue: l10n?.totalRevenue ?? 'Total Revenue',
      totalPaid: l10n?.totalPaid ?? 'Total Paid',
      transactionsLabel: l10n?.transactionsLabel ?? 'Transactions',
      activityDetails: l10n?.activityDetails ?? 'Activity Details',
      generatedBy: l10n?.generatedBy ?? 'Generated by',
      getMonthName: getMonthName,
      formatActivityDate: formatActivityDate,
      pageOf: (current, total) => l10n?.pageOf('$current', '$total') ?? 'Page $current of $total',
      newDebt: l10n?.newDebt ?? 'New Debt',
      partialPayment: l10n?.partialPayment ?? 'Partial Payment',
      debtPaid: l10n?.debtPaid ?? 'Debt Paid',
      fullyPaid: l10n?.fullyPaid ?? 'Fully Paid',
      activity: l10n?.activity ?? 'Activity',
      isArabic: isArabic,
      // Amounts and counts always in English numerals (user request)
      formatNumber: (String s) => s,
    );
  }

  static String _formatDateForPDFEn(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatActivityDateEn(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);
    final timeStr = _formatTime12HourEn(date);
    if (activityDate == today) return 'Today at $timeStr';
    if (activityDate == yesterday) return 'Yesterday at $timeStr';
    return '${_formatDateForPDFEn(date)} at $timeStr';
  }

  static String _formatTime12HourEn(DateTime date) {
    int hour = date.hour;
    String period = date.hour >= 12 ? 'pm' : 'am';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  static String _getMonthNameEn(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  static _ReceiptStrings _buildReceiptStrings(AppLocalizations l10n, bool isArabic) {
    String formatDateTime(DateTime dt) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      final period = hour >= 12 ? l10n.timePm : l10n.timeAm;
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      String s = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${displayHour.toString().padLeft(2, '0')}:$minute:$second $period';
      if (isArabic) s = _toArabicNumerals(s);
      return s;
    }
    return _ReceiptStrings(
      customerReceipt: l10n.customerReceipt,
      generatedOn: l10n.generatedOn,
      customerInformation: l10n.customerInformation.toUpperCase(),
      accountSummary: l10n.accountSummary,
      totalOriginal: l10n.totalOriginal,
      totalPaid: l10n.totalPaid,
      remaining: l10n.remaining,
      transactionHistory: l10n.transactionHistory.toUpperCase(),
      generatedBy: l10n.generatedBy,
      receiptFor: l10n.receiptFor,
      idLabel: l10n.idLabel,
      partialPayment: l10n.partialPayment,
      pageOf: (current, total) => l10n.pageOf('$current', '$total'),
      formatDateTime: formatDateTime,
    );
  }

  static const String _whatsappBaseUrl = 'https://wa.me/';
  
  static Future<String> _getEmailSubject() async {
    final businessName = await BusinessNameService().getBusinessName();
    return 'Your Debt Receipt from $businessName';
  }
  
  /// Share receipt via WhatsApp
  static Future<bool> shareReceiptViaWhatsApp(
    BuildContext context,
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        context: context,
        customer: customer,
        debts: customerDebts,
        // Note: Partial payments are now handled as activities only
        activities: activities,
        specificDate: specificDate,
        specificDebtId: specificDebtId,
      );
      
      if (pdfFile == null) return false;
      
      // Format phone number for WhatsApp
      final phoneNumber = _formatPhoneNumber(customer.phone);
      
      // Create WhatsApp message
      final message = await _createWhatsAppMessage(customer, specificDate);
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL with PDF attachment
      final whatsappUrl = '$_whatsappBaseUrl$phoneNumber?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        // Launch WhatsApp
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // The PDF will be available in the app's share sheet for manual attachment
        return launched;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Share receipt via email
  static Future<bool> shareReceiptViaEmail(
    BuildContext context,
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Generate PDF receipt
      final pdfFile = await generateReceiptPDF(
        context: context,
        customer: customer,
        debts: customerDebts,
        // Note: Partial payments are now handled as activities only
        activities: activities,
        specificDate: specificDate,
        specificDebtId: specificDebtId,
      );
      
      if (pdfFile == null) return false;
      
      // Create email body
      final emailBody = await _createEmailBody(customer, specificDate);
      final emailSubject = await _getEmailSubject();
      
      // Create email URI
      final emailUri = Uri(
        scheme: 'mailto',
        path: customer.email,
        queryParameters: {
          'subject': emailSubject,
          'body': emailBody,
        },
      );
      
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Share receipt via SMS (for customers without WhatsApp)
  static Future<bool> shareReceiptViaSMS(
    Customer customer,
    List<Debt> customerDebts,
    // Note: Partial payments are now handled as activities only
    List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  ) async {
    try {
      // Create SMS message
      final message = await _createSMSMessage(customer, specificDate);
      
      // Create SMS URI
      final smsUri = Uri(
        scheme: 'sms',
        path: customer.phone,
        queryParameters: {
          'body': message,
        },
      );
      
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate and save PDF receipt for a customer
  static Future<File?> generateReceiptPDF({
    required BuildContext context,
    required Customer customer,
    required List<Debt> debts,
    // Note: Partial payments are now handled as activities only
    required List<Activity> activities,
    DateTime? specificDate,
    String? specificDebtId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final receiptStrings = _buildReceiptStrings(l10n, isArabic);
    try {
      // Get business name for PDF generation
      final businessNameService = BusinessNameService();
      final businessName = await businessNameService.getBusinessName();
      
      // Validate business name for non-admin users
      if (businessName.isEmpty) {
        throw Exception('Business name is required. Please set your business name in Settings.');
      }
      
      // Filter debts to only include those relevant to the payment being viewed
      final relevantDebts = _getRelevantDebts(debts, activities, customer, specificDate, specificDebtId);
      final sortedDebts = List<Debt>.from(relevantDebts);
      sortedDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Use a font that supports Arabic when the app locale is Arabic, so Arabic text renders correctly in the PDF
      pw.ThemeData? pdfTheme;
      pw.Font? pdfFont;
      if (isArabic) {
        try {
          pdfFont = await PdfGoogleFonts.notoSansArabicRegular();
          pdfTheme = pw.ThemeData.withFont(base: pdfFont);
        } catch (_) {
          // If font fails to load, continue without theme (Arabic may show as boxes)
        }
      }
      
      // Create PDF document (with Arabic font theme when locale is Arabic)
      final pdf = pw.Document(theme: pdfTheme);
      
      // Build PDF content
      final allItems = <Map<String, dynamic>>[];
      
      // Add debts for this customer
      for (Debt debt in sortedDebts) {
        allItems.add({
          'type': 'debt',
          'description': debt.description,
          'amount': debt.amount,
          'date': debt.createdAt,
          'debt': debt,
        });
      }
      
      // Filter partial payments to only include those relevant to the debts being shown
      // Note: Partial payments are now handled as payment activities below
      
      // Filter payment activities to only include those relevant to the debts being shown
      final relevantPaymentActivities = _getRelevantPaymentActivities(activities, sortedDebts, customer, specificDate, specificDebtId);
      
      // Add relevant payment activities (these are the actual partial payments shown in Activity History)
      for (Activity activity in relevantPaymentActivities) {
        // Only add payment activities that have a payment amount
        if (activity.paymentAmount != null && activity.paymentAmount! > 0) {
          allItems.add({
            'type': 'payment_activity',
            'description': receiptStrings.partialPayment,
            'amount': activity.paymentAmount!,
            'date': activity.date,
            'activity': activity,
          });
        }
      }
      
      allItems.sort((a, b) => b['date'].compareTo(a['date']));
      
      // Calculate total paid amount from relevant payment activities
      double totalPaidAmount = relevantPaymentActivities.fold<double>(0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
      
      // Calculate total original amount from relevant debts
      double totalOriginalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
      
      final sanitizedCustomerName = PdfFontUtils.sanitizeText(customer.name);
      final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(customer.phone);
      final sanitizedCustomerId = PdfFontUtils.sanitizeText(customer.id);
      
      // Pagination constants - items per page
      const int itemsPerFirstPage = 10; // Items that fit on first page (with header, customer info, summary, footer)
      const int itemsPerPage = 15; // Items that fit on subsequent pages (with header, footer)
      
      // Calculate total pages needed
      int totalPages;
      if (allItems.length <= itemsPerFirstPage) {
        totalPages = 1;
      } else {
        final remainingItems = allItems.length - itemsPerFirstPage;
        final additionalPages = (remainingItems / itemsPerPage).ceil();
        totalPages = 1 + additionalPages;
      }
      
      final remainingAmount = totalOriginalAmount - totalPaidAmount;
      
      // Generate first page with header, customer info, and summary
      final firstPageItems = allItems.take(itemsPerFirstPage).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return buildPDFPage(
              pageItems: firstPageItems,
              allItems: allItems,
              remainingAmount: remainingAmount,
              totalPaidAmount: totalPaidAmount,
              totalOriginalAmount: totalOriginalAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              specificDate: specificDate,
              pageIndex: 0,
              totalPages: totalPages,
              isFirstPage: true,
              showSummary: totalPages == 1, // Show summary on first page only if it's the only page
              businessName: businessName,
              receiptStrings: receiptStrings,
              pdfFont: pdfFont,
            );
          },
        ),
      );
      
      // Generate additional pages if needed
      if (allItems.length > itemsPerFirstPage) {
        int currentIndex = itemsPerFirstPage;
        
        // Calculate how many additional pages we need
        final remainingItems = allItems.length - itemsPerFirstPage;
        final additionalPagesNeeded = (remainingItems / itemsPerPage).ceil();
        
        // Create exactly the number of additional pages needed
        for (int i = 0; i < additionalPagesNeeded && currentIndex < allItems.length; i++) {
          final pageItems = allItems.skip(currentIndex).take(itemsPerPage).toList();
          
          // Only create a page if there are items to show
          if (pageItems.isEmpty) {
            break;
          }
          
          // pageIndex for additional pages: i + 1 (since page 0 is the first page)
          final pageIndex = i + 1;
          final isLastPage = (currentIndex + pageItems.length >= allItems.length);
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return buildPDFPage(
                  pageItems: pageItems,
                  allItems: allItems,
                  remainingAmount: remainingAmount,
                  totalPaidAmount: totalPaidAmount,
                  totalOriginalAmount: totalOriginalAmount,
                  sanitizedCustomerName: sanitizedCustomerName,
                  sanitizedCustomerPhone: sanitizedCustomerPhone,
                  sanitizedCustomerId: sanitizedCustomerId,
                  specificDate: specificDate,
                  pageIndex: pageIndex,
                  totalPages: totalPages,
                  isFirstPage: false,
                  showSummary: isLastPage, // Show summary only on the last page
                  businessName: businessName,
                  receiptStrings: receiptStrings,
                  pdfFont: pdfFont,
                );
              },
            ),
          );
          
          currentIndex += pageItems.length;
        }
      }
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = '${customer.name}_Receipt_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_ID${customer.id}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verify file was created
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Build PDF page content
  static pw.Widget buildPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required List<Map<String, dynamic>> allItems,
    required double remainingAmount,
    required double totalPaidAmount,
    required double totalOriginalAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    required String businessName,
    required _ReceiptStrings receiptStrings,
    pw.Font? pdfFont,
    DateTime? specificDate,
    int pageIndex = 0,
    int totalPages = 1,
    bool isFirstPage = true,
    bool showSummary = true,
  }) {
    // When Arabic, use Noto Sans Arabic as primary and Helvetica as fallback so both Arabic and Latin (e.g. "Bechaalany Connect", "USD", "Test") render correctly
    pw.TextStyle withPdfFont(pw.TextStyle s) {
      if (pdfFont == null) return s;
      return s.copyWith(
        font: pdfFont,
        fontNormal: pdfFont,
        fontBold: pdfFont,
        fontItalic: pdfFont,
        fontBoldItalic: pdfFont,
        fontFallback: [pw.Font.helvetica()],
      );
    }
    // Only Arabic text (labels/localized strings) should render RTL; page layout and amounts stay LTR
    final useRtl = pdfFont != null;
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: PdfColors.white,
      child: pw.Column(
        children: [
          // Ultra Compact Header (only on first page)
          if (isFirstPage)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // App name
                  pw.Text(
                    businessName,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    )),
                  ),
                  pw.SizedBox(height: 4),
                  
                  // Main title (Arabic when locale is Arabic)
                  pw.Text(
                    receiptStrings.customerReceipt,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                  pw.SizedBox(height: 1),
                  
                  // Generation date (Arabic label + date)
                  pw.Text(
                    '${receiptStrings.generatedOn} ${receiptStrings.formatDateTime(DateTime.now())}',
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF94A3B8),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                ],
              ),
            ),
          
          // Compact Customer Information Section (only on first page)
          if (isFirstPage)
            pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    receiptStrings.customerInformation,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                      letterSpacing: 0.3,
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    sanitizedCustomerName,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    )),
                    textDirection: (useRtl && _containsArabic(sanitizedCustomerName)) ? pw.TextDirection.rtl : null,
                  ),
                  if (sanitizedCustomerPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      sanitizedCustomerPhone,
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColor.fromInt(0xFF475569),
                      )),
                    ),
                  ],
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${receiptStrings.idLabel}: $sanitizedCustomerId',
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColor.fromInt(0xFF64748B),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                ],
              ),
            ),
          ),
          
          // Clean Summary Section (only on first page)
          if (isFirstPage)
            pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Column(
              children: [
                // Summary title (Arabic when locale is Arabic)
                pw.Text(
                  receiptStrings.accountSummary,
                  style: withPdfFont(pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  )),
                  textDirection: useRtl ? pw.TextDirection.rtl : null,
                ),
                pw.SizedBox(height: 8),
                
                // Clean summary layout - no cards, just clean rows
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          receiptStrings.totalOriginal,
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          )),
                          textDirection: useRtl ? pw.TextDirection.rtl : null,
                        ),
                        pw.Text(
                          _formatCurrency(totalOriginalAmount),
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF64748B),
                          )),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          receiptStrings.totalPaid,
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          )),
                          textDirection: useRtl ? pw.TextDirection.rtl : null,
                        ),
                        pw.Text(
                          _formatCurrency(totalPaidAmount),
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF10B981),
                          )),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          receiptStrings.remaining,
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF64748B),
                          )),
                          textDirection: useRtl ? pw.TextDirection.rtl : null,
                        ),
                        pw.Text(
                          _formatCurrency(remainingAmount),
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFFEF4444),
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Date filter info if applicable (only on first page)
          if (specificDate != null && isFirstPage) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEFF6FF),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFF3B82F6),
                    width: 1,
                  ),
                ),
                child: pw.Text(
                  '${receiptStrings.receiptFor}: ${receiptStrings.formatDateTime(specificDate)}',
                  style: withPdfFont(pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF3B82F6),
                  )),
                  textDirection: useRtl ? pw.TextDirection.rtl : null,
                ),
              ),
            ),
          ],
          
          // Transactions Header (only on first page)
          if (isFirstPage)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: pw.Text(
                receiptStrings.transactionHistory,
                style: withPdfFont(pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E293B),
                  letterSpacing: -0.3,
                )),
                textDirection: useRtl ? pw.TextDirection.rtl : null,
              ),
            ),
          
          // All transactions (debts and payments) with modern design
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.fromLTRB(32, isFirstPage ? 0 : 24, 32, 0),
              child: pw.ListView.builder(
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final item = pageItems[index];
                  final isPayment = item['type'] == 'partial_payment' || item['type'] == 'payment_activity';
                  
                  PdfColor backgroundColor;
                  PdfColor borderColor;
                  PdfColor textColor;
                  PdfColor amountColor;
                  
                  if (isPayment) {
                    backgroundColor = PdfColor.fromInt(0xFFFFFBEB); // Light orange for payments
                    borderColor = PdfColor.fromInt(0xFFF59E0B); // Orange border
                    textColor = PdfColor.fromInt(0xFF92400E); // Dark orange text
                    amountColor = PdfColor.fromInt(0xFFF59E0B); // Orange amount
                  } else {
                    backgroundColor = PdfColor.fromInt(0xFFF0F4FF); // Light blue for debts
                    borderColor = PdfColor.fromInt(0xFF6366F1); // Blue border
                    textColor = PdfColor.fromInt(0xFF1E40AF); // Dark blue text
                    amountColor = PdfColor.fromInt(0xFF6366F1); // Blue amount
                  }
                  
                  return pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: backgroundColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        // Status indicator dot
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: borderColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                item['description'],
                                style: withPdfFont(pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                )),
                                textDirection: (useRtl && _containsArabic(item['description'] as String)) ? pw.TextDirection.rtl : null,
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                receiptStrings.formatDateTime(item['date']),
                                style: withPdfFont(pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColor.fromInt(0xFF64748B),
                                )),
                                textDirection: useRtl ? pw.TextDirection.rtl : null,
                              ),
                            ],
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(item['amount']),
                          style: withPdfFont(pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: amountColor,
                          )),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Clean Footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      businessName,
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromInt(0xFF94A3B8),
                        letterSpacing: 0.3,
                      )),
                    ),
                    pw.Text(
                      ' ${receiptStrings.generatedBy}',
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromInt(0xFF94A3B8),
                        letterSpacing: 0.3,
                      )),
                      textDirection: useRtl ? pw.TextDirection.rtl : null,
                    ),
                  ],
                ),
                // Page number at bottom (if multiple pages)
                if (totalPages > 1) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    receiptStrings.pageOf(pageIndex + 1, totalPages),
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                      letterSpacing: 0.3,
                    )),
                    textAlign: pw.TextAlign.center,
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Create WhatsApp message
  static Future<String> _createWhatsAppMessage(Customer customer, DateTime? specificDate) async {
    final businessName = await BusinessNameService().getBusinessName();
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Hi ${customer.name}! 

Here's your debt receipt$dateInfo from $businessName.

I've attached the detailed PDF receipt showing all your transactions and current balance.

If you have any questions about your account, please don't hesitate to contact us.

Thank you for your business! 💼✨

Best regards,
$businessName Team''';
  }
  
  /// Create email body
  static Future<String> _createEmailBody(Customer customer, DateTime? specificDate) async {
    final businessName = await BusinessNameService().getBusinessName();
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Dear ${customer.name},

Thank you for requesting your debt receipt$dateInfo from $businessName.

Please find attached your detailed receipt in PDF format, which includes:
• All debt transactions
• Payment history
• Current balance status
• Account summary

If you have any questions about your account or need clarification on any transactions, please don't hesitate to reach out to us.

We appreciate your business and look forward to continuing to serve you.

Best regards,
$businessName Team

---
This is an automated receipt. Please contact us for any account-related inquiries.''';
  }
  
  /// Create SMS message
  static Future<String> _createSMSMessage(Customer customer, DateTime? specificDate) async {
    final businessName = await BusinessNameService().getBusinessName();
    final dateInfo = specificDate != null 
        ? ' for ${_formatDate(specificDate)}'
        : '';
    
    return '''Hi ${customer.name}! Your debt receipt$dateInfo from $businessName has been generated. Check your email or WhatsApp for the detailed PDF. Thank you for your business! 💼✨''';
  }
  
  /// Format phone number for WhatsApp
  static String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Ensure it starts with country code
    if (digits.startsWith('0')) {
      digits = '961${digits.substring(1)}'; // Lebanon country code
    } else if (!digits.startsWith('961')) {
      digits = '961$digits'; // Add Lebanon country code if missing
    }
    
    return digits;
  }
  
  /// Format currency
  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} USD';
  }
  
  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Format date and time for display
  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final second = dateTime.second;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} at ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';
  }
  
  /// Get relevant debts based on payment context
  static List<Debt> _getRelevantDebts(
    List<Debt> allCustomerDebts,
    List<Activity> activities,
    Customer customer,
    DateTime? specificDate,
    String? specificDebtId,
  ) {
    // If a specific debt ID is provided, show all debts until partial payment
    if (specificDebtId != null) {
      // Check if any partial payments have been made
      final hasPartialPayments = allCustomerDebts.any((debt) => debt.paidAmount > 0);
      
      if (hasPartialPayments) {
        // If partial payments exist, show only the specific debt
        return allCustomerDebts.where((debt) {
          return debt.id == specificDebtId;
        }).toList();
      } else {
        // If no partial payments, show all debts (accumulate all new debts)
        return allCustomerDebts.where((debt) => debt.paidAmount == 0).toList();
      }
    }
    
    // If a specific date is provided, filter debts to only include those relevant to that date
    if (specificDate != null) {
      final targetDate = specificDate;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return allCustomerDebts.where((debt) {
        // Include debts created within 1 hour of the specific debt time
        return debt.createdAt.isAfter(startTime) && debt.createdAt.isBefore(endTime);
      }).toList();
    }
    
    // If no specific date or debt ID, show only active debts (not fully paid)
    // This excludes old debts that were already paid off
    return allCustomerDebts.where((debt) => !debt.isFullyPaid).toList();
  }
  
  /// Get relevant partial payments based on the debts being shown
  // Note: Partial payments are now handled as activities only
  
  /// Get relevant payment activities based on the debts being shown
  static List<Activity> _getRelevantPaymentActivities(
    List<Activity> allActivities,
    List<Debt> relevantDebts,
    Customer customer,
    DateTime? specificDate,
    String? specificDebtId,
  ) {
    // Filter to only payment activities for this customer
    final customerPaymentActivities = allActivities
        .where((activity) => 
            activity.type == ActivityType.payment && 
            activity.customerId == customer.id)
        .toList();
    
    // If a specific debt ID is provided, only include activities for that debt
    if (specificDebtId != null) {
      return customerPaymentActivities.where((activity) => activity.debtId == specificDebtId).toList();
    }
    
    // If a specific date is provided, only include activities within 1 hour of that date
    if (specificDate != null) {
      final targetDate = specificDate;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return customerPaymentActivities.where((activity) {
        return activity.date.isAfter(startTime) && activity.date.isBefore(endTime);
      }).toList();
    }
    
    // If no specific filters, include only payment activities for the active debts being shown
    // This excludes payments for old debts that were already paid off
    final relevantDebtIds = relevantDebts.map((debt) => debt.id).toSet();
    return customerPaymentActivities.where((activity) {
      // If activity has a specific debt ID, check if it matches
      if (activity.debtId != null) {
        return relevantDebtIds.contains(activity.debtId);
      }
      // If activity doesn't have a specific debt ID (cross-debt payment),
      // check if the activity date is after any of the relevant debts
      return relevantDebts.any((debt) => activity.date.isAfter(debt.createdAt));
    }).toList();
  }

  /// Generate monthly activity PDF report.
  /// Pass [l10n] to render the PDF in the app's current locale (e.g. Arabic).
  static Future<File?> generateMonthlyActivityPDF({
    required List<Activity> monthlyActivities,
    required List<Debt> monthlyDebts,
    required double totalRevenue,
    required double totalPaid,
    required DateTime monthDate,
    AppLocalizations? l10n,
  }) async {
    try {
      final reportStrings = _buildMonthlyReportStrings(l10n);
      // Get business name for PDF generation
      final businessNameService = BusinessNameService();
      final businessName = await businessNameService.getBusinessName();
      
      // Validate business name for non-admin users
      if (businessName.isEmpty) {
        throw Exception('Business name is required. Please set your business name in Settings.');
      }
      
      // Use a font that supports Arabic when the report is in Arabic, so Arabic text renders in the PDF
      pw.ThemeData? pdfTheme;
      pw.Font? pdfFont;
      if (reportStrings.isArabic) {
        try {
          pdfFont = await PdfGoogleFonts.notoSansArabicRegular();
          pdfTheme = pw.ThemeData.withFont(base: pdfFont);
        } catch (_) {
          // If font fails to load, continue without theme (Arabic may show as boxes)
        }
      }
      
      // Create PDF document (with Arabic font theme when locale is Arabic)
      final pdf = pw.Document(theme: pdfTheme);
      
      // Build PDF content
      final allItems = <Map<String, dynamic>>[];
      
      // Add all activities for the month - ensure ALL activities are included
      for (Activity activity in monthlyActivities) {
        try {
          // Calculate amount - use paymentAmount if available, otherwise amount, default to 0.0
          final amount = activity.paymentAmount ?? activity.amount ?? 0.0;
          
          // Include ALL activities regardless of amount (some might have 0 amount)
          allItems.add({
            'type': activity.type.toString().split('.').last,
            'description': activity.description ?? '',
            'amount': amount,
            'date': activity.date,
            'activity': activity,
            'customerName': activity.customerName ?? '',
            'customerId': activity.customerId ?? '',
          });
        } catch (e) {
          // If there's an error adding an activity, try to add it with minimal data
          // This ensures we don't lose any transactions
          try {
            allItems.add({
              'type': 'activity',
              'description': activity.description ?? 'Activity',
              'amount': 0.0,
              'date': activity.date,
              'activity': activity,
              'customerName': activity.customerName ?? '',
              'customerId': activity.customerId ?? '',
            });
          } catch (_) {
            // Skip this activity only if we can't add it at all
            // This should rarely happen
          }
        }
      }
      
      // Sort by date (newest first)
      allItems.sort((a, b) => b['date'].compareTo(a['date']));
      
      // Verify we have the correct number of items
      // If not, it means some activities couldn't be added
      // The PDF will still generate with available items
      
      final monthName = reportStrings.getMonthName(monthDate.month);
      final year = monthDate.year;
      
      // Pagination constants - items per page (adjusted based on actual fit)
      const int itemsPerFirstPage = 10; // Items that fit on first page (with header, summary, footer)
      const int itemsPerPage = 14; // Items that fit on subsequent pages (with header, footer)
      
      // Calculate total pages needed
      int totalPages;
      if (allItems.length <= itemsPerFirstPage) {
        totalPages = 1;
      } else {
        final remainingItems = allItems.length - itemsPerFirstPage;
        // Calculate how many additional pages we need for remaining items
        final additionalPages = (remainingItems / itemsPerPage).ceil();
        totalPages = 1 + additionalPages;
      }
      
      // Generate first page with summary
      final firstPageItems = allItems.take(itemsPerFirstPage).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return buildMonthlyActivityPDFPage(
              pageItems: firstPageItems,
              totalRevenue: totalRevenue,
              totalPaid: totalPaid,
              monthName: monthName,
              year: year,
              totalTransactions: allItems.length, // Use actual allItems length, not monthlyActivities
              pageIndex: 0,
              totalPages: totalPages,
              isFirstPage: true,
              showSummary: true,
              businessName: businessName,
              reportStrings: reportStrings,
              pdfFont: pdfFont,
            );
          },
        ),
      );
      
      // Generate additional pages if needed
      if (allItems.length > itemsPerFirstPage) {
        int currentIndex = itemsPerFirstPage;
        
        // Calculate how many additional pages we need
        final remainingItems = allItems.length - itemsPerFirstPage;
        final additionalPagesNeeded = (remainingItems / itemsPerPage).ceil();
        
        // Create exactly the number of additional pages needed
        for (int i = 0; i < additionalPagesNeeded && currentIndex < allItems.length; i++) {
          final pageItems = allItems.skip(currentIndex).take(itemsPerPage).toList();
          
          // Only create a page if there are items to show
          if (pageItems.isEmpty) {
            break;
          }
          
          // pageIndex for additional pages: i + 1 (since page 0 is the first page)
          final pageIndex = i + 1;
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return buildMonthlyActivityPDFPage(
                  pageItems: pageItems,
                  totalRevenue: totalRevenue,
                  totalPaid: totalPaid,
                  monthName: monthName,
                  year: year,
                  totalTransactions: allItems.length, // Use actual allItems length
                  pageIndex: pageIndex,
                  totalPages: totalPages,
                  isFirstPage: false,
                  showSummary: false,
                  businessName: businessName,
                  reportStrings: reportStrings,
                  pdfFont: pdfFont,
                );
              },
            ),
          );
          
          currentIndex += pageItems.length;
        }
      }
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'Monthly_Activity_Report_${monthName}_${year}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verify file was created
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Build monthly activity PDF page content
  static pw.Widget buildMonthlyActivityPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required double totalRevenue,
    required double totalPaid,
    required String monthName,
    required int year,
    required int totalTransactions,
    required String businessName,
    required _MonthlyReportStrings reportStrings,
    pw.Font? pdfFont,
    int pageIndex = 0,
    int totalPages = 1,
    bool isFirstPage = true,
    bool showSummary = true,
  }) {
    // When Arabic, use Noto Sans Arabic as primary and Helvetica as fallback for Latin (e.g. business name, numbers)
    pw.TextStyle withPdfFont(pw.TextStyle s) {
      if (pdfFont == null) return s;
      return s.copyWith(
        font: pdfFont,
        fontNormal: pdfFont,
        fontBold: pdfFont,
        fontItalic: pdfFont,
        fontBoldItalic: pdfFont,
        fontFallback: [pw.Font.helvetica()],
      );
    }
    final useRtl = pdfFont != null;
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: PdfColors.white,
      child: pw.Column(
        children: [
          // Ultra Compact Header (only on first page)
          if (isFirstPage)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // App name (often English; keep LTR)
                  pw.Text(
                    businessName,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    )),
                  ),
                  pw.SizedBox(height: 4),
                  
                  // Main title (Arabic when locale is Arabic → RTL)
                  pw.Text(
                    reportStrings.monthlyActivityReport,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                  pw.SizedBox(height: 2),
                  
                  // Month and year (Arabic month name when Arabic → RTL)
                  pw.Text(
                    '$monthName $year',
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColor.fromInt(0xFF475569),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                  pw.SizedBox(height: 1),
                  // Generation date (only on first page) (Arabic label → RTL)
                  pw.Text(
                    reportStrings.formatGeneratedOn(DateTime.now()),
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF94A3B8),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                ],
              ),
            ),
          
          // Clean Summary Section (only on first page)
          if (showSummary)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Column(
                children: [
                  // Summary title (Arabic → RTL)
                  pw.Text(
                    reportStrings.reportSummary,
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    )),
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                  pw.SizedBox(height: 8),
                  
                  // Clean summary layout - labels RTL when Arabic; amounts always English numerals, LTR
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            reportStrings.totalRevenue,
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            )),
                            textDirection: useRtl ? pw.TextDirection.rtl : null,
                          ),
                          pw.Text(
                            '${totalRevenue.toStringAsFixed(2)}\$',
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF10B981),
                            )),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            reportStrings.totalPaid,
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            )),
                            textDirection: useRtl ? pw.TextDirection.rtl : null,
                          ),
                          pw.Text(
                            '${totalPaid.toStringAsFixed(2)}\$',
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF3B82F6),
                            )),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            reportStrings.transactionsLabel,
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF64748B),
                            )),
                            textDirection: useRtl ? pw.TextDirection.rtl : null,
                          ),
                          pw.Text(
                            '$totalTransactions',
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF6366F1),
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Activities Section with clean design
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Activity Details header (only on first page) (Arabic → RTL)
                  if (isFirstPage) ...[
                    pw.Text(
                      reportStrings.activityDetails,
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1E293B),
                        letterSpacing: -0.3,
                      )),
                      textDirection: useRtl ? pw.TextDirection.rtl : null,
                    ),
                    pw.SizedBox(height: 16),
                  ],
                  pw.Expanded(
                    child: pw.ListView.builder(
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        final item = pageItems[index];
                        return _buildModernActivityPDFItem(item, reportStrings, pdfFont, useRtl);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Clean Footer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Split so Arabic (generatedBy) uses RTL on the right, English (businessName) LTR on the left
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      businessName,
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 11,
                        color: PdfColor.fromInt(0xFF94A3B8),
                        letterSpacing: 0.3,
                      )),
                      textDirection: pw.TextDirection.ltr,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      reportStrings.generatedBy,
                      style: withPdfFont(pw.TextStyle(
                        fontSize: 11,
                        color: PdfColor.fromInt(0xFF94A3B8),
                        letterSpacing: 0.3,
                      )),
                      textDirection: useRtl ? pw.TextDirection.rtl : null,
                    ),
                  ],
                ),
                // Page number at bottom (if multiple pages)
                if (totalPages > 1) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    reportStrings.pageOf(pageIndex + 1, totalPages),
                    style: withPdfFont(pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                      letterSpacing: 0.3,
                    )),
                    textAlign: pw.TextAlign.center,
                    textDirection: useRtl ? pw.TextDirection.rtl : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern summary card for PDF
  static pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact summary card for PDF
  static pw.Widget _buildCompactSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer summary card for PDF
  static pw.Widget _buildCustomerSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build description as PDF widgets: product name (RTL if Arabic) then " x N" in LTR so "x 2" appears on the right of the product.
  static List<pw.Widget> _buildDescriptionWithQuantityPdf(String description, bool useRtl, pw.TextStyle Function(pw.TextStyle) withPdfFont) {
    const quantitySeparator = ' x ';
    final textStyle = withPdfFont(pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromInt(0xFF1E293B),
    ));
    if (description.contains(quantitySeparator)) {
      final parts = description.split(quantitySeparator);
      if (parts.length >= 2) {
        final quantityPart = parts.last.trim();
        final isNumeric = double.tryParse(quantityPart.replaceAll(',', '.')) != null;
        if (isNumeric) {
          final productName = parts.sublist(0, parts.length - 1).join(quantitySeparator).trim();
          return [
            pw.Text(
              productName,
              style: textStyle,
              textDirection: (useRtl && _containsArabic(productName)) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            ),
            pw.Text(
              '$quantitySeparator$quantityPart',
              style: textStyle,
              textDirection: pw.TextDirection.ltr,
            ),
          ];
        }
      }
    }
    return [
      pw.Text(
        description,
        style: textStyle,
        textDirection: (useRtl && _containsArabic(description)) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    ];
  }

  /// Build modern activity item for PDF
  static pw.Widget _buildModernActivityPDFItem(Map<String, dynamic> item, _MonthlyReportStrings reportStrings, pw.Font? pdfFont, bool useRtl) {
    pw.TextStyle withPdfFont(pw.TextStyle s) {
      if (pdfFont == null) return s;
      return s.copyWith(
        font: pdfFont,
        fontNormal: pdfFont,
        fontBold: pdfFont,
        fontItalic: pdfFont,
        fontBoldItalic: pdfFont,
        fontFallback: [pw.Font.helvetica()],
      );
    }
    final activity = item['activity'] as Activity;
    final amount = item['amount'] as double;
    final date = item['date'] as DateTime;
    final customerName = item['customerName'] as String;
    String description = item['description'] as String;
    // For new debt, activity.description is "$amount product" (e.g. "$20.00 جينز"); we show amount in the column, so strip it from text to avoid duplicate
    if (activity.type == ActivityType.newDebt && description.isNotEmpty) {
      final amountPrefix = RegExp(r'^\$\d+(\.\d+)?\s+');
      if (amountPrefix.hasMatch(description)) {
        description = description.replaceFirst(amountPrefix, '').trim();
      }
    }
    
    PdfColor statusColor;
    String statusText;
    PdfColor backgroundColor;
    
    switch (activity.type) {
      case ActivityType.payment:
        if (activity.isPaymentCompleted) {
          if (description.startsWith('Fully paid:') || description.startsWith('مدفوع بالكامل:')) {
            statusColor = PdfColor.fromInt(0xFF10B981);
            statusText = reportStrings.fullyPaid;
            backgroundColor = PdfColor.fromInt(0xFFECFDF5);
          } else {
            statusColor = PdfColor.fromInt(0xFF3B82F6);
            statusText = reportStrings.debtPaid;
            backgroundColor = PdfColor.fromInt(0xFFEFF6FF);
          }
        } else {
          statusColor = PdfColor.fromInt(0xFFF59E0B);
          statusText = reportStrings.partialPayment;
          backgroundColor = PdfColor.fromInt(0xFFFFFBEB);
        }
        break;
      case ActivityType.newDebt:
        statusColor = PdfColor.fromInt(0xFF6366F1);
        statusText = reportStrings.newDebt;
        backgroundColor = PdfColor.fromInt(0xFFF0F4FF);
        break;
      case ActivityType.debtCleared:
        statusColor = PdfColor.fromInt(0xFF3B82F6);
        statusText = reportStrings.debtPaid;
        backgroundColor = PdfColor.fromInt(0xFFEFF6FF);
        break;
      default:
        statusColor = PdfColor.fromInt(0xFF64748B);
        statusText = reportStrings.activity;
        backgroundColor = PdfColor.fromInt(0xFFF8FAFC);
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: 0.5,
        ),
      ),
      child: pw.Row(
        children: [
          // Status indicator dot
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: statusColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 10),
          
          // Main content: customer name (always LTR, left) then product; amount stays on the right
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: activity.type == ActivityType.payment
                      ? [
                          // Fully paid / Partial payment: left shows only customer name; amount and status on the right
                          pw.Text(
                            customerName,
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1E293B),
                            )),
                            textDirection: pw.TextDirection.ltr,
                          ),
                        ]
                      : [
                          // New debt etc.: customer name then product (and optional " x 2")
                          pw.Text(
                            '$customerName - ',
                            style: withPdfFont(pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1E293B),
                            )),
                            textDirection: pw.TextDirection.ltr,
                          ),
                          ..._buildDescriptionWithQuantityPdf(description, useRtl, withPdfFont),
                        ],
                ),
                pw.SizedBox(height: 2),
                
                // Date (Arabic label when Arabic → RTL)
                pw.Text(
                  reportStrings.formatActivityDate(date),
                  style: withPdfFont(pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF94A3B8),
                  )),
                  textDirection: useRtl ? pw.TextDirection.rtl : null,
                ),
              ],
            ),
          ),
          
          // Amount (always English numerals, LTR) and status (Arabic when useRtl → RTL)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '${amount.toStringAsFixed(2)}\$',
                style: withPdfFont(pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: statusColor,
                )),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                statusText,
                style: withPdfFont(pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.normal,
                  color: statusColor,
                )),
                textDirection: useRtl ? pw.TextDirection.rtl : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual activity item for PDF (legacy method for compatibility)
  static pw.Widget _buildActivityPDFItem(Map<String, dynamic> item) {
    final activity = item['activity'] as Activity;
    final amount = item['amount'] as double;
    final date = item['date'] as DateTime;
    final customerName = item['customerName'] as String;
    final description = item['description'] as String;
    
    PdfColor iconColor;
    String statusText;
    
    switch (activity.type) {
      case ActivityType.payment:
        if (activity.isPaymentCompleted) {
          if (description.startsWith('Fully paid:')) {
            iconColor = PdfColors.green;
            statusText = 'Fully Paid';
          } else {
            iconColor = PdfColors.blue;
            statusText = 'Debt Paid';
          }
        } else {
          iconColor = PdfColors.orange;
          statusText = 'Partial Payment';
        }
        break;
      case ActivityType.newDebt:
        iconColor = PdfColors.blue;
        statusText = 'New Debt';
        break;
      case ActivityType.debtCleared:
        iconColor = PdfColors.blue;
        statusText = 'Debt Paid';
        break;
      default:
        iconColor = PdfColors.grey;
        statusText = 'Activity';
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: iconColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '$statusText: \$${amount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: iconColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _formatActivityDate(date),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get month name from month number
  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Format date for PDF
  static String _formatDateForPDF(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format activity date for PDF
  static String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      return 'Today at ${_formatTime12Hour(date)}';
    } else if (activityDate == yesterday) {
      return 'Yesterday at ${_formatTime12Hour(date)}';
    } else {
      return '${_formatDateForPDF(date)} at ${_formatTime12Hour(date)}';
    }
  }

  /// Format time in 12-hour format for PDF
  static String _formatTime12Hour(DateTime date) {
    int hour = date.hour;
    String period = 'am';
    
    if (hour >= 12) {
      period = 'pm';
      if (hour > 12) {
        hour -= 12;
      }
    }
    if (hour == 0) {
      hour = 12;
    }
    
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  /// Share a PDF file using the system share dialog
  static Future<void> sharePDFFile(File pdfFile) async {
    try {
      final businessName = await BusinessNameService().getBusinessName();
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Monthly Activity Report from $businessName',
      );
    } catch (e) {
      // Handle error silently
    }
  }
}
