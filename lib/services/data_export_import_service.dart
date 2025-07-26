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
      // Create CSV data for customers
      final customerData = [
        ['ID', 'Name', 'Phone', 'Email', 'Address', 'Created At'], // Header
        ...customers.map((customer) => [
          customer.id,
          customer.name,
          customer.phone,
          customer.email ?? '',
          customer.address ?? '',
          customer.createdAt.toIso8601String(),
        ]),
      ];

      // Create CSV data for debts
      final debtData = [
        ['ID', 'Customer ID', 'Customer Name', 'Description', 'Amount', 'Paid Amount', 'Remaining Amount', 'Type', 'Status', 'Created At', 'Paid At', 'Notes'], // Header
        ...debts.map((debt) => [
          debt.id,
          debt.customerId,
          debt.customerName,
          debt.description,
          debt.amount.toString(),
          debt.paidAmount.toString(),
          debt.remainingAmount.toString(),
          debt.type.toString().split('.').last,
          debt.status.toString().split('.').last,
          debt.createdAt.toIso8601String(),
          debt.paidAt?.toIso8601String() ?? '',
          debt.notes ?? '',
        ]),
      ];

      // Create combined CSV
      final combinedData = [
        ['=== CUSTOMERS DATA ==='],
        ...customerData,
        [''],
        ['=== DEBTS DATA ==='],
        ...debtData,
      ];

      final csvString = const ListToCsvConverter().convert(combinedData);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/debt_app_export_$timestamp.csv');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
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
            final customer = Customer(
              id: row[0].toString(),
              name: row[1].toString(),
              phone: row[2].toString(),
              email: row[3].toString().isEmpty ? null : row[3].toString(),
              address: row[4].toString().isEmpty ? null : row[4].toString(),
              createdAt: DateTime.parse(row[5].toString()),
            );
            customers.add(customer);
          } catch (e) {
            print('Error parsing customer row: $e');
          }
        }

        if (inDebtsSection && row.length >= 12) {
          try {
            final debt = Debt(
              id: row[0].toString(),
              customerId: row[1].toString(),
              customerName: row[2].toString(),
              description: row[3].toString(),
              amount: double.parse(row[4].toString()),
              type: DebtType.values.firstWhere(
                (e) => e.toString().split('.').last == row[7].toString(),
                orElse: () => DebtType.credit,
              ),
              status: DebtStatus.values.firstWhere(
                (e) => e.toString().split('.').last == row[8].toString(),
                orElse: () => DebtStatus.pending,
              ),
              createdAt: DateTime.parse(row[9].toString()),
              paidAt: row[10].toString().isEmpty ? null : DateTime.parse(row[10].toString()),
              notes: row[11].toString().isEmpty ? null : row[11].toString(),
              paidAmount: double.parse(row[5].toString()),
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