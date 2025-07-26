import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();

  Future<String> exportToCSV(List<Customer> customers, List<Debt> debts) async {
    try {
      // Create CSV data for customers with better formatting
      final customerData = [
        ['Customer ID', 'Customer Name', 'Phone Number', 'Email Address', 'Physical Address', 'Registration Date'], // Header
        ...customers.map((customer) => [
          customer.id,
          customer.name,
          customer.phone,
          customer.email ?? 'N/A',
          customer.address ?? 'N/A',
          _formatDate(customer.createdAt),
        ]),
      ];

      // Create CSV data for debts with better formatting
      final debtData = [
        ['Debt ID', 'Customer ID', 'Customer Name', 'Description', 'Total Amount', 'Paid Amount', 'Remaining Amount', 'Debt Type', 'Status', 'Created Date', 'Paid Date', 'Notes'], // Header
        ...debts.map((debt) => [
          debt.id,
          debt.customerId,
          debt.customerName,
          debt.description,
          _formatCurrency(debt.amount),
          _formatCurrency(debt.paidAmount),
          _formatCurrency(debt.remainingAmount),
          _formatDebtType(debt.type),
          _formatDebtStatus(debt.status),
          _formatDate(debt.createdAt),
          debt.paidAt != null ? _formatDate(debt.paidAt!) : 'N/A',
          debt.notes ?? 'N/A',
        ]),
      ];

      // Create a summary header
      final summaryData = [
        ['Bechaalany Debt App - Data Export'],
        ['Export Date: ${_formatDate(DateTime.now())}'],
        ['Total Customers: ${customers.length}'],
        ['Total Debts: ${debts.length}'],
        [''],
        ['=== CUSTOMERS DATA ==='],
        ...customerData,
        [''],
        ['=== DEBTS DATA ==='],
        ...debtData,
      ];

      final csvString = const ListToCsvConverter().convert(summaryData);

      // Save to temporary file with better naming
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
      final file = File('${directory.path}/Bechaalany_Debt_Export_$dateStr.csv');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDebtType(DebtType type) {
    switch (type) {
      case DebtType.credit:
        return 'Credit';
      case DebtType.payment:
        return 'Payment';
    }
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
      // Remove $ and parse
      return double.parse(currencyStr.replaceAll('\$', '').trim());
    } catch (e) {
      return 0.0;
    }
  }

  DebtType _parseDebtType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'credit':
        return DebtType.credit;
      case 'payment':
        return DebtType.payment;
      default:
        return DebtType.credit;
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
          text: 'Bechaalany Debt App - Data Export',
          subject: 'Debt App Data Export',
        );
      } else {
        throw Exception('Export file not found');
      }
    } catch (e) {
      throw Exception('Failed to share export file: $e');
    }
  }

  Future<Map<String, dynamic>> importFromCSV() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Read CSV content
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      // Parse the data
      final customers = <Customer>[];
      final debts = <Debt>[];

      bool inCustomersSection = false;
      bool inDebtsSection = false;

      for (final row in csvData) {
        if (row.isEmpty || row.length == 1) continue;

        final firstCell = row[0].toString().trim();
        
        if (firstCell == '=== CUSTOMERS DATA ===') {
          inCustomersSection = true;
          inDebtsSection = false;
          continue;
        }

        if (firstCell == '=== DEBTS DATA ===') {
          inCustomersSection = false;
          inDebtsSection = true;
          continue;
        }

        if (inCustomersSection && row.length >= 6) {
          try {
            // Skip header row
            if (row[0].toString().toLowerCase().contains('customer id')) continue;
            
            final customer = Customer(
              id: row[0].toString(),
              name: row[1].toString(),
              phone: row[2].toString(),
              email: row[3].toString() == 'N/A' ? null : row[3].toString(),
              address: row[4].toString() == 'N/A' ? null : row[4].toString(),
              createdAt: _parseDate(row[5].toString()),
            );
            customers.add(customer);
          } catch (e) {
            print('Error parsing customer row: $e');
          }
        }

        if (inDebtsSection && row.length >= 12) {
          try {
            // Skip header row
            if (row[0].toString().toLowerCase().contains('debt id')) continue;
            
            final debt = Debt(
              id: row[0].toString(),
              customerId: row[1].toString(),
              customerName: row[2].toString(),
              description: row[3].toString(),
              amount: _parseCurrency(row[4].toString()),
              type: _parseDebtType(row[7].toString()),
              status: _parseDebtStatus(row[8].toString()),
              createdAt: _parseDate(row[9].toString()),
              paidAt: row[10].toString() == 'N/A' ? null : _parseDate(row[10].toString()),
              notes: row[11].toString() == 'N/A' ? null : row[11].toString(),
              paidAmount: _parseCurrency(row[5].toString()),
            );
            debts.add(debt);
          } catch (e) {
            print('Error parsing debt row: $e');
          }
        }
      }

      return {
        'customers': customers,
        'debts': debts,
        'totalCustomers': customers.length,
        'totalDebts': debts.length,
      };
    } catch (e) {
      throw Exception('Failed to import data: $e');
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