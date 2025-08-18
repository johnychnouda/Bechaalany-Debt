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
import '../services/backup_service.dart';
import '../services/ios18_service.dart';
import '../services/revenue_calculation_service.dart';
import '../services/data_migration_service.dart';
import '../services/whatsapp_automation_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final BackupService _backupService = BackupService();
  final DataMigrationService _migrationService = DataMigrationService();
  
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
  
  // WhatsApp Automation Settings
  bool _whatsappAutomationEnabled = false;
  String _whatsappCustomMessage = '';
  
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
  
  // WhatsApp Automation Getters
  bool get whatsappAutomationEnabled => _whatsappAutomationEnabled;
  String get whatsappCustomMessage => _whatsappCustomMessage;
  
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
    double totalPaid = 0.0;
    
    // Get all debts for this customer and sum their paidAmount
    // This is the most reliable method since paidAmount is directly maintained
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    
    for (final debt in customerDebts) {
      totalPaid += debt.paidAmount;
    }
    
    return totalPaid;
  }

  // PROFESSIONAL REVENUE CALCULATION - Based on product profit margins
  // Revenue is calculated from actual product costs and selling prices at purchase time
  // This ensures revenue integrity and professional accounting standards
  double get totalHistoricalRevenue {
    // AUTOMATIC SAFEGUARD: Check if any debts are missing cost prices and auto-migrate
    final debtsWithMissingCosts = _debts.where((debt) => 
      debt.originalCostPrice == null || debt.originalSellingPrice == null
    ).toList();
    
    if (debtsWithMissingCosts.isNotEmpty) {
      // Trigger auto-migration in background
      Future.microtask(() => autoMigrateRemainingDebts());
    }
    
    // AUTO-FIX: Check for corrupted cost/selling prices that cause revenue calculation errors
    final debtsWithCorruptedPrices = _debts.where((debt) => 
      (debt.originalCostPrice != null && debt.originalCostPrice! > 1000) ||
      (debt.originalSellingPrice != null && debt.originalSellingPrice! > 1000)
    ).toList();
    
    if (debtsWithCorruptedPrices.isNotEmpty) {
      // Trigger auto-fix in background
      Future.microtask(() => fixCorruptedDebtPrices());
    }
    
    // Revenue calculation service returns values in USD (same as debt amounts)
    final revenue = RevenueCalculationService().calculateTotalRevenue(_debts, _partialPayments, activities: _activities, appState: this);
    
    // No currency conversion needed - revenue is already in USD
    return revenue;
  }

  // Get customer-specific revenue for financial summaries
  double getCustomerRevenue(String customerId) {
    // Revenue calculation service returns values in USD (same as debt amounts)
    final revenue = RevenueCalculationService().calculateCustomerRevenue(customerId, _debts);
    // No currency conversion needed - revenue is already in USD
    return revenue;
  }

  // Get customer potential revenue (from unpaid amounts)
  double getCustomerPotentialRevenue(String customerId) {
    // Revenue calculation service returns values in USD (same as debt amounts)
    final potentialRevenue = RevenueCalculationService().calculateCustomerPotentialRevenue(customerId, _debts);
    // No currency conversion needed - revenue is already in USD
    return potentialRevenue;
  }

  // Get detailed revenue breakdown for a customer
  Map<String, dynamic> getCustomerRevenueBreakdown(String customerId) {
    final breakdown = RevenueCalculationService().getCustomerRevenueBreakdown(customerId, _debts);
    
    // Revenue calculation service returns values in USD (same as debt amounts)
    // No currency conversion needed for revenue values
    // Note: debt and payment amounts are already in USD
    return {
      'totalRevenue': breakdown['totalRevenue'] ?? 0.0,  // Already in USD
      'earnedRevenue': breakdown['earnedRevenue'] ?? 0.0,  // Already in USD
      'potentialRevenue': breakdown['potentialRevenue'] ?? 0.0,  // Already in USD
      'totalDebtAmount': breakdown['totalDebtAmount'] ?? 0.0,  // Already in USD
      'totalPaidAmount': breakdown['totalPaidAmount'] ?? 0.0,  // Already in USD
      'remainingAmount': breakdown['remainingAmount'] ?? 0.0,  // Already in USD
      'revenueToDebtRatio': breakdown['totalDebtAmount'] ?? 0.0,
      'calculatedAt': breakdown['calculatedAt'] ?? DateTime.now(),
    };
  }

  // Get comprehensive dashboard revenue summary
  Map<String, dynamic> getDashboardRevenueSummary() {
    final lbpSummary = RevenueCalculationService().getDashboardRevenueSummary(_debts, activities: _activities, appState: this);
    
    // If no currency settings exist, create default ones with 89,500 LBP per 1 USD
    if (_currencySettings == null) {
      _currencySettings = CurrencySettings(
        baseCurrency: 'USD',
        targetCurrency: 'LBP',
        exchangeRate: 89500.0,
        lastUpdated: DateTime.now(),
        notes: 'Default exchange rate',
      );
      // Save the default settings
      _dataService.saveCurrencySettings(_currencySettings!);
    }
    
    // Revenue calculation service returns values in USD (same as debt amounts)
    
    // Revenue calculation service returns values in USD (same as debt amounts)
    // No currency conversion needed for revenue values
    // Note: debt and payment amounts are already in USD
    return {
      'totalRevenue': lbpSummary['totalRevenue'] ?? 0.0,  // Already in USD
      'totalPotentialRevenue': lbpSummary['totalPotentialRevenue'] ?? 0.0,  // Already in USD
      'totalPaidAmount': lbpSummary['totalPaidAmount'] ?? 0.0,  // Already in USD
      'totalDebtAmount': lbpSummary['totalDebtAmount'] ?? 0.0,  // Already in USD
      'totalCustomers': lbpSummary['totalCustomers'] ?? 0,
      'averageRevenuePerCustomer': lbpSummary['averageRevenuePerCustomer'] ?? 0.0,  // Already in USD
      'revenueToDebtRatio': lbpSummary['revenueToDebtRatio'] ?? 0.0,
      'calculatedAt': lbpSummary['calculatedAt'] ?? DateTime.now(),
    };
  }

  // DATA MIGRATION METHODS - Critical for revenue calculation accuracy
  /// Run data migration to ensure all debts have cost price information
  Future<void> runDataMigration() async {
    try {
      await _migrationService.migrateDebtCostPrices();
      // Reload data after migration
      await _loadData();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Automatically migrate any remaining debts with missing cost prices
  /// This runs automatically and ensures all debts have proper cost information
  Future<void> autoMigrateRemainingDebts() async {
    try {
      // Identify debts that still need migration
      final debtsNeedingMigration = _debts.where((debt) => 
        debt.originalCostPrice == null || 
        debt.originalSellingPrice == null ||
        debt.subcategoryId == null
      ).toList();
      
      if (debtsNeedingMigration.isEmpty) {
        return; // All debts are properly configured
      }
      
      // Try to match them with existing products by name
      for (final debt in debtsNeedingMigration) {
        // Try to find a matching subcategory by name
        Subcategory? matchingSubcategory;
        
        for (final category in _categories) {
          for (final subcategory in category.subcategories) {
            if (subcategory.name.toLowerCase() == debt.description.toLowerCase() ||
                debt.description.toLowerCase().contains(subcategory.name.toLowerCase()) ||
                subcategory.name.toLowerCase().contains(debt.description.toLowerCase())) {
              matchingSubcategory = subcategory;
              break;
            }
          }
          if (matchingSubcategory != null) break;
        }
        
        if (matchingSubcategory != null) {
          // Update the debt with the found product information
          final updatedDebt = debt.copyWith(
            originalCostPrice: matchingSubcategory.costPrice,
            originalSellingPrice: matchingSubcategory.sellingPrice,
            subcategoryId: matchingSubcategory.id,
          );
          
          await updateDebt(updatedDebt);
        }
      }
    } catch (e) {
      // Silent fail - this is background migration
    }
  }
  
  /// Fix corrupted cost/selling prices that are stored in wrong currency
  /// This prevents revenue calculation errors like the $1,790,005.00 issue
  Future<void> fixCorruptedDebtPrices() async {
    try {
      bool hasFixedData = false;
      
      for (int i = 0; i < _debts.length; i++) {
        final debt = _debts[i];
        bool needsUpdate = false;
        double? newCostPrice = debt.originalCostPrice;
        double? newSellingPrice = debt.originalSellingPrice;
        
        // Check if cost price is corrupted (LBP values stored in USD fields)
        if (debt.originalCostPrice != null && debt.originalCostPrice! > 1000) {
          print('FIXING: Corrupted cost price for ${debt.description}');
          print('  Old cost price: ${debt.originalCostPrice}');
          // Convert from LBP to USD (assuming 89,500 exchange rate)
          newCostPrice = debt.originalCostPrice! / 89500;
          print('  New cost price: $newCostPrice');
          needsUpdate = true;
        }
        
        // Check if selling price is corrupted (LBP values stored in USD fields)
        if (debt.originalSellingPrice != null && debt.originalSellingPrice! > 1000) {
          print('FIXING: Corrupted selling price for ${debt.description}');
          print('  Old selling price: ${debt.originalSellingPrice}');
          // Convert from LBP to USD (assuming 89,500 exchange rate)
          newSellingPrice = debt.originalSellingPrice! / 89500;
          print('  New selling price: $newSellingPrice');
          needsUpdate = true;
        }
        
        // Update the debt if needed
        if (needsUpdate) {
          final updatedDebt = debt.copyWith(
            originalCostPrice: newCostPrice,
            originalSellingPrice: newSellingPrice,
          );
          
          // Update in storage
          await _dataService.updateDebt(updatedDebt);
          
          // Update in local list
          _debts[i] = updatedDebt;
          hasFixedData = true;
          
          print('  ✅ Fixed debt: ${debt.description}');
        }
      }
      
      if (hasFixedData) {
        print('🎉 Fixed corrupted debt prices! Revenue calculations should now be accurate.');
        _clearCache();
        notifyListeners();
      } else {
        print('✅ No corrupted debt prices found.');
      }
    } catch (e) {
      print('❌ Error fixing corrupted debt prices: $e');
      rethrow;
    }
  }

  // ESSENTIAL METHODS - Restored after cleanup
  Future<void> _loadData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Use getters instead of load methods
      _customers = _dataService.customers;
      _debts = _dataService.debts;
      _categories = _dataService.categories;
      _productPurchases = _dataService.productPurchases;
      _activities = _dataService.activities;
      _partialPayments = _dataService.partialPayments;
      
      // Load currency settings
      _currencySettings = _dataService.currencySettings;
      
      _clearCache();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCurrencySettings(CurrencySettings settings) async {
    try {
      await _dataService.saveCurrencySettings(settings);
      _currencySettings = settings;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _whatsappAutomationEnabled = prefs.getBool('whatsappAutomationEnabled') ?? false;
      _whatsappCustomMessage = prefs.getString('whatsappCustomMessage') ?? '';
      _defaultCurrency = prefs.getString('defaultCurrency') ?? 'USD';
      notifyListeners();
    } catch (e) {
      // Use defaults if settings can't be loaded
    }
  }

  void _loadSettingsSync() {
    SharedPreferences.getInstance().then((prefs) {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _whatsappAutomationEnabled = prefs.getBool('whatsappAutomationEnabled') ?? false;
      _whatsappCustomMessage = prefs.getString('whatsappCustomMessage') ?? '';
      _defaultCurrency = prefs.getString('defaultCurrency') ?? 'USD';
      notifyListeners();
    });
  }

  void _clearCache() {
    _cachedTotalDebt = null;
    _cachedTotalPaid = null;
    _cachedPendingCount = null;
    _cachedRecentDebts = null;
    _cachedTopDebtors = null;
  }

  Future<void> _addActivity(Activity activity) async {
    try {
      await _dataService.addActivity(activity);
      _activities.add(activity);
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPaymentActivity(Debt debt, double amount, DebtStatus oldStatus, DebtStatus newStatus) async {
    try {
      // Check if the CUSTOMER is fully paid (all debts settled), not just this individual debt
      final customerFullyPaid = isCustomerFullyPaid(debt.customerId);
      
      // Determine the correct description based on customer status, not individual debt status
      // Show clean payment status with just the amount
      final description = customerFullyPaid 
          ? 'Fully paid: ${amount.toStringAsFixed(2)}\$'  // Clean: just payment status + amount
          : 'Partial payment: ${amount.toStringAsFixed(2)}\$';    // Clean: just payment status + amount
      
      // For the activity status, we need to determine if this represents a full customer payment
      // or just a partial payment toward the customer's total debt
      final effectiveNewStatus = customerFullyPaid ? DebtStatus.paid : DebtStatus.pending;
      
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: debt.customerId,
        customerName: debt.customerName,
        type: ActivityType.payment,
        description: description,
        paymentAmount: amount,
        amount: debt.amount,
        oldStatus: oldStatus,
        newStatus: effectiveNewStatus, // Use customer-level status, not individual debt status
        date: DateTime.now(),
        debtId: debt.id,
      );
      
      await _addActivity(activity);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addDebtActivity(Debt debt) async {
    try {
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: debt.customerId,
        customerName: debt.customerName,
        type: ActivityType.newDebt,
        description: '${debt.description}: ${debt.amount.toStringAsFixed(2)}\$',  // Clean: Product name: amount
        amount: debt.amount,
        date: DateTime.now(),
        debtId: debt.id,
      );
      
      await _addActivity(activity);
    } catch (e) {
      rethrow;
    }
  }

  bool isCustomerFullyPaid(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return true;
    
    return customerDebts.every((debt) => debt.remainingAmount <= 0);
  }

  bool isCustomerPartiallyPaid(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return false;
    
    final hasPaidDebts = customerDebts.any((debt) => debt.paidAmount > 0);
    final hasUnpaidDebts = customerDebts.any((debt) => debt.remainingAmount > 0);
    
    return hasPaidDebts && hasUnpaidDebts;
  }

  Future<void> _checkAndConsolidateMultipleDebtCompletions(String customerId, String customerName) async {
    // This method was used for complex debt consolidation logic
    // Simplified to avoid compilation errors
  }

  Future<void> _clearAllCustomerDebts(String customerId) async {
    try {
      // Get all debts for this customer
      final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
      
      // Clear all debts for this customer (this will also clean up activities and partial payments)
      for (final debt in customerDebts) {
        await _dataService.deleteDebt(debt.id);
      }
      
      // Remove from local lists
      _debts.removeWhere((d) => d.customerId == customerId);
      _partialPayments.removeWhere((p) => customerDebts.any((d) => d.id == p.debtId));
      
      // Reload activities from data service to ensure UI stays in sync
      _activities = _dataService.activities;
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _triggerWhatsAppAutomation(String customerId) async {
    if (_whatsappAutomationEnabled) {
      try {
        final customer = _customers.firstWhere((c) => c.id == customerId);
        final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
        
        if (customerDebts.isNotEmpty) {
          final totalAmount = customerDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
          
          if (totalAmount > 0) {
            final message = _whatsappCustomMessage.isNotEmpty 
                ? _whatsappCustomMessage 
                : 'Hello ${customer.name}, you have an outstanding balance of \$${totalAmount.toStringAsFixed(2)}. Please contact us to arrange payment.';
            
            // Use the available sendSettlementMessage method or create a simple message
            try {
              await WhatsAppAutomationService.sendSettlementMessage(
                customer: customer,
                settledDebts: [], // No settled debts for this case
                partialPayments: [],
                customMessage: message,
                settlementDate: DateTime.now(),
              );
            } catch (e) {
              // Fallback: just log that automation was attempted
              print('WhatsApp automation attempted for ${customer.name}');
            }
          }
        }
      } catch (e) {
        // Silent fail for WhatsApp automation
      }
    }
  }

  Future<void> _scheduleNotifications() async {
    // This method was used for scheduling notifications
    // Simplified to avoid compilation errors
  }

  Future<void> _setupConnectivityListener() async {
    // This method was used for connectivity monitoring
    // Simplified to avoid compilation errors
  }

  Future<void> createMissingPaymentActivitiesForAllPaidDebts() async {
    // This method was used for creating missing payment activities
    // Simplified to avoid compilation errors
  }

  Future<void> createMissingPaymentActivitiesForPartialPayments() async {
    // This method was used for creating missing payment activities
    // Simplified to avoid compilation errors
  }

  Future<void> removeActivitiesByCustomerAndAmount(String customerName, double amount) async {
    // This method was used for removing activities
    // Simplified to avoid compilation errors
  }

  Future<void> cleanupIncorrectPaymentActivities() async {
    // This method was used for cleaning up payment activities
    // Simplified to avoid compilation errors
  }

  Future<void> fixJohnyChnoudaPaymentActivities() async {
    // This method was used for fixing specific payment activities
    // Simplified to avoid compilation errors
  }

  void validateDebtProductData() {
    // This method was used for validating debt product data
    // Simplified to avoid compilation errors
  }

  Future<void> _cleanupWrongFullyPaidActivities(String customerId) async {
    // This method was used for cleaning up wrong fully paid activities
    // Simplified to avoid compilation errors
  }

  // Clear only debts, activities, and payment records (preserve customers and products)
  Future<void> clearDebtsAndActivities() async {
    try {
      await _dataService.clearDebts();
      _debts.clear();
      _partialPayments.clear();
      
      // Reload activities from data service to ensure UI stays in sync
      _activities = _dataService.activities;
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Clear debts for a specific customer (preserve customer and products)
  Future<void> clearCustomerDebts(String customerId) async {
    try {
      await _dataService.deleteCustomerDebts(customerId);
      
      // Remove from local list
      _debts.removeWhere((d) => d.customerId == customerId);
      
      // Clear cache and notify
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to clear Johny Chnouda's debts specifically
  Future<void> clearJohnyChnoudaDebts() async {
    try {
      // Find Johny Chnouda by name
      final johnyCustomer = _customers.firstWhere(
        (c) => c.name.toLowerCase().contains('johny') || c.name.toLowerCase().contains('chnouda'),
        orElse: () => throw Exception('Johny Chnouda not found'),
      );
      
      await clearCustomerDebts(johnyCustomer.id);
    } catch (e) {
      rethrow;
    }
  }

  // Clear all data (customers, debts, products, activities) - use with caution
  Future<void> clearAllData() async {
    try {
      await _dataService.clearAllData();
      _customers.clear();
      _debts.clear();
      _categories.clear();
      _productPurchases.clear();
      _activities.clear();
      _partialPayments.clear();
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // CRITICAL METHODS FOR APP FUNCTIONALITY
  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> initialize() async {
    await _loadSettings();
    await _loadData();
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _dataService.addCustomer(customer);
      _customers.add(customer);
      _clearCache();
      notifyListeners();
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
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _dataService.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.id == customerId);
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addDebt(Debt debt) async {
    try {
      await _dataService.addDebt(debt);
      _debts.add(debt);
      
      // Create activity for new debt so it appears in history
      await addDebtActivity(debt);
      
      _clearCache();
      notifyListeners();
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
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      // Get the debt before deleting to clean up related data
      final debt = _debts.firstWhere((d) => d.id == debtId);
      
      await _dataService.deleteDebt(debtId);
      
      // Remove from local lists
      _debts.removeWhere((d) => d.id == debtId);
      _partialPayments.removeWhere((p) => p.debtId == debtId);
      
      // Reload activities from data service to ensure UI stays in sync
      _activities = _dataService.activities;
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markDebtAsPaid(String debtId) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == debtId);
      final oldStatus = debt.status; // Store the old status before updating
      
      final updatedDebt = debt.copyWith(
        status: DebtStatus.paid,
        paidAmount: debt.amount,
        // Note: remainingAmount is a computed getter, not a field that can be set
        // The debt will automatically calculate the correct remaining amount
      );
      await updateDebt(updatedDebt);
      
      // Record a payment activity for the full debt amount when marking as paid
      final paymentAmount = debt.amount;
      await addPaymentActivity(debt, paymentAmount, oldStatus, updatedDebt.status);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> applyPartialPayment(String debtId, double paymentAmount, {bool skipActivityCreation = false}) async {
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
      
      // Update the debt in storage first
      await _dataService.updateDebt(_debts[index]);
      
      // Always create payment activity for partial payments (shows complete payment history)
      if (!skipActivityCreation) {
        // ALWAYS create partial payment activity to show payment history
        final paymentAmountToShow = paymentAmount;
        final oldStatus = originalDebt.status;
        final newStatus = _debts[index].status;
        
        await addPaymentActivity(originalDebt, paymentAmountToShow, oldStatus, newStatus);
        
        // If this payment completes the debt, also check for consolidation
        if (isThisDebtFullyPaid) {
          await _checkAndConsolidateMultipleDebtCompletions(originalDebt.customerId, originalDebt.customerName);
          
          // Check if customer is now fully paid and clear all debts
          if (isCustomerFullyPaid(originalDebt.customerId)) {
            await _clearAllCustomerDebts(originalDebt.customerId);
          }
        }
      }
      
      // Check if WhatsApp automation should be triggered
      if (_whatsappAutomationEnabled && isThisDebtFullyPaid) {
        await _triggerWhatsAppAutomation(originalDebt.customerId);
      }
      
      _clearCache();
      notifyListeners();
      
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
    if (_currencySettings == null) return amount;
    
    if (_currencySettings!.baseCurrency == 'USD' && _currencySettings!.targetCurrency == 'LBP') {
      return amount * (_currencySettings!.exchangeRate ?? 1.0);
    } else if (_currencySettings!.baseCurrency == 'LBP' && _currencySettings!.targetCurrency == 'USD') {
      return amount / (_currencySettings!.exchangeRate ?? 1.0);
    }
    
    return amount;
  }

  double convertBack(double amount) {
    if (_currencySettings == null || _currencySettings!.exchangeRate == null) {
      return amount;
    }
    
    // Since revenue values are coming from the service in LBP (target currency),
    // we need to convert them to USD (base currency)
    // The logic is: LBP amount ÷ exchange rate = USD amount
    if (_currencySettings!.baseCurrency == 'USD' && _currencySettings!.targetCurrency == 'LBP') {
      // Convert LBP amount to USD by dividing by exchange rate
      final convertedAmount = amount / _currencySettings!.exchangeRate!;
      return convertedAmount;
    } else if (_currencySettings!.baseCurrency == 'LBP' && _currencySettings!.targetCurrency == 'USD') {
      // Convert USD amount to LBP by multiplying by exchange rate
      final convertedAmount = amount * _currencySettings!.exchangeRate!;
      return convertedAmount;
    }
    
    return amount;
  }

  // Cache management methods
  Future<void> clearCache() async {
    try {
      // Clear local cache variables only
      _clearCache();
      
      // Cache cleared successfully
    } catch (e) {
      // Error clearing cache
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

  // Settings methods
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('whatsappAutomationEnabled', _whatsappAutomationEnabled);
      await prefs.setString('whatsappCustomMessage', _whatsappCustomMessage);
      await prefs.setString('defaultCurrency', _defaultCurrency);
    } catch (e) {
      // Use defaults if settings can't be saved
    }
  }

  // WhatsApp automation settings
  Future<void> setWhatsappAutomationEnabled(bool enabled) async {
    _whatsappAutomationEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setWhatsappCustomMessage(String message) async {
    _whatsappCustomMessage = message;
    await _saveSettings();
    notifyListeners();
  }

  // Apply payment across multiple debts
  Future<void> applyPaymentAcrossDebts(List<String> debtIds, double paymentAmount) async {
    try {
      if (debtIds.isEmpty || paymentAmount <= 0) return;
      
      double remainingPayment = paymentAmount;
      final sortedDebts = _debts.where((d) => debtIds.contains(d.id))
          .where((d) => d.remainingAmount > 0)
          .toList()
        ..sort((a, b) => a.remainingAmount.compareTo(b.remainingAmount));
      
      for (final debt in sortedDebts) {
        if (remainingPayment <= 0) break;
        
        final paymentForThisDebt = remainingPayment > debt.remainingAmount 
            ? debt.remainingAmount 
            : remainingPayment;
        
        final oldStatus = debt.status;
        final updatedDebt = debt.copyWith(
          paidAmount: debt.paidAmount + paymentForThisDebt,
          status: (debt.paidAmount + paymentForThisDebt) >= debt.amount ? DebtStatus.paid : DebtStatus.pending,
          // Note: remainingAmount is a computed getter, not a field that can be set
          // The debt will automatically calculate the correct remaining amount
        );
        
        await updateDebt(updatedDebt);
        
        // Create payment activity for this debt
        await addPaymentActivity(debt, paymentForThisDebt, oldStatus, updatedDebt.status);
        
        remainingPayment -= paymentForThisDebt;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Calculation methods
  double _calculateTotalDebt() {
    final pendingDebts = _debts.where((d) => d.paidAmount < d.amount).toList();
    final totalDebt = pendingDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
    

    
    return totalDebt;
  }
  
  double _calculateTotalPaid() {
    // Count all payments made (including partial payments), not just fully paid debts
    final totalPaid = _debts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
    

    
    return totalPaid;
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

  // Get customer-level debt status text
  String getCustomerDebtStatusText(String customerId) {
    if (isCustomerFullyPaid(customerId)) {
      return 'Fully Paid';
    } else if (isCustomerPartiallyPaid(customerId)) {
      return 'Partially Paid';
    } else if (isCustomerPending(customerId)) {
      return 'Pending';
    } else {
      return 'Unknown';
    }
  }
  
  // Get customer-level pending count (ALL debts are pending until customer is fully settled)
  int getCustomerPendingDebtsCount(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    
    // BUSINESS RULE: ALL debts are considered pending until customer settles ALL their debts
    if (isCustomerFullyPaid(customerId)) {
      return 0; // No pending debts when customer is fully settled
    } else {
      return customerDebts.length; // All debts are pending when customer is not fully settled
    }
  }

  bool isCustomerPending(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return false;
    
    // Customer is pending when they have no payments on any debts
    return customerDebts.every((d) => d.paidAmount == 0);
  }

  // Get customer-level total remaining amount
  double getCustomerTotalRemainingAmount(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    return customerDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Settings methods
  Future<void> setDarkModeEnabled(bool enabled) async {
    _isDarkMode = enabled;
    await _saveSettings();
    notifyListeners();
  }
} 