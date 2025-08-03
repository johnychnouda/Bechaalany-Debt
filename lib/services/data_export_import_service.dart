import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cross_file/cross_file.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();



  Future<String> exportToExcel(List<Customer> customers, List<Debt> debts) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Remove the default Sheet1
      excel.delete('Sheet1');
      
      // Create Customers sheet
      final customersSheet = excel['Customers'];
      
      // Add headers for customers
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Customer ID';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Name';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'Phone';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'Email';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'Address';
      customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'Date Added';
      
      // Style headers - make them bold and centered
      for (int col = 0; col < 6; col++) {
        final cell = customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      // Add customer data
      for (int i = 0; i < customers.length; i++) {
        final customer = customers[i];
        final rowIndex = i + 1;
        
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = customer.id;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = customer.name;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = customer.phone;
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = customer.email ?? '';
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = customer.address ?? '';
        customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = _formatDate(customer.createdAt);
        
        // Style data rows - center all content
        for (int col = 0; col < 6; col++) {
          final cell = customersSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }
      
      // Note: Column widths are automatically adjusted by Excel
      
      // Create Debts sheet
      final debtsSheet = excel['Debts'];
      
      // Add headers for debts
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Customer ID';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Customer';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'Description';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'Amount';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'Paid';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'Remaining';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = 'Status';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = 'Date';
      debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = 'Notes';
      
      // Style headers - make them bold and centered
      for (int col = 0; col < 9; col++) {
        final cell = debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      // Add debt data
      for (int i = 0; i < debts.length; i++) {
        final debt = debts[i];
        final rowIndex = i + 1;
        
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = debt.customerId;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = debt.customerName;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = debt.description;
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = _formatCurrency(debt.amount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = _formatCurrency(debt.paidAmount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = _formatCurrency(debt.remainingAmount);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = _formatDebtStatus(debt.status);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = _formatDate(debt.createdAt);
        debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = debt.notes ?? '';
        
        // Style data rows - center all content
        for (int col = 0; col < 9; col++) {
          final cell = debtsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }
      
      // Note: Column widths are automatically adjusted by Excel
      
      // Create Summary sheet
      final summarySheet = excel['Summary'];
      
      // Add summary data
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Debt Management Summary';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Generated on: ${_formatDate(DateTime.now())}';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Total Customers:';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = customers.length;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Debts:';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = debts.length;
      
      final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalPaid = debts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
      final totalRemaining = debts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Amount:';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = _formatCurrency(totalAmount);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Total Paid:';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = _formatCurrency(totalPaid);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = 'Total Remaining:';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = _formatCurrency(totalRemaining);
      
      // Style summary sheet - make title bold and centered
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );
      
      // Style all summary data - center align
      for (int row = 0; row <= 7; row++) {
        for (int col = 0; col < 2; col++) {
          final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          if (cell.value != null) {
            cell.cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
              verticalAlign: VerticalAlign.Center,
            );
          }
        }
      }
      
      // Note: Column widths are automatically adjusted by Excel
      
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

  Future<String> exportToPDF(List<Customer> customers, List<Debt> debts) async {
    try {
      final pdf = pw.Document();
      
      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Debt Management Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${_formatDate(DateTime.now())}', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 30),
                
                // Summary section
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text('Total Customers: ${customers.length}'),
                      pw.Text('Total Debts: ${debts.length}'),
                      pw.Text('Total Amount: ${_formatCurrency(debts.fold<double>(0, (sum, debt) => sum + debt.amount))}'),
                      pw.Text('Total Paid: ${_formatCurrency(debts.fold<double>(0, (sum, debt) => sum + debt.paidAmount))}'),
                      pw.Text('Total Remaining: ${_formatCurrency(debts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount))}'),
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
                  pw.Header(
                    level: 0,
                    child: pw.Text('Customers', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Customers table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Header row
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Customer ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Phone', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Email', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      // Data rows
                      ...customers.map((customer) => pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(customer.id)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(customer.name)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(customer.phone)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(customer.email ?? '')),
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
      
      // Add debts page
      if (debts.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text('Debts', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Debts table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Header row
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Customer ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      // Data rows
                      ...debts.map((debt) => pw.TableRow(
                        children: [
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(debt.customerId)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(debt.customerName)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(debt.description)),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(debt.amount))),
                          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(_formatDebtStatus(debt.status))),
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

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDebtStatus(DebtStatus status) {
    switch (status) {
      case DebtStatus.pending:
        return 'Pending';
      case DebtStatus.paid:
        return 'Paid';
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