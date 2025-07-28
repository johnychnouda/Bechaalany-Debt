import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';
import '../models/partial_payment.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/localization_service.dart';
import '../services/cloudkit_service.dart';
import '../services/data_export_import_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
  final CloudKitService _cloudKitService = CloudKitService();
  final DataExportImportService _exportImportService = DataExportImportService();
  LocalizationService? _localizationService;
  
  // Data
  List<Customer> _customers = [];
  List<Debt> _debts = [];
  List<ProductCategory> _categories = [];
  List<ProductPurchase> _productPurchases = [];
  List<Activity> _activities = [];
  List<PartialPayment> _partialPayments = [];
  CurrencySettings? _currencySettings;
  
  // Loading states
  bool _isLoading = false;
  bool _isSyncing = false;
  
  // Connectivity
  bool _isOnline = true;
  
  // App Settings
  bool _isDarkMode = false;
  String _language = 'en';
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  bool _biometricEnabled = false;
  bool _offlineModeEnabled = false;
  bool _ipadOptimizationsEnabled = false;
  bool _boldTextEnabled = false;
  bool _iCloudSyncEnabled = false;
  
  // Notification Settings
  bool _paymentDueRemindersEnabled = true;
  bool _weeklyReportsEnabled = false;
  bool _monthlyReportsEnabled = true;
  bool _quietHoursEnabled = false;
  String _notificationPriority = 'Normal';
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  
  // Data Management Settings
  bool _dataValidationEnabled = true;
  bool _duplicateDetectionEnabled = true;
  bool _auditTrailEnabled = true;
  bool _customReportsEnabled = false;
  bool _calendarIntegrationEnabled = false;
  bool _multiDeviceSyncEnabled = true;
  
  // Accessibility Settings
  bool _largeTextEnabled = false;
  bool _reduceMotionEnabled = false;
  String _textSize = 'Medium'; // Small, Medium, Large, Extra Large
  
  // Cached calculations
  double? _cachedTotalDebt;
  double? _cachedTotalPaid;
  int? _cachedPendingCount;
  List<Debt>? _cachedRecentDebts;
  List<Customer>? _cachedTopDebtors;
  
  // Getters
  List<Customer> get customers => _customers;
  List<Debt> get debts => _debts;

  List<PartialPayment> get partialPayments => _partialPayments;
  List<ProductCategory> get categories => _categories;
  List<ProductPurchase> get productPurchases => _productPurchases;
  List<Activity> get activities => _activities;
  CurrencySettings? get currencySettings => _currencySettings;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  
  // App Settings Getters
  bool get isDarkMode => _isDarkMode;
  bool get darkModeEnabled => _isDarkMode;
  String get language => _language;
  String get selectedLanguage => _localizationService?.currentLanguageName ?? 'English';
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  bool get ipadOptimizationsEnabled => _ipadOptimizationsEnabled;
  bool get boldTextEnabled => _boldTextEnabled;
  bool get iCloudSyncEnabled => _iCloudSyncEnabled;
  
  // Notification Settings Getters
  bool get paymentDueRemindersEnabled => _paymentDueRemindersEnabled;
  bool get weeklyReportsEnabled => _weeklyReportsEnabled;
  bool get monthlyReportsEnabled => _monthlyReportsEnabled;
  bool get quietHoursEnabled => _quietHoursEnabled;
  String get notificationPriority => _notificationPriority;
  String get selectedNotificationPriority => _notificationPriority;
  String get quietHoursStart => _quietHoursStart;
  String get selectedQuietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;
  String get selectedQuietHoursEnd => _quietHoursEnd;
  
  // Data Management Settings Getters
  bool get dataValidationEnabled => _dataValidationEnabled;
  bool get duplicateDetectionEnabled => _duplicateDetectionEnabled;
  bool get auditTrailEnabled => _auditTrailEnabled;
  bool get customReportsEnabled => _customReportsEnabled;
  bool get calendarIntegrationEnabled => _calendarIntegrationEnabled;
  bool get multiDeviceSyncEnabled => _multiDeviceSyncEnabled;
  
  // Accessibility Settings Getters
  bool get largeTextEnabled => _largeTextEnabled;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  String get textSize => _textSize;
  
  // Cached getters
  double get totalDebt {
    _cachedTotalDebt ??= _calculateTotalDebt();
    return _cachedTotalDebt!;
  }
  
  double get totalPaid {
    _cachedTotalPaid ??= _calculateTotalPaid();
    return _cachedTotalPaid!;
  }
  
  int get pendingDebtsCount {
    _cachedPendingCount ??= _calculatePendingCount();
    return _cachedPendingCount!;
  }
  
  int get totalCustomersCount {
    return _customers.length;
  }
  
  double get averageDebtAmount {
    final pendingDebts = _debts.where((d) => d.status == DebtStatus.pending).toList();
    if (pendingDebts.isEmpty) return 0.0;
    final totalAmount = pendingDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    return totalAmount / pendingDebts.length;
  }
  
  List<Debt> get recentDebts {
    _cachedRecentDebts ??= _calculateRecentDebts();
    return _cachedRecentDebts!;
  }
  
  List<Customer> get topDebtors {
    _cachedTopDebtors ??= _calculateTopDebtors();
    return _cachedTopDebtors!;
  }
  
  // Initialize the app state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load settings first
      await _loadSettings();
      
      // Initialize services
      await _notificationService.initialize();
      await _syncService.initialize();
      
      // Load data
      await _loadData();
      
      // Clean up existing debt descriptions (remove "Qty: x" text)
      await cleanUpDebtDescriptions();
      
      // Setup connectivity listener
      _setupConnectivityListener();
      
      // Schedule notifications
      await _scheduleNotifications();
      
    } catch (e) {
      print('Error initializing app state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set localization service reference
  void setLocalizationService(LocalizationService service) {
    _localizationService = service;
  }
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _language = prefs.getString('language') ?? 'en';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? true;
      _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      _offlineModeEnabled = prefs.getBool('offlineModeEnabled') ?? false;
      _ipadOptimizationsEnabled = prefs.getBool('ipadOptimizationsEnabled') ?? false;
      _boldTextEnabled = prefs.getBool('boldTextEnabled') ?? false;
      _iCloudSyncEnabled = prefs.getBool('iCloudSyncEnabled') ?? false;
      
      // Notification settings
      _paymentDueRemindersEnabled = prefs.getBool('paymentDueRemindersEnabled') ?? true;
      _weeklyReportsEnabled = prefs.getBool('weeklyReportsEnabled') ?? false;
      _monthlyReportsEnabled = prefs.getBool('monthlyReportsEnabled') ?? true;
      _quietHoursEnabled = prefs.getBool('quietHoursEnabled') ?? false;
      _notificationPriority = prefs.getString('notificationPriority') ?? 'Normal';
      _quietHoursStart = prefs.getString('quietHoursStart') ?? '22:00';
      _quietHoursEnd = prefs.getString('quietHoursEnd') ?? '08:00';
      
      // Data management settings
      _dataValidationEnabled = prefs.getBool('dataValidationEnabled') ?? true;
      _duplicateDetectionEnabled = prefs.getBool('duplicateDetectionEnabled') ?? true;
      _auditTrailEnabled = prefs.getBool('auditTrailEnabled') ?? true;
      _customReportsEnabled = prefs.getBool('customReportsEnabled') ?? false;
      _calendarIntegrationEnabled = prefs.getBool('calendarIntegrationEnabled') ?? false;
      _multiDeviceSyncEnabled = prefs.getBool('multiDeviceSyncEnabled') ?? true;
      
      // Accessibility settings
      _largeTextEnabled = prefs.getBool('largeTextEnabled') ?? false;
      _reduceMotionEnabled = prefs.getBool('reduceMotionEnabled') ?? false;
      _textSize = prefs.getString('textSize') ?? 'Medium';
      
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setString('language', _language);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('autoSyncEnabled', _autoSyncEnabled);
      await prefs.setBool('biometricEnabled', _biometricEnabled);
      await prefs.setBool('offlineModeEnabled', _offlineModeEnabled);
      await prefs.setBool('ipadOptimizationsEnabled', _ipadOptimizationsEnabled);
      await prefs.setBool('boldTextEnabled', _boldTextEnabled);
      await prefs.setBool('iCloudSyncEnabled', _iCloudSyncEnabled);
      
      // Notification settings
      await prefs.setBool('paymentDueRemindersEnabled', _paymentDueRemindersEnabled);
      await prefs.setBool('weeklyReportsEnabled', _weeklyReportsEnabled);
      await prefs.setBool('monthlyReportsEnabled', _monthlyReportsEnabled);
      await prefs.setBool('quietHoursEnabled', _quietHoursEnabled);
      await prefs.setString('notificationPriority', _notificationPriority);
      await prefs.setString('quietHoursStart', _quietHoursStart);
      await prefs.setString('quietHoursEnd', _quietHoursEnd);
      
      // Data management settings
      await prefs.setBool('dataValidationEnabled', _dataValidationEnabled);
      await prefs.setBool('duplicateDetectionEnabled', _duplicateDetectionEnabled);
      await prefs.setBool('auditTrailEnabled', _auditTrailEnabled);
      await prefs.setBool('customReportsEnabled', _customReportsEnabled);
      await prefs.setBool('calendarIntegrationEnabled', _calendarIntegrationEnabled);
      await prefs.setBool('multiDeviceSyncEnabled', _multiDeviceSyncEnabled);
      
      // Accessibility settings
      await prefs.setBool('largeTextEnabled', _largeTextEnabled);
      await prefs.setBool('reduceMotionEnabled', _reduceMotionEnabled);
      await prefs.setString('textSize', _textSize);
      
    } catch (e) {
      print('Error saving settings: $e');
    }
  }
  
  // Load data from local storage
  Future<void> _loadData() async {
    try {
      _customers = _dataService.customers;
      _debts = _dataService.debts;
      _categories = _dataService.categories;
      _productPurchases = _dataService.productPurchases;
      _activities = _dataService.activities;
      _partialPayments = _dataService.partialPayments;
      _currencySettings = _dataService.currencySettings;
    } catch (e) {
      print('Error loading data: $e');
      // Initialize with empty lists if there's an error
      _customers = [];
      _debts = [];
      _categories = [];
      _productPurchases = [];
      _activities = [];
      _partialPayments = [];
      _currencySettings = null;
    }
    
    // Debug: Print data counts
    print('Loaded data:');
    print('- Customers: ${_customers.length}');
    print('- Debts: ${_debts.length}');
    print('- Activities: ${_activities.length}');
    print('- Categories: ${_categories.length}');
    print('- Product Purchases: ${_productPurchases.length}');
    print('- Partial Payments: ${_partialPayments.length}');
    
    _clearCache();
    notifyListeners();
  }
  

  
  // Setup connectivity monitoring
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _syncData();
      }
      notifyListeners();
    });
  }
  
  // Sync data with cloud
  Future<void> _syncData() async {
    if (!_isOnline) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      await _syncService.syncData(_customers, _debts);
    } catch (e) {
      print('Error syncing data: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Schedule notifications for due/overdue debts
  Future<void> _scheduleNotifications() async {
    if (!_notificationsEnabled) return;
    
    final pendingDebts = _debts.where((debt) => debt.status == DebtStatus.pending).toList();
    
    await _notificationService.scheduleDebtReminders(pendingDebts);
  }
  
  // Customer operations
  Future<void> addCustomer(Customer customer) async {
    try {
      await _dataService.addCustomer(customer);
      _customers.add(customer);
      _clearCache();
      
      // Sync to CloudKit if enabled
      // if (_iCloudSyncEnabled) {
      //   await _cloudKitService.syncCustomers(_customers);
      // }
      
      notifyListeners();
      
      // Show system notification
      await _notificationService.showCustomerAddedNotification(customer);
      
      if (_isOnline) {
        await _syncService.syncCustomers([customer]);
      }
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }
  
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dataService.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _clearCache();
        
        // Sync to CloudKit if enabled
        // if (_iCloudSyncEnabled) {
        //   await _cloudKitService.syncCustomers(_customers);
        // }
        
        notifyListeners();
        
        // Show system notification
        await _notificationService.showCustomerUpdatedNotification(customer);
      }
      
      if (_isOnline) {
        await _syncService.syncCustomers([customer]);
      }
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }
  
  Future<void> deleteCustomer(String customerId) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      await _dataService.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.id == customerId);
      _debts.removeWhere((d) => d.customerId == customerId);
      _clearCache();
      
      // Sync to CloudKit if enabled
      if (_iCloudSyncEnabled) {
        await _cloudKitService.deleteCustomer(customerId);
      }
      
      notifyListeners();
      
      // Show system notification
      await _notificationService.showCustomerDeletedNotification(customer.name);
      
      if (_isOnline) {
        await _syncService.deleteCustomer(customerId);
      }
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }
  
  // Debt operations
  Future<void> addDebt(Debt debt) async {
    try {
      // Check if customer has existing partially paid debts (not fully paid)
      final existingPartiallyPaidDebts = _debts.where((d) => 
        d.customerId == debt.customerId && 
        d.paidAmount > 0 && d.paidAmount < d.amount
      ).toList();
      
      if (existingPartiallyPaidDebts.isNotEmpty) {
        // Add to existing partially paid debt's remaining balance
        final existingDebt = existingPartiallyPaidDebts.first;
        final newTotalAmount = existingDebt.amount + debt.amount;
        final newDescription = existingDebt.description.isEmpty 
            ? debt.description 
            : '${existingDebt.description} + ${debt.description}';
        
        final updatedDebt = existingDebt.copyWith(
          amount: newTotalAmount,
          description: newDescription,
          // Keep the original createdAt timestamp
          // Update paidAt to reflect the latest activity (when debt was modified)
          paidAt: DateTime.now(),
          // Status remains the same (partially paid)
        );
        
        await _dataService.updateDebt(updatedDebt);
        final index = _debts.indexWhere((d) => d.id == existingDebt.id);
        if (index != -1) {
          _debts[index] = updatedDebt;
        }
        
        // Also create a new pending debt for the new amount
        final newPendingDebt = debt.copyWith(
          createdAt: DateTime.now(),
        );
        
        await _dataService.addDebt(newPendingDebt);
        _debts.add(newPendingDebt);
        
        _clearCache();
        
        // Track activity for the addition
        await addDebtActivity(debt);
        
        // Sync to CloudKit if enabled
        if (_iCloudSyncEnabled) {
          await _cloudKitService.syncDebts(_debts);
        }
        
        notifyListeners();
        
        // Show system notification
        await _notificationService.showDebtAddedNotification(debt);
        
        if (_isOnline) {
          await _syncService.syncDebts([updatedDebt, newPendingDebt]);
        }
        
        // Reschedule notifications
        await _scheduleNotifications();
      } else {
        // No existing partially paid debts, create new debt as pending
        await _dataService.addDebt(debt);
        _debts.add(debt);
        _clearCache();
        
        // Track activity
        await addDebtActivity(debt);
        
        // Sync to CloudKit if enabled
        if (_iCloudSyncEnabled) {
          await _cloudKitService.syncDebts(_debts);
        }
        
        notifyListeners();
        
        // Show system notification
        await _notificationService.showDebtAddedNotification(debt);
        
        if (_isOnline) {
          await _syncService.syncDebts([debt]);
        }
        
        // Reschedule notifications
        await _scheduleNotifications();
      }
    } catch (e) {
      print('Error adding debt: $e');
      rethrow;
    }
  }
  
    Future<void> updateDebt(Debt debt) async {
    try {
      await _dataService.updateDebt(debt);
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt;
        _clearCache();
        
        // Sync to CloudKit if enabled
        if (_iCloudSyncEnabled) {
          await _cloudKitService.syncDebts(_debts);
        }
        
        notifyListeners();
        
        // Show system notification
        await _notificationService.showDebtUpdatedNotification(debt);
      }
      
      if (_isOnline) {
        await _syncService.syncDebts([debt]);
      }
      
      // Reschedule notifications
      await _scheduleNotifications();
    } catch (e) {
      print('Error updating debt: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == debtId);
      await _dataService.deleteDebt(debtId);
      _debts.removeWhere((d) => d.id == debtId);
      _clearCache();
      notifyListeners();
      
      // Track debt cleared activity
      await addDebtClearedActivity(debt);
      
      // Show system notification
      await _notificationService.showDebtDeletedNotification(debt.customerName, debt.amount);
      
      if (_isOnline) {
        await _syncService.deleteDebt(debtId);
      }
    } catch (e) {
      print('Error deleting debt: $e');
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      await _dataService.markDebtAsPaid(debtId);
      final index = _debts.indexWhere((d) => d.id == debtId);
      if (index != -1) {
        final originalDebt = _debts[index];
        _debts[index] = _debts[index].copyWith(
          status: DebtStatus.paid,
          paidAmount: _debts[index].amount,
          paidAt: DateTime.now(),
        );
        _clearCache();
        notifyListeners();
        
        // Track payment activity
        await addPaymentActivity(originalDebt, originalDebt.amount, DebtStatus.pending, DebtStatus.paid);
        
        // Show system notification
        await _notificationService.showDebtPaidNotification(originalDebt);
      }
      
      if (_isOnline) {
        await _syncService.syncDebts([_debts[index]]);
      }
      
      // Reschedule notifications
      await _scheduleNotifications();
    } catch (e) {
      print('Error marking debt as paid: $e');
      rethrow;
    }
  }

  Future<void> applyPartialPayment(String debtId, double paymentAmount) async {
    try {
      final index = _debts.indexWhere((debt) => debt.id == debtId);
      
      if (index == -1) {
        return;
      }

      final originalDebt = _debts[index];
      
      // Create a new partial payment record
      final partialPayment = PartialPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        debtId: debtId,
        amount: paymentAmount,
        paidAt: DateTime.now(),
      );
      
      // Add the partial payment to storage
      await _dataService.addPartialPayment(partialPayment);
      _partialPayments.add(partialPayment);
      
      // Calculate total paid amount from all partial payments
      final allPartialPayments = _dataService.getPartialPaymentsByDebt(debtId);
      final totalPaidAmount = allPartialPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      
      final isFullyPaid = totalPaidAmount >= originalDebt.amount;
      
      // Update the debt with the new total paid amount
      _debts[index] = originalDebt.copyWith(
        paidAmount: totalPaidAmount,
        status: isFullyPaid ? DebtStatus.paid : DebtStatus.pending,
        paidAt: DateTime.now(), // Update to latest payment time
      );
      
      await _dataService.updateDebt(_debts[index]);
      _clearCache();
      notifyListeners();
      
      // Track payment activity
      await addPaymentActivity(originalDebt, paymentAmount, originalDebt.status, _debts[index].status);
      
      // Show system notification for partial payment
      await _notificationService.showPaymentAppliedNotification(originalDebt, paymentAmount);
      
      if (_isOnline) {
        await _syncService.syncDebts([_debts[index]]);
      }
      
      // Reschedule notifications
      await _scheduleNotifications();
    } catch (e) {
      rethrow;
    }
  }

  // Category operations
  Future<void> addCategory(ProductCategory category) async {
    try {
      await _dataService.addCategory(category);
      _categories.add(category);
      _clearCache();
      notifyListeners();
      
      // Show notification
      await _notificationService.showCategoryAddedNotification(category.name);
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(ProductCategory category) async {
    try {
      await _dataService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        _clearCache();
        notifyListeners();
        
        // Show notification
        await _notificationService.showCategoryUpdatedNotification(category.name);
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Get category name before deletion for notification
      final category = _categories.firstWhere((c) => c.id == categoryId);
      final categoryName = category.name;
      
      await _dataService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _clearCache();
      notifyListeners();
      
      // Show notification
      await _notificationService.showCategoryDeletedNotification(categoryName);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> deleteSubcategory(String categoryId, String subcategoryId) async {
    try {
      final categoryIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (categoryIndex != -1) {
        final category = _categories[categoryIndex];
        final updatedSubcategories = category.subcategories.where((s) => s.id != subcategoryId).toList();
        final updatedCategory = category.copyWith(subcategories: updatedSubcategories);
        
        await _dataService.updateCategory(updatedCategory);
        _categories[categoryIndex] = updatedCategory;
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting subcategory: $e');
      rethrow;
    }
  }

  // Product Purchase operations
  Future<void> addProductPurchase(ProductPurchase purchase) async {
    try {
      await _dataService.addProductPurchase(purchase);
      _productPurchases.add(purchase);
      _clearCache();
      notifyListeners();
      
      // Show notification
      await _notificationService.showProductPurchaseAddedNotification(purchase.subcategoryName);
    } catch (e) {
      print('Error adding product purchase: $e');
      rethrow;
    }
  }

  Future<void> updateProductPurchase(ProductPurchase purchase) async {
    try {
      await _dataService.updateProductPurchase(purchase);
      final index = _productPurchases.indexWhere((p) => p.id == purchase.id);
      if (index != -1) {
        _productPurchases[index] = purchase;
        _clearCache();
        notifyListeners();
        
              // Show notification
      await _notificationService.showProductPurchaseUpdatedNotification(purchase.subcategoryName);
      }
    } catch (e) {
      print('Error updating product purchase: $e');
      rethrow;
    }
  }

  Future<void> deleteProductPurchase(String purchaseId) async {
    try {
      // Get purchase name before deletion for notification
      final purchase = _productPurchases.firstWhere((p) => p.id == purchaseId);
      final purchaseName = purchase.subcategoryName;
      
      await _dataService.deleteProductPurchase(purchaseId);
      _productPurchases.removeWhere((p) => p.id == purchaseId);
      _clearCache();
      notifyListeners();
      
      // Show notification
      await _notificationService.showProductPurchaseDeletedNotification(purchaseName);
    } catch (e) {
      print('Error deleting product purchase: $e');
      rethrow;
    }
  }

  Future<void> markProductPurchaseAsPaid(String purchaseId) async {
    try {
      await _dataService.markProductPurchaseAsPaid(purchaseId);
      final index = _productPurchases.indexWhere((p) => p.id == purchaseId);
      if (index != -1) {
        _productPurchases[index] = _productPurchases[index].copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
        );
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking product purchase as paid: $e');
      rethrow;
    }
  }
  
  // Manual refresh
  Future<void> refresh() async {
    await _loadData();
    if (_isOnline) {
      await _syncData();
    }
  }

  // Debug method to check current data state
  void debugPrintDataState() {
    // This method is intentionally left empty to avoid console spam
    // Remove all debug prints for production
  }

  // Clean up existing debt descriptions by removing "Qty: x" text
  Future<void> cleanUpDebtDescriptions() async {
    try {
      print('=== Cleaning up debt descriptions ===');
      int updatedCount = 0;
      
      for (final debt in _debts) {
        if (debt.description.contains(' - Qty:')) {
          final cleanedDescription = debt.description.split(' - Qty:')[0];
          final updatedDebt = debt.copyWith(description: cleanedDescription);
          
          await _dataService.updateDebt(updatedDebt);
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          }
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) {
        _clearCache();
        notifyListeners();
        print('Updated $updatedCount debt descriptions');
      } else {
        print('No debt descriptions needed cleaning');
      }
    } catch (e) {
      print('Error cleaning up debt descriptions: $e');
    }
  }

  // Generate unique IDs
  String generateCustomerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String generateDebtId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String generateCategoryId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String generateProductPurchaseId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Currency conversion methods
  double convertAmount(double amount) {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.convertAmount(amount);
    }
    return amount; // Return original amount if no settings
  }

  double convertBack(double amount) {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.convertBack(amount);
    }
    return amount; // Return original amount if no settings
  }

  // Cache management methods
  Future<void> clearCache() async {
    try {
      // Clear Hive cache by compacting boxes
      await _dataService.clearAllData();
      
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<String> exportData() async {
    try {
      final filePath = await _exportImportService.exportToCSV(_customers, _debts);
      return filePath;
    } catch (e) {
      print('Error exporting data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      int totalSize = 0;
      int totalItems = 0;
      
      // Calculate size for each data type
      totalSize += (_customers.length * 0.5).round(); // KB per customer
      totalItems += _customers.length;
      
      totalSize += (_debts.length * 0.3).round(); // KB per debt
      totalItems += _debts.length;
      
      totalSize += (_categories.length * 0.2).round(); // KB per category
      totalItems += _categories.length;
      
      totalSize += (_productPurchases.length * 0.4).round(); // KB per purchase
      totalItems += _productPurchases.length;
      
      return {
        'size': totalSize,
        'items': totalItems,
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {'size': 0, 'items': 0};
    }
  }

  // Activity tracking methods
  Future<void> _addActivity(Activity activity) async {
    try {
      await _dataService.addActivity(activity);
      _activities.add(activity);
      notifyListeners();
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }

  Future<void> addDebtActivity(Debt debt) async {
    final activity = Activity(
      id: 'activity_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
      date: debt.createdAt,
      type: ActivityType.newDebt,
      customerName: debt.customerName,
      customerId: debt.customerId,
      description: debt.description,
      amount: debt.amount,
      debtId: debt.id,
    );
    await _addActivity(activity);
  }

  Future<void> addPaymentActivity(Debt debt, double paymentAmount, DebtStatus oldStatus, DebtStatus newStatus) async {
    final activity = Activity(
      id: 'activity_payment_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      type: ActivityType.payment,
      customerName: debt.customerName,
      customerId: debt.customerId,
      description: debt.description,
      amount: debt.amount,
      paymentAmount: paymentAmount,
      oldStatus: oldStatus,
      newStatus: newStatus,
      debtId: debt.id,
    );
    await _addActivity(activity);
  }

  Future<void> addDebtClearedActivity(Debt debt) async {
    final activity = Activity(
      id: 'activity_cleared_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      type: ActivityType.debtCleared,
      customerName: debt.customerName,
      customerId: debt.customerId,
      description: debt.description,
      amount: debt.amount,
      debtId: debt.id,
    );
    await _addActivity(activity);
  }

  // Settings methods
  Future<void> setDarkModeEnabled(bool enabled) async {
    _isDarkMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBoldTextEnabled(bool enabled) async {
    _boldTextEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setReduceMotionEnabled(bool enabled) async {
    _reduceMotionEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTextSize(String size) async {
    _textSize = size;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setPaymentDueRemindersEnabled(bool enabled) async {
    _paymentDueRemindersEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setWeeklyReportsEnabled(bool enabled) async {
    _weeklyReportsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMonthlyReportsEnabled(bool enabled) async {
    _monthlyReportsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    _quietHoursEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setICloudSyncEnabled(bool enabled) async {
    _iCloudSyncEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // Cache management
  void _clearCache() {
    _cachedTotalDebt = null;
    _cachedTotalPaid = null;
    _cachedPendingCount = null;
    _cachedRecentDebts = null;
    _cachedTopDebtors = null;
  }

  // Calculation methods
  double _calculateTotalDebt() {
    return _debts
        .where((d) => d.status == DebtStatus.pending)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }
  
  double _calculateTotalPaid() {
    return _debts
        .where((d) => d.status == DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.paidAmount);
  }
  
  int _calculatePendingCount() {
    return _debts.where((d) => d.status == DebtStatus.pending).length;
  }
  
  List<Debt> _calculateRecentDebts() {
    final sortedDebts = List<Debt>.from(_debts);
    sortedDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedDebts.take(5).toList();
  }
  
  List<Customer> _calculateTopDebtors() {
    final Map<String, double> customerDebts = {};
    for (final customer in _customers) {
      final customerDebtsList = _debts.where((debt) => 
        debt.customerId == customer.id && debt.status != DebtStatus.paid
      ).toList();
      final totalDebt = customerDebtsList.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      if (totalDebt > 0) {
        customerDebts[customer.id] = totalDebt;
      }
    }
    
    final sortedCustomers = _customers.where((customer) => 
      customerDebts.containsKey(customer.id)
    ).toList()
      ..sort((a, b) => customerDebts[b.id]!.compareTo(customerDebts[a.id]!));
    
    return sortedCustomers.take(5).toList();
  }
} 