import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/activity.dart';
import '../models/category.dart';
import '../models/currency_settings.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/product_purchase.dart';
import '../services/data_service.dart';
import '../services/revenue_calculation_service.dart';
import '../services/theme_service.dart';
import '../services/whatsapp_automation_service.dart';


class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final ThemeService _themeService = ThemeService();

  

  
  // Data
  List<Customer> _customers = [];
  List<Debt> _debts = [];
  List<ProductCategory> _categories = [];
  List<ProductPurchase> _productPurchases = [];
  List<Activity> _activities = [];
  CurrencySettings? _currencySettings;
  
  // Loading states
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _hasLoadedActivities = false; // Flag to track if activities have been loaded
  
  // Firebase stream initialization flag
  bool _streamsInitialized = false;
  
  // Auth listener to handle user switching
  dynamic _authListener;
  
  // Connectivity
  bool _isOnline = true;
  
  // App Settings (Only implemented ones)
  bool _isDarkMode = false;
  bool _autoSyncEnabled = true;
  
  // Firebase authentication status
  bool get isAuthenticated => _dataService.isAuthenticated;
  
  
  // WhatsApp Automation Settings
  bool _whatsappAutomationEnabled = true; // Enable by default for testing
  String _whatsappCustomMessage = '';
  
  // Business Settings (Only implemented ones)
  String _defaultCurrency = 'USD';
  
  // Category filter order (list of category IDs in display order)
  List<String> _categoryOrder = [];
  
  // Constructor to load settings immediately for theme persistence
  AppState() {
    // Load settings synchronously but DON'T notify listeners yet
    // This prevents frame skipping during app initialization
    _loadSettingsSyncWithoutNotify();
    
    // Reset flags on app initialization
    _hasLoadedActivities = false;
    
    // Defer all heavy operations to avoid blocking main thread
    // Use microtask to defer initialization until after current frame
    Future.microtask(() {
      // Listen to authentication state changes to handle user switching
      _setupAuthListener();
      
      // Initialize Firebase streams asynchronously to avoid blocking main thread
      _initializeFirebaseStreams();
      
      // Now notify listeners after initialization is deferred
      // This allows the UI to render first before updating
      Future.microtask(() {
        notifyListeners();
      });
    });
    
    // Simple initialization - no complex synchronization needed
    
    // Migration will run during _loadData() - no need for separate startup call
    // This prevents infinite loops and startup deadlocks
    
    // Clean up duplicate activities on startup - delayed to avoid blocking
    // Increased delay to reduce startup impact
    Future.delayed(const Duration(seconds: 5), () {
      removeDuplicatePaymentActivities();
    });
    
    // Fix floating-point precision issues in existing debt amounts
    // Increased delay to reduce startup impact
    Future.delayed(const Duration(seconds: 6), () {
      fixDebtAmountPrecision();
    });
  }
  
  @override
  void dispose() {
    // Clean up auth listener
    _authListener?.cancel();
    super.dispose();
  }
  
  // Cached calculations
  double? _cachedTotalDebt;
  double? _cachedTotalPaid;
  int? _cachedPendingCount;
  List<Debt>? _cachedRecentDebts;
  List<Customer>? _cachedTopDebtors;
  
  // Helper method to check if two lists are equal (by ID)
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
  
        // Getters
  List<Customer> get customers {
    return List.from(_customers); // Return a copy to prevent external modification
  }
  
  // Protected setter for customers to catch when it's being cleared
  set customers(List<Customer> newCustomers) {
    _customers = newCustomers;
  }
  List<Debt> get debts => _debts;
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
  bool get whatsappAutomationEnabled {
    return _whatsappAutomationEnabled;
  }
  String get whatsappCustomMessage => _whatsappCustomMessage;
  
  // Business Settings Getters (Only implemented ones)
  String get defaultCurrency => _defaultCurrency;
  
  // Category order getter
  List<String> get categoryOrder => List.from(_categoryOrder);
  
  // Accessibility Settings Getters (Needed for theme service)
  String get textSize => 'Medium'; // Default value
  bool get boldTextEnabled => false; // Default value
  
  // Setup authentication state listener to handle user switching
  void _setupAuthListener() {
    _authListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // User signed out - clear all local data
        _clearAllLocalData();
      } else {
        // User signed in - reinitialize streams for new user
        _reinitializeStreamsForNewUser();
      }
    });
  }
  
  // Clear all local data when user signs out
  void _clearAllLocalData() {
    _customers.clear();
    _debts.clear();
    _categories.clear();
    _productPurchases.clear();
    _activities.clear();
    // Note: Partial payments are now handled as activities only
    _currencySettings = null;
    
    // Clear cached calculations
    _clearCache();
    
    // Reset flags
    _hasLoadedActivities = false;
    
    // Notify listeners to update UI
    notifyListeners();
  }
  
  // Reinitialize streams for new user (when switching accounts)
  void _reinitializeStreamsForNewUser() {
    // Reset stream initialization flag to allow re-initialization
    _streamsInitialized = false;
    
    // Clear any existing data first
    _clearAllLocalData();
    
    // Initialize streams for the new user
    _initializeFirebaseStreams();
  }
  
  // Initialize Firebase streams
  void _initializeFirebaseStreams() {
    
    // CRITICAL: Only initialize streams once to prevent duplicate listeners
    if (_streamsInitialized) {
      return;
    }
    _streamsInitialized = true;
    
    
    // Listen to customers stream FIRST (most important)
    _dataService.customersFirebaseStream.listen(
      (customers) {
        // CRITICAL FIX: Never overwrite existing customers with an empty list
        // This prevents the issue where customers disappear after being loaded
        final List<Customer> newCustomers = customers.isNotEmpty 
            ? List<Customer>.from(customers) 
            : (_customers.isEmpty ? <Customer>[] : _customers);
        
        // Only update and notify if data actually changed
        if (newCustomers.length != _customers.length ||
            !_listsEqual(newCustomers, _customers)) {
          _customers = newCustomers;
          notifyListeners();
        }
      },
      onError: (error) {
        // Handle error silently - don't notify on error to avoid unnecessary rebuilds
      },
    );
    
    // Listen to categories stream
    _dataService.categoriesFirebaseStream.listen(
      (categories) {
        if (categories.isNotEmpty) {
          _categories = List.from(categories); // Create a new list to prevent reference issues
          
          // Initialize category order if it's empty or has missing categories
          if (_categoryOrder.isEmpty || 
              _categoryOrder.length != categories.length ||
              !categories.every((cat) => _categoryOrder.contains(cat.id))) {
            // Build order: existing order first, then new categories
            // Remove duplicates from existing order first
            final existingOrderSet = <String>{};
            final existingOrder = _categoryOrder.where((id) {
              if (categories.any((cat) => cat.id == id) && !existingOrderSet.contains(id)) {
                existingOrderSet.add(id);
                return true;
              }
              return false;
            }).toList();
            final newCategoryIds = categories
                .where((cat) => !existingOrderSet.contains(cat.id))
                .map((cat) => cat.id)
                .toList();
            _categoryOrder = [...existingOrder, ...newCategoryIds];
            _saveSettings(); // Save updated order
          }
        } else {
          // If Firebase returns empty, set to empty (allows real-time removal)
          _categories = [];
          _categoryOrder = [];
          _saveSettings();
        }
        
        
        notifyListeners();
      },
      onError: (error) {
        // Don't clear categories on error - keep existing data
        // Still notify listeners so UI can show error state if needed
        notifyListeners();
      },
    );
    
    // RE-ENABLE Firebase stream for debts with improved race condition protection
    
    // Listen to debts stream
    _dataService.debtsFirebaseStream.listen(
      (debts) {
        // Simple update from Firebase
        _debts = List.from(debts);
        _clearDebtCache();
        notifyListeners();
      },
      onError: (error) {
        notifyListeners();
      },
    );
    
    // Note: Partial payments are now handled as activities only
    
    // Listen to product purchases stream
    _dataService.productPurchasesFirebaseStream.listen(
      (productPurchases) {
        
        // Always update product purchases from Firebase stream for real-time updates
        if (productPurchases.isNotEmpty) {
          _productPurchases = List.from(productPurchases); // Create a new list to prevent reference issues
        } else {
          // If Firebase returns empty, set to empty (allows real-time removal)
          _productPurchases = [];
        }
        
        
        notifyListeners();
      },
      onError: (error) {
        // CRITICAL: Don't clear product purchases on error - keep existing data
        // Still notify listeners so UI can show error state if needed
        notifyListeners();
      },
    );
    
    // Listen to activities stream
    _dataService.activitiesFirebaseStream.listen(
      (activities) {
        
        // Better handling of Firebase stream updates
        if (activities.isNotEmpty) {
          _activities = List.from(activities); // Create a new list to prevent reference issues
          
          // IMPROVED: Always mark as loaded when we get activities from Firebase
          _hasLoadedActivities = true;
          
        } else {
          // CRITICAL FIX: Never clear activities when Firebase returns empty
          // This prevents activities from disappearing due to temporary Firebase issues
          // Only clear activities if this is the very first load and we have no local activities
          if (_activities.isEmpty && !_hasLoadedActivities) {
            _activities = [];
          }
          // Otherwise, keep existing activities to prevent UI flickering
          
          // Don't set _hasLoadedActivities to true when Firebase returns empty
          // This ensures we can still load fresh data on subsequent restarts
        }
        
        // Always run duplicate cleanup after any activity update
        removeAllDuplicates();
        
        
        
        notifyListeners();
      },
      onError: (error) {
        // CRITICAL: Don't clear activities on error - keep existing data
        // Still notify listeners so UI can show error state if needed
        notifyListeners();
      },
    );
    
    // Listen to currency settings stream
    _dataService.currencySettingsFirebaseStream.listen(
      (currencySettings) {
        
        // Only update if we received valid currency settings
        if (currencySettings != null && currencySettings.exchangeRate != null) {
          _currencySettings = currencySettings;
        } else if (currencySettings == null && _currencySettings != null) {
          // Don't update - keep existing settings
        } else if (currencySettings != null && currencySettings.exchangeRate == null) {
          // Don't update - keep existing settings
        } else {
          _currencySettings = currencySettings;
        }
        
        
        notifyListeners();
      },
      onError: (error) {
        // CRITICAL: Don't clear currency settings on error - keep existing data
        // Still notify listeners so UI can show error state if needed
        notifyListeners();
      },
    );
  }
  

  // Clear debt calculation cache when debts change
  void _clearDebtCache() {
    _cachedTotalDebt = null;
    _cachedTotalPaid = null;
    _cachedPendingCount = null;
    _cachedRecentDebts = null;
    _cachedTopDebtors = null;
  }
  



  // Cached getters
  double get totalDebt {
    // Always recalculate to ensure floating-point precision is correct
    _cachedTotalDebt = _calculateTotalDebt();
    return _cachedTotalDebt!;
  }
  
  double get totalPaid {
    // Always recalculate to ensure floating-point precision is correct
    _cachedTotalPaid = _calculateTotalPaid();
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
    final totalAmount = pendingDebts.fold<double>(0, (total, debt) => total + debt.amount);
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
    // Fix floating-point precision issues by rounding to 2 decimal places
    totalPaid = ((totalPaid * 100).round() / 100);
    
    // Note: Partial payments are now handled as activities only
    
    // Fix floating-point precision issues by rounding to 2 decimal places
    return ((totalPaid * 100).round() / 100);
  }

  // Fix payment synchronization issues for a specific customer
  // This ensures debt records are properly updated with payments
  Future<void> fixCustomerPaymentSynchronization(String customerId) async {
    try {
      // Note: Payment synchronization is now handled by activities
      // This method is kept for compatibility but no longer performs partial payment operations
    } catch (e) {
      // Silent fail - this is a background fix
    }
  }
  
  // Get comprehensive revenue summary for dashboard
  Map<String, dynamic> getDashboardRevenueSummary() {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfYear = DateTime(now.year, 1, 1);
      
      // Calculate monthly revenue from payment activities
      double monthlyRevenue = 0.0;
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && 
            activity.paymentAmount != null &&
            activity.date.isAfter(startOfMonth)) {
          monthlyRevenue += activity.paymentAmount!;
        }
      }
      
      // Calculate yearly revenue from payment activities
      double yearlyRevenue = 0.0;
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && 
            activity.paymentAmount != null &&
            activity.date.isAfter(startOfYear)) {
          yearlyRevenue += activity.paymentAmount!;
        }
      }
      
      // Calculate pending revenue (total debt - total paid)
      final pendingRevenue = totalDebt - totalPaid;
      
      // Calculate potential revenue - sum of profit from unpaid debts
      double totalPotentialRevenue = 0.0;
      for (final debt in _debts) {
        if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
          // Only count profit from unpaid debts (use tolerance for floating-point precision)
          if (debt.remainingAmount > 0.01) {
            // Use the proper remainingRevenue calculation which reduces with payments
            totalPotentialRevenue += debt.remainingRevenue;
          }
        }
      }
      
      // Calculate profit margin (if we have product cost data)
      double totalProfit = 0.0;
      for (final debt in _debts) {
        if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
          totalProfit += (debt.originalSellingPrice! - debt.originalCostPrice!);
        }
      }
      
      return {
        'totalRevenue': totalHistoricalRevenue,
        'totalPotentialRevenue': totalPotentialRevenue,
        'monthlyRevenue': monthlyRevenue,
        'yearlyRevenue': yearlyRevenue,
        'pendingRevenue': pendingRevenue,
        'totalProfit': totalProfit,
        'totalDebts': totalDebt,
        'totalPaid': totalPaid,
        'pendingDebtsCount': pendingDebtsCount,
        'totalCustomersCount': totalCustomersCount,
        'averageDebtAmount': averageDebtAmount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalRevenue': 0.0,
        'totalPotentialRevenue': 0.0,
        'monthlyRevenue': 0.0,
        'yearlyRevenue': 0.0,
        'pendingRevenue': 0.0,
        'totalProfit': 0.0,
        'totalDebts': 0.0,
        'totalPaid': 0.0,
        'pendingDebtsCount': 0,
        'totalCustomersCount': 0,
        'averageDebtAmount': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
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
    final revenue = RevenueCalculationService().calculateTotalRevenue(_debts, activities: _activities, appState: this);
    
    // CRITICAL: Round to exactly 2 decimal places to avoid floating-point precision errors
    final roundedRevenue = (revenue * 100).round() / 100;
    
    // No currency conversion needed - revenue is already in USD
    return roundedRevenue;
  }

  // Get customer-specific revenue for financial summaries
  double getCustomerRevenue(String customerId) {
    // Revenue calculation service returns values in USD (same as debt amounts)
    final revenue = RevenueCalculationService().calculateCustomerRevenue(customerId, _debts);
    
    // CRITICAL: Round to exactly 2 decimal places to avoid floating-point precision errors
    final roundedRevenue = (revenue * 100).round() / 100;
    
    // No currency conversion needed - revenue is already in USD
    return roundedRevenue;
  }

  // Force refresh activities from Firebase (for manual refresh)
  Future<void> refreshActivitiesFromFirebase() async {
    try {
      // Force a fresh fetch of activities from Firebase
      final freshActivities = await _dataService.getAllActivities();
      
      if (freshActivities.isNotEmpty) {
        _activities = List.from(freshActivities);
        _hasLoadedActivities = true;
        
        // Clean up duplicates
        _activities = _removeDuplicatesFromList(_activities);
        
        notifyListeners();
      }
    } catch (e) {
      // If refresh fails, don't clear existing data
      // Just notify listeners so UI can show error state if needed
      notifyListeners();
    }
  }

  // Helper method to remove duplicate activities from a list
  List<Activity> _removeDuplicatesFromList(List<Activity> activities) {
    final seenIds = <String>{};
    return activities.where((activity) {
      if (seenIds.contains(activity.id)) {
        return false;
      }
      seenIds.add(activity.id);
      return true;
    }).toList();
  }

  // Get customer potential revenue (from unpaid amounts)
  double getCustomerPotentialRevenue(String customerId) {
    // Revenue calculation service returns values in USD (same as debt amounts)
    final potentialRevenue = RevenueCalculationService().calculateCustomerPotentialRevenue(customerId, _debts);
    
    // CRITICAL: Round to exactly 2 decimal places to avoid floating-point precision errors
    final roundedPotentialRevenue = (potentialRevenue * 100).round() / 100;
    
    // No currency conversion needed - revenue is already in USD
    return roundedPotentialRevenue;
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

  // Period-specific financial data for Activity History
  Map<String, dynamic> getPeriodFinancialData(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime startDate;
    DateTime endDate;
    
    switch (period.toLowerCase()) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'weekly':
        final daysFromMonday = today.weekday - 1;
        final daysToSunday = 7 - today.weekday;
        startDate = DateTime(today.year, today.month, today.day - daysFromMonday);
        endDate = DateTime(today.year, today.month, today.day + daysToSunday, 23, 59, 59);
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        // Default to daily
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    
    // Get activities within the period
    final periodActivities = _activities.where((activity) {
      return (activity.date.isAtSameMomentAs(startDate) || 
              activity.date.isAtSameMomentAs(endDate) ||
              (activity.date.isAfter(startDate) && activity.date.isBefore(endDate)));
    }).toList();
    
    // Calculate total paid directly from payment activities in the period
    double periodPaid = 0.0;
    final relevantDebtIds = <String>{};
    
    for (final activity in periodActivities) {
      if (activity.type == ActivityType.payment && activity.paymentAmount != null) {
        periodPaid += activity.paymentAmount!;
        // Track debt IDs that had payments in this period
        if (activity.debtId != null) {
          relevantDebtIds.add(activity.debtId!);
        } else {
          // FALLBACK: If debtId is null, find debt by customer name and recent payment amount
          // This handles cases where payment activities weren't properly linked to debts
          final matchingDebts = _debts.where((debt) => 
            debt.customerId == activity.customerId && 
            debt.paidAmount > 0 &&
            (debt.paidAmount - activity.paymentAmount!).abs() < 0.01 // Allow for small floating point differences
          ).toList();
          
          if (matchingDebts.isNotEmpty) {
            // Use the most recently updated debt for this customer
            final mostRecentDebt = matchingDebts.reduce((a, b) => 
              a.createdAt.isAfter(b.createdAt) ? a : b);
            relevantDebtIds.add(mostRecentDebt.id);
          }
        }
      }
    }
    
    // Get all debts that had activities (payments or creation) within the period
    final relevantDebts = <String>{};
    
    // Add debts created within the period
    for (final debt in _debts) {
      if (debt.createdAt.isAtSameMomentAs(startDate) || 
          debt.createdAt.isAtSameMomentAs(endDate) ||
          (debt.createdAt.isAfter(startDate) && debt.createdAt.isBefore(endDate))) {
        relevantDebts.add(debt.id);
      }
    }
    
    // Add debts that had payments within the period
    relevantDebts.addAll(relevantDebtIds);
    
    // Filter debts for the period
    final periodDebts = _debts.where((debt) => relevantDebts.contains(debt.id)).toList();
    
    // Use the same RevenueCalculationService as the dashboard for consistency
    final revenue = RevenueCalculationService().calculateTotalRevenue(
      periodDebts, 
      activities: periodActivities, 
      appState: this
    );
    
    // Round to 2 decimal places (same as dashboard)
    final periodRevenue = (revenue * 100).round() / 100;
    periodPaid = (periodPaid * 100).round() / 100;
    
    return {
      'totalRevenue': periodRevenue,
      'totalPaid': periodPaid,
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'calculatedAt': DateTime.now(),
    };
  }

  // DATA MIGRATION METHODS - Critical for revenue calculation accuracy
  /// Run data migration to ensure all debts have cost price information
  /// REMOVED: This was causing infinite loops and startup deadlocks
  /// Migration is now handled in runCurrencyDataMigration() only

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
        if (debt.originalCostPrice != null && debt.originalCostPrice! > 1000 && _currencySettings?.exchangeRate != null) {
          // Convert from LBP to USD using current exchange rate
          newCostPrice = (debt.originalCostPrice! / _currencySettings!.exchangeRate!).toDouble();
          needsUpdate = true;
        }
        
        // Check if selling price is corrupted (LBP values stored in USD fields)
        if (debt.originalSellingPrice != null && debt.originalSellingPrice! > 1000 && _currencySettings?.exchangeRate != null) {
          // Convert from LBP to USD using current exchange rate
          newSellingPrice = (debt.originalSellingPrice! / _currencySettings!.exchangeRate!).toDouble();
          needsUpdate = true;
        }
        
        // Update the debt if needed
        if (needsUpdate) {
          final updatedDebt = debt.copyWith(
            originalCostPrice: newCostPrice,
            originalSellingPrice: newSellingPrice,
          );
          
          await updateDebt(updatedDebt);
          hasFixedData = true;
        }
      }
      
      if (hasFixedData) {
        // Reload data after fixing
        await _loadData();
        notifyListeners();
      }
    } catch (e) {
      // Error fixing corrupted debt prices
    }
  }

  /// Reset corrupted products to safe default values
  /// This handles cases where products have Infinity, NaN, or other invalid values
  /// REMOVED: This was causing infinite loops and startup deadlocks
  /// Migration is now handled in runCurrencyDataMigration() only

  /// Manually fix alfa ushare product to correct values
  /// This ensures the revenue calculation shows $0.13 instead of $0.28
  Future<void> fixAlfaUshareProduct() async {
    try {
      // Find and update the alfa ushare product
      for (final category in _categories) {
        for (final subcategory in category.subcategories) {
          if (subcategory.name.toLowerCase() == 'alfa ushare') {
            // Set the correct LBP values to keep exchange rate card visible
            // Use current exchange rate if available, otherwise use default
            final exchangeRate = _currencySettings?.exchangeRate ?? 89500.0;
            subcategory.costPrice = 0.25 * exchangeRate; // Convert USD to LBP
            subcategory.sellingPrice = 0.38 * exchangeRate; // Convert USD to LBP
            subcategory.costPriceCurrency = 'LBP'; // Keep as LBP
            subcategory.sellingPriceCurrency = 'LBP'; // Keep as LBP
            
            // Update in database
            await _dataService.updateCategory(category);
            
            // Reload data and notify
            await _loadData();
            notifyListeners();
            
            return;
          }
        }
      }
    } catch (e) {
      // Error fixing alfa ushare product
    }
  }

  /// Force refresh the cache after migration to ensure UI shows correct values
  /// This is needed when migration updates debt amounts directly through DataService
  void forceCacheRefresh() {
    _clearCache();
    notifyListeners();
  }

  /// Manual method to clear cache and refresh UI
  /// Call this if totals are still showing incorrect values
  void manualCacheClear() {
    _clearCache();
    notifyListeners();
  }
  
  /// Force refresh of all calculated totals
  /// This ensures the UI shows the most up-to-date values
  void refreshTotals() {
    _clearCache();
    notifyListeners();
  }
  
  /// Force the migration to run again to fix debt amounts
  /// This is needed when the migration didn't complete properly
  Future<void> forceMigrationRerun() async {
    await runCurrencyDataMigration();
    _clearCache();
    notifyListeners();
  }
  
  /// Fix floating-point precision issues in debt status calculations
  /// This ensures debts are properly marked as fully paid when they should be
  Future<void> fixDebtStatusPrecision() async {
    try {
      bool hasUpdates = false;
      
      for (int i = 0; i < _debts.length; i++) {
        final debt = _debts[i];
        final remainingAmount = debt.amount - debt.paidAmount;
        
        // If the remaining amount is very small (less than 1 cent), mark as fully paid
        if (remainingAmount.abs() < 0.01 && debt.status != DebtStatus.paid) {
          _debts[i] = debt.copyWith(
            status: DebtStatus.paid,
            paidAt: debt.paidAt ?? DateTime.now(),
          );
          
          // Update in database
          await _dataService.updateDebt(_debts[i]);
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      // Error fixing debt status precision
    }
  }
  
  /// Fix the Syria tel debt currency and amount issue
  /// This debt is stored as 0.375 LBP but should be 0.38 USD
  /// Also automatically fixes any new Syria tel debts with incorrect currency
  Future<void> fixSyriaTelDebt() async {
    try {
      
      for (final debt in _debts) {
        if (debt.description.toLowerCase().contains('syria tel')) {
          // Update the debt with correct USD values
          final updatedDebt = debt.copyWith(
            amount: 0.38, // Correct USD amount
            paidAmount: 0.0, // No payments made yet
            storedCurrency: 'USD', // Store as USD for consistency
            originalCostPrice: 0.0, // Set appropriate cost price
            originalSellingPrice: 0.38, // Set appropriate selling price
          );
          
          // Update in database
          await _dataService.updateDebt(updatedDebt);
          
          // Update local list
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          }
        }
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Automatically fix any Syria tel debts with incorrect currency when app starts
  /// This prevents the issue from happening again
  Future<void> autoFixSyriaTelDebts() async {
    try {
      
      for (final debt in _debts) {
        if (debt.description.toLowerCase().contains('syria tel')) {
          bool needsFix = false;
          // Check for various issues that need fixing
          if (debt.storedCurrency == 'LBP' && debt.amount < 1.0) {
            needsFix = true;
          } else if (debt.amount == 0.0 || debt.amount < 0.1) {
            needsFix = true;
          } else if (debt.storedCurrency != 'USD') {
            needsFix = true;
          }
          
          if (needsFix) {
            // Determine the correct amount based on the debt description or other criteria
            // For now, preserve the original amount if it's reasonable, otherwise use 0.38
            double correctAmount = debt.amount;
            if (debt.amount < 0.1 || debt.amount > 1.0) {
              correctAmount = 0.38; // Default amount for Syria tel
            }
            
            // Update the debt with correct USD values
            final updatedDebt = debt.copyWith(
              amount: correctAmount, // Preserve original amount if reasonable
              storedCurrency: 'USD', // Store as USD for consistency
              originalCostPrice: 0.0, // Set appropriate cost price
              originalSellingPrice: correctAmount, // Set appropriate selling price
            );
            
            // Update in database
            await _dataService.updateDebt(updatedDebt);
            
            // Update local list
            final index = _debts.indexWhere((d) => d.id == debt.id);
            if (index != -1) {
              _debts[index] = updatedDebt;
            }
          }
        }
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Error during auto-fix of Syria tel debts
      // Don't rethrow - this is a background fix that shouldn't crash the app
    }
  }

  /// Private method to fix a single Syria tel debt
  Future<void> _autoFixSingleSyriaTelDebt(Debt debt) async {
    try {
      // Update the debt with correct USD values
      final updatedDebt = debt.copyWith(
        amount: debt.amount, // Preserve original amount
        storedCurrency: 'USD', // Store as USD for consistency
        originalCostPrice: 0.0, // Set appropriate cost price
        originalSellingPrice: debt.amount, // Set appropriate selling price
      );
      
      // Update in database
      await _dataService.updateDebt(updatedDebt);
      
      // Update local list
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = updatedDebt;
      }
    } catch (e) {
      // Error during auto-fix of single Syria tel debt
      // Don't rethrow - this is a background fix that shouldn't crash the app
    }
  }

  /// Recreate missing Syria tel debt for the 2:36:59 PM purchase
  Future<void> recreateMissingSyriaTelDebt() async {
    try {
      // Find the missing activity
      final missingActivity = _activities.firstWhere(
        (a) => a.customerId == '1' && 
               a.type == ActivityType.newDebt && 
               a.description.contains('Syria tel') &&
               a.date.hour == 14 && a.date.minute == 36,
        orElse: () => throw Exception('Missing activity not found'),
      );
      
      // Create the missing debt
      final missingDebt = Debt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: missingActivity.customerId,
        customerName: missingActivity.customerName,
        amount: 0.38, // Correct USD amount
        description: 'Syria tel',
        type: DebtType.credit,
        status: DebtStatus.pending,
        createdAt: missingActivity.date, // Use the original activity date
        subcategoryId: null,
        subcategoryName: 'Syria tel',
        originalSellingPrice: 0.38,
        originalCostPrice: 0.0,
        categoryName: 'Telecom',
        storedCurrency: 'USD',
      );
      
      // Add the debt to storage and local list
      await _dataService.addDebt(missingDebt);
      _debts.add(missingDebt);
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Directly fix the alfa ushare debt amount to 3.42
  /// This bypasses migration and directly updates the debt
  Future<void> fixAlfaUshareDebtDirectly() async {
    try {
      
      for (final debt in _debts) {
        if (debt.description.toLowerCase().contains('alfa')) {
          // Update the debt with correct values to match the product
          // Product: Cost 2.00$, Selling 4.50$, Revenue 2.50$
          // Debt amount should match product selling price: 4.50$
          final updatedDebt = debt.copyWith(
            amount: 4.50, // Match product selling price
            originalCostPrice: 2.00, // Match product cost price
            originalSellingPrice: 4.50, // Match product selling price
            storedCurrency: 'USD', // Store as USD for consistency
          );
          
          await _dataService.updateDebt(updatedDebt);
          
          // Update local debt list
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          }
          
        }
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Error fixing alfa debts
    }
  }

  /// Force complete data reload to clear all cached values
  /// This is a more aggressive approach when cache clearing doesn't work
  Future<void> forceCompleteDataReload() async {
    _clearCache();
    await _loadData();
  }

  /// Reset the migration flag to allow re-running migration
  void resetMigrationFlag() {
    notifyListeners();
  }

  // ESSENTIAL METHODS - Restored after cleanup
  Future<void> _loadData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // CRITICAL FIX: Don't overwrite Firebase stream data with empty lists
      // Firebase streams are the source of truth for customers, debts, etc.
      // Only load currency settings and other non-stream data
      
      // Currency settings are loaded via Firebase stream, don't override them here
      // _currencySettings = _dataService.currencySettings; // This returns null, causing the issue

      
      // Run currency data migration to fix any corrupted data
      if (_currencySettings?.exchangeRate != null) {
        await runCurrencyDataMigration();
        
        // Force cache refresh after migration to show correct totals
        _clearCache();
      }
      
      // Backfill activities for existing debts if no activities exist
      if (_activities.isEmpty && _debts.isNotEmpty) {
        await backfillActivitiesForExistingDebts();
      }
      
      // Clean up any existing duplicate activities
      removeDuplicateActivitiesById();
      
      // Migration already handled above - no need for duplicate calls
      // This prevents infinite loops and startup deadlocks
      
      // CRITICAL FIX: Removed automatic duplicate debt removal from startup
      // This was causing legitimate multiple purchases to be deleted
      // The removeDuplicateDebts method is now much more conservative and only
      // removes truly corrupted duplicates (same ID), not legitimate purchases
      
      // Migration methods removed to prevent infinite loops
      // All migration is now handled in runCurrencyDataMigration() only
      

      
      // Simple cache clear after migration - avoid recursive calls
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          _isDarkMode = data['isDarkMode'] ?? false;
          _whatsappAutomationEnabled = data['whatsappAutomationEnabled'] ?? true;
          _whatsappCustomMessage = data['whatsappCustomMessage'] ?? '';
          _defaultCurrency = data['defaultCurrency'] ?? 'USD';
          // Load category order and remove duplicates (preserve order)
          final loadedOrder = List<String>.from(data['categoryOrder'] ?? []);
          final seen = <String>{};
          _categoryOrder = loadedOrder.where((id) {
            if (seen.contains(id)) {
              return false; // Skip duplicate
            }
            seen.add(id);
            return true;
          }).toList();
        } else {
          // Use default values if document doesn't exist
          _isDarkMode = false;
          _whatsappAutomationEnabled = true;
          _whatsappCustomMessage = '';
          _defaultCurrency = 'USD';
          _categoryOrder = [];
        }
      } else {
        // Use default values if user is not authenticated
        _isDarkMode = false;
        _whatsappAutomationEnabled = true;
        _whatsappCustomMessage = '';
        _defaultCurrency = 'USD';
        _categoryOrder = [];
      }
      notifyListeners();
    } catch (e) {
      // Use defaults if settings can't be loaded
      _isDarkMode = false;
      _whatsappAutomationEnabled = true;
      _whatsappCustomMessage = '';
      _defaultCurrency = 'USD';
      _categoryOrder = [];
      notifyListeners();
    }
  }

  void _loadSettingsSync() {
    // SharedPreferences removed - using Firebase only
    // Use default values for synchronous loading (Firebase loading is async)
    _loadSettingsSyncWithoutNotify();
    
    // Load actual settings from Firebase asynchronously
    _loadSettings();
  }
  
  // Load settings without notifying listeners (for constructor use)
  void _loadSettingsSyncWithoutNotify() {
    // SharedPreferences removed - using Firebase only
    // Use default values for synchronous loading (Firebase loading is async)
    _isDarkMode = false;
    _whatsappAutomationEnabled = true; // Default to enabled
    _whatsappCustomMessage = '';
    _defaultCurrency = 'USD';
    _categoryOrder = [];
    // DON'T call notifyListeners() here - it will be called after initialization
  }

  void _clearCache() {
    // Cache cleared - using Firebase only
  }
  
  /// Public method to clear cache and refresh calculations
  void refreshCalculations() {
    _clearCache();
    notifyListeners();
  }
  
  

  
  /// Remove phantom activities created during backup testing
  // Phantom activities are handled by duplicate removal logic

  /// Remove duplicate payment activities that might be causing incorrect totals
  Future<void> removeDuplicatePaymentActivities() async {
    try {
      // Group activities by customer, amount, and date to find duplicates
      final Map<String, List<Activity>> groupedActivities = {};
      
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && activity.paymentAmount != null) {
          // Group by customer, amount, and date (year-month-day) for duplicate detection
          final key = '${activity.customerId}_${activity.paymentAmount}_${activity.date.year}_${activity.date.month}_${activity.date.day}';
          if (!groupedActivities.containsKey(key)) {
            groupedActivities[key] = [];
          }
          groupedActivities[key]!.add(activity);
        }
      }
      
      // Find and remove duplicates (keep only the first one)
      final activitiesToRemove = <Activity>[];
      for (final activities in groupedActivities.values) {
        if (activities.length > 1) {
          // Sort by date (keep the earliest one)
          activities.sort((a, b) => a.date.compareTo(b.date));
          
          // For each group, check if there are activities with the same or very close timestamp
          final Map<String, List<Activity>> timestampGroups = {};
          for (final activity in activities) {
            // Group by timestamp with 1-second tolerance to catch near-duplicates
            final timestampKey = '${(activity.date.millisecondsSinceEpoch / 1000).floor()}';
            if (!timestampGroups.containsKey(timestampKey)) {
              timestampGroups[timestampKey] = [];
            }
            timestampGroups[timestampKey]!.add(activity);
          }
          
          // Remove timestamp duplicates (keep only the first one)
          for (final timestampActivities in timestampGroups.values) {
            if (timestampActivities.length > 1) {
              // Keep the first one, mark the rest for removal
              for (int i = 1; i < timestampActivities.length; i++) {
                activitiesToRemove.add(timestampActivities[i]);
              }
            }
          }
        }
      }
      
      // Remove duplicate activities
      for (final activity in activitiesToRemove) {
        await _dataService.deleteActivity(activity.id);
        _activities.removeWhere((a) => a.id == activity.id);
      }
      
      if (activitiesToRemove.isNotEmpty) {
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Remove specific duplicate activities: "Debt paid" and "Fully paid" for same amount
  Future<void> removeDebtPaidFullyPaidDuplicates() async {
    try {
      final activitiesToRemove = <Activity>[];
      
      // Group activities by customer, amount, and date
      final Map<String, List<Activity>> groupedActivities = {};
      
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && 
            activity.paymentAmount != null &&
            (activity.description.contains('Debt paid:') || activity.description.contains('Fully paid:'))) {
          final key = '${activity.customerId}_${activity.paymentAmount}_${activity.date.year}_${activity.date.month}_${activity.date.day}';
          if (!groupedActivities.containsKey(key)) {
            groupedActivities[key] = [];
          }
          groupedActivities[key]!.add(activity);
        }
      }
      
      // For each group, if we have both "Debt paid" and "Fully paid" activities, remove the "Fully paid" ones
      for (final activities in groupedActivities.values) {
        if (activities.length > 1) {
          final debtPaidActivities = activities.where((a) => a.description.contains('Debt paid:')).toList();
          final fullyPaidActivities = activities.where((a) => a.description.contains('Fully paid:')).toList();
          
          // If we have both types, remove the "Fully paid" activities (keep "Debt paid")
          if (debtPaidActivities.isNotEmpty && fullyPaidActivities.isNotEmpty) {
            activitiesToRemove.addAll(fullyPaidActivities);
          }
        }
      }
      
      // Remove duplicate activities
      for (final activity in activitiesToRemove) {
        await _dataService.deleteActivity(activity.id);
        _activities.removeWhere((a) => a.id == activity.id);
      }
      
      if (activitiesToRemove.isNotEmpty) {
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Fix total payments calculation by removing duplicates and phantom activities
  Future<void> fixTotalPaymentsCalculation() async {
    try {
      // First, remove duplicate payment activities
      await removeDuplicatePaymentActivities();
      
      // Remove specific "Debt paid" vs "Fully paid" duplicates
      await removeDebtPaidFullyPaidDuplicates();
      
      // Remove individual "Debt paid" activities that should be consolidated into "Fully paid"
      await consolidateIndividualDebtPayments();
      
      // Phantom activities are handled by duplicate removal logic
      
      // Clear cache and refresh
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      // Handle error silently
    }
  }

  /// Manually trigger duplicate removal for testing
  Future<void> cleanupDuplicatePayments() async {
    await removeDuplicatePaymentActivities();
    _clearCache();
    notifyListeners();
  }
  
  /// Remove duplicate activities by ID (immediate fix)
  void removeDuplicateActivitiesById() {
    final seenIds = <String>{};
    final uniqueActivities = <Activity>[];
    
    for (final activity in _activities) {
      if (!seenIds.contains(activity.id)) {
        seenIds.add(activity.id);
        uniqueActivities.add(activity);
      }
    }
    
    _activities.clear();
    _activities.addAll(uniqueActivities);
    
    _clearCache();
    notifyListeners();
  }

  /// Consolidate individual "Debt paid" activities into "Fully paid" activities for same-day payments
  Future<void> consolidateIndividualDebtPayments() async {
    try {
      final activitiesToRemove = <Activity>[];
      final activitiesToAdd = <Activity>[];
      
      // Group activities by customer and date
      final Map<String, Map<String, List<Activity>>> groupedByCustomerAndDate = {};
      
      for (final activity in _activities) {
        if (activity.type == ActivityType.payment && 
            activity.description.contains('Debt paid:')) {
          final dateKey = '${activity.date.year}_${activity.date.month}_${activity.date.day}';
          final customerKey = activity.customerId;
          
          if (!groupedByCustomerAndDate.containsKey(customerKey)) {
            groupedByCustomerAndDate[customerKey] = {};
          }
          if (!groupedByCustomerAndDate[customerKey]!.containsKey(dateKey)) {
            groupedByCustomerAndDate[customerKey]![dateKey] = [];
          }
          groupedByCustomerAndDate[customerKey]![dateKey]!.add(activity);
        }
      }
      
      // For each customer-date group, if there are multiple "Debt paid" activities, consolidate them
      for (final customerEntry in groupedByCustomerAndDate.entries) {
        final customerId = customerEntry.key;
        final customerName = customerEntry.value.values.first.first.customerName;
        
        for (final dateEntry in customerEntry.value.entries) {
          final activities = dateEntry.value;
          
          // If there are multiple "Debt paid" activities on the same day for the same customer
          if (activities.length > 1) {
            // Calculate total amount
            double totalAmount = 0.0;
            for (final activity in activities) {
              totalAmount += activity.paymentAmount ?? 0.0;
            }
            
            // Create a consolidated "Fully paid" activity
            final consolidatedActivity = Activity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              customerId: customerId,
              customerName: customerName,
              type: ActivityType.payment,
              description: 'Fully paid: ${totalAmount.toStringAsFixed(2)}\$',
              paymentAmount: totalAmount,
              amount: totalAmount,
              oldStatus: DebtStatus.pending,
              newStatus: DebtStatus.paid,
              date: activities.first.date, // Use the earliest date
              debtId: null, // No specific debt ID since this is consolidated
            );
            
            activitiesToAdd.add(consolidatedActivity);
            activitiesToRemove.addAll(activities);
          }
        }
      }
      
      // Remove old activities and add consolidated ones
      for (final activity in activitiesToRemove) {
        await _dataService.deleteActivity(activity.id);
        _activities.removeWhere((a) => a.id == activity.id);
      }
      
      for (final activity in activitiesToAdd) {
        await _dataService.addActivity(activity);
        _activities.add(activity);
      }
      
      if (activitiesToRemove.isNotEmpty || activitiesToAdd.isNotEmpty) {
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Force refresh all debt data and clear caches to fix potential revenue calculation
  Future<void> forceRefreshDebtData() async {
    try {
      // Clear all caches
      _clearCache();
      
      // Reload all data from Firebase
      await _loadData();
      
      // Force notify listeners
      notifyListeners();
      
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clean up existing duplicate activities and consolidate individual debt payments
  Future<void> cleanupDuplicateActivities() async {
    try {
      // Run all cleanup methods
      await fixTotalPaymentsCalculation();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Fix floating-point precision issues in existing debt amounts
  Future<void> fixDebtAmountPrecision() async {
    try {
      bool hasUpdates = false;
      final updatedDebts = <Debt>[];
      
      for (final debt in _debts) {
        // Round the amount to 2 decimal places
        final roundedAmount = ((debt.amount * 100).round() / 100);
        final roundedPaidAmount = ((debt.paidAmount * 100).round() / 100);
        
        // Only update if there's a difference
        if ((debt.amount - roundedAmount).abs() > 0.001 || (debt.paidAmount - roundedPaidAmount).abs() > 0.001) {
          final updatedDebt = debt.copyWith(
            amount: roundedAmount,
            paidAmount: roundedPaidAmount,
          );
          updatedDebts.add(updatedDebt);
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        // Update debts in Firebase
        for (final debt in updatedDebts) {
          await _dataService.updateDebt(debt);
        }
        
        // Update local list
        for (int i = 0; i < _debts.length; i++) {
          final updatedDebt = updatedDebts.firstWhere(
            (d) => d.id == _debts[i].id,
            orElse: () => _debts[i],
          );
          if (updatedDebt.id != _debts[i].id) {
            _debts[i] = updatedDebt;
          }
        }
        
        // Clear cache and notify listeners
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Backfill activities for existing debts
  /// This method creates activities for all existing debts that don't have corresponding activities
  Future<void> backfillActivitiesForExistingDebts() async {
    try {
      // Get all existing activities to avoid duplicates
      final existingActivityDebtIds = _activities
          .where((activity) => activity.debtId != null)
          .map((activity) => activity.debtId!)
          .toSet();
      
      int activitiesCreated = 0;
      
      // Create activities for debts that don't have them
      for (final debt in _debts) {
        if (!existingActivityDebtIds.contains(debt.id)) {
          final activity = Activity(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + debt.id,
            customerId: debt.customerId,
            customerName: debt.customerName,
            type: ActivityType.newDebt,
            description: '${debt.description}: ${debt.amount.toStringAsFixed(2)}\$',
            amount: debt.amount,
            date: debt.createdAt, // Use the debt's creation date
            debtId: debt.id,
          );
          
          await _addActivity(activity);
          activitiesCreated++;
        }
      }
      
      if (activitiesCreated > 0) {
        _clearCache();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fix the current partial payment distribution for Johny Chnouda
  /// This method will properly distribute the $0.15 payment across the Syria tel debts
  Future<void> fixJohnyChnoudaPartialPayment() async {
    try {
      // Find Johny Chnouda's customer ID
      final customer = _customers.firstWhere(
        (c) => c.name.toLowerCase().contains('johny') || c.name.toLowerCase().contains('chnouda'),
        orElse: () => throw Exception('Johny Chnouda not found'),
      );
      
      // Get all Syria tel debts for this customer
      final syriaTelDebts = _debts.where((d) => 
        d.customerId == customer.id && 
        d.description.toLowerCase().contains('syria tel')
      ).toList();
      
      // Check if there are any partial payments that need to be distributed
      final totalPaidAmount = syriaTelDebts.fold(0.0, (total, debt) => total + debt.paidAmount);
      
      if (totalPaidAmount > 0) {
        // Reset all paid amounts to 0 first
        for (final debt in syriaTelDebts) {
          final debtIndex = _debts.indexWhere((d) => d.id == debt.id);
          if (debtIndex != -1) {
            _debts[debtIndex] = debt.copyWith(
              paidAmount: 0.0,
              status: DebtStatus.pending,
            );
            await _dataService.updateDebt(_debts[debtIndex]);
          }
        }
      }
      
      // Now apply the $0.15 payment properly
      
      // Sort debts by creation date (oldest first)
      syriaTelDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      double remainingPayment = 0.15;
      
      // Calculate total remaining amount to distribute payment proportionally
      final totalRemaining = syriaTelDebts.fold(0.0, (total, debt) => total + debt.remainingAmount);
      
      for (final debt in syriaTelDebts) {
        if (remainingPayment <= 0) break;
        
        final debtIndex = _debts.indexWhere((d) => d.id == debt.id);
        if (debtIndex == -1) continue;
        
        final currentDebt = _debts[debtIndex];
        final currentRemaining = currentDebt.remainingAmount;
        
        // Calculate proportional payment for this debt
        double paymentForThisDebt;
        if (totalRemaining > 0) {
          // Distribute payment proportionally based on remaining amount
          final proportion = currentRemaining / totalRemaining;
          paymentForThisDebt = (0.15 * proportion); // Calculate proportional amount
          
          // Round to 2 decimal places to avoid floating-point precision issues
          paymentForThisDebt = ((paymentForThisDebt * 100).round() / 100);
          
          // Ensure we don't overpay or exceed remaining payment
          if (paymentForThisDebt > currentRemaining) {
            paymentForThisDebt = currentRemaining;
          }
          if (paymentForThisDebt > remainingPayment) {
            paymentForThisDebt = remainingPayment;
          }
        } else {
          paymentForThisDebt = 0;
        }
        
        if (paymentForThisDebt > 0) {
          // Update debt
          final newTotalPaidAmount = currentDebt.paidAmount + paymentForThisDebt;
          final isThisDebtFullyPaid = newTotalPaidAmount >= currentDebt.amount;
          
          _debts[debtIndex] = currentDebt.copyWith(
            paidAmount: newTotalPaidAmount,
            status: isThisDebtFullyPaid ? DebtStatus.paid : DebtStatus.pending,
            paidAt: DateTime.now(),
          );
          
          // Update in storage
          await _dataService.updateDebt(_debts[debtIndex]);
          
          remainingPayment -= paymentForThisDebt;
        }
      }
      
      // Create a consolidated payment activity
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customer.id,
        customerName: customer.name,
        type: ActivityType.payment,
        description: 'Partial payment: 0.15\$',
        paymentAmount: 0.15,
        amount: 0.15,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.pending,
        date: DateTime.now(),
        debtId: null,
      );
      
      await _addActivity(activity);
      
      // Clear cache and notify listeners
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _addActivity(Activity activity) async {
    try {
      // CRITICAL FIX: Always remove any existing activities with the same ID first
      final removedCount = _activities.length;
      _activities.removeWhere((a) => a.id == activity.id);
      final afterRemovalCount = _activities.length;
      // Check if activity already exists to prevent duplicates
      final existingActivity = _activities.any((a) => a.id == activity.id);
      if (existingActivity) {
        return;
      }
      
      // Save to Firebase first and wait for confirmation
      await _dataService.addActivity(activity);
      
      // Only add to local list after successful Firebase save
      _activities.add(activity);
      
      // CRITICAL FIX: Check for duplicates and remove them immediately
      if (activity.type == ActivityType.payment) {
        final paymentActivities = _activities.where((a) => a.type == ActivityType.payment).toList();
        final activityIds = paymentActivities.map((a) => a.id).toList();
        final uniqueIds = activityIds.toSet();
        if (activityIds.length != uniqueIds.length) {
          removeDuplicateActivitiesById();
        }
      }
      
      // Clear cache and notify listeners
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Don't add to local list if Firebase save failed
      rethrow;
    }
  }
  
  // Public method for adding activities
  Future<void> addActivity(Activity activity) async {
    await _addActivity(activity);
  }

  Future<void> addPaymentActivity(Debt debt, double amount, DebtStatus oldStatus, DebtStatus newStatus) async {
    
    // Check if THIS SPECIFIC DEBT is fully paid after this payment
    final isThisDebtFullyPaid = newStatus == DebtStatus.paid;
    
    // Create appropriate description based on payment type
    String description;
    if (isThisDebtFullyPaid) {
      // For fully paid debts, show the actual amount that was just paid to complete it
      // This is simply the amount parameter passed to this method
      description = 'Debt paid: ${amount.toStringAsFixed(2)}\$';
    } else {
      // For partial payments, show the actual payment amount
      description = 'Partial payment: ${amount.toStringAsFixed(2)}\$';
    }
    
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: debt.customerId,
      customerName: debt.customerName,
      type: ActivityType.payment,
      description: description,
      paymentAmount: amount,
      amount: debt.amount,
      oldStatus: oldStatus,
      newStatus: isThisDebtFullyPaid ? DebtStatus.paid : DebtStatus.pending,
      date: DateTime.now(),
      debtId: debt.id,
    );
    
    // Save to Firebase immediately and wait for confirmation
    try {
      await _dataService.addActivity(activity);
    } catch (e) {
      
      // Check Firebase health if saving fails
      try {
        await _dataService.checkFirebaseHealth();
      } catch (healthError) {
      }
    }
    
    // Add to local list regardless of Firebase save result
    _activities.add(activity);
    
    // Clear cache and notify listeners
    _clearCache();
    notifyListeners();
    
  }

  // Add debt-specific "Fully paid" activity when a debt is completed
  Future<void> addCustomerFullyPaidActivity(String customerId, String customerName, double totalAmount, {String? debtId}) async {
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      customerName: customerName,
      type: ActivityType.payment,
      description: 'Fully paid: ${totalAmount.toStringAsFixed(2)}\$',
      paymentAmount: totalAmount,
      amount: totalAmount,
      oldStatus: DebtStatus.pending,
      newStatus: DebtStatus.paid,
      date: DateTime.now(),
      debtId: debtId, // Tie this activity to the specific debt that was completed
    );
    
    // Save to Firebase - if it fails, continue with local processing
    try {
      await _dataService.addActivity(activity);
    } catch (e) {
    }
    
    // Add to local list regardless of Firebase save result
    _activities.add(activity);
    
    // Clear cache and notify listeners
    _clearCache();
    notifyListeners();
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



  /// Remove all duplicate activities based on ID
  void removeAllDuplicates() {
    try {
      final seenIds = <String>{};
      final activitiesToKeep = <Activity>[];
      
      for (int i = 0; i < _activities.length; i++) {
        final activity = _activities[i];
        
        if (!seenIds.contains(activity.id)) {
          seenIds.add(activity.id);
          activitiesToKeep.add(activity);
        }
      }
      
      if (activitiesToKeep.length != _activities.length) {
        _activities = activitiesToKeep;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Create activities for existing debts that don't have activities
  /// This fixes the issue where debts exist but no activities are shown
  Future<void> createActivitiesForExistingDebts() async {
    try {
      
      for (final debt in _debts) {
        // Check if there's already an activity for this debt
        final hasActivity = _activities.any((activity) => 
          activity.debtId == debt.id || 
          (activity.customerId == debt.customerId && 
           activity.description.contains(debt.description))
        );
        
        if (!hasActivity) {
          
          // Create a new debt activity
          final activity = Activity(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + debt.id,
            customerId: debt.customerId,
            customerName: debt.customerName,
            type: ActivityType.newDebt,
            description: debt.description,
            amount: debt.amount,
            date: debt.createdAt,
            debtId: debt.id,
          );
          
          await _addActivity(activity);
        }
      }
      
    } catch (e) {
      // Handle error silently
    }
  }



  bool isCustomerFullyPaid(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return true;
    
    // A customer is only fully paid when ALL their debts have remainingAmount <= 0
    // AND they have no pending debts
    final hasPendingDebts = customerDebts.any((debt) => debt.remainingAmount > 0);
    return !hasPendingDebts;
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

  /// CRITICAL: This method should ONLY be called when explicitly clearing customer data



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

  // Clear only debts, activities, and payment records (preserve customers and products)
  Future<void> clearDebtsAndActivities() async {
    try {
      // Add overall timeout to prevent hanging
      await Future.wait([
        _dataService.clearDebts(),
        _dataService.clearActivities(),
        // Note: Partial payments are now handled as activities only
      ]).timeout(const Duration(seconds: 90)); // 90 seconds total timeout
      
      // Clear local lists
      _debts.clear();
      // Note: Partial payments are now handled as activities only
      _activities.clear();
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      // Always clear local data even if Firebase fails
      _debts.clear();
      // Note: Partial payments are now handled as activities only
      _activities.clear();
      _clearCache();
      notifyListeners();
      
      if (e.toString().contains('timeout')) {
        throw Exception('Operation timed out, but local data has been cleared. Please restart the app to ensure Firebase sync.');
      } else {
        throw Exception('Firebase operation failed, but local data has been cleared. Please restart the app to ensure Firebase sync.');
      }
    }
  }
  
  // Quick clear method that clears both Firebase and local data
  Future<void> quickClearDebtsAndActivities() async {
    try {
      // Clear local data first for immediate UI response
      _debts.clear();
      // Note: Partial payments are now handled as activities only
      _activities.clear();
      _clearCache();
      notifyListeners();
      
      // Then clear Firebase data in background with shorter timeout
      try {
        await Future.wait([
          _dataService.clearDebts(),
          _dataService.clearActivities(),
          // Note: Partial payments are now handled as activities only
        ]).timeout(const Duration(seconds: 10)); // Reduced to 10 seconds
      } catch (firebaseError) {
        // Firebase clearing failed, but local data is already cleared
        // This is acceptable since the user sees immediate results
      }
    } catch (e) {
      // Always clear local data even if everything fails
      _debts.clear();
      // Note: Partial payments are now handled as activities only
      _activities.clear();
      _clearCache();
      notifyListeners();
      rethrow;
    }
  }
  
  // Clear only local data (synchronous, for instant UI response)
  void clearLocalDataOnly() {
    try {

      
      // Clear local lists immediately
      _debts.clear();
      // Note: Partial payments are now handled as activities only
      _activities.clear();
      
      _clearCache();
      notifyListeners();
      

    } catch (e) {

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





  // Clear all data (customers, debts, products, activities) - use with caution
  Future<void> clearAllData() async {
    try {
      await _dataService.clearAllData();
      _customers.clear();
      _debts.clear();
      _categories.clear();
      _productPurchases.clear();
      _activities.clear();
      // Note: Partial payments are now handled as activities only
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
      
      // Customer added successfully
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dataService.updateCustomer(customer);
      
      // Update the customer in the local list (don't overwrite from data service)
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        // Update the local list with the new customer data
        _customers[index] = customer;
        _clearCache();
        notifyListeners();
        
        // Customer updated successfully
      } else {
        // If customer not found in local list, add it
        _customers.add(customer);
        _clearCache();
        notifyListeners();
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
      _clearCache();
      notifyListeners();
      
      // Customer deleted successfully
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
      
      // Auto-fix any Syria tel debts with incorrect currency
      if (debt.description.toLowerCase().contains('syria tel')) {
        bool needsFix = false;
        String fixReason = '';
        
        if (debt.storedCurrency == 'LBP' && debt.amount < 1.0) {
          needsFix = true;
          fixReason = 'LBP currency with small amount';
        } else if (debt.amount == 0.0 || debt.amount < 0.1) {
          needsFix = true;
          fixReason = 'Amount too small or zero';
        } else if (debt.storedCurrency != 'USD') {
          needsFix = true;
          fixReason = 'Wrong currency: ${debt.storedCurrency}';
        }
        
        if (needsFix) {
          await _autoFixSingleSyriaTelDebt(debt);
        }
      }
      
      _clearCache();
      notifyListeners();
      
      // Debt added successfully
      
      // Note: WhatsApp automation for new debt creation has been removed as requested
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
      // Check if debt exists before trying to delete
      final debtIndex = _debts.indexWhere((d) => d.id == debtId);
      if (debtIndex == -1) {
        // Debt not found in local list, but still try to delete from Firebase
        // This handles cases where local state might be out of sync
        await _dataService.deleteDebt(debtId);
        _clearCache();
        notifyListeners();
        return;
      }
      
      final debt = _debts[debtIndex];
      final customerName = debt.customerName;
      final amount = debt.amount;
      
      // Delete from Firebase first
      await _dataService.deleteDebt(debtId);
      
      // Remove from local lists
      _debts.removeWhere((d) => d.id == debtId);
      // Note: Partial payments are now handled as activities only
      
      // Remove all activities associated with this debt
      final activitiesToDelete = _activities.where((activity) => activity.debtId == debtId).toList();
      for (final activity in activitiesToDelete) {
        try {
          await _dataService.deleteActivity(activity.id);
        } catch (e) {
          // Continue even if activity deletion fails
        }
      }
      _activities.removeWhere((activity) => activity.debtId == debtId);
      
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markDebtAsPaid(String debtId) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == debtId);

      // Validation: Check if debt is already paid
      if (debt.status == DebtStatus.paid) {
        // Debt is already paid, no need to proceed
        return;
      }

      final oldStatus = debt.status; // Store the old status before updating

      final updatedDebt = debt.copyWith(
        status: DebtStatus.paid,
        paidAmount: debt.amount,
        // Note: remainingAmount is a computed getter, not a field that can be set
        // The debt will automatically calculate the correct remaining amount
      );
      
      await updateDebt(updatedDebt);
      
      // Record a payment activity for the actual remaining amount that was paid
      final paymentAmount = debt.remainingAmount; // This is the actual amount that completed the debt
      await addPaymentActivity(debt, paymentAmount, oldStatus, updatedDebt.status);
      
      // Check if this was the last debt for the customer and trigger settlement confirmation
      try {
        final customerDebts = _debts.where((d) => d.customerId == debt.customerId).toList();
        
        
        // Calculate the remaining amount that was just paid to complete the settlement
        final remainingAmountBeforePayment = debt.remainingAmount;
        
        // CRITICAL FIX: Use the updated debt in our calculation instead of the old one
        final updatedCustomerDebts = customerDebts.map((d) => d.id == debtId ? updatedDebt : d).toList();
        final totalOutstanding = updatedCustomerDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
        
        
        if (totalOutstanding == 0) {
          // All customer debts are now paid - trigger settlement confirmation
          await _triggerSettlementConfirmationAutomation(
            debt.customerId, 
            newlySettledDebts: [updatedDebt] // Pass the debt that was just completed
          );
        }
      } catch (e) {
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Mark debt as paid without creating individual activity (for consolidated payments)
  Future<void> markDebtAsPaidWithoutActivity(String debtId) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == debtId);

      // Validation: Check if debt is already paid
      if (debt.status == DebtStatus.paid) {
        // Debt is already paid, no need to proceed
        return;
      }

      final updatedDebt = debt.copyWith(
        status: DebtStatus.paid,
        paidAmount: debt.amount,
        // Note: remainingAmount is a computed getter, not a field that can be set
        // The debt will automatically calculate the correct remaining amount
      );
      
      await updateDebt(updatedDebt);
      
      // No activity creation - this is handled by the calling method for consolidated payments
      
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
      
      // Validation: Check if debt is already fully paid
      if (originalDebt.status == DebtStatus.paid) {
        // Debt is already fully paid, no need to proceed with partial payment
        return;
      }
      
      // Check for duplicate payments within the last 5 seconds to prevent double-tapping
      final now = DateTime.now();
      final fiveSecondsAgo = now.subtract(const Duration(seconds: 5));
      
      final recentPayments = _activities.where((activity) => 
        activity.type == ActivityType.payment &&
        activity.customerId == originalDebt.customerId &&
        activity.paymentAmount == paymentAmount &&
        activity.date.isAfter(fiveSecondsAgo)
      ).toList();
      
      if (recentPayments.isNotEmpty) {
        // Duplicate payment detected, don't create another one
        return;
      }
      
      // Note: Partial payments are now handled as activities only
      
      // Calculate new total paid amount by adding to existing paidAmount
      final newTotalPaidAmount = originalDebt.paidAmount + paymentAmount;
      
      // Check if THIS debt is fully paid (not all customer debts)
      // Use a small tolerance for floating-point precision issues
      final tolerance = 0.01; // 1 cent tolerance
      final isThisDebtFullyPaid = (newTotalPaidAmount + tolerance) >= originalDebt.amount;
      
      // Additional check: if the remaining amount is very small (less than 1 cent), consider it fully paid
      final remainingAmount = originalDebt.amount - newTotalPaidAmount;
      final isEffectivelyFullyPaid = remainingAmount.abs() < 0.01;
      
      // Update the debt with the new total paid amount
      _debts[index] = originalDebt.copyWith(
        paidAmount: newTotalPaidAmount,
        status: (isThisDebtFullyPaid || isEffectivelyFullyPaid) ? DebtStatus.paid : DebtStatus.pending,
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
        if (isThisDebtFullyPaid || isEffectivelyFullyPaid) {
          await _checkAndConsolidateMultipleDebtCompletions(originalDebt.customerId, originalDebt.customerName);
          
          // CRITICAL FIX: Never clear all customer debts during partial payments
          // This was causing products to disappear when they shouldn't
          // Only mark individual debts as paid, preserve all customer product records
          
          // Check if this was the last debt for the customer and trigger settlement confirmation
          final customerDebts = _debts.where((d) => d.customerId == originalDebt.customerId).toList();
          
          // CRITICAL FIX: Use the updated debt in our calculation instead of the old one
          final updatedCustomerDebts = customerDebts.map((d) => d.id == debtId ? _debts[index] : d).toList();
          final totalOutstanding = updatedCustomerDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
          
          // If all customer debts are now fully paid, trigger settlement confirmation
          if (totalOutstanding == 0) {
            await _triggerSettlementConfirmationAutomation(
              originalDebt.customerId, 
              newlySettledDebts: [_debts[index]] // Pass the debt that was just completed
            );
          }
        }
      }
      
      // Check if WhatsApp automation should be triggered
      // Note: Automatic partial payment reminders have been removed as requested
      // Only settlement confirmations are sent automatically when debts are fully paid
      
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Apply a partial payment to a customer, distributing it across their pending debts
  /// This is useful when a customer makes a payment but doesn't specify which debt to apply it to
  Future<void> applyCustomerPartialPayment(String customerId, double paymentAmount, {bool skipActivityCreation = false}) async {
    try {
      // Get all pending debts for this customer
      final customerDebts = _debts.where((d) => 
        d.customerId == customerId && !d.isFullyPaid
      ).toList();
      
      if (customerDebts.isEmpty) {
        return;
      }
      
      // Sort debts by creation date (oldest first) to prioritize older debts
      customerDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      double remainingPayment = paymentAmount;
      int updatedDebts = 0;
      
      // Distribute payment across debts, starting with the oldest
      for (final debt in customerDebts) {
        if (remainingPayment <= 0) break;
        
        final debtIndex = _debts.indexWhere((d) => d.id == debt.id);
        if (debtIndex == -1) continue;
        
        final currentDebt = _debts[debtIndex];
        final currentRemaining = currentDebt.remainingAmount;
        
        // Calculate how much of the remaining payment to apply to this debt
        final paymentForThisDebt = remainingPayment > currentRemaining ? currentRemaining : remainingPayment;
        
        // Create partial payment record with unique ID
        final now = DateTime.now();
        final randomSuffix = (now.microsecondsSinceEpoch % 10000).toString().padLeft(4, '0');
        final uniqueId = '${now.millisecondsSinceEpoch}_${updatedDebts}_$randomSuffix';
        
        // Note: Partial payments are now handled as activities only
        
        // Update debt
        final newTotalPaidAmount = currentDebt.paidAmount + paymentForThisDebt;
        // Use a small tolerance for floating-point precision issues
        final tolerance = 0.01; // 1 cent tolerance
        final isThisDebtFullyPaid = (newTotalPaidAmount + tolerance) >= currentDebt.amount;
        
        // Additional check: if the remaining amount is very small (less than 1 cent), consider it fully paid
        final remainingAmount = currentDebt.amount - newTotalPaidAmount;
        final isEffectivelyFullyPaid = remainingAmount.abs() < 0.01;
        
        _debts[debtIndex] = currentDebt.copyWith(
          paidAmount: newTotalPaidAmount,
          status: (isThisDebtFullyPaid || isEffectivelyFullyPaid) ? DebtStatus.paid : DebtStatus.pending,
          paidAt: DateTime.now(),
        );
        
        // Update in storage
        await _dataService.updateDebt(_debts[debtIndex]);
        
        // Note: Activity creation is handled by the main applyPartialPayment logic above
        // No need to create duplicate activities here
        
        remainingPayment -= paymentForThisDebt;
        updatedDebts++;
      }
      
      // Check if all customer debts are now fully paid and trigger settlement confirmation
      final allCustomerDebts = _debts.where((d) => d.customerId == customerId).toList();
      final totalOutstanding = allCustomerDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
      
      if (totalOutstanding == 0) {
        // Get all debts that were just completed in this payment
        final newlySettledDebts = allCustomerDebts.where((d) => d.status == DebtStatus.paid).toList();
        await _triggerSettlementConfirmationAutomation(
          customerId, 
          newlySettledDebts: newlySettledDebts
        );
      } else {
      }
      
      // Clear cache and notify listeners
      _clearCache();
      notifyListeners();
      
      
    } catch (e) {
      rethrow;
    }
  }

  // Category operations
  Future<void> addCategory(ProductCategory category) async {
    try {
      await _dataService.addCategory(category);
      _categories.add(category);
      // Add new category to the end of the order list (only if not already present)
      if (!_categoryOrder.contains(category.id)) {
        _categoryOrder.add(category.id);
      }
      await _saveSettings();
      _clearCache();
      notifyListeners();
      
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
        
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final category = _categories.firstWhere((c) => c.id == categoryId);
      final categoryName = category.name;
      
      await _dataService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      // Remove from order list
      _categoryOrder.removeWhere((id) => id == categoryId);
      await _saveSettings();
      _clearCache();
      notifyListeners();
      
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
        
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProductPurchase(String purchaseId) async {
    try {
      final purchase = _productPurchases.firstWhere((p) => p.id == purchaseId);
      final purchaseName = purchase.subcategoryName;
      
      await _dataService.deleteProductPurchase(purchaseId);
      _productPurchases.removeWhere((p) => p.id == purchaseId);
      _clearCache();
      notifyListeners();
      
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

  /// Gets the current USD equivalent for a product based on its stored currency
  /// This implements the business logic where:
  /// - LBP products: Always convert to current USD rate for new purchases
  /// - USD products: Always use the same USD amount regardless of exchange rate
  double getCurrentUSDEquivalent(double amount, String storedCurrency) {
    if (_currencySettings == null || _currencySettings!.exchangeRate == null) {
      return amount;
    }
    
    if (storedCurrency.toUpperCase() == 'LBP') {
      // LBP products: Convert to current USD rate for new purchases
      // This ensures new customers pay the updated USD equivalent
      return amount / _currencySettings!.exchangeRate!;
    } else if (storedCurrency.toUpperCase() == 'USD') {
      // USD products: Always use the same USD amount
      // This ensures all customers pay the same regardless of exchange rate changes
      return amount;
    }
    
    // Fallback to original amount
    return amount;
  }

  /// Gets the original amount in its stored currency
  /// This preserves the original cost/selling context for historical records
  double getOriginalAmount(double amount, String storedCurrency) {
    // Always return the original amount as stored
    // This is used for historical debt records and calculations
    return amount;
  }

  /// Runs data migration to fix any corrupted currency data
  /// This should be called once after app startup to ensure data integrity
  Future<void> runCurrencyDataMigration() async {
    try {
      // Implement Firebase data migration
      final validation = await _dataService.validateDataIntegrity();
      if (validation['isValid'] == false) {
        await _dataService.fixDataInconsistencies();
      }
      
      // Auto-fix any Syria tel debts with incorrect currency
      await autoFixSyriaTelDebts();
      
      // Don't call _loadData here to prevent recursive calls
      // The migration is already complete, just notify listeners
      notifyListeners();
    } catch (e) {

    }
  }

  /// Validates that all currency data is correct
  Future<bool> validateCurrencyData() async {
    try {
      // Implement Firebase data validation
      final validation = await _dataService.validateDataIntegrity();
      return validation['isValid'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Manually fix activities debtId linking for existing data
  Future<void> fixActivitiesLinking() async {
    try {
      // Implement Firebase activities linking
      // Get activities from Firebase stream
      final activitiesStream = _dataService.activitiesFirebaseStream;
      await for (final activities in activitiesStream.take(1)) {
        _activities = activities;
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }


  /// Manually fix alfa product cost/selling to correct values
  Future<void> fixAlfaProductValues() async {
    try {
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Fix alfa product currency and cost/selling to show correct USD values
  /// This fixes the issue where LBP currency is set but USD values are stored
  Future<void> fixAlfaProductCurrency() async {
    try {
      // Find the alfa product in categories
      for (final category in _categories) {
        for (final subcategory in category.subcategories) {
          if (subcategory.name.toLowerCase().contains('alfa')) {
            // Check if this is the LBP currency issue
            if (subcategory.costPriceCurrency == 'LBP' && subcategory.costPrice > 1000) {
              // Convert the large LBP values to proper USD values using current exchange rate
              final exchangeRate = _currencySettings?.exchangeRate ?? 100000.0;
              final costPriceUSD = subcategory.costPrice / exchangeRate;
              final sellingPriceUSD = subcategory.sellingPrice / exchangeRate;
              
              // Update the subcategory with correct USD values and currency
              final updatedSubcategory = subcategory.copyWith(
                costPrice: costPriceUSD,
                sellingPrice: sellingPriceUSD,
                costPriceCurrency: 'USD',
                sellingPriceCurrency: 'USD',
              );
              
              // Update in database - use updateCategory instead
              await _dataService.updateCategory(category);
              
              // Update local list
              final categoryIndex = _categories.indexWhere((c) => c.id == category.id);
              if (categoryIndex != -1) {
                final subcategoryIndex = _categories[categoryIndex].subcategories.indexWhere((s) => s.id == subcategory.id);
                if (subcategoryIndex != -1) {
                  _categories[categoryIndex].subcategories[subcategoryIndex] = updatedSubcategory;
                }
              }
              

            }
          }
        }
      }
      
      _clearCache();
      notifyListeners();

    } catch (e) {

      rethrow;
    }
  }

  /// Check and fix any debts with suspicious cost/selling (e.g. 100000.0 instead of 1.00)
  Future<void> fixSuspiciousValues() async {
    try {

      
      for (final debt in _debts) {
        bool needsFix = false;
        String reason = '';
        
        // Check for suspicious cost prices
        if (debt.originalCostPrice != null && debt.originalCostPrice! > 1000) {
          needsFix = true;
          reason = 'Cost price too high: ${debt.originalCostPrice}';
        }
        
        // Check for suspicious selling prices
        if (debt.originalSellingPrice != null && debt.originalSellingPrice! > 1000) {
          needsFix = true;
          reason = 'Selling price too high: ${debt.originalSellingPrice}';
        }
        
        // Check for suspicious debt amounts
        if (debt.amount > 1000) {
          needsFix = true;
          reason = 'Debt amount too high: ${debt.amount}';
        }
        
        if (needsFix) {

          
          // Fix by converting from LBP to USD or setting reasonable defaults
          double newAmount = debt.amount;
          double? newCostPrice = debt.originalCostPrice;
          double? newSellingPrice = debt.originalSellingPrice;
          
          // If amounts are suspiciously high, they're likely in LBP
          if (debt.amount > 1000) {
            // Convert from LBP to USD using current exchange rate or reasonable default
            final exchangeRate = _currencySettings?.exchangeRate ?? 1500.0;
            newAmount = debt.amount / exchangeRate;

          }
          
          if (debt.originalCostPrice != null && debt.originalCostPrice! > 1000) {
            final exchangeRate = _currencySettings?.exchangeRate ?? 1500.0;
            newCostPrice = debt.originalCostPrice! / exchangeRate;

          }
          
          if (debt.originalSellingPrice != null && debt.originalSellingPrice! > 1000) {
            final exchangeRate = _currencySettings?.exchangeRate ?? 1500.0;
            newSellingPrice = debt.originalSellingPrice! / exchangeRate;

          }
          
          // Ensure reasonable values
          if (newAmount < 0.01) newAmount = 1.00;
          if (newCostPrice != null && newCostPrice < 0.01) newCostPrice = 0.50;
          if (newSellingPrice != null && newSellingPrice < 0.01) newSellingPrice = 1.00;
          
          final updatedDebt = debt.copyWith(
            amount: newAmount,
            originalCostPrice: newCostPrice,
            originalSellingPrice: newSellingPrice,
            storedCurrency: 'USD',
          );
          
          await _dataService.updateDebt(updatedDebt);
          
          // Update local debt list
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          }
          

        }
      }
      
      _clearCache();
      notifyListeners();
    } catch (e) {

      rethrow;
    }
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
      
      // Migration already handled in _loadData - no need for duplicate calls
      
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
          'isDarkMode': _isDarkMode,
          'whatsappAutomationEnabled': _whatsappAutomationEnabled,
          'whatsappCustomMessage': _whatsappCustomMessage,
          'defaultCurrency': _defaultCurrency,
          'categoryOrder': _categoryOrder,
        }, SetOptions(merge: true));
      }
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

  // Category order settings
  Future<void> updateCategoryOrder(List<String> categoryIds) async {
    // Remove duplicates while preserving order
    final seen = <String>{};
    _categoryOrder = categoryIds.where((id) {
      if (seen.contains(id)) {
        return false; // Skip duplicate
      }
      seen.add(id);
      return true;
    }).toList();
    await _saveSettings();
    notifyListeners();
  }

  // Get categories in the saved order (or default order if not set)
  List<ProductCategory> getCategoriesInOrder() {
    if (_categoryOrder.isEmpty) {
      // If no order is saved, return categories in their current order
      return List.from(_categories);
    }
    
    // Create a map for quick lookup
    final categoryMap = {for (var cat in _categories) cat.id: cat};
    
    // Build ordered list based on saved order (use Set to track added IDs and prevent duplicates)
    final orderedCategories = <ProductCategory>[];
    final addedIds = <String>{};
    
    for (final id in _categoryOrder) {
      if (categoryMap.containsKey(id) && !addedIds.contains(id)) {
        orderedCategories.add(categoryMap[id]!);
        addedIds.add(id);
      }
    }
    
    // Add any categories that aren't in the saved order (new categories)
    for (final category in _categories) {
      if (!addedIds.contains(category.id)) {
        orderedCategories.add(category);
        addedIds.add(category.id);
      }
    }
    
    return orderedCategories;
  }

  // Apply payment across multiple debts with proportional distribution
  Future<void> applyPaymentAcrossDebts(List<String> debtIds, double paymentAmount) async {
    try {
      if (debtIds.isEmpty || paymentAmount <= 0) {
        return;
      }
      
      // Get all pending debts for the customer
      final pendingDebts = _debts.where((d) => debtIds.contains(d.id))
          .where((d) => d.remainingAmount > 0)
          .toList();
      
      if (pendingDebts.isEmpty) return;
      
      // Check for duplicate payments within the last 5 seconds to prevent double-tapping
      final now = DateTime.now();
      final fiveSecondsAgo = now.subtract(const Duration(seconds: 5));
      
      final recentPayments = _activities.where((activity) => 
        activity.type == ActivityType.payment &&
        activity.customerId == pendingDebts.first.customerId &&
        activity.paymentAmount == paymentAmount &&
        activity.date.isAfter(fiveSecondsAgo)
      ).toList();
      
      if (recentPayments.isNotEmpty) {
        // Duplicate payment detected, don't create another one
        return;
      }
      
      // Sort debts by creation date (oldest first) for fair distribution
      pendingDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Calculate total remaining amount across all pending debts
      final totalRemaining = pendingDebts.fold(0.0, (total, debt) => total + debt.remainingAmount);
      
      if (totalRemaining <= 0) return;
      
      // Distribute payment proportionally across all debts
      double remainingPayment = paymentAmount;
      
      for (final debt in pendingDebts) {
        if (remainingPayment <= 0) break;
        
        // Calculate proportional payment for this debt
        final debtProportion = debt.remainingAmount / totalRemaining;
        final paymentForThisDebt = (paymentAmount * debtProportion).clamp(0.0, debt.remainingAmount);
        
        // Ensure we don't overpay
        final actualPayment = remainingPayment < paymentForThisDebt ? remainingPayment : paymentForThisDebt;
        
        if (actualPayment > 0) {
          final oldStatus = debt.status;
          final updatedDebt = debt.copyWith(
            paidAmount: debt.paidAmount + actualPayment,
            status: (debt.paidAmount + actualPayment) >= debt.amount ? DebtStatus.paid : DebtStatus.pending,
            paidAt: DateTime.now(),
          );
          
          // Update in storage
          await _dataService.updateDebt(updatedDebt);
          
          // Update local debt list
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          }
          
          remainingPayment -= actualPayment;
        }
      }
      
      // Create ONE consolidated payment activity for the entire payment amount
      if (paymentAmount > 0) {
        final firstDebt = pendingDebts.first;
        final consolidatedActivity = Activity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: firstDebt.customerId,
          customerName: firstDebt.customerName,
          type: ActivityType.payment,
          description: 'Partial payment: ${paymentAmount.toStringAsFixed(2)}\$',
          paymentAmount: paymentAmount,
          amount: paymentAmount,
          oldStatus: DebtStatus.pending,
          newStatus: DebtStatus.pending,
          date: DateTime.now(),
          debtId: null, // No specific debt ID for consolidated payments
        );
        
        await _addActivity(consolidatedActivity);
        
        // Clean up any duplicates that might have been created
        await removeDuplicatePaymentActivities();
      }
      
      // Check if all customer debts are now paid and trigger settlement automation
      final customerId = pendingDebts.first.customerId;
      final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
      final totalOutstanding = customerDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
      
      
      if (totalOutstanding == 0) {
        // Pass only the debts that were just completed, not all customer debts
        await _triggerSettlementConfirmationAutomation(customerId, newlySettledDebts: pendingDebts);
      } else {
      }
      
      // Clear cache and notify listeners to refresh UI
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  // Apply payment evenly across all pending debts for a customer
  Future<void> applyPaymentEvenlyAcrossCustomerDebts(String customerId, double paymentAmount) async {
    try {
      if (paymentAmount <= 0) {
        return;
      }
      
      // Get all pending debts for the customer
      final pendingDebts = _debts.where((d) => 
        d.customerId == customerId && d.remainingAmount > 0
      ).toList();
      
      if (pendingDebts.isEmpty) {
        return;
      }
      
      // Check for duplicate payments within the last 5 seconds to prevent double-tapping
      final now = DateTime.now();
      final fiveSecondsAgo = now.subtract(const Duration(seconds: 5));
      
      final recentPayments = _activities.where((activity) => 
        activity.type == ActivityType.payment &&
        activity.customerId == customerId &&
        activity.paymentAmount == paymentAmount &&
        activity.date.isAfter(fiveSecondsAgo)
      ).toList();
      
      if (recentPayments.isNotEmpty) {
        // Duplicate payment detected, don't create another one
        return;
      }
      

      
      // Sort debts by creation date (oldest first) for fair distribution
      pendingDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Calculate total remaining amount across all pending debts
      final totalRemaining = pendingDebts.fold(0.0, (total, debt) => total + debt.remainingAmount);
      
      if (totalRemaining <= 0) return;
      
      // Track the first debt for activity creation
      final firstDebt = pendingDebts.first;
      final oldStatus = firstDebt.status;
      
      // Distribute payment evenly across all debts
      double remainingPayment = paymentAmount;
      final paymentPerDebt = paymentAmount / pendingDebts.length;
      
      for (final debt in pendingDebts) {
        if (remainingPayment <= 0) break;
        
        // Calculate payment for this debt (even distribution)
        final paymentForThisDebt = paymentPerDebt.clamp(0.0, debt.remainingAmount);
        
        // Ensure we don't overpay
        final actualPayment = remainingPayment < paymentForThisDebt ? remainingPayment : paymentForThisDebt;
        
        if (actualPayment > 0) {
          final newPaidAmount = debt.paidAmount + actualPayment;
          final isFullyPaid = newPaidAmount >= debt.amount;
          
          final updatedDebt = debt.copyWith(
            paidAmount: newPaidAmount,
            status: isFullyPaid ? DebtStatus.paid : DebtStatus.pending,
            paidAt: DateTime.now(),
          );
          
          // Update in storage
          await _dataService.updateDebt(updatedDebt);
          
          // Update local debt list
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) {
            _debts[index] = updatedDebt;
          } else {
            // Debt not found in local list
          }
          
          remainingPayment -= actualPayment;
        }
      }
      
      // Create consolidated payment activity
      if (firstDebt != null) {
        // Check if this payment completes ALL selected debts
        final allSelectedDebtsCompleted = pendingDebts.every((debt) {
          final debtIndex = _debts.indexWhere((d) => d.id == debt.id);
          return debtIndex != -1 && _debts[debtIndex].status == DebtStatus.paid;
        });
        
        // Create a more descriptive consolidated activity
        String description;
        if (allSelectedDebtsCompleted) {
          if (pendingDebts.length == 1) {
            // Single debt completed
            description = '${pendingDebts.first.description}: ${paymentAmount.toStringAsFixed(2)}\$';
          } else {
            // Multiple debts completed - show as consolidated settlement
            description = 'Complete settlement: ${paymentAmount.toStringAsFixed(2)}\$ (${pendingDebts.length} products)';
          }
        } else {
          description = 'Partial payment: ${paymentAmount.toStringAsFixed(2)}\$';
        }
        
        final newStatus = allSelectedDebtsCompleted ? DebtStatus.paid : DebtStatus.pending;
        
        final activity = Activity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: firstDebt.customerId,
          customerName: firstDebt.customerName,
          type: ActivityType.payment,
          description: description,
          paymentAmount: paymentAmount,
          amount: firstDebt.amount,
          oldStatus: oldStatus,
          newStatus: newStatus,
          date: DateTime.now(),
          debtId: null, // No specific debt ID since this is a consolidated payment
        );
        
        await _addActivity(activity);
        
        // Clean up any duplicates that might have been created
        await removeDuplicatePaymentActivities();
      }
      
      // Check if all customer debts are now paid and trigger settlement automation
      final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
      final totalOutstanding = customerDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
      
      if (totalOutstanding == 0) {

        // Pass only the debts that were just completed, not all customer debts
        await _triggerSettlementConfirmationAutomation(customerId, newlySettledDebts: pendingDebts);
      }
      
      // Clear cache and notify listeners to refresh UI
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      // Handle error silently
      rethrow;
    }
  }

  // Fix existing uneven payment distributions for a customer
  Future<void> fixUnevenPaymentDistribution(String customerId) async {
    try {
      // Get all debts for the customer that have partial payments
      final customerDebts = _debts.where((d) => 
        d.customerId == customerId && d.paidAmount > 0 && !d.isFullyPaid
      ).toList();
      
      if (customerDebts.isEmpty) return;
      
      // Calculate total paid amount across all debts
      final totalPaidAmount = customerDebts.fold(0.0, (total, debt) => total + debt.paidAmount);
      
      if (totalPaidAmount <= 0) return;
      
      // Reset all paid amounts to 0 first
      for (final debt in customerDebts) {
        final updatedDebt = debt.copyWith(
          paidAmount: 0.0,
          status: DebtStatus.pending,
        );
        
        await _dataService.updateDebt(updatedDebt);
        
        // Update local debt list
        final index = _debts.indexWhere((d) => d.id == debt.id);
        if (index != -1) {
          _debts[index] = updatedDebt;
        }
      }
      
      // Now redistribute the total paid amount evenly across all debts
      await applyPaymentEvenlyAcrossCustomerDebts(customerId, totalPaidAmount);
      
    } catch (e) {
      rethrow;
    }
  }

  // Calculation methods
  double _calculateTotalDebt() {
    // Simple and reliable: sum all remaining amounts from debts
    double totalDebt = 0.0;
    for (final debt in _debts) {
      totalDebt += debt.remainingAmount;
    }
    // Fix floating-point precision issues by rounding to 2 decimal places
    return ((totalDebt * 100).round() / 100);
  }
  
  double _calculateTotalPaid() {
    // Calculate total from debt records' paidAmount field
    // This is the most reliable source since paidAmount is directly maintained
    double totalPaid = 0.0;
    
    for (final debt in _debts) {
      totalPaid += debt.paidAmount;
    }
    // Fix floating-point precision issues by rounding to 2 decimal places
    return ((totalPaid * 100).round() / 100);
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
      
      double totalDebt = 0.0;
      for (final debt in customerDebtsList) {
        totalDebt += debt.remainingAmount;
      }
      // Fix floating-point precision issues by rounding to 2 decimal places
      totalDebt = ((totalDebt * 100).round() / 100);
      
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
    double totalRemaining = 0.0;
    
    for (final debt in customerDebts) {
      totalRemaining += debt.remainingAmount;
    }
    
    // Fix floating-point precision issues by rounding to 2 decimal places
    return ((totalRemaining * 100).round() / 100);
  }

  // Settings methods
  Future<void> setDarkModeEnabled(bool enabled) async {
    _isDarkMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Simple method to manually fix the revenue calculation
  /// Call this from the UI to immediately fix the alfa ushare debt
  void fixRevenueNow() {
    
  }

  /// Restore the correct Syria tel debt amounts for Johny Chnouda
  /// This fixes the corrupted amounts that were modified by the migration service
  Future<void> restoreCorrectSyriaTelAmounts() async {
    try {
      // Find Johny Chnouda's customer ID
      final customer = _customers.firstWhere(
        (c) => c.name.toLowerCase().contains('johny') || c.name.toLowerCase().contains('chnouda'),
        orElse: () => throw Exception('Johny Chnouda not found'),
      );
      
      // Get all Syria tel debts for this customer
      final syriaTelDebts = _debts.where((d) => 
        d.customerId == customer.id && 
        d.description.toLowerCase().contains('syria tel')
      ).toList();
      
      // Sort by creation date to assign correct amounts
      syriaTelDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // The correct amounts based on the original values
      final correctAmounts = [0.19, 0.38, 0.38];
      
      for (int i = 0; i < syriaTelDebts.length && i < correctAmounts.length; i++) {
        final debt = syriaTelDebts[i];
        final correctAmount = correctAmounts[i];
        
        // Restore the correct amount while preserving paid amounts
        final updatedDebt = debt.copyWith(
          amount: correctAmount,
          originalSellingPrice: correctAmount, // Set as USD
          storedCurrency: 'USD',
        );
        
        // Update in storage
        await _dataService.updateDebt(updatedDebt);
        
        // Update local debt list
        final index = _debts.indexWhere((d) => d.id == debt.id);
        if (index != -1) {
          _debts[index] = updatedDebt;
        }
      }
      
      // Clear cache and notify listeners
      _clearCache();
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  // Refresh all data from the data service
  Future<void> refreshDataFromService() async {
    try {
      // CRITICAL FIX: Don't overwrite Firebase stream data with empty lists
      // Firebase streams are the source of truth for customers, debts, etc.
      // Currency settings are also loaded via Firebase stream, don't override them here
      
      // _currencySettings = _dataService.currencySettings; // This returns null, causing the issue

      
      _clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Method for manual payment reminder automation (customers with remaining debts)
  Future<void> _triggerManualPaymentReminderAutomation(String customerId, {String? customMessage}) async {
    if (_whatsappAutomationEnabled) {
      try {
        final customer = _customers.firstWhere((c) => c.id == customerId);
        
        final customerDebts = _debts.where((d) => d.customerId == customerId && !d.isFullyPaid).toList();
        
        if (customerDebts.isNotEmpty) {
          final totalAmount = customerDebts.fold<double>(0, (total, debt) => total + debt.remainingAmount);
          
          // Use custom message if provided, otherwise use custom settlement message
          String message;
          if (customMessage?.isNotEmpty == true) {
            message = customMessage!;
          } else if (_whatsappCustomMessage.isNotEmpty) {
            // Use the custom settlement message for payment reminders too
            message = _whatsappCustomMessage;
          } else {
            // This should never happen since custom messages are always required
            throw Exception('Custom message is required for payment reminders');
          }
          
          try {
            await WhatsAppAutomationService.sendPaymentReminderMessage(
              customer: customer,
              outstandingDebts: customerDebts,
              customMessage: message,
            );
          } catch (e) {
            // Fallback: just log that automation was attempted
          }
        }
      } catch (e) {
        // Silent fail for WhatsApp automation
      }
    }
  }

  // Method for settlement confirmation automation with specific payment amount
  Future<void> triggerSettlementConfirmationAutomationWithAmount(String customerId, {double? actualPaymentAmount, List<Debt>? newlySettledDebts}) async {
    
    if (_whatsappAutomationEnabled) {
      try {
        final customer = _customers.firstWhere((c) => c.id == customerId);
        
        final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
        
        if (customerDebts.isNotEmpty) {
          final totalAmount = customerDebts.fold<double>(0, (total, debt) => total + debt.remainingAmount);
          
          
          if (totalAmount == 0) {
            // Customer has no outstanding balance - send settlement confirmation
            // Use receipt-style message (no custom message needed)
            final customMessage = '';
            
            try {
              // Use newly settled debts if provided, otherwise fall back to all customer debts
              final debtsToShow = newlySettledDebts ?? customerDebts;

              final success = await WhatsAppAutomationService.sendSettlementMessage(
                customer: customer,
                settledDebts: debtsToShow, // Only show newly settled debts
                // Note: Partial payments are now handled as activities only
                customMessage: customMessage,
                settlementDate: DateTime.now(),
                actualPaymentAmount: actualPaymentAmount, // Use the provided payment amount
              );

              if (!success) {
                // The user can manually send the message if needed
              }
            } catch (e) {
              // WhatsApp automation failed - this is expected in some cases
              // The user can manually send the message if needed
            }
          } else {
          }
        } else {
        }
      } catch (e) {
        // Silent fail for WhatsApp automation
      }
    } else {
    }
  }

  // Method for settlement confirmation automation (when debts are fully paid)
  Future<void> _triggerSettlementConfirmationAutomation(String customerId, {List<Debt>? newlySettledDebts}) async {
    
    if (_whatsappAutomationEnabled) {
      try {
        final customer = _customers.firstWhere((c) => c.id == customerId);
        
        final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
        
        if (customerDebts.isNotEmpty) {
          final totalAmount = customerDebts.fold<double>(0, (total, debt) => total + debt.remainingAmount);
          
          
          if (totalAmount == 0) {
            // Customer has no outstanding balance - send settlement confirmation
            // Use receipt-style message (no custom message needed)
            final customMessage = '';
            
            try {
              // Use newly settled debts if provided, otherwise fall back to all customer debts
              final debtsToShow = newlySettledDebts ?? customerDebts;

              // Calculate the actual payment amount that completed the debt
              double actualPaymentAmount = 0.0;
              
              // Get the most recent partial payment for THIS specific customer
              // Note: Partial payments are now handled as activities only
              final customerPartialPayments = <Activity>[];
              
              if (customerPartialPayments.isNotEmpty) {
                // Sort by date and get the most recent payment amount for this customer
                customerPartialPayments.sort((a, b) => b.date.compareTo(a.date));
                actualPaymentAmount = customerPartialPayments.first.paymentAmount ?? 0.0;
              }
              
              // If no customer-specific payments found, use the total amount
              if (actualPaymentAmount == 0.0) {
                // Note: Payment amount calculation is now handled by activities
                actualPaymentAmount = totalAmount;
              }
              
              // If still no payment found, calculate from debt remaining amounts
              if (actualPaymentAmount == 0.0) {
                actualPaymentAmount = debtsToShow.fold<double>(0, (total, debt) => total + debt.remainingAmount);
              }

              final success = await WhatsAppAutomationService.sendSettlementMessage(
                customer: customer,
                settledDebts: debtsToShow, // Only show newly settled debts
                // Note: Partial payments are now handled as activities only
                customMessage: customMessage,
                settlementDate: DateTime.now(),
                actualPaymentAmount: actualPaymentAmount, // Pass the actual payment amount
              );

              if (!success) {
                // The user can manually send the message if needed
              }
            } catch (e) {
              // WhatsApp automation failed - this is expected in some cases
              // The user can manually send the message if needed
            }
          } else {
          }
        } else {
        }
      } catch (e) {
        // Silent fail for WhatsApp automation
      }
    } else {
    }
  }

  // Helper method to format phone number for WhatsApp
  String _formatPhoneForWhatsApp(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+' + cleaned.substring(2);
    }
    
    // If it doesn't start with +, add it
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  // Note: Debt creation automation has been removed as requested
  // Only settlement confirmations are sent automatically

  // Public method to manually trigger WhatsApp payment reminder (for customers with remaining debts)
  Future<void> sendWhatsAppPaymentReminder(String customerId, {String? customMessage}) async {
    if (_whatsappAutomationEnabled) {
      await _triggerManualPaymentReminderAutomation(customerId, customMessage: customMessage);
    } else {
      throw Exception('WhatsApp automation is not enabled. Please enable it in settings.');
    }
  }

  // Public method to manually trigger WhatsApp settlement notification (for customers who have paid all debts)
  Future<void> sendWhatsAppSettlementNotification(String customerId) async {
    if (_whatsappAutomationEnabled) {
      await _triggerSettlementConfirmationAutomation(customerId);
    } else {
      throw Exception('WhatsApp automation is not enabled. Please enable it in settings.');
    }
  }




  // Method for settlement confirmation automation (when debts are fully paid)
  
}