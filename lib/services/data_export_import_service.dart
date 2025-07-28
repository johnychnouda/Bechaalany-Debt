import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/customer.dart';
import '../models/debt.dart';

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();

  Future<String> exportToCSV(List<Customer> customers, List<Debt> debts) async {
    try {
      // Create simple, user-friendly CSV data for customers
      final customerData = [
        ['Name', 'Phone', 'Email', 'Address', 'Date Added'], // Simple headers
        ...customers.map((customer) => [
          customer.name,
          customer.phone,
          customer.email ?? '',
          customer.address ?? '',
          _formatDate(customer.createdAt),
        ]),
      ];

      // Create simple, user-friendly CSV data for debts
      final debtData = [
        ['Customer', 'Description', 'Amount', 'Paid', 'Remaining', 'Status', 'Date', 'Notes'], // Simple headers
        ...debts.map((debt) => [
          debt.customerName,
          debt.description,
          _formatCurrency(debt.amount),
          _formatCurrency(debt.paidAmount),
          _formatCurrency(debt.remainingAmount),
          _formatDebtStatus(debt.status),
          _formatDate(debt.createdAt),
          debt.notes ?? '',
        ]),
      ];

      // Create simple combined CSV
      final combinedData = [
        ...customerData,
        [''], // Empty row for separation
        ['DEBTS'], // Simple section header
        ...debtData,
      ];

      final csvString = const ListToCsvConverter().convert(combinedData);

      // Save to temporary file with simple naming
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
      final file = File('${directory.path}/Debt_Data_$dateStr.csv');
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

      bool inCustomersSection = true; // Start with customers section
      bool inDebtsSection = false;

      for (final row in csvData) {
        if (row.isEmpty || row.length == 1) continue;

        final firstCell = row[0].toString().trim();
        
        if (firstCell == 'DEBTS') {
          inCustomersSection = false;
          inDebtsSection = true;
          continue;
        }

        if (inCustomersSection && row.length >= 5) {
          try {
            // Skip header row
            if (row[0].toString().toLowerCase().contains('name')) continue;
            
            final customer = Customer(
              id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate new ID
              name: row[0].toString(),
              phone: row[1].toString(),
              email: row[2].toString().isEmpty ? null : row[2].toString(),
              address: row[3].toString().isEmpty ? null : row[3].toString(),
              createdAt: _parseDate(row[4].toString()),
            );
            customers.add(customer);
          } catch (e) {
            print('Error parsing customer row: $e');
          }
        }

        if (inDebtsSection && row.length >= 8) {
          try {
            // Skip header row
            if (row[0].toString().toLowerCase().contains('customer')) continue;
            
            final debt = Debt(
              id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate new ID
              customerId: '', // Will be linked by customer name
              customerName: row[0].toString(),
              description: row[1].toString(),
              amount: _parseCurrency(row[2].toString()),
              type: DebtType.credit, // Default type
              status: _parseDebtStatus(row[5].toString()),
              createdAt: _parseDate(row[6].toString()),
              paidAt: null,
              notes: row[7].toString().isEmpty ? null : row[7].toString(),
              paidAmount: _parseCurrency(row[3].toString()),
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