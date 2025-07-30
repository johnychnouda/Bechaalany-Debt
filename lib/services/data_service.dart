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
    try {
      if (!Hive.isBoxOpen('customers')) {
        // Customers box is not open, attempting to open...
        // Note: This is a getter, so we can't use await here
        // The box should be opened in main.dart before the app starts
        throw Exception('Customers box is not open. Please ensure Hive is properly initialized.');
      }
      _customerBox ??= Hive.box<Customer>('customers');
      return _customerBox!;
    } catch (e) {
      // Error accessing customers box
      rethrow;
    }
  }
  
  Box<Debt> get _debtBoxSafe {
    try {
      if (!Hive.isBoxOpen('debts')) {
        throw Exception('Debts box is not open');
      }
      _debtBox ??= Hive.box<Debt>('debts');
      return _debtBox!;
    } catch (e) {
      // Error accessing debts box
      rethrow;
    }
  }

  Box<ProductCategory> get _categoryBoxSafe {
    try {
      if (!Hive.isBoxOpen('categories')) {
        throw Exception('Categories box is not open');
      }
      _categoryBox ??= Hive.box<ProductCategory>('categories');
      return _categoryBox!;
    } catch (e) {
      // Error accessing categories box
      rethrow;
    }
  }

  Box<ProductPurchase> get _productPurchaseBoxSafe {
    try {
      if (!Hive.isBoxOpen('product_purchases')) {
        throw Exception('Product purchases box is not open');
      }
      _productPurchaseBox ??= Hive.box<ProductPurchase>('product_purchases');
      return _productPurchaseBox!;
    } catch (e) {
      // Error accessing product purchases box
      rethrow;
    }
  }

  Box<CurrencySettings> get _currencySettingsBoxSafe {
    try {
      if (!Hive.isBoxOpen('currency_settings')) {
        throw Exception('Currency settings box is not open');
      }
      _currencySettingsBox ??= Hive.box<CurrencySettings>('currency_settings');
      return _currencySettingsBox!;
    } catch (e) {
      // Error accessing currency settings box
      rethrow;
    }
  }

  Box<Activity> get _activityBoxSafe {
    try {
      if (!Hive.isBoxOpen('activities')) {
        throw Exception('Activities box is not open');
      }
      _activityBox ??= Hive.box<Activity>('activities');
      return _activityBox!;
    } catch (e) {
      // Error accessing activities box
      rethrow;
    }
  }

  Box<PartialPayment> get _partialPaymentBoxSafe {
    try {
      if (!Hive.isBoxOpen('partial_payments')) {
        throw Exception('Partial payments box is not open');
      }
      _partialPaymentBox ??= Hive.box<PartialPayment>('partial_payments');
      return _partialPaymentBox!;
    } catch (e) {
      // Error accessing partial payments box
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
      
      // Backup created successfully
      
      // Clean up old backups
      await _cleanupOldBackups(backupDir);
      
    } catch (e) {
      // Error creating backup
    }
  }
  
  // Restore from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory(backupPath);
      
      if (!await backupDir.exists()) {
        // Backup directory does not exist
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
      
      // Data restored from backup successfully
      return true;
      
    } catch (e) {
      // Error restoring from backup
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
      // Error getting backups
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
      // Error cleaning up backups
    }
  }
  
  // Auto-backup before major operations
  Future<void> _autoBackup() async {
    try {
      await createBackup();
    } catch (e) {
      // Auto-backup failed
    }
  }
  
  // Ensure all boxes are open
  Future<void> ensureBoxesOpen() async {
    try {
      // Ensuring all Hive boxes are open...
      
      // Open each box individually with proper error handling
      try {
        if (!Hive.isBoxOpen('customers')) {
          // Opening box: customers
          await Hive.openBox<Customer>('customers');
          // Successfully opened box: customers
        } else {
          // Box customers is already open
        }
      } catch (e) {
        // Error opening box customers
        try {
          await Hive.deleteBoxFromDisk('customers');
          await Hive.openBox<Customer>('customers');
          // Successfully recreated box: customers
        } catch (recreateError) {
          // Failed to recreate box customers
        }
      }

      try {
        if (!Hive.isBoxOpen('debts')) {
          // Opening box: debts
          await Hive.openBox<Debt>('debts');
          // Successfully opened box: debts
        } else {
          // Box debts is already open
        }
      } catch (e) {
        // Error opening box debts
        try {
          await Hive.deleteBoxFromDisk('debts');
          await Hive.openBox<Debt>('debts');
          // Successfully recreated box: debts
        } catch (recreateError) {
          // Failed to recreate box debts
        }
      }

      try {
        if (!Hive.isBoxOpen('categories')) {
          // Opening box: categories
          await Hive.openBox<ProductCategory>('categories');
          // Successfully opened box: categories
        } else {
          // Box categories is already open
        }
      } catch (e) {
        // Error opening box categories
        try {
          await Hive.deleteBoxFromDisk('categories');
          await Hive.openBox<ProductCategory>('categories');
          // Successfully recreated box: categories
        } catch (recreateError) {
          // Failed to recreate box categories
        }
      }

      try {
        if (!Hive.isBoxOpen('product_purchases')) {
          // Opening box: product_purchases
          await Hive.openBox<ProductPurchase>('product_purchases');
          // Successfully opened box: product_purchases
        } else {
          // Box product_purchases is already open
        }
      } catch (e) {
        // Error opening box product_purchases
        try {
          await Hive.deleteBoxFromDisk('product_purchases');
          await Hive.openBox<ProductPurchase>('product_purchases');
          // Successfully recreated box: product_purchases
        } catch (recreateError) {
          // Failed to recreate box product_purchases
        }
      }

      try {
        if (!Hive.isBoxOpen('currency_settings')) {
          // Opening box: currency_settings
          await Hive.openBox<CurrencySettings>('currency_settings');
          // Successfully opened box: currency_settings
        } else {
          // Box currency_settings is already open
        }
      } catch (e) {
        // Error opening box currency_settings
        try {
          await Hive.deleteBoxFromDisk('currency_settings');
          await Hive.openBox<CurrencySettings>('currency_settings');
          // Successfully recreated box: currency_settings
        } catch (recreateError) {
          // Failed to recreate box currency_settings
        }
      }

      try {
        if (!Hive.isBoxOpen('activities')) {
          // Opening box: activities
          await Hive.openBox<Activity>('activities');
          // Successfully opened box: activities
        } else {
          // Box activities is already open
        }
      } catch (e) {
        // Error opening box activities
        try {
          await Hive.deleteBoxFromDisk('activities');
          await Hive.openBox<Activity>('activities');
          // Successfully recreated box: activities
        } catch (recreateError) {
          // Failed to recreate box activities
        }
      }

      try {
        if (!Hive.isBoxOpen('partial_payments')) {
          // Opening box: partial_payments
          await Hive.openBox<PartialPayment>('partial_payments');
          // Successfully opened box: partial_payments
        } else {
          // Box partial_payments is already open
        }
        
        // Verify the box is working
        // Partial payments box verified
      } catch (e) {
        // Error opening box partial_payments
        try {
          await Hive.deleteBoxFromDisk('partial_payments');
          await Hive.openBox<PartialPayment>('partial_payments');
          // Successfully recreated box: partial_payments
        } catch (recreateError) {
          // Failed to recreate box partial_payments
        }
      }
      
      // All boxes verification completed
    } catch (e) {
      // Error ensuring boxes are open
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
        // Partial payments box is not open, returning empty list
        return [];
      }
      final payments = _partialPaymentBoxSafe.values.toList();
      // Loading partial payments...
      // Total partial payments loaded: ${payments.length}
      // Payments loaded successfully
      return payments;
    } catch (e) {
      // Error accessing partial payments box
      rethrow;
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
      // Getting partial payments for debt
      // Debt ID: $debtId
      // Partial payments box is open: ${Hive.isBoxOpen('partial_payments')}
      // Total partial payments in storage: ${_partialPaymentBoxSafe.length}
      // All partial payments: ${_partialPaymentBoxSafe.values.toList()}
      
      final payments = _partialPaymentBoxSafe.values.where((p) => p.debtId == debtId).toList();
      // Found ${payments.length} partial payments for debt $debtId
      return payments;
    } catch (e) {
      // Error getting partial payments
      return [];
    }
  }

  Future<void> addPartialPayment(PartialPayment payment) async {
    try {
      // Saving partial payment to storage
      // Payment ID: ${payment.id}
      // Debt ID: ${payment.debtId}
      // Amount: ${payment.amount}
      
      // Check if box is open
      // Partial payments box is open: ${Hive.isBoxOpen('partial_payments')}
      // Partial payments box length before: ${_partialPaymentBoxSafe.length}
      
      _partialPaymentBoxSafe.put(payment.id, payment);
      
      // Partial payment saved to storage successfully
      // Total partial payments in storage: ${_partialPaymentBoxSafe.length}
      // Partial payments box keys: ${_partialPaymentBoxSafe.keys.toList()}
    } catch (e) {
      // Error saving partial payment
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
      // Retrieved ${activities.length} activities
      return activities;
    } catch (e) {
      // Error retrieving activities
      rethrow;
    }
  }
  
  Future<void> addActivity(Activity activity) async {
    try {
      _activityBoxSafe.put(activity.id, activity);
    } catch (e) {
      // Handle error silently
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