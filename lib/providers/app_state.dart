import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/localization_service.dart';
import '../services/cloudkit_service.dart';
import '../services/data_export_import_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  List<ProductCategory> get categories => _categories;
  List<ProductPurchase> get productPurchases => _productPurchases;
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
    _customers = _dataService.customers;
    _debts = _dataService.debts;
    _categories = _dataService.categories;
    _productPurchases = _dataService.productPurchases;
    _currencySettings = _dataService.currencySettings;
    
    // Add mock data if no data exists
    // Temporarily force mock data loading for testing
    if (_customers.isEmpty && _debts.isEmpty && _categories.isEmpty) {
      await _loadMockData();
    }
    
    // Force mock data loading for testing (comment out in production)
    await _loadMockData();
    
    _clearCache();
    notifyListeners();
  }
  
  // Load mock data for testing
  Future<void> _loadMockData() async {
    try {
      print('Starting mock data loading...');
      // Mock Customers
      final mockCustomers = [
        Customer(
          id: 'customer_1',
          name: 'Ahmed Hassan',
          phone: '+961 70 123 456',
          email: 'ahmed.hassan@email.com',
          address: 'Beirut, Lebanon',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Customer(
          id: 'customer_2',
          name: 'Sarah Khalil',
          phone: '+961 71 234 567',
          email: 'sarah.khalil@email.com',
          address: 'Tripoli, Lebanon',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Customer(
          id: 'customer_3',
          name: 'Omar Mansour',
          phone: '+961 76 345 678',
          email: 'omar.mansour@email.com',
          address: 'Sidon, Lebanon',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Customer(
          id: 'customer_4',
          name: 'Layla Ziad',
          phone: '+961 78 456 789',
          email: 'layla.ziad@email.com',
          address: 'Tyre, Lebanon',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Customer(
          id: 'customer_5',
          name: 'Karim Fares',
          phone: '+961 79 567 890',
          email: 'karim.fares@email.com',
          address: 'Baalbek, Lebanon',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      
      // Mock Categories and Products
      final mockCategories = [
        ProductCategory(
          id: 'cat_1',
          name: 'Electronics',
          description: 'Electronic devices and accessories',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          subcategories: [
            Subcategory(
              id: 'sub_1',
              name: 'iPhone 15 Pro',
              description: 'Latest iPhone model',
              costPrice: 800.0,
              sellingPrice: 1200.0,
              createdAt: DateTime.now().subtract(const Duration(days: 40)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
            Subcategory(
              id: 'sub_2',
              name: 'Samsung Galaxy S24',
              description: 'Premium Android phone',
              costPrice: 600.0,
              sellingPrice: 900.0,
              createdAt: DateTime.now().subtract(const Duration(days: 35)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
            Subcategory(
              id: 'sub_3',
              name: 'AirPods Pro',
              description: 'Wireless earbuds',
              costPrice: 150.0,
              sellingPrice: 250.0,
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
          ],
        ),
        ProductCategory(
          id: 'cat_2',
          name: 'Clothing',
          description: 'Fashion and apparel',
          createdAt: DateTime.now().subtract(const Duration(days: 40)),
          subcategories: [
            Subcategory(
              id: 'sub_4',
              name: 'Nike Air Max',
              description: 'Premium running shoes',
              costPrice: 80.0,
              sellingPrice: 150.0,
              createdAt: DateTime.now().subtract(const Duration(days: 25)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
            Subcategory(
              id: 'sub_5',
              name: 'Adidas Tracksuit',
              description: 'Comfortable sportswear',
              costPrice: 45.0,
              sellingPrice: 85.0,
              createdAt: DateTime.now().subtract(const Duration(days: 20)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
          ],
        ),
        ProductCategory(
          id: 'cat_3',
          name: 'Home & Garden',
          description: 'Home improvement and garden supplies',
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
          subcategories: [
            Subcategory(
              id: 'sub_6',
              name: 'Garden Tools Set',
              description: 'Complete gardening toolkit',
              costPrice: 120.0,
              sellingPrice: 200.0,
              createdAt: DateTime.now().subtract(const Duration(days: 15)),
              costPriceCurrency: 'USD',
              sellingPriceCurrency: 'USD',
            ),
          ],
        ),
      ];
      
      // Mock Debts
      final mockDebts = [
        Debt(
          id: 'debt_1',
          customerId: 'customer_1',
          customerName: 'Ahmed Hassan',
          amount: 1200.0,
          description: 'iPhone 15 Pro purchase',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'Due in 7 days',
        ),
        Debt(
          id: 'debt_2',
          customerId: 'customer_2',
          customerName: 'Sarah Khalil',
          amount: 900.0,
          description: 'Samsung Galaxy S24 purchase',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          notes: 'Due in 10 days',
        ),
        Debt(
          id: 'debt_3',
          customerId: 'customer_3',
          customerName: 'Omar Mansour',
          amount: 250.0,
          description: 'AirPods Pro purchase',
          type: DebtType.credit,
          status: DebtStatus.paid,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          paidAt: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'Paid in full',
        ),
        Debt(
          id: 'debt_4',
          customerId: 'customer_4',
          customerName: 'Layla Ziad',
          amount: 150.0,
          description: 'Nike Air Max purchase',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'Due in 14 days',
        ),
        Debt(
          id: 'debt_5',
          customerId: 'customer_5',
          customerName: 'Karim Fares',
          amount: 85.0,
          description: 'Adidas Tracksuit purchase',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          notes: 'Due in 21 days',
        ),
      ];
      
      // Mock Product Purchases
      final mockPurchases = [
        ProductPurchase(
          id: 'purchase_1',
          customerId: 'customer_1',
          subcategoryId: 'sub_1',
          categoryName: 'Electronics',
          subcategoryName: 'iPhone 15 Pro',
          quantity: 1,
          costPrice: 800.0,
          sellingPrice: 1200.0,
          totalAmount: 1200.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'Customer requested installment payment',
          isPaid: false,
        ),
        ProductPurchase(
          id: 'purchase_2',
          customerId: 'customer_2',
          subcategoryId: 'sub_2',
          categoryName: 'Electronics',
          subcategoryName: 'Samsung Galaxy S24',
          quantity: 1,
          costPrice: 600.0,
          sellingPrice: 900.0,
          totalAmount: 900.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
          notes: 'Cash payment preferred',
          isPaid: false,
        ),
        ProductPurchase(
          id: 'purchase_3',
          customerId: 'customer_3',
          subcategoryId: 'sub_3',
          categoryName: 'Electronics',
          subcategoryName: 'AirPods Pro',
          quantity: 1,
          costPrice: 150.0,
          sellingPrice: 250.0,
          totalAmount: 250.0,
          purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
          notes: 'Paid in full',
          isPaid: true,
          paidAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      
      // Clear existing data first
      print('Clearing existing data...');
      for (final customer in _customers) {
        await _dataService.deleteCustomer(customer.id);
      }
      for (final debt in _debts) {
        await _dataService.deleteDebt(debt.id);
      }
      for (final category in _categories) {
        await _dataService.deleteCategory(category.id);
      }
      for (final purchase in _productPurchases) {
        await _dataService.deleteProductPurchase(purchase.id);
      }
      
      print('Adding mock customers...');
      // Add mock data to data service
      for (final customer in mockCustomers) {
        await _dataService.addCustomer(customer);
      }
      
      print('Adding mock categories...');
      for (final category in mockCategories) {
        await _dataService.addCategory(category);
      }
      
      print('Adding mock debts...');
      for (final debt in mockDebts) {
        await _dataService.addDebt(debt);
      }
      
      print('Adding mock purchases...');
      for (final purchase in mockPurchases) {
        await _dataService.addProductPurchase(purchase);
      }
      
      // Update local lists
      _customers = _dataService.customers;
      _debts = _dataService.debts;
      _categories = _dataService.categories;
      _productPurchases = _dataService.productPurchases;
      
      print('Mock data loaded successfully!');
      print('Customers loaded: ${_customers.length}');
      print('Debts loaded: ${_debts.length}');
      print('Categories loaded: ${_categories.length}');
      print('Product purchases loaded: ${_productPurchases.length}');
    } catch (e) {
      print('Error loading mock data: $e');
    }
  }
  
  // Public method to load mock data (for testing)
  Future<void> loadMockData() async {
    await _loadMockData();
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
      await _dataService.addDebt(debt);
      _debts.add(debt);
      _clearCache();
      
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

  // Apply partial payment to a debt
  Future<void> applyPartialPayment(String debtId, double paymentAmount) async {
    try {
      final index = _debts.indexWhere((d) => d.id == debtId);
      if (index != -1) {
        final originalDebt = _debts[index];
        final newPaidAmount = originalDebt.paidAmount + paymentAmount;
        final isFullyPaid = newPaidAmount >= originalDebt.amount;
        
        _debts[index] = originalDebt.copyWith(
          paidAmount: newPaidAmount,
          status: isFullyPaid ? DebtStatus.paid : DebtStatus.pending,
          paidAt: isFullyPaid ? DateTime.now() : originalDebt.paidAt,
        );
        
        await _dataService.updateDebt(_debts[index]);
        _clearCache();
        notifyListeners();
        
        // Show system notification for partial payment
        await _notificationService.showPaymentAppliedNotification(originalDebt, paymentAmount);
        
        if (_isOnline) {
          await _syncService.syncDebts([_debts[index]]);
        }
        
        // Reschedule notifications
        await _scheduleNotifications();
      }
    } catch (e) {
      print('Error applying partial payment: $e');
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

  // Generate IDs
  String generateCustomerId() {
    return _dataService.generateCustomerId();
  }

  String generateDebtId() {
    return _dataService.generateDebtId();
  }

  String generateCategoryId() {
    return _dataService.generateCategoryId();
  }

  String generateProductPurchaseId() {
    return _dataService.generateProductPurchaseId();
  }

  // Clear cache when data changes
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
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }
  
  double _calculateTotalPaid() {
    return _debts
        .where((d) => d.status == DebtStatus.paid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
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
      final totalDebt = customerDebtsList.fold<double>(0, (sum, debt) => sum + debt.amount);
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
  
  // Settings update methods
  Future<void> setDarkModeEnabled(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setSelectedLanguage(String languageCode) async {
    _language = languageCode;
    await _saveSettings();
    
    // Update localization service
    await _localizationService?.setLanguage(languageCode);
    
    notifyListeners();
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setOfflineModeEnabled(bool enabled) async {
    _offlineModeEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setIpadOptimizationsEnabled(bool enabled) async {
    _ipadOptimizationsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setBoldTextEnabled(bool enabled) async {
    _boldTextEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setICloudSyncEnabled(bool enabled) async {
    _iCloudSyncEnabled = enabled;
    await _saveSettings();
    
    if (enabled) {
      // Initialize CloudKit and perform initial sync
      try {
        await _cloudKitService.initialize();
        await _performCloudKitSync();
      } catch (e) {
        print('Error enabling iCloud sync: $e');
        // Don't disable the setting if sync fails, just log the error
      }
    }
    
    notifyListeners();
  }

  Future<void> _performCloudKitSync() async {
    if (!_iCloudSyncEnabled) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      // Sync all data to CloudKit
      await _cloudKitService.syncData(_customers, _debts);
      
      print('CloudKit sync completed successfully');
    } catch (e) {
      print('Error performing CloudKit sync: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Notification settings
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
  
  Future<void> setSelectedNotificationPriority(String priority) async {
    _notificationPriority = priority;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setSelectedQuietHoursStart(String start) async {
    _quietHoursStart = start;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setSelectedQuietHoursEnd(String end) async {
    _quietHoursEnd = end;
    await _saveSettings();
    notifyListeners();
  }
  
  // Data management settings
  Future<void> setDataValidationEnabled(bool enabled) async {
    _dataValidationEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setDuplicateDetectionEnabled(bool enabled) async {
    _duplicateDetectionEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setAuditTrailEnabled(bool enabled) async {
    _auditTrailEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setCustomReportsEnabled(bool enabled) async {
    _customReportsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setCalendarIntegrationEnabled(bool enabled) async {
    _calendarIntegrationEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setMultiDeviceSyncEnabled(bool enabled) async {
    _multiDeviceSyncEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  // Accessibility settings
  Future<void> setLargeTextEnabled(bool enabled) async {
    _largeTextEnabled = enabled;
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

  // Currency Settings methods
  Future<void> updateCurrencySettings(CurrencySettings settings) async {
    await _dataService.updateCurrencySettings(settings);
    _currencySettings = settings;
    notifyListeners();
  }

  // Convert amount using current exchange rate
  double convertAmount(double amount) {
    return _dataService.convertAmount(amount);
  }

  // Convert amount back to base currency
  double convertBack(double amount) {
    return _dataService.convertBack(amount);
  }

  // Get formatted exchange rate
  String get formattedExchangeRate {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.formattedRate;
    }
    return 'No exchange rate set';
  }

  // Get reverse formatted exchange rate
  String get reverseFormattedExchangeRate {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.reverseFormattedRate;
    }
    return 'No exchange rate set';
  }

  // Sync status methods
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _syncService.isInitialized,
      'lastSyncTime': _syncService.lastSyncTime?.toIso8601String(),
      'isSyncNeeded': _syncService.isSyncNeeded(),
      'cloudKitStatus': _cloudKitService.getSyncStatus(),
      'iCloudSyncEnabled': _iCloudSyncEnabled,
    };
  }

  Future<void> resetSyncState() async {
    await _syncService.resetSyncState();
    await _cloudKitService.resetSyncState();
  }

  // Export and Import methods
  Future<String> exportData() async {
    try {
      final filePath = await _exportImportService.exportToCSV(_customers, _debts);
      return filePath;
    } catch (e) {
      print('Error exporting data: $e');
      rethrow;
    }
  }

  Future<void> shareExportFile(String filePath) async {
    try {
      await _exportImportService.shareExportFile(filePath);
    } catch (e) {
      print('Error sharing export file: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> importData() async {
    try {
      final importData = await _exportImportService.importFromCSV();
      await _exportImportService.validateImportData(importData);
      return importData;
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }

  Future<void> applyImportedData(Map<String, dynamic> importData) async {
    try {
      final customers = importData['customers'] as List<Customer>;
      final debts = importData['debts'] as List<Debt>;

      // Clear existing data
      _customers.clear();
      _debts.clear();

      // Add imported customers
      for (final customer in customers) {
        await _dataService.addCustomer(customer);
        _customers.add(customer);
      }

      // Add imported debts
      for (final debt in debts) {
        await _dataService.addDebt(debt);
        _debts.add(debt);
      }

      _clearCache();
      notifyListeners();

      // Sync to CloudKit if enabled
      if (_iCloudSyncEnabled) {
        await _cloudKitService.syncData(_customers, _debts);
      }
    } catch (e) {
      print('Error applying imported data: $e');
      rethrow;
    }
  }

  // Clear all data method
  Future<void> clearAllData() async {
    try {
      // Clear from data service
      await _dataService.clearAllData();
      
      // Clear local lists
      _customers.clear();
      _debts.clear();
      
      // Clear cache
      _clearCache();
      
      // Notify listeners
      notifyListeners();
      
      // Clear from CloudKit if enabled
      if (_iCloudSyncEnabled) {
        await _cloudKitService.clearAllData();
      }
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  // Cache management methods
  Future<void> clearAppCache() async {
    try {
      // Clear Hive cache
      await _dataService.clearCache();
      
      // Clear any temporary files
      await _clearTemporaryFiles();
      
      // Clear cache
      _clearCache();
      
      notifyListeners();
    } catch (e) {
      print('Error clearing app cache: $e');
      rethrow;
    }
  }

  Future<void> _clearTemporaryFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error clearing temporary files: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheInfo = await _dataService.getCacheInfo();
      final tempInfo = await _getTemporaryFilesInfo();
      
      return {
        'hiveCache': cacheInfo,
        'temporaryFiles': tempInfo,
        'totalSize': (cacheInfo['size'] ?? 0) + (tempInfo['size'] ?? 0),
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {
        'hiveCache': {'size': 0, 'items': 0},
        'temporaryFiles': {'size': 0, 'items': 0},
        'totalSize': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getTemporaryFilesInfo() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      int totalSize = 0;
      int itemCount = 0;
      
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
          itemCount++;
        }
      }
      
      return {
        'size': totalSize,
        'items': itemCount,
      };
    } catch (e) {
      print('Error getting temporary files info: $e');
      return {'size': 0, 'items': 0};
    }
  }
} 