import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cross_file/cross_file.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/product_purchase.dart';
import '../models/category.dart';

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();

  Future<String> exportToExcel(List<Customer> customers, List<Debt> debts, List<ProductPurchase> productPurchases, List<ProductCategory> categories) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Remove the default Sheet1
      excel.delete('Sheet1');
      
      // Create Summary sheet
      final summarySheet = excel['Summary'];
      
      // Add title and date
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'DEBT MANAGEMENT SYSTEM - DATA EXPORT';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Generated on: ${_formatDate(DateTime.now())}';
      
      // Style title
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      // Add summary statistics
      final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaid = debts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      final totalRemaining = debts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      final pendingDebts = debts.where((debt) => debt.status == DebtStatus.pending).length;
      final paidDebts = debts.where((debt) => debt.status == DebtStatus.paid).length;
      
      // Calculate total revenue as profit from all paid amounts (full + partial payments)
      double totalRevenue = 0.0;
      
      // Revenue from all paid amounts (profit)
      for (final debt in debts) {
        if (debt.paidAmount > 0 && debt.originalSellingPrice != null) {
          // Find the subcategory to get cost price
          try {
            final subcategory = categories
                .expand((category) => category.subcategories)
                .firstWhere((sub) => sub.name == debt.subcategoryName);
            
            // Calculate profit ratio: (selling price - cost price) / selling price
            final profitRatio = (debt.originalSellingPrice! - subcategory.costPrice) / debt.originalSellingPrice!;
            
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
      
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'SUMMARY STATISTICS';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Customers: ${customers.length}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Debts: ${debts.length}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Pending Debts: $pendingDebts';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = 'Paid Debts: $paidDebts';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8)).value = 'Total Amount: ${_formatCurrency(totalAmount)}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = 'Total Paid: ${_formatCurrency(totalPaid)}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = 'Total Remaining: ${_formatCurrency(totalRemaining)}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).value = 'Total Revenue (Profit): ${_formatCurrency(totalRevenue)}';
      
      // Style summary section
      for (int row = 3; row <= 11; row++) {
        final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        cell.cellStyle = CellStyle(
          bold: row == 3,
          fontSize: row == 3 ? 14 : 12,
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      // Create Customers sheet
      final customersSheet = excel['Customers'];
      
      // Add title
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'CUSTOMERS LIST';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Total Customers: ${customers.length}';
      
      // Style title
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      // Add headers for customers (starting from row 3)
      final headers = ['Customer ID', 'Name', 'Phone', 'Email', 'Address', 'Date Added', 'Total Debts', 'Total Amount'];
      for (int col = 0; col < headers.length; col++) {
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2)).value = headers[col];
        
        // Style headers
        final cell = customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      // Add customer data
      for (int i = 0; i < customers.length; i++) {
        final customer = customers[i];
        final rowIndex = i + 3;
        final customerDebts = debts.where((debt) => debt.customerId == customer.id).toList();
        final customerTotalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
        
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = customer.id;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = customer.name;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = customer.phone;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = customer.email ?? '';
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = customer.address ?? '';
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = _formatDate(customer.createdAt);
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = customerDebts.length;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = _formatCurrency(customerTotalAmount);
        
        // Style data rows - center all content
        for (int col = 0; col < headers.length; col++) {
          final cell = customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }
      
      // Create Debts sheet
      final debtsSheet = excel['Debts'];
      
      // Add title
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'DEBTS LIST';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Total Debts: ${debts.length}';
      
      // Style title
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      // Add headers for debts (starting from row 3)
      final debtHeaders = ['Customer ID', 'Customer Name', 'Description', 'Amount', 'Paid Amount', 'Remaining', 'Status', 'Date Created', 'Notes', 'Category', 'Subcategory'];
      for (int col = 0; col < debtHeaders.length; col++) {
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2)).value = debtHeaders[col];
        
        // Style headers
        final cell = debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      // Add debt data
      for (int i = 0; i < debts.length; i++) {
        final debt = debts[i];
        final rowIndex = i + 3;
        
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = debt.customerId;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = debt.customerName;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = debt.description;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = _formatCurrency(debt.amount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = _formatCurrency(debt.paidAmount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = _formatCurrency(debt.remainingAmount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = _formatDebtStatus(debt.status);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = _formatDate(debt.createdAt);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = debt.notes ?? '';
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = debt.categoryName ?? '';
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = debt.subcategoryName ?? '';
        
        // Style data rows - center all content
        for (int col = 0; col < debtHeaders.length; col++) {
          final cell = debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
      final file = File('${directory.path}/Debt_Data_$dateStr.xlsx');
      await file.writeAsBytes(excel.encode()!);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export Excel data: $e');
    }
  }

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

  DateTime _parseDate(String dateStr) {
    try {
      // Handle DD/MM/YYYY format
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      // Fallback to ISO format
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  double _parseCurrency(String currencyStr) {
    try {
      // Remove $ and commas, then parse
      return double.parse(currencyStr.replaceAll('\$', '').replaceAll(',', '').trim());
    } catch (e) {
      return 0.0;
    }
  }

  DebtStatus _parseDebtStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return DebtStatus.pending;
      case 'paid':
        return DebtStatus.paid;
      default:
        return DebtStatus.pending;
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

  Future<void> validateImportData(Map<String, dynamic> importData) async {
    final customers = importData['customers'] as List<Customer>;
    final debts = importData['debts'] as List<Debt>;

    // Validate customers
    for (final customer in customers) {
      if (customer.name.trim().isEmpty) {
        throw Exception('Customer name cannot be empty');
      }
      if (customer.phone.trim().isEmpty) {
        throw Exception('Customer phone cannot be empty');
      }
    }

    // Validate debts
    for (final debt in debts) {
      if (debt.customerName.trim().isEmpty) {
        throw Exception('Debt customer name cannot be empty');
      }
      if (debt.description.trim().isEmpty) {
        throw Exception('Debt description cannot be empty');
      }
      if (debt.amount <= 0) {
        throw Exception('Debt amount must be greater than 0');
      }
    }

    // Check for duplicate IDs
    final customerIds = customers.map((c) => c.id).toSet();
    if (customerIds.length != customers.length) {
      throw Exception('Duplicate customer IDs found in import data');
    }

    final debtIds = debts.map((d) => d.id).toSet();
    if (debtIds.length != debts.length) {
      throw Exception('Duplicate debt IDs found in import data');
    }
  }
} 