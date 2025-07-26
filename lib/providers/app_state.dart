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

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
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
      notifyListeners();
      
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
        notifyListeners();
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
      await _dataService.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.id == customerId);
      _debts.removeWhere((d) => d.customerId == customerId);
      _clearCache();
      notifyListeners();
      
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
      notifyListeners();
      
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
        notifyListeners();
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
      await _dataService.deleteDebt(debtId);
      _debts.removeWhere((d) => d.id == debtId);
      _clearCache();
      notifyListeners();
      
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
        _debts[index] = _debts[index].copyWith(
          status: DebtStatus.paid,
          paidAmount: _debts[index].amount,
          paidAt: DateTime.now(),
        );
        _clearCache();
        notifyListeners();
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

  // Category operations
  Future<void> addCategory(ProductCategory category) async {
    try {
      await _dataService.addCategory(category);
      _categories.add(category);
      _clearCache();
      notifyListeners();
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
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dataService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _clearCache();
      notifyListeners();
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
      }
    } catch (e) {
      print('Error updating product purchase: $e');
      rethrow;
    }
  }

  Future<void> deleteProductPurchase(String purchaseId) async {
    try {
      await _dataService.deleteProductPurchase(purchaseId);
      _productPurchases.removeWhere((p) => p.id == purchaseId);
      _clearCache();
      notifyListeners();
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
} 