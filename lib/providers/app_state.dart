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

// CloudKit service removed - using built-in backend
import '../services/data_export_import_service.dart';
import '../services/backup_service.dart';
import '../services/ios18_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
  // CloudKit service removed - using built-in backend
  final DataExportImportService _exportImportService = DataExportImportService();
  final BackupService _backupService = BackupService();
  // final IOS18Service _ios18Service = IOS18Service(); // Commented out - static methods don't need instance

  
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
  
  // App Settings (Only implemented ones)
  bool _isDarkMode = false;
  bool _autoSyncEnabled = true;
  
  // Business Settings (Only implemented ones)
  String _defaultCurrency = 'USD';
  
  // Constructor to load settings immediately for theme persistence
  AppState() {
    _loadSettingsSync();
  }
  
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
  
  // App Settings Getters (Only implemented ones)
  bool get isDarkMode => _isDarkMode;
  bool get darkModeEnabled => _isDarkMode;
  String get selectedLanguage => 'English';
  bool get autoSyncEnabled => _autoSyncEnabled;
  
  // Business Settings Getters (Only implemented ones)
  String get defaultCurrency => _defaultCurrency;
  
  // Accessibility Settings Getters (Needed for theme service)
  String get textSize => 'Medium'; // Default value
  bool get boldTextEnabled => false; // Default value
  
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
      // Load settings first - this is critical for theme persistence
      await _loadSettings();
      
      // Initialize services
      await _notificationService.initialize();
      await _syncService.initialize();
      await _backupService.initializeDailyBackup();
      await IOS18Service.initialize();
      
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
  

  
  // Load settings from SharedPreferences (Only implemented ones)
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? true;
      
      // Business Settings (Only implemented ones)
      _defaultCurrency = prefs.getString('defaultCurrency') ?? 'USD';
      
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Synchronous settings loading for immediate theme persistence
  void _loadSettingsSync() {
    try {
      // Use a microtask to load settings asynchronously but immediately
      Future.microtask(() async {
        await _loadSettings();
        notifyListeners(); // Notify listeners after settings are loaded
      });
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Save settings to SharedPreferences (Only implemented ones)
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('autoSyncEnabled', _autoSyncEnabled);
      
      // Business Settings (Only implemented ones)
      await prefs.setString('defaultCurrency', _defaultCurrency);
      
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Clean up duplicate payment activities - removed unused method

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
      // Error loading data
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
      // Error creating missing payment activities
    }
  }
  

  
  // Setup connectivity monitoring
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
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
    // Debt reminders removed as per user request
  }
  
  // Customer operations
  Future<void> addCustomer(Customer customer) async {
    try {
      await _dataService.addCustomer(customer);
      _customers.add(customer);
      _clearCache();
      
      // CloudKit sync removed - using built-in backend
      
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
        
              // CloudKit sync removed - using built-in backend
        
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
      
      // CloudKit sync removed - using built-in backend
      
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
        
        // CloudKit sync removed - using built-in backend
        
        notifyListeners();
        
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
        
        // CloudKit sync removed - using built-in backend
        
        notifyListeners();
        
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
        
        // CloudKit sync removed - using built-in backend
        
        notifyListeners();
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
      
      if (_isOnline) {
        await _syncService.deleteDebt(debtId);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      await _dataService.markDebtAsPaid(debtId);
      final index = _debts.indexWhere((d) => d.id == debtId);
      if (index != -1) {
        final originalDebt = _debts[index];
        
        // Calculate the remaining amount to be paid
        final remainingAmount = originalDebt.amount - originalDebt.paidAmount;
        
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
        } else {
          // If not fully paid, just update the paid amount but don't mark as paid
          _debts[index] = _debts[index].copyWith(
            paidAmount: originalDebt.paidAmount + remainingAmount,
            status: DebtStatus.pending, // Keep as pending since it's not fully paid
            paidAt: DateTime.now(),
          );
          
          // Create a partial payment activity
          await addPaymentActivity(originalDebt, remainingAmount, DebtStatus.pending, DebtStatus.pending);
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
    
          for (final activity in _activities) {
        if (activity.type == ActivityType.payment && activity.debtId == null) {
          // Check if this activity is for a debt that was already fully paid
          final customerDebts = _debts.where((d) => d.customerId == activity.customerId).toList();
          final allDebtsFullyPaid = customerDebts.every((d) => d.isFullyPaid);
          
          if (allDebtsFullyPaid) {
            // This activity should be removed as it's for already paid debts
            // Check if this is an old activity (more than 24 hours old)
            final isOldActivity = DateTime.now().difference(activity.date).inHours > 24;
            
            if (isOldActivity) {
              activitiesToRemove.add(activity);
            }
          }
        }
      }
      
      for (final activity in activitiesToRemove) {
        await _dataService.deleteActivity(activity.id);
        _activities.remove(activity);
      }
      
      if (activitiesToRemove.isNotEmpty) {
        _clearCache();
        notifyListeners();
      }
  }

  // Manual cleanup method to remove specific activities
  Future<void> removeActivityById(String activityId) async {
    try {
      await _dataService.deleteActivity(activityId);
      _activities.removeWhere((activity) => activity.id == activityId);
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Handle error silently
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
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // New method for applying payment across multiple debts with single activity
  Future<void> applyPaymentAcrossDebts(List<String> debtIds, double totalPaymentAmount) async {
    try {
      double remainingPayment = totalPaymentAmount;
      
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
      final filePath = await _exportImportService.exportToExcel(_customers, _debts, _productPurchases);
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
      // Error in addPaymentActivity
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
      
      // Cleaned up activities for $customerName
      
    } catch (e) {
      // Error cleaning up activities
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
        // Customer not found: $customerName
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
      
      // Created payment activity for $customerName
      
    } catch (e) {
      // Error creating payment activity
    }
  }

  // Check and fix payment activities for a specific customer
  Future<void> checkPaymentActivitiesForCustomer(String customerName) async {
    try {
      // Find all payment activities for this customer
      _activities.where((activity) => 
        activity.customerName.toLowerCase() == customerName.toLowerCase() &&
        activity.type == ActivityType.payment
      ).toList();
      
      // Found payment activities for $customerName
      
      // Find the customer's current debts
      final customer = _customers.firstWhere(
        (c) => c.name.toLowerCase() == customerName.toLowerCase(),
        orElse: () => Customer(id: '', name: '', phone: '', createdAt: DateTime.now()),
      );
      
      if (customer.id.isNotEmpty) {
        _debts.where((debt) => debt.customerId == customer.id).toList();
        // Customer has debts - removed unused variables
      }
      
    } catch (e) {
      // Error checking payment activities
    }
  }



  // Settings methods
  Future<void> setDarkModeEnabled(bool enabled) async {
    _isDarkMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // Removed unused setter methods

  // New iOS 18+ settings methods
  // Removed unused setter methods

  // Cache management
  void _clearCache() {
    _cachedTotalDebt = null;
    _cachedTotalPaid = null;
    _cachedPendingCount = null;
    _cachedRecentDebts = null;
    _cachedTopDebtors = null;
  }
  
  // Refresh data after clearing operations
  Future<void> refreshData() async {
    try {
      await _loadData();
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
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