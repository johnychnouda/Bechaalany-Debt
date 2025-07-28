import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';
import '../models/partial_payment.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  Box<Customer>? _customerBox;
  Box<Debt>? _debtBox;
  Box<ProductCategory>? _categoryBox;
  Box<ProductPurchase>? _productPurchaseBox;
  Box<CurrencySettings>? _currencySettingsBox;
  Box<Activity>? _activityBox;
  Box<PartialPayment>? _partialPaymentBox;
  
  // Backup and recovery
  static const String _backupDirName = 'backups';
  static const int _maxBackups = 5;
  
  Box<Customer> get _customerBoxSafe {
    _customerBox ??= Hive.box<Customer>('customers');
    return _customerBox!;
  }
  
  Box<Debt> get _debtBoxSafe {
    _debtBox ??= Hive.box<Debt>('debts');
    return _debtBox!;
  }

  Box<ProductCategory> get _categoryBoxSafe {
    _categoryBox ??= Hive.box<ProductCategory>('categories');
    return _categoryBox!;
  }

  Box<ProductPurchase> get _productPurchaseBoxSafe {
    _productPurchaseBox ??= Hive.box<ProductPurchase>('product_purchases');
    return _productPurchaseBox!;
  }

  Box<CurrencySettings> get _currencySettingsBoxSafe {
    _currencySettingsBox ??= Hive.box<CurrencySettings>('currency_settings');
    return _currencySettingsBox!;
  }

  Box<Activity> get _activityBoxSafe {
    _activityBox ??= Hive.box<Activity>('activities');
    return _activityBox!;
  }

  Box<PartialPayment> get _partialPaymentBoxSafe {
    try {
      if (!Hive.isBoxOpen('partial_payments')) {
        throw Exception('Partial payments box is not open');
      }
      _partialPaymentBox ??= Hive.box<PartialPayment>('partial_payments');
      return _partialPaymentBox!;
    } catch (e) {
      print('Error accessing partial payments box: $e');
      rethrow;
    }
  }
  
  // Create backup of all data
  Future<void> createBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupDirName');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_$timestamp';
      final backupDirPath = Directory(backupPath);
      await backupDirPath.create();
      
      // Copy all Hive files
      final hiveFiles = [
        'customers.hive', 'debts.hive', 'categories.hive', 
        'product_purchases.hive', 'currency_settings.hive', 
        'activities.hive', 'partial_payments.hive'
      ];
      
      for (final fileName in hiveFiles) {
        final sourceFile = File('${directory.path}/$fileName');
        if (await sourceFile.exists()) {
          final destFile = File('$backupPath/$fileName');
          await sourceFile.copy(destFile.path);
        }
      }
      
      print('Backup created at: $backupPath');
      
      // Clean up old backups
      await _cleanupOldBackups(backupDir);
      
    } catch (e) {
      print('Error creating backup: $e');
    }
  }
  
  // Restore from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory(backupPath);
      
      if (!await backupDir.exists()) {
        print('Backup directory does not exist: $backupPath');
        return false;
      }
      
      // Close all boxes first
      await Hive.close();
      
      // Copy backup files
      final hiveFiles = [
        'customers.hive', 'debts.hive', 'categories.hive', 
        'product_purchases.hive', 'currency_settings.hive', 
        'activities.hive', 'partial_payments.hive'
      ];
      
      for (final fileName in hiveFiles) {
        final backupFile = File('$backupPath/$fileName');
        if (await backupFile.exists()) {
          final destFile = File('${directory.path}/$fileName');
          await backupFile.copy(destFile.path);
        }
      }
      
      print('Data restored from backup: $backupPath');
      return true;
      
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }
  
  // Get list of available backups
  Future<List<String>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/$_backupDirName');
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final backupDirs = await backupDir.list().where((entity) => 
        entity is Directory && entity.path.contains('backup_')
      ).toList();
      
      return backupDirs.map((dir) => dir.path).toList()..sort((a, b) => b.compareTo(a));
      
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }
  
  // Clean up old backups
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final backupDirs = await backupDir.list().where((entity) => 
        entity is Directory && entity.path.contains('backup_')
      ).toList();
      
      if (backupDirs.length > _maxBackups) {
        backupDirs.sort((a, b) => a.path.compareTo(b.path));
        final toDelete = backupDirs.take(backupDirs.length - _maxBackups);
        
        for (final dir in toDelete) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      print('Error cleaning up backups: $e');
    }
  }
  
  // Auto-backup before major operations
  Future<void> _autoBackup() async {
    try {
      await createBackup();
    } catch (e) {
      print('Auto-backup failed: $e');
    }
  }
  
  // Customer methods
  List<Customer> get customers {
    try {
      return _customerBoxSafe.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addCustomer(Customer customer) async {
    try {
      await _autoBackup(); // Create backup before adding
      _customerBoxSafe.put(customer.id, customer);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateCustomer(Customer customer) async {
    try {
      _customerBoxSafe.put(customer.id, customer);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteCustomer(String customerId) async {
    try {
      _customerBoxSafe.delete(customerId);
      // Also remove related debts
      _debtBoxSafe.values.where((d) => d.customerId == customerId).toList().forEach((d) {
        _debtBoxSafe.delete(d.id);
      });
    } catch (e) {
      rethrow;
    }
  }
  
  Customer? getCustomer(String customerId) {
    try {
      return _customerBoxSafe.get(customerId);
    } catch (e) {
      return null;
    }
  }

  // Debt methods
  List<Debt> get debts {
    try {
      return _debtBoxSafe.values.toList();
    } catch (e) {
      return [];
    }
  }

  List<PartialPayment> get partialPayments {
    try {
      // Check if the box is open
      if (!Hive.isBoxOpen('partial_payments')) {
        print('Partial payments box is not open, returning empty list');
        return [];
      }
      return _partialPaymentBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing partial payments box: $e');
      return [];
    }
  }
  
  List<Debt> getDebtsByCustomer(String customerId) {
    try {
      return _debtBoxSafe.values.where((d) => d.customerId == customerId).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addDebt(Debt debt) async {
    try {
      await _autoBackup(); // Create backup before adding
      _debtBoxSafe.put(debt.id, debt);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateDebt(Debt debt) async {
    try {
      _debtBoxSafe.put(debt.id, debt);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      _debtBoxSafe.delete(debtId);
      // Also delete related partial payments
      final partialPayments = _partialPaymentBoxSafe.values.where((p) => p.debtId == debtId).toList();
      for (final payment in partialPayments) {
        _partialPaymentBoxSafe.delete(payment.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Partial Payment methods
  List<PartialPayment> getPartialPaymentsByDebt(String debtId) {
    try {
      return _partialPaymentBoxSafe.values.where((p) => p.debtId == debtId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addPartialPayment(PartialPayment payment) async {
    try {
      _partialPaymentBoxSafe.put(payment.id, payment);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePartialPayment(String paymentId) async {
    try {
      _partialPaymentBoxSafe.delete(paymentId);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      final debt = _debtBoxSafe.get(debtId);
      if (debt != null) {
        final updatedDebt = Debt(
          id: debt.id,
          customerId: debt.customerId,
          customerName: debt.customerName,
          amount: debt.amount,
          description: debt.description,
          type: debt.type,
          status: DebtStatus.paid,
          createdAt: debt.createdAt,
          paidAt: DateTime.now(),
          notes: debt.notes,
          paidAmount: debt.amount,
        );
        _debtBoxSafe.put(debtId, updatedDebt);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Category methods
  List<ProductCategory> get categories {
    try {
      return _categoryBoxSafe.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addCategory(ProductCategory category) async {
    try {
      _categoryBoxSafe.put(category.id, category);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateCategory(ProductCategory category) async {
    try {
      _categoryBoxSafe.put(category.id, category);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteCategory(String categoryId) async {
    try {
      _categoryBoxSafe.delete(categoryId);
    } catch (e) {
      rethrow;
    }
  }

  // Product Purchase methods
  List<ProductPurchase> get productPurchases {
    try {
      return _productPurchaseBoxSafe.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addProductPurchase(ProductPurchase purchase) async {
    try {
      _productPurchaseBoxSafe.put(purchase.id, purchase);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateProductPurchase(ProductPurchase purchase) async {
    try {
      _productPurchaseBoxSafe.put(purchase.id, purchase);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteProductPurchase(String purchaseId) async {
    try {
      _productPurchaseBoxSafe.delete(purchaseId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markProductPurchaseAsPaid(String purchaseId) async {
    try {
      final purchase = _productPurchaseBoxSafe.get(purchaseId);
      if (purchase != null) {
        final updatedPurchase = purchase.copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
        );
        _productPurchaseBoxSafe.put(purchaseId, updatedPurchase);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Currency Settings methods
  CurrencySettings? get currencySettings {
    try {
      final settings = _currencySettingsBoxSafe.values.toList();
      return settings.isNotEmpty ? settings.first : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveCurrencySettings(CurrencySettings settings) async {
    try {
      // Clear existing settings and save new ones
      await _currencySettingsBoxSafe.clear();
      _currencySettingsBoxSafe.put('default', settings);
    } catch (e) {
      rethrow;
    }
  }

  // Activity methods
  List<Activity> get activities {
    try {
      final activities = _activityBoxSafe.values.toList();
      print('DataService: Retrieved ${activities.length} activities');
      return activities;
    } catch (e) {
      print('DataService: Error retrieving activities: $e');
      return [];
    }
  }
  
  Future<void> addActivity(Activity activity) async {
    try {
      _activityBoxSafe.put(activity.id, activity);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateActivity(Activity activity) async {
    try {
      _activityBoxSafe.put(activity.id, activity);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteActivity(String activityId) async {
    try {
      _activityBoxSafe.delete(activityId);
    } catch (e) {
      rethrow;
    }
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await _customerBoxSafe.clear();
      await _debtBoxSafe.clear();
      await _categoryBoxSafe.clear();
      await _productPurchaseBoxSafe.clear();
      await _currencySettingsBoxSafe.clear();
      await _activityBoxSafe.clear();
    } catch (e) {
      rethrow;
    }
  }
} 