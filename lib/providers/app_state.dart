import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

import '../services/cloudkit_service.dart';
import '../services/data_export_import_service.dart';
import '../services/ios18_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
  final CloudKitService _cloudKitService = CloudKitService();
  final DataExportImportService _exportImportService = DataExportImportService();
  final IOS18Service _ios18Service = IOS18Service();

  
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
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  bool _biometricEnabled = false;
  bool _appLockEnabled = false;
  bool _offlineModeEnabled = false;
  bool _ipadOptimizationsEnabled = false;
  bool _boldTextEnabled = false;
  bool _iCloudSyncEnabled = false;
  String _accentColor = 'blue';
  String _reminderFrequency = '3_days';
  
  // New Business Settings
  String _defaultCurrency = 'USD';
  String _receiptTemplate = 'simple';
  String _businessHours = '9_18';
  String _backupFrequency = 'weekly';
  List<String> _quickActions = ['add_debt', 'add_customer'];
  String _quietHours = '22_08';
  
  // Notification Settings
  bool _paymentDueRemindersEnabled = true;
  bool _weeklyReportsEnabled = false;
  bool _monthlyReportsEnabled = true;
  bool _quietHoursEnabled = false;
  bool _liveActivitiesEnabled = false;
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
  
  // iOS 18+ Integration Settings
  bool _widgetsEnabled = false;
  bool _focusModeEnabled = false;
  bool _shortcutsEnabled = false;
  bool _dynamicIslandEnabled = false;
  bool _smartStackEnabled = false;
  bool _aiFeaturesEnabled = false;
  
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
  String get selectedLanguage => 'English';
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get appLockEnabled => _appLockEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  bool get ipadOptimizationsEnabled => _ipadOptimizationsEnabled;
  bool get boldTextEnabled => _boldTextEnabled;
  bool get iCloudSyncEnabled => _iCloudSyncEnabled;
  String get accentColor => _accentColor;
  String get reminderFrequency => _reminderFrequency;
  
  // New Business Settings Getters
  String get defaultCurrency => _defaultCurrency;
  String get receiptTemplate => _receiptTemplate;
  String get businessHours => _businessHours;
  String get backupFrequency => _backupFrequency;
  List<String> get quickActions => _quickActions;
  String get quietHours => _quietHours;
  
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
  bool get liveActivitiesEnabled => _liveActivitiesEnabled;
  
  // Data Management Settings Getters
  bool get dataValidationEnabled => _dataValidationEnabled;
  bool get duplicateDetectionEnabled => _duplicateDetectionEnabled;
  bool get auditTrailEnabled => _auditTrailEnabled;
  bool get customReportsEnabled => _customReportsEnabled;
  bool get calendarIntegrationEnabled => _calendarIntegrationEnabled;
  bool get multiDeviceSyncEnabled => _multiDeviceSyncEnabled;
  
  // iOS 18+ Integration Settings Getters
  bool get widgetsEnabled => _widgetsEnabled;
  bool get focusModeEnabled => _focusModeEnabled;
  bool get shortcutsEnabled => _shortcutsEnabled;
  bool get dynamicIslandEnabled => _dynamicIslandEnabled;
  bool get smartStackEnabled => _smartStackEnabled;
  bool get aiFeaturesEnabled => _aiFeaturesEnabled;
  
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
    final pendingDebts = _debts.where((d) => d.paidAmount == 0).toList();
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

  // Get total historical payments for a customer (including deleted debts)
  double getCustomerTotalHistoricalPayments(String customerId) {
    // Get payments from activities
    final paymentActivities = _activities.where((a) => 
      a.customerId == customerId && 
      a.type == ActivityType.payment
    ).toList();
    
    // Get payments from partial payments
    final partialPayments = _partialPayments.where((p) {
      final debt = _debts.firstWhere(
        (d) => d.id == p.debtId,
        orElse: () => Debt(
          id: '',
          customerId: '',
          customerName: '',
          description: '',
          amount: 0,
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      return debt.customerId == customerId;
    }).toList();
    
    final totalFromActivities = paymentActivities.fold(0.0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
    final totalFromPartialPayments = partialPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    
    return totalFromActivities + totalFromPartialPayments;
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
      await _ios18Service.initialize();
      
      // Ensure all Hive boxes are open
      await _dataService.ensureBoxesOpen();
      
      // Wait a moment to ensure boxes are fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Load data
      await _loadData();
      
      // Clean up existing debt descriptions (remove "Qty: x" text)
      await cleanUpDebtDescriptions();
      
      // AUTOMATICALLY create missing payment activities for existing paid debts
      await createMissingPaymentActivitiesForAllPaidDebts();
      
      // Clean up invalid activities
      await _cleanupInvalidActivities();
      
      // Remove specific problematic activities
      await removeActivitiesByCustomerAndAmount('Johny Chnouda', 400.0);
      
      // Setup connectivity listener
      _setupConnectivityListener();
      
      // Schedule notifications
      await _scheduleNotifications();
      
    } catch (e) {
      // Handle error silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  

  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? true;
      _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      _appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
      _offlineModeEnabled = prefs.getBool('offlineModeEnabled') ?? false;
      _ipadOptimizationsEnabled = prefs.getBool('ipadOptimizationsEnabled') ?? false;
      _boldTextEnabled = prefs.getBool('boldTextEnabled') ?? false;
      _iCloudSyncEnabled = prefs.getBool('iCloudSyncEnabled') ?? false;
      _accentColor = prefs.getString('accentColor') ?? 'blue';
      _reminderFrequency = prefs.getString('reminderFrequency') ?? '3_days';
      
      // New Business Settings
      _defaultCurrency = prefs.getString('defaultCurrency') ?? 'USD';
      _receiptTemplate = prefs.getString('receiptTemplate') ?? 'simple';
      _businessHours = prefs.getString('businessHours') ?? '9_18';
      _backupFrequency = prefs.getString('backupFrequency') ?? 'weekly';
      _quietHours = prefs.getString('quietHours') ?? '22_08';
      _quickActions = prefs.getStringList('quickActions') ?? ['add_debt', 'add_customer'];
      
      // Notification settings
      _paymentDueRemindersEnabled = prefs.getBool('paymentDueRemindersEnabled') ?? true;
      _weeklyReportsEnabled = prefs.getBool('weeklyReportsEnabled') ?? false;
      _monthlyReportsEnabled = prefs.getBool('monthlyReportsEnabled') ?? true;
      _quietHoursEnabled = prefs.getBool('quietHoursEnabled') ?? false;
      _liveActivitiesEnabled = prefs.getBool('liveActivitiesEnabled') ?? false;
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
      
      // iOS 18+ Integration settings
      _widgetsEnabled = prefs.getBool('widgetsEnabled') ?? false;
      _focusModeEnabled = prefs.getBool('focusModeEnabled') ?? false;
      _shortcutsEnabled = prefs.getBool('shortcutsEnabled') ?? false;
      _dynamicIslandEnabled = prefs.getBool('dynamicIslandEnabled') ?? false;
      _smartStackEnabled = prefs.getBool('smartStackEnabled') ?? false;
      _aiFeaturesEnabled = prefs.getBool('aiFeaturesEnabled') ?? false;
      
      // Accessibility settings
      _largeTextEnabled = prefs.getBool('largeTextEnabled') ?? false;
      _reduceMotionEnabled = prefs.getBool('reduceMotionEnabled') ?? false;
      _textSize = prefs.getString('textSize') ?? 'Medium';
      
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('autoSyncEnabled', _autoSyncEnabled);
      await prefs.setBool('biometricEnabled', _biometricEnabled);
      await prefs.setBool('appLockEnabled', _appLockEnabled);
      await prefs.setBool('offlineModeEnabled', _offlineModeEnabled);
      await prefs.setBool('ipadOptimizationsEnabled', _ipadOptimizationsEnabled);
      await prefs.setBool('boldTextEnabled', _boldTextEnabled);
      await prefs.setBool('iCloudSyncEnabled', _iCloudSyncEnabled);
      await prefs.setString('accentColor', _accentColor);
      await prefs.setString('reminderFrequency', _reminderFrequency);
      
      // New Business Settings
      await prefs.setString('defaultCurrency', _defaultCurrency);
      await prefs.setString('receiptTemplate', _receiptTemplate);
      await prefs.setString('businessHours', _businessHours);
      await prefs.setString('backupFrequency', _backupFrequency);
      await prefs.setString('quietHours', _quietHours);
      await prefs.setStringList('quickActions', _quickActions);
      
      // Notification settings
      await prefs.setBool('paymentDueRemindersEnabled', _paymentDueRemindersEnabled);
      await prefs.setBool('weeklyReportsEnabled', _weeklyReportsEnabled);
      await prefs.setBool('monthlyReportsEnabled', _monthlyReportsEnabled);
      await prefs.setBool('quietHoursEnabled', _quietHoursEnabled);
      await prefs.setBool('liveActivitiesEnabled', _liveActivitiesEnabled);
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
      
      // iOS 18+ Integration settings
      await prefs.setBool('widgetsEnabled', _widgetsEnabled);
      await prefs.setBool('focusModeEnabled', _focusModeEnabled);
      await prefs.setBool('shortcutsEnabled', _shortcutsEnabled);
      await prefs.setBool('dynamicIslandEnabled', _dynamicIslandEnabled);
      await prefs.setBool('smartStackEnabled', _smartStackEnabled);
      await prefs.setBool('aiFeaturesEnabled', _aiFeaturesEnabled);
      
      // Accessibility settings
      await prefs.setBool('largeTextEnabled', _largeTextEnabled);
      await prefs.setBool('reduceMotionEnabled', _reduceMotionEnabled);
      await prefs.setString('textSize', _textSize);
      
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Clean up duplicate payment activities for the same customer and debt
  void _cleanupDuplicatePaymentActivities() {
    try {
      final Map<String, List<Activity>> groupedActivities = {};
      
      // Group activities by customer and debt
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && activity.debtId != null) {
          final key = '${activity.customerName}_${activity.debtId}';
          if (!groupedActivities.containsKey(key)) {
            groupedActivities[key] = [];
          }
          groupedActivities[key]!.add(activity);
        }
      }
      
      // Process each group
      for (final activities in groupedActivities.values) {
        if (activities.length > 1) {
          // Sort by date to find the most recent
          activities.sort((a, b) => b.date.compareTo(a.date));
          
          // Keep the most recent activity and combine amounts
          final mostRecent = activities.first;
          final totalAmount = activities.fold<double>(0, (sum, activity) => 
            sum + (activity.paymentAmount ?? 0));
          
          // Update the most recent activity with combined amount
          final updatedActivity = mostRecent.copyWith(
            paymentAmount: totalAmount,
          );
          
          // Remove old activities and update the most recent
          for (int i = 1; i < activities.length; i++) {
            _activities.remove(activities[i]);
            _dataService.deleteActivity(activities[i].id);
          }
          
          // Update the most recent activity
          final index = _activities.indexWhere((a) => a.id == mostRecent.id);
          if (index != -1) {
            _activities[index] = updatedActivity;
            _dataService.updateActivity(updatedActivity);
          }
        }
      }
    } catch (e) {
      print('Error cleaning up duplicate payment activities: $e');
    }
  }

  // Load data from storage
  Future<void> _loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load all data from storage
      _customers = _dataService.customers;
      _debts = _dataService.debts;
      _categories = _dataService.categories;
      _productPurchases = _dataService.productPurchases;
      _activities = _dataService.activities;
      _partialPayments = _dataService.partialPayments;
      _currencySettings = _dataService.currencySettings;

      // Clean up duplicate payment activities - DISABLED to preserve partial payments
      // _cleanupDuplicatePaymentActivities();

      // Sort activities by date (newest first)
      _activities.sort((a, b) => b.date.compareTo(a.date));

      _clearCache();
      notifyListeners();
      
      // Create missing payment activities for fully paid debts
      await createMissingPaymentActivitiesForAllPaidDebts();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create missing payment activities for all paid debts
  Future<void> createMissingPaymentActivitiesForAllPaidDebts() async {
    try {
      for (final debt in _debts) {
        if (debt.isFullyPaid && debt.paidAmount > 0) {
          // Check if there's already a payment activity for this debt
          final hasPaymentActivity = _activities.any((activity) => 
            activity.type == ActivityType.payment && 
            activity.debtId == debt.id);
          
          if (!hasPaymentActivity) {
            // Create a payment activity for the full paid amount
            await addPaymentActivity(debt, debt.paidAmount, DebtStatus.pending, DebtStatus.paid);
          }
        }
      }
    } catch (e) {
      print('Error creating missing payment activities: $e');
    }
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
      // Handle error silently
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Schedule notifications for due/overdue debts
  Future<void> _scheduleNotifications() async {
    if (!_notificationsEnabled) return;
    
    final pendingDebts = _debts.where((debt) => debt.paidAmount == 0).toList();
    
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
      rethrow;
    }
  }
  
  // Debt operations
  Future<void> addDebt(Debt debt) async {
    try {
      // Always create a new debt - no more combining debts with same description
      // This allows multiple debts for the same product with different prices
      
      // Check if customer has existing partially paid debts (not fully paid)
      final existingPartiallyPaidDebts = _debts.where((d) => 
        d.customerId == debt.customerId && 
        d.paidAmount > 0 && d.paidAmount < d.amount
      ).toList();
      
      if (existingPartiallyPaidDebts.isNotEmpty) {
        // For product-based debts, always create a new debt instead of concatenating
        // This prevents the "product + product + product" issue
        await _dataService.addDebt(debt);
        _debts.add(debt);
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
          await _syncService.syncDebts([debt]);
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
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == debtId);
      
      // Create a summary activity to preserve payment history before deleting
      if (debt.paidAmount > 0) {
        final summaryActivity = Activity(
          id: 'summary_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          type: ActivityType.debtCleared,
          customerName: debt.customerName,
          customerId: debt.customerId,
          description: 'Cleared debt: ${debt.description}',
          amount: debt.amount,
          paymentAmount: debt.paidAmount,
          oldStatus: debt.status,
          newStatus: DebtStatus.paid,
          debtId: debt.id,
        );
        await _addActivity(summaryActivity);
      }
      
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
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      print('markDebtAsPaid called with debtId: $debtId');
      await _dataService.markDebtAsPaid(debtId);
      final index = _debts.indexWhere((d) => d.id == debtId);
      print('Found debt at index: $index');
      if (index != -1) {
        final originalDebt = _debts[index];
        print('Original debt: ${originalDebt.customerName} - ${originalDebt.amount}');
        print('Original paid amount: ${originalDebt.paidAmount}');
        
        // Calculate the remaining amount to be paid
        final remainingAmount = originalDebt.amount - originalDebt.paidAmount;
        print('Remaining amount to be paid: $remainingAmount');
        
        // Get all debts for this customer
        final customerDebts = _debts.where((debt) => debt.customerId == originalDebt.customerId).toList();
        
        // Check if ALL customer debts are fully paid
        bool allCustomerDebtsFullyPaid = true;
        for (final debt in customerDebts) {
          if (debt.id == debtId) {
            // For the current debt, check if it would be fully paid after this payment
            if (originalDebt.paidAmount + remainingAmount < debt.amount) {
              allCustomerDebtsFullyPaid = false;
              break;
            }
          } else {
            // For other debts, check if they're already fully paid
            if (!debt.isFullyPaid) {
              allCustomerDebtsFullyPaid = false;
              break;
            }
          }
        }
        
        // Only mark as paid if ALL customer debts are fully paid
        final shouldMarkAsPaid = allCustomerDebtsFullyPaid;
        
        // Only mark as paid if the debt is actually fully paid
        if (shouldMarkAsPaid) {
          _debts[index] = _debts[index].copyWith(
            status: DebtStatus.paid,
            paidAmount: _debts[index].amount,
            paidAt: DateTime.now(),
          );
          
          // Create a fully paid activity only if the debt is actually fully paid
          await addPaymentActivity(originalDebt, remainingAmount, DebtStatus.pending, DebtStatus.paid);
          print('Payment activity created for full debt amount');
          
          // Show system notification
          await _notificationService.showDebtPaidNotification(originalDebt);
        } else {
          // If not fully paid, just update the paid amount but don't mark as paid
          _debts[index] = _debts[index].copyWith(
            paidAmount: originalDebt.paidAmount + remainingAmount,
            status: DebtStatus.pending, // Keep as pending since it's not fully paid
            paidAt: DateTime.now(),
          );
          
          // Create a partial payment activity
          await addPaymentActivity(originalDebt, remainingAmount, DebtStatus.pending, DebtStatus.pending);
          print('Payment activity created for partial payment');
        }
        
        _clearCache();
        notifyListeners();
      }
      
      if (_isOnline) {
        await _syncService.syncDebts([_debts[index]]);
      }
      
      // Reschedule notifications
      await _scheduleNotifications();
    } catch (e) {
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
      
      // Calculate new total paid amount by adding to existing paidAmount
      final newTotalPaidAmount = originalDebt.paidAmount + paymentAmount;
      
      // Check if THIS debt is fully paid (not all customer debts)
      final isThisDebtFullyPaid = newTotalPaidAmount >= originalDebt.amount;
      
      // Update the debt with the new total paid amount
      _debts[index] = originalDebt.copyWith(
        paidAmount: newTotalPaidAmount,
        status: isThisDebtFullyPaid ? DebtStatus.paid : DebtStatus.pending,
        paidAt: DateTime.now(), // Update to latest payment time
      );
      
      await _dataService.updateDebt(_debts[index]);
      _clearCache();
      notifyListeners();
      
      // AUTOMATICALLY track payment activity (for both partial and full payments)
      // If this payment makes the debt fully paid, show the remaining amount as payment
      final paymentAmountToShow = isThisDebtFullyPaid && !originalDebt.isFullyPaid 
          ? (originalDebt.amount - originalDebt.paidAmount) 
          : paymentAmount;
      
      await addPaymentActivity(originalDebt, paymentAmountToShow, originalDebt.status, _debts[index].status);
      
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

  // Clean up old activities that shouldn't be there
  Future<void> _cleanupInvalidActivities() async {
    final activitiesToRemove = <Activity>[];
    
    print('Starting cleanup of invalid activities. Total activities: ${_activities.length}');
    
    for (final activity in _activities) {
      if (activity.type == ActivityType.payment && activity.debtId == null) {
        // Check if this activity is for a debt that was already fully paid
        final customerDebts = _debts.where((d) => d.customerId == activity.customerId).toList();
        final allDebtsFullyPaid = customerDebts.every((d) => d.isFullyPaid);
        
        print('Activity: ${activity.customerName} - ${activity.paymentAmount} - ${activity.newStatus}');
        print('Customer debts: ${customerDebts.length}, all fully paid: $allDebtsFullyPaid');
        
        if (allDebtsFullyPaid) {
          // This activity should be removed as it's for already paid debts
          // Check if this is an old activity (more than 24 hours old)
          final isOldActivity = DateTime.now().difference(activity.date).inHours > 24;
          
          if (isOldActivity) {
            activitiesToRemove.add(activity);
            print('Marking activity for removal: ${activity.customerName} - ${activity.paymentAmount}');
          }
        }
      }
    }
    
    print('Activities to remove: ${activitiesToRemove.length}');
    
    for (final activity in activitiesToRemove) {
      await _dataService.deleteActivity(activity.id);
      _activities.remove(activity);
      print('Removed activity: ${activity.customerName} - ${activity.paymentAmount}');
    }
    
    if (activitiesToRemove.isNotEmpty) {
      print('Cleaned up ${activitiesToRemove.length} invalid activities');
      _clearCache();
      notifyListeners();
    } else {
      print('No invalid activities found to clean up');
    }
  }

  // Manual cleanup method to remove specific activities
  Future<void> removeActivityById(String activityId) async {
    try {
      await _dataService.deleteActivity(activityId);
      _activities.removeWhere((activity) => activity.id == activityId);
      _clearCache();
      notifyListeners();
      print('Manually removed activity: $activityId');
    } catch (e) {
      print('Error removing activity: $e');
    }
  }

  // Remove activities by customer and amount
  Future<void> removeActivitiesByCustomerAndAmount(String customerName, double amount) async {
    try {
      final activitiesToRemove = _activities.where((activity) => 
        activity.customerName == customerName && 
        activity.paymentAmount == amount
      ).toList();
      
      for (final activity in activitiesToRemove) {
        await _dataService.deleteActivity(activity.id);
        _activities.remove(activity);
        print('Removed activity: ${activity.customerName} - ${activity.paymentAmount}');
      }
      
      _clearCache();
      notifyListeners();
      print('Removed ${activitiesToRemove.length} activities for $customerName with amount $amount');
    } catch (e) {
      print('Error removing activities: $e');
    }
  }

  // New method for applying payment across multiple debts with single activity
  Future<void> applyPaymentAcrossDebts(List<String> debtIds, double totalPaymentAmount) async {
    try {
      double remainingPayment = totalPaymentAmount;
      final appState = this;
      
      // Check if any of these debts are already fully paid - if so, skip them
      final validDebtIds = <String>[];
      for (final debtId in debtIds) {
        final debt = _debts.firstWhere((d) => d.id == debtId);
        if (!debt.isFullyPaid) {
          validDebtIds.add(debtId);
        }
      }
      
      // If no valid debts to pay, don't create an activity
      if (validDebtIds.isEmpty) {
        print('No valid debts to pay - all debts are already fully paid');
        return;
      }
      
      // Create a single payment activity for the total amount
      final firstDebt = _debts.firstWhere((d) => d.id == validDebtIds.first);
      
      // Check if this payment makes all valid debts fully paid
      final totalDebtAmount = validDebtIds.fold<double>(0, (sum, debtId) {
        final debt = _debts.firstWhere((d) => d.id == debtId);
        return sum + debt.amount;
      });
      final totalPaidBefore = validDebtIds.fold<double>(0, (sum, debtId) {
        final debt = _debts.firstWhere((d) => d.id == debtId);
        return sum + debt.paidAmount;
      });
      final isAllDebtsFullyPaid = (totalPaidBefore + totalPaymentAmount) >= totalDebtAmount;
      
      final activity = Activity(
        id: 'activity_payment_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        type: ActivityType.payment,
        customerName: firstDebt.customerName,
        customerId: firstDebt.customerId,
        description: 'Payment across multiple debts',
        amount: totalDebtAmount,
        paymentAmount: totalPaymentAmount,
        oldStatus: DebtStatus.pending,
        newStatus: isAllDebtsFullyPaid ? DebtStatus.paid : DebtStatus.pending,
        debtId: null, // No specific debt ID since it's across multiple debts
      );
      
      print('Creating activity: paymentAmount=${activity.paymentAmount}, amount=${activity.amount}, isAllDebtsFullyPaid=$isAllDebtsFullyPaid, validDebtIds=$validDebtIds');
      
      // Apply payment to each valid debt
      for (final debtId in validDebtIds) {
        if (remainingPayment <= 0) break;
        
        final index = _debts.indexWhere((debt) => debt.id == debtId);
        if (index == -1) continue;
        
        final originalDebt = _debts[index];
        final debtRemaining = originalDebt.remainingAmount;
        final paymentForThisDebt = remainingPayment > debtRemaining ? debtRemaining : remainingPayment;
        
        // Create partial payment record
        final partialPayment = PartialPayment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          debtId: debtId,
          amount: paymentForThisDebt,
          paidAt: DateTime.now(),
        );
        
        await _dataService.addPartialPayment(partialPayment);
        _partialPayments.add(partialPayment);
        
        // Update debt
        final newTotalPaidAmount = originalDebt.paidAmount + paymentForThisDebt;
        final isThisDebtFullyPaid = newTotalPaidAmount >= originalDebt.amount;
        
        _debts[index] = originalDebt.copyWith(
          paidAmount: newTotalPaidAmount,
          status: isThisDebtFullyPaid ? DebtStatus.paid : DebtStatus.pending,
          paidAt: DateTime.now(),
        );
        
        await _dataService.updateDebt(_debts[index]);
        remainingPayment -= paymentForThisDebt;
      }
      
      // Add the single payment activity
      await _dataService.addActivity(activity);
      _activities.add(activity);
      _activities.sort((a, b) => b.date.compareTo(a.date));
      
      _clearCache();
      notifyListeners();
      
      // Show notification
      await _notificationService.showPaymentAppliedNotification(firstDebt, totalPaymentAmount);
      
      if (_isOnline) {
        await _syncService.syncDebts(_debts.where((d) => validDebtIds.contains(d.id)).toList());
      }
      
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
      rethrow;
    }
  }
  
  // Refresh all data and notify listeners
  Future<void> refresh() async {
    try {
      await _loadData();
      
      // Automatically create missing payment activities when data is refreshed
      await createMissingPaymentActivitiesForAllPaidDebts();
      
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      // Handle error silently
    }
  }



  // Clean up existing debt descriptions by removing "Qty: x" text
  Future<void> cleanUpDebtDescriptions() async {
    try {
      // Cleaning up debt descriptions
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
        // Updated $updatedCount debt descriptions
      } else {
        // No debt descriptions needed cleaning
      }
    } catch (e) {
      // Error cleaning up debt descriptions
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
      
      // Cache cleared successfully
    } catch (e) {
      // Error clearing cache
    }
  }

  Future<String> exportData() async {
    try {
      final filePath = await _exportImportService.exportToCSV(_customers, _debts);
      return filePath;
    } catch (e) {
      // Error exporting data
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
      return {'size': 0, 'items': 0};
    }
  }

  // Activity tracking methods
  Future<void> _addActivity(Activity activity) async {
    try {
      // Add to data service first
      await _dataService.addActivity(activity);
      
      // Add to local list
      _activities.add(activity);
      
      // Sort activities by date (newest first) after adding new activity
      _activities.sort((a, b) => b.date.compareTo(a.date));
      
      notifyListeners();
      
    } catch (e) {
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
    try {
      
      // ALWAYS create a new payment activity - don't merge with existing ones
      // This ensures partial payments remain visible in activity history
      final activity = Activity(
        id: 'activity_payment_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(), // Use current time for payment
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
      
      // ALWAYS add to storage first
      await _dataService.addActivity(activity);
      
      // ALWAYS add to local list
      _activities.add(activity);
      
      // Sort activities by date (newest first) after adding new activity
      _activities.sort((a, b) => b.date.compareTo(a.date));
      
      // ALWAYS notify listeners
      notifyListeners();
      
    } catch (e) {
      print('Error in addPaymentActivity: $e');
      rethrow;
    }
  }

  // Check if a payment activity exists for a debt
  bool hasPaymentActivity(String debtId) {
    return _activities.any((activity) => 
      activity.debtId == debtId && 
      activity.type == ActivityType.payment
    );
  }
  
  // Get payment activities for a debt
  List<Activity> getPaymentActivities(String debtId) {
    return _activities.where((activity) => 
      activity.debtId == debtId && 
      activity.type == ActivityType.payment
    ).toList();
  }

  // Get payment activities for a specific customer
  List<Activity> getPaymentActivitiesForCustomer(String customerName) {
    return _activities.where((activity) => 
      activity.customerName.toLowerCase() == customerName.toLowerCase() && 
      activity.type == ActivityType.payment
    ).toList();
  }
  
  // Check if a customer has any payment activities
  bool hasPaymentActivitiesForCustomer(String customerName) {
    return _activities.any((activity) => 
      activity.customerName.toLowerCase() == customerName.toLowerCase() && 
      activity.type == ActivityType.payment
    );
  }

  // Manual method to create payment activity for testing
  Future<void> createTestPaymentActivity(String customerName, String debtId, double amount) async {
    try {
      final activity = Activity(
        id: 'test_payment_${debtId}_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        type: ActivityType.payment,
        customerName: customerName,
        customerId: 'test_customer_id',
        description: 'Test payment',
        amount: amount,
        paymentAmount: amount,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: debtId,
      );
      
      await _addActivity(activity);
      await _loadData();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  // Create payment activity for Charbel Bechaalany if missing
  Future<void> createMissingPaymentActivityForCharbel() async {
    try {
      final charbelActivities = getPaymentActivitiesForCustomer('Charbel Bechaalany');
      
      if (charbelActivities.isEmpty) {
        // Find Charbel's debts
        final charbelDebts = _debts.where((debt) => 
          debt.customerName.toLowerCase() == 'charbel bechaalany'.toLowerCase()
        ).toList();
        
        if (charbelDebts.isNotEmpty) {
          final debt = charbelDebts.first;
          
          // Create the activity without triggering UI updates immediately
          final activity = Activity(
            id: 'activity_payment_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            type: ActivityType.payment,
            customerName: debt.customerName,
            customerId: debt.customerId,
            description: debt.description,
            amount: debt.amount,
            paymentAmount: debt.amount,
            oldStatus: DebtStatus.pending,
            newStatus: DebtStatus.paid,
            debtId: debt.id,
          );
          
          // Add to storage directly
          await _dataService.addActivity(activity);
          _activities.add(activity);
        }
      }
      
    } catch (e) {
      // Handle error silently
    }
  }

  // Comprehensive method to check and create missing payment activities
  Future<void> checkAndCreateMissingPaymentActivities() async {
    try {
      // Get all paid debts
      final paidDebts = _debts.where((debt) => debt.isFullyPaid).toList();
      
      for (final debt in paidDebts) {
        // Check if payment activity exists for this debt
        final existingActivities = _activities.where((activity) => 
          activity.debtId == debt.id && 
          activity.type == ActivityType.payment
        ).toList();
        
        if (existingActivities.isEmpty) {
          // Create payment activity
          final activity = Activity(
            id: 'activity_payment_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
            date: debt.paidAt ?? DateTime.now(),
            type: ActivityType.payment,
            customerName: debt.customerName,
            customerId: debt.customerId,
            description: debt.description,
            amount: debt.amount,
            paymentAmount: debt.amount,
            oldStatus: DebtStatus.pending,
            newStatus: DebtStatus.paid,
            debtId: debt.id,
          );
          
          // Add to storage and local list
          await _dataService.addActivity(activity);
          _activities.add(activity);
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      // Handle error silently
    }
  }



  // Test method to create a payment activity for testing
  Future<void> testCreatePaymentActivity() async {
    try {
      // Create a test debt
      final testDebt = Debt(
        id: 'test_debt_${DateTime.now().millisecondsSinceEpoch}',
        customerId: 'test_customer',
        customerName: 'Test Customer',
        amount: 50.0,
        description: 'Test debt',
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: DateTime.now(),
      );
      
      // Create payment activity
      await addPaymentActivity(testDebt, 50.0, DebtStatus.pending, DebtStatus.paid);
      
    } catch (e) {
      // Handle error silently
    }
  }

  // Clean up duplicate or incorrect activities for a specific customer
  Future<void> cleanupCustomerActivities(String customerName) async {
    try {
      // Find all activities for this customer
      final customerActivities = _activities.where((activity) => 
        activity.customerName.toLowerCase() == customerName.toLowerCase()
      ).toList();
      
      // Remove all activities for this customer
      for (final activity in customerActivities) {
        await _dataService.deleteActivity(activity.id);
        _activities.removeWhere((a) => a.id == activity.id);
      }
      
      // Sort activities by date (newest first)
      _activities.sort((a, b) => b.date.compareTo(a.date));
      
      // Notify listeners
      notifyListeners();
      
      print('Cleaned up ${customerActivities.length} activities for $customerName');
      
    } catch (e) {
      print('Error cleaning up activities: $e');
    }
  }

  // Create a payment activity for a specific customer (for testing/fixing)
  Future<void> createPaymentActivityForCustomer(String customerName, double amount, String description) async {
    try {
      // Find the customer
      final customer = _customers.firstWhere(
        (c) => c.name.toLowerCase() == customerName.toLowerCase(),
        orElse: () => Customer(id: '', name: '', phone: '', createdAt: DateTime.now()),
      );
      
      if (customer.id.isEmpty) {
        print('Customer not found: $customerName');
        return;
      }
      
      // Create payment activity
      final activity = Activity(
        id: 'payment_${customer.id}_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        type: ActivityType.payment,
        customerName: customer.name,
        customerId: customer.id,
        description: description,
        amount: amount,
        paymentAmount: amount,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: 'manual_payment_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Add to storage and local list
      await _dataService.addActivity(activity);
      _activities.add(activity);
      
      // Sort activities by date (newest first)
      _activities.sort((a, b) => b.date.compareTo(a.date));
      
      // Notify listeners
      notifyListeners();
      
      print('Created payment activity for $customerName: ${amount}');
      
    } catch (e) {
      print('Error creating payment activity: $e');
    }
  }

  // Check and fix payment activities for a specific customer
  Future<void> checkPaymentActivitiesForCustomer(String customerName) async {
    try {
      // Find all payment activities for this customer
      final customerActivities = _activities.where((activity) => 
        activity.customerName.toLowerCase() == customerName.toLowerCase() &&
        activity.type == ActivityType.payment
      ).toList();
      
      print('Found ${customerActivities.length} payment activities for $customerName:');
      for (final activity in customerActivities) {
        print('- ${activity.paymentAmount} (${activity.date})');
      }
      
      // Find the customer's current debts
      final customer = _customers.firstWhere(
        (c) => c.name.toLowerCase() == customerName.toLowerCase(),
        orElse: () => Customer(id: '', name: '', phone: '', createdAt: DateTime.now()),
      );
      
      if (customer.id.isNotEmpty) {
        final customerDebts = _debts.where((debt) => debt.customerId == customer.id).toList();
        print('Customer has ${customerDebts.length} debts:');
        for (final debt in customerDebts) {
          print('- ${debt.amount} (paid: ${debt.paidAmount}, remaining: ${debt.remainingAmount})');
        }
      }
      
    } catch (e) {
      print('Error checking payment activities: $e');
    }
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

  // New iOS 18+ settings methods
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    _appLockEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAccentColor(String color) async {
    _accentColor = color;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setReminderFrequency(String frequency) async {
    _reminderFrequency = frequency;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLiveActivitiesEnabled(bool enabled) async {
    _liveActivitiesEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setWidgetsEnabled(bool enabled) async {
    _widgetsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    _focusModeEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setShortcutsEnabled(bool enabled) async {
    _shortcutsEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDynamicIslandEnabled(bool enabled) async {
    _dynamicIslandEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSmartStackEnabled(bool enabled) async {
    _smartStackEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAiFeaturesEnabled(bool enabled) async {
    _aiFeaturesEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // New Business Settings Setters
  Future<void> setDefaultCurrency(String currency) async {
    _defaultCurrency = currency;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setReceiptTemplate(String template) async {
    _receiptTemplate = template;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBusinessHours(String hours) async {
    _businessHours = hours;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBackupFrequency(String frequency) async {
    _backupFrequency = frequency;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addQuickAction(String action) async {
    if (!_quickActions.contains(action)) {
      _quickActions.add(action);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> removeQuickAction(String action) async {
    _quickActions.remove(action);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setQuietHours(String hours) async {
    _quietHours = hours;
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
        .where((d) => d.paidAmount < d.amount)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }
  
  double _calculateTotalPaid() {
    return _debts
        .where((d) => d.paidAmount >= d.amount)
        .fold(0.0, (sum, debt) => sum + debt.paidAmount);
  }
  
  int _calculatePendingCount() {
    return _debts.where((d) => d.paidAmount == 0).length;
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
        debt.customerId == customer.id && debt.paidAmount < debt.amount
      ).toList();
      final totalDebt = customerDebtsList.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
      if (totalDebt > 0) {
        customerDebts[customer.id] = totalDebt;
      }
    }
    
    final sortedCustomers = _customers.where((customer) => 
      customerDebts.containsKey(customer.id)
    ).toList()
      ..sort((a, b) {
        final debtA = customerDebts[a.id];
        final debtB = customerDebts[b.id];
        if (debtA == null || debtB == null) return 0;
        return debtB.compareTo(debtA);
      });
    
    return sortedCustomers.take(5).toList();
  }




} 