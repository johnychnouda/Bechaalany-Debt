import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/product_purchase.dart';
import '../models/category.dart';

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();

  Future<String> exportToPDF(List<Customer> customers, List<Debt> debts, List<ProductPurchase> productPurchases, List<ProductCategory> categories) async {
    try {
      final pdf = pw.Document();
      
      // Calculate summary statistics
      final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaid = debts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      final totalRemaining = debts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      final pendingDebts = debts.where((debt) => debt.status == DebtStatus.pending).length;
      final paidDebts = debts.where((debt) => debt.status == DebtStatus.paid).length;
      
      // Calculate total revenue as profit from all paid amounts (full + partial payments)
      double totalRevenue = 0.0;
      
      // Revenue from all paid amounts (profit)
      for (final debt in debts) {
        if (debt.paidAmount > 0) {
          // Handle case where originalSellingPrice might not be set for existing debts
          double? sellingPrice = debt.originalSellingPrice;
          if (sellingPrice == null && debt.subcategoryName != null) {
            // Try to find the subcategory and get its current selling price
            try {
              final subcategory = categories
                  .expand((category) => category.subcategories)
                  .firstWhere((sub) => sub.name == debt.subcategoryName);
              sellingPrice = subcategory.sellingPrice;
            } catch (e) {
              // If subcategory not found, skip this debt
              continue;
            }
          }
          
          if (sellingPrice != null) {
            // Find the subcategory to get cost price
            try {
              final subcategory = categories
                  .expand((category) => category.subcategories)
                  .firstWhere((sub) => sub.name == debt.subcategoryName);
              
              // Calculate profit ratio: (selling price - cost price) / selling price
              final profitRatio = (sellingPrice! - subcategory.costPrice) / sellingPrice!;
              
              // Calculate actual profit from paid amount: paid amount * profit ratio
              final profitFromPaidAmount = debt.paidAmount * profitRatio;
              totalRevenue += profitFromPaidAmount;
            } catch (e) {
              // If subcategory not found, assume 50% profit ratio
              final profitFromPaidAmount = debt.paidAmount * 0.5;
              totalRevenue += profitFromPaidAmount;
            }
          }
        }
      }
      
      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header with logo/icon
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'DEBT MANAGEMENT SYSTEM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'COMPREHENSIVE DATA REPORT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Generation date
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'Generated on: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Summary statistics
                pw.Container(
                  padding: pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue, width: 2),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SUMMARY STATISTICS',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      _buildSummaryRow('Total Customers', '${customers.length}'),
                      _buildSummaryRow('Total Debts', '${debts.length}'),
                      _buildSummaryRow('Pending Debts', '$pendingDebts'),
                      _buildSummaryRow('Paid Debts', '$paidDebts'),
                      pw.Divider(color: PdfColors.grey),
                      _buildSummaryRow('Total Amount', _formatCurrency(totalAmount)),
                      _buildSummaryRow('Total Paid', _formatCurrency(totalPaid)),
                      _buildSummaryRow('Total Remaining', _formatCurrency(totalRemaining)),
                      _buildSummaryRow('Total Revenue (Profit)', _formatCurrency(totalRevenue)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Add customers page
      if (customers.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page header
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'CUSTOMERS LIST',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Customers table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.blue, width: 1),
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildTableHeader('Customer ID'),
                          _buildTableHeader('Name'),
                          _buildTableHeader('Phone'),
                          _buildTableHeader('Email'),
                          _buildTableHeader('Total Debts'),
                          _buildTableHeader('Total Amount'),
                        ],
                      ),
                      // Data rows
                      ...customers.map((customer) {
                        final customerDebts = debts.where((debt) => debt.customerId == customer.id).toList();
                        final customerTotalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
                        
                        return pw.TableRow(
                          children: [
                            _buildTableCell(customer.id),
                            _buildTableCell(customer.name),
                            _buildTableCell(customer.phone),
                            _buildTableCell(customer.email ?? ''),
                            _buildTableCell('${customerDebts.length}'),
                            _buildTableCell(_formatCurrency(customerTotalAmount)),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // Add debts page
      if (debts.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page header
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'DEBTS LIST',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Debts table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.blue, width: 1),
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildTableHeader('Customer'),
                          _buildTableHeader('Description'),
                          _buildTableHeader('Amount'),
                          _buildTableHeader('Paid'),
                          _buildTableHeader('Remaining'),
                          _buildTableHeader('Status'),
                          _buildTableHeader('Date'),
                        ],
                      ),
                      // Data rows
                      ...debts.map((debt) => pw.TableRow(
                        children: [
                          _buildTableCell(debt.customerName),
                          _buildTableCell(debt.description),
                          _buildTableCell(_formatCurrency(debt.amount)),
                          _buildTableCell(_formatCurrency(debt.paidAmount)),
                          _buildTableCell(_formatCurrency(debt.remainingAmount)),
                          _buildTableCell(_formatDebtStatus(debt.status)),
                          _buildTableCell(_formatDate(debt.createdAt)),
                        ],
                      )),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
      final file = File('${directory.path}/Debt_Report_$dateStr.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export PDF data: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper methods for PDF formatting
  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDebtStatus(DebtStatus status) {
    switch (status) {
      case DebtStatus.pending:
        return 'Pending';
      case DebtStatus.paid:
        return 'Paid';
      default:
        return 'Pending';
    }
  }

  Future<void> shareExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Debt App Data Export',
        );
      } else {
        throw Exception('Export file not found');
      }
    } catch (e) {
      throw Exception('Failed to share export file: $e');
    }
  }
} 