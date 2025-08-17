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

import '../services/revenue_calculation_service.dart';
import '../services/data_migration_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
  // CloudKit service removed - using built-in backend
  final DataExportImportService _exportImportService = DataExportImportService();
  final BackupService _backupService = BackupService();
  final DataMigrationService _migrationService = DataMigrationService();
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
    // Get payments from payment activities only - this avoids double-counting with partial payments
    final paymentActivities = _activities.where((a) => 
      a.customerId == customerId && 
      a.type == ActivityType.payment
    ).toList();
    
    // Remove duplicate payment activities to fix the $85 vs $70 issue
    final deduplicatedActivities = <Activity>[];
    final seenDescriptions = <String>{};
    
    // Simple approach: Count all unique payment activities by description and amount
    // This avoids complex deduplication logic that was causing issues
    final uniquePayments = <String, double>{};
    
    for (final activity in paymentActivities) {
      final key = '${activity.description}_${activity.paymentAmount}';
      if (!uniquePayments.containsKey(key)) {
        uniquePayments[key] = activity.paymentAmount ?? 0;
        deduplicatedActivities.add(activity);
        print('  - Added unique payment: ${activity.description} - \$${activity.paymentAmount}');
      } else {
        print('  - Skipped duplicate: ${activity.description} - \$${activity.paymentAmount}');
      }
    }
    
    // Debug: Print all payment activities for this customer
    print('=== DEBUG: Payment Activities for Customer $customerId ===');
    print('Original activities: ${paymentActivities.length}');
    print('Deduplicated activities: ${deduplicatedActivities.length}');
    
    for (final activity in deduplicatedActivities) {
      print('  - ${activity.type}: ${activity.description} - Amount: ${activity.paymentAmount ?? activity.amount} - Date: ${activity.date}');
    }
    
    final totalFromActivities = deduplicatedActivities.fold(0.0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
    
    print('  - Total calculated: \$${totalFromActivities}');
    print('=== END DEBUG ===');
    
    return totalFromActivities;
  }
  
  // Debug method to help identify missing products
  void debugMissingProducts() {
    print('=== MISSING PRODUCTS ANALYSIS ===');
    
    // Get all unique product names mentioned in activities
    final mentionedProducts = <String>{};
    for (final activity in _activities) {
      if (activity.description.isNotEmpty) {
        // Look for product names in descriptions
        final words = activity.description.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 2 && !word.contains('(') && !word.contains(')') && !word.contains(':') && !word.contains('-') && !word.contains('debt') && !word.contains('payment')) {
            mentionedProducts.add(word);
          }
        }
      }
    }
    
    // Get all existing product names
    final existingProducts = <String>{};
    for (final category in _categories) {
      for (final subcategory in category.subcategories) {
        existingProducts.add(subcategory.name.toLowerCase());
      }
    }
    
    // Find missing products
    final missingProducts = mentionedProducts.difference(existingProducts);
    
    print('EXISTING PRODUCTS in system:');
    for (final category in _categories) {
      for (final subcategory in category.subcategories) {
        print('  - "${subcategory.name}" (Category: ${category.name})');
      }
    }
    
    print('\nPRODUCT NAMES mentioned in activities:');
    for (final product in mentionedProducts) {
      print('  - "$product"');
    }
    
    if (missingProducts.isNotEmpty) {
      print('\nMISSING PRODUCTS that activities reference:');
      for (final product in missingProducts) {
        print('  - "$product" (referenced in activities but not in products list)');
      }
      
      print('\nACTIVITIES that reference missing products:');
      for (final activity in _activities) {
        for (final missingProduct in missingProducts) {
          if (activity.description.toLowerCase().contains(missingProduct)) {
            print('  - ${activity.description} (references "$missingProduct")');
          }
        }
      }
    } else {
      print('\nNo missing products detected - all referenced products exist in the system.');
    }
    
    print('=== END MISSING PRODUCTS ANALYSIS ===');
  }

  // Debug method to check specific product revenue expectations
  void debugCheckProductRevenue(String productName) {
    print('=== CHECKING REVENUE FOR PRODUCT: $productName ===');
    
    // Find the product
    Subcategory? foundProduct;
    for (final category in _categories) {
      for (final subcategory in category.subcategories) {
        if (subcategory.name.toLowerCase().contains(productName.toLowerCase()) ||
            productName.toLowerCase().contains(subcategory.name.toLowerCase())) {
          foundProduct = subcategory;
          break;
        }
      }
      if (foundProduct != null) break;
    }
    
    if (foundProduct != null) {
      final profit = foundProduct.sellingPrice - foundProduct.costPrice;
      print('Found product: ${foundProduct.name}');
      print('Cost Price: ${foundProduct.costPrice}');
      print('Selling Price: ${foundProduct.sellingPrice}');
      print('Expected Profit per unit: $profit');
      
      // Check how many payments exist for this product
      final productPayments = _activities.where((a) => 
        a.type == ActivityType.payment && 
        (a.description.toLowerCase().contains(foundProduct!.name.toLowerCase()) ||
         foundProduct.name.toLowerCase().contains(a.description.toLowerCase()))
      ).toList();
      
      print('Payment activities for this product: ${productPayments.length}');
      for (final payment in productPayments) {
        print('  - ${payment.description}: ${payment.paymentAmount} (${payment.date})');
      }
      
      // Check debts for this product
      final productDebts = _debts.where((d) => 
        d.subcategoryName?.toLowerCase().contains(foundProduct?.name.toLowerCase() ?? '') == true ||
        d.description.toLowerCase().contains(foundProduct?.name.toLowerCase() ?? '')
      ).toList();
      
      print('Current debts for this product: ${productDebts.length}');
      for (final debt in productDebts) {
        print('  - ${debt.description}: ${debt.amount} (Status: ${debt.status})');
      }
      
    } else {
      print('Product "$productName" not found in system');
      
      // Show all activities that might contain this product name
      print('\nSearching for activities that might contain "$productName":');
      final relatedActivities = _activities.where((a) => 
        a.description.toLowerCase().contains(productName.toLowerCase())
      ).toList();
      
      if (relatedActivities.isNotEmpty) {
        print('Found ${relatedActivities.length} activities containing "$productName":');
        for (final activity in relatedActivities) {
          print('  - ${activity.type}: ${activity.description} - Amount: ${activity.paymentAmount ?? activity.amount}');
        }
      } else {
        print('No activities found containing "$productName"');
      }
      
      // Show all existing product names for comparison
      print('\nAll existing product names for comparison:');
      for (final category in _categories) {
        for (final subcategory in category.subcategories) {
          print('  - "${subcategory.name}"');
        }
      }
    }
    print('=== END PRODUCT REVENUE CHECK ===');
  }

  // Debug method to print all products and their profit margins
  void debugPrintProducts() {
    print('=== PRODUCT DEBUG ===');
    print('Total Categories: ${_categories.length}');
    for (final category in _categories) {
      print('Category: ${category.name}');
      for (final subcategory in category.subcategories) {
        final profit = subcategory.sellingPrice - subcategory.costPrice;
        print('  - ${subcategory.name}: Cost: ${subcategory.costPrice}, Selling: ${subcategory.sellingPrice}, Profit: $profit');
      }
    }
    print('=== END PRODUCT DEBUG ===');
  }

  /// Debug method to identify debts with missing cost prices
  void debugDebtsWithMissingCostPrices() {
    print('=== DEBTS WITH MISSING COST PRICES ANALYSIS ===');
    
    int totalDebts = _debts.length;
    int debtsWithCostPrice = 0;
    int debtsWithSellingPrice = 0;
    int debtsWithSubcategory = 0;
    
    for (final debt in _debts) {
      if (debt.originalCostPrice != null) debtsWithCostPrice++;
      if (debt.originalSellingPrice != null) debtsWithSellingPrice++;
      if (debt.subcategoryId != null) debtsWithSubcategory++;
      
      if (debt.originalCostPrice == null || debt.originalSellingPrice == null) {
        print('DEBT WITH MISSING PRICES: ${debt.description}');
        print('  - ID: ${debt.id}');
        print('  - Customer: ${debt.customerName}');
        print('  - Amount: \$${debt.amount}');
        print('  - Cost Price: ${debt.originalCostPrice}');
        print('  - Selling Price: ${debt.originalSellingPrice}');
        print('  - Subcategory ID: ${debt.subcategoryId}');
        print('  - Subcategory Name: ${debt.subcategoryName}');
        print('  - Category Name: ${debt.categoryName}');
        print('  - Created: ${debt.createdAt}');
        print('  - Status: ${debt.status}');
        print('  - Paid Amount: \$${debt.paidAmount}');
        print('  ---');
      }
    }
    
    print('SUMMARY:');
    print('  - Total Debts: $totalDebts');
    print('  - With Cost Price: $debtsWithCostPrice');
    print('  - With Selling Price: $debtsWithSellingPrice');
    print('  - With Subcategory: $debtsWithSubcategory');
    print('  - Missing Cost Price: ${totalDebts - debtsWithCostPrice}');
    print('  - Missing Selling Price: ${totalDebts - debtsWithSellingPrice}');
    print('  - Missing Subcategory: ${totalDebts - debtsWithSubcategory}');
    print('=== END ANALYSIS ===');
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
      print('Revenue calculation detected ${debtsWithMissingCosts.length} debts with missing cost prices - auto-migrating...');
      // Trigger auto-migration in background
      Future.microtask(() => autoMigrateRemainingDebts());
    }
    
    return RevenueCalculationService().calculateTotalRevenue(_debts, _partialPayments, activities: _activities, appState: this);
  }

  // Get customer-specific revenue for financial summaries
  double getCustomerRevenue(String customerId) {
    return RevenueCalculationService().calculateCustomerRevenue(customerId, _debts);
  }

  // Get customer potential revenue (from unpaid amounts)
  double getCustomerPotentialRevenue(String customerId) {
    return RevenueCalculationService().calculateCustomerPotentialRevenue(customerId, _debts);
  }

  // Get detailed revenue breakdown for a customer
  Map<String, dynamic> getCustomerRevenueBreakdown(String customerId) {
    return RevenueCalculationService().getCustomerRevenueBreakdown(customerId, _debts);
  }

  // Get comprehensive dashboard revenue summary
  Map<String, dynamic> getDashboardRevenueSummary() {
    return RevenueCalculationService().getDashboardRevenueSummary(_debts, activities: _activities, appState: this);
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
      print('Data migration failed: $e');
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
      
      print('Auto-migrating ${debtsNeedingMigration.length} debts with missing cost prices...');
      
      // Try to match them with existing products by name
      for (final debt in debtsNeedingMigration) {
        // Try to find a matching subcategory by name
        Subcategory? matchingSubcategory;
        String? categoryName;
        
        for (final category in _categories) {
          for (final subcategory in category.subcategories) {
            if (subcategory.name.toLowerCase() == debt.description.toLowerCase() ||
                debt.description.toLowerCase().contains(subcategory.name.toLowerCase()) ||
                subcategory.name.toLowerCase().contains(debt.description.toLowerCase())) {
              matchingSubcategory = subcategory;
              categoryName = category.name;
              break;
            }
          }
          if (matchingSubcategory != null) break;
        }
        
        if (matchingSubcategory != null) {
          // Update the debt with the missing information
          final updatedDebt = debt.copyWith(
            originalCostPrice: matchingSubcategory.costPrice,
            originalSellingPrice: matchingSubcategory.sellingPrice,
            subcategoryId: matchingSubcategory.id,
            subcategoryName: matchingSubcategory.name,
            categoryName: categoryName,
          );
          
          await updateDebt(updatedDebt);
          print('Auto-migrated debt: ${debt.description} with cost price \$${matchingSubcategory.costPrice}');
        }
      }
      
    } catch (e) {
      print('Error during auto-migration: $e');
      // Don't rethrow - this should be silent and automatic
    }
  }

  /// Manually trigger migration for any remaining debts with missing cost prices
  Future<void> forceMigrationForRemainingDebts() async {
    try {
      print('=== FORCING MIGRATION FOR REMAINING DEBTS ===');
      
      // First, identify debts that still need migration
      final debtsNeedingMigration = _debts.where((debt) => 
        debt.originalCostPrice == null || 
        debt.originalSellingPrice == null ||
        debt.subcategoryId == null
      ).toList();
      
      if (debtsNeedingMigration.isEmpty) {
        print('No debts need migration - all are properly configured');
        return;
      }
      
      print('Found ${debtsNeedingMigration.length} debts that need migration');
      
      // Try to match them with existing products by name
      for (final debt in debtsNeedingMigration) {
        print('Attempting to migrate debt: ${debt.description}');
        
        // Try to find a matching subcategory by name
        Subcategory? matchingSubcategory;
        String? categoryName;
        
        for (final category in _categories) {
          for (final subcategory in category.subcategories) {
            if (subcategory.name.toLowerCase() == debt.description.toLowerCase() ||
                debt.description.toLowerCase().contains(subcategory.name.toLowerCase()) ||
                subcategory.name.toLowerCase().contains(debt.description.toLowerCase())) {
              matchingSubcategory = subcategory;
              categoryName = category.name;
              break;
            }
          }
          if (matchingSubcategory != null) break;
        }
        
        if (matchingSubcategory != null) {
          print('Found matching subcategory: ${matchingSubcategory.name}');
          
          // Update the debt with the missing information
          final updatedDebt = debt.copyWith(
            originalCostPrice: matchingSubcategory.costPrice,
            originalSellingPrice: matchingSubcategory.sellingPrice,
            subcategoryId: matchingSubcategory.id,
            subcategoryName: matchingSubcategory.name,
            categoryName: categoryName,
          );
          
          await updateDebt(updatedDebt);
          print('Successfully migrated debt: ${debt.description}');
        } else {
          print('No matching subcategory found for debt: ${debt.description}');
        }
      }
      
      print('=== MIGRATION COMPLETE ===');
      
    } catch (e) {
      print('Error during forced migration: $e');
      rethrow;
    }
  }

  /// Validate data integrity and get migration status
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    return await _migrationService.validateDataIntegrity();
  }

  /// Get migration recommendations
  List<String> getMigrationRecommendations(Map<String, dynamic> integrityReport) {
    return _migrationService.getMigrationRecommendations(integrityReport);
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
      

      
      // AUTOMATICALLY create missing payment activities for existing paid debts
      await createMissingPaymentActivitiesForAllPaidDebts();
      

      
      // Remove specific problematic activities
      await removeActivitiesByCustomerAndAmount('Johny Chnouda', 400.0);
      
      // CRITICAL: Run data migration to ensure revenue calculation accuracy
      await runDataMigration();
      
      // AUTOMATIC: Run additional auto-migration for any remaining debts
      await autoMigrateRemainingDebts();
      
      // Validate debt product data integrity
      validateDebtProductData();
      
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
      
      // Automatically create missing payment activities when data is loaded
      await createMissingPaymentActivitiesForAllPaidDebts();
      
      // Also create missing payment activities for partial payments
      await createMissingPaymentActivitiesForPartialPayments();
      
      // Setup connectivity monitoring
      _setupConnectivityListener();
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
          
          // CRITICAL FIX: Don't create payment activities for debts that are suspicious
          // This prevents creating fake "Payment completed" activities for cleared debts
          bool shouldCreatePaymentActivity = !hasPaymentActivity;
          
          // Additional checks to prevent fake payment activities
          if (shouldCreatePaymentActivity) {
            // Check if this debt was created with the full amount already paid
            // This suggests it's a debt that was cleared immediately, not a real payment
            if (debt.paidAmount == debt.amount && debt.createdAt.isAtSameMomentAs(debt.paidAt ?? debt.createdAt)) {
              shouldCreatePaymentActivity = false;
              print('DEBUG: Skipping payment activity creation for debt ${debt.id} - appears to be immediately cleared');
            }
            
            // Check if there are other payment activities for the same customer around the same time
            // This suggests the debt was paid through other means
            final customerPaymentActivities = _activities.where((a) => 
              a.type == ActivityType.payment && 
              a.customerId == debt.customerId &&
              a.date.isAfter(debt.createdAt.subtract(const Duration(minutes: 5))) &&
              a.date.isBefore(debt.createdAt.add(const Duration(minutes: 5)))
            ).toList();
            
            if (customerPaymentActivities.isNotEmpty) {
              shouldCreatePaymentActivity = false;
              print('DEBUG: Skipping payment activity creation for debt ${debt.id} - customer has other payment activities');
            }
          }
          
          if (shouldCreatePaymentActivity) {
            // Create a payment activity for the full paid amount
            await addPaymentActivity(debt, debt.paidAmount, DebtStatus.pending, DebtStatus.paid);
          }
        }
      }
    } catch (e) {
      // Error creating missing payment activities
    }
  }
  
  // Create missing payment activities for partial payments
  Future<void> createMissingPaymentActivitiesForPartialPayments() async {
    try {
      for (final partialPayment in _partialPayments) {
        // Check if there's already a payment activity for this partial payment
        final hasPaymentActivity = _activities.any((activity) => 
          activity.type == ActivityType.payment && 
          activity.debtId == partialPayment.debtId &&
          activity.paymentAmount == partialPayment.amount &&
          (activity.date.difference(partialPayment.paidAt).inMinutes.abs() < 5) // Within 5 minutes
        );
        
        if (!hasPaymentActivity) {
          // Find the corresponding debt
          final debt = _debts.firstWhere(
            (d) => d.id == partialPayment.debtId,
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
          
          if (debt.id.isNotEmpty) {
            // Create a payment activity for this partial payment
            final activity = Activity(
              id: 'activity_partial_${partialPayment.id}_${DateTime.now().millisecondsSinceEpoch}',
              date: partialPayment.paidAt, // Use the original payment date
              type: ActivityType.payment,
              customerName: debt.customerName,
              customerId: debt.customerId,
              description: debt.description,
              amount: debt.amount,
              paymentAmount: partialPayment.amount,
              oldStatus: DebtStatus.pending,
              newStatus: debt.isFullyPaid ? DebtStatus.paid : DebtStatus.pending,
              debtId: debt.id,
            );
            
            await _addActivity(activity);
            print('Created missing payment activity for partial payment: ${partialPayment.id}');
          }
        }
      }
    } catch (e) {
      print('Error creating missing payment activities for partial payments: $e');
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
      
      // DIFFERENT LOGIC FOR PAID vs PENDING DEBTS
      if (debt.paidAmount > 0) {
        // PAID DEBT: Preserve revenue data before deletion
        print('DELETE DEBT: Preserving revenue data for PAID debt');
        print('  - Description: ${debt.description}');
        print('  - Paid Amount: \$${debt.paidAmount}');
        print('  - Original Revenue: \$${debt.originalRevenue}');
        print('  - Earned Revenue: \$${debt.earnedRevenue}');
        
        // Create a comprehensive summary activity that preserves ALL revenue information
        String detailedDescription = 'Cleared debt: ${debt.description}';
        
        // Add product information if available to help with revenue calculation
        if (debt.subcategoryName != null) {
          detailedDescription += ' (Product: ${debt.subcategoryName})';
        }
        if (debt.categoryName != null) {
          detailedDescription += ' (Category: ${debt.categoryName})';
        }
        
        // Add revenue information to the description for audit purposes
        if (debt.originalRevenue > 0) {
          detailedDescription += ' [Revenue: \$${debt.originalRevenue}]';
        }
        
        final summaryActivity = Activity(
          id: 'summary_${debt.id}_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          type: ActivityType.debtCleared,
          customerName: debt.customerName,
          customerId: debt.customerId,
          description: detailedDescription,
          amount: debt.amount,
          paymentAmount: debt.paidAmount,
          oldStatus: debt.status,
          newStatus: DebtStatus.paid,
          debtId: debt.id,
          // Store revenue data in the activity for future reference
          notes: 'Revenue: \$${debt.originalRevenue}, Cost: \$${debt.originalCostPrice}, Selling: \$${debt.originalSellingPrice}',
        );
        await _addActivity(summaryActivity);
        
        print('DELETE DEBT: Created revenue preservation activity: ${summaryActivity.id}');
      } else {
        // PENDING DEBT: Complete removal without preservation
        print('DELETE DEBT: Complete removal of PENDING debt (no revenue to preserve)');
      }
      
      // Now delete the debt
      await _dataService.deleteDebt(debtId);
      _debts.removeWhere((d) => d.id == debtId);
      

      
      _clearCache();
      notifyListeners();
      
      if (_isOnline) {
        await _syncService.deleteDebt(debtId);
      }
      
      print('DELETE DEBT: Successfully deleted debt ${debt.id}');
    } catch (e) {
      print('DELETE DEBT: Error deleting debt: $e');
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
      
      // Update the debt in storage first
      await _dataService.updateDebt(_debts[index]);
      
      // AUTOMATICALLY track payment activity (for both partial and full payments)
      // If this payment makes the debt fully paid, show the remaining amount as payment
      final paymentAmountToShow = isThisDebtFullyPaid && !originalDebt.isFullyPaid 
          ? (originalDebt.amount - originalDebt.paidAmount) 
          : paymentAmount;
      
      // Determine the correct status for the activity
      final oldStatus = originalDebt.status;
      final newStatus = _debts[index].status;
      
      await addPaymentActivity(originalDebt, paymentAmountToShow, oldStatus, newStatus);
      
      // AUTOMATICALLY delete fully paid debts to keep the system clean
      if (isThisDebtFullyPaid) {
        print('🔄 Auto-deleting fully paid debt: ${originalDebt.description}');
        await deleteDebt(originalDebt.id);
        return; // Exit early since debt was deleted
      }
      
      _clearCache();
      notifyListeners();
      
      if (_isOnline) {
        await _syncService.syncDebts([_debts[index]]);
      }
      
      // Reschedule notifications
      await _scheduleNotifications();
    } catch (e) {
      rethrow;
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
        activity.customerName.toLowerCase() == customerName.toLowerCase() && 
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
      

      
      // Apply payment to each valid debt WITHOUT creating individual payment activities
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
      
      // Also create missing payment activities for partial payments
      await createMissingPaymentActivitiesForPartialPayments();
      
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      // Handle error silently
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
  double? convertAmount(double amount) {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.convertAmount(amount);
    }
    return null; // Return null if no settings
  }

  double? convertBack(double amount) {
    final settings = _currencySettings;
    if (settings != null) {
      return settings.convertBack(amount);
    }
    return null; // Return null if no settings
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
      final filePath = await _exportImportService.exportToPDF(_customers, _debts, _productPurchases, _categories.whereType<ProductCategory>().toList());
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


  
  // Customer-level debt status methods (considers ALL customer debts)
  bool isCustomerFullyPaid(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return true;
    
    // Customer is only fully paid when ALL their debts have no remaining amount
    return customerDebts.every((d) => d.remainingAmount == 0);
  }
  
  bool isCustomerPartiallyPaid(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return false;
    
    // Customer is partially paid when they have some payments but not all debts settled
    final hasAnyPayments = customerDebts.any((d) => d.paidAmount > 0);
    final hasUnpaidDebts = customerDebts.any((d) => d.remainingAmount > 0);
    
    return hasAnyPayments && hasUnpaidDebts;
  }
  
  bool isCustomerPending(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    if (customerDebts.isEmpty) return false;
    
    // Customer is pending when they have no payments on any debts
    return customerDebts.every((d) => d.paidAmount == 0);
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
  
  // Get customer-level total remaining amount
  double getCustomerTotalRemainingAmount(String customerId) {
    final customerDebts = _debts.where((d) => d.customerId == customerId).toList();
    return customerDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }
  
  // Fix missing product data for any debts that lack cost/selling price information
  Future<void> fixMissingProductData() async {
    try {
      print('🔧 Starting product data fix for all debts...');
      
      // Find all debts that are missing product information
      final debtsToFix = <Debt>[];
      for (final debt in _debts) {
        if (debt.originalCostPrice == null || debt.originalSellingPrice == null || debt.subcategoryId == null) {
          debtsToFix.add(debt);
          print('Found debt needing fix: ${debt.description}');
          print('  - Missing cost price: ${debt.originalCostPrice == null}');
          print('  - Missing selling price: ${debt.originalSellingPrice == null}');
          print('  - Missing subcategoryId: ${debt.subcategoryId == null}');
        }
      }
      
      if (debtsToFix.isEmpty) {
        print('✅ All debts have complete product data');
        return;
      }
      
      print('🔧 Found ${debtsToFix.length} debts needing product data fix...');
      
      for (final debt in debtsToFix) {
        await _fixSingleDebtProductData(debt);
      }
      
      print('🔄 Reloading data and notifying listeners...');
      _clearCache();
      await _loadData();
      notifyListeners();
      print('✅ Product data fix completed for ${debtsToFix.length} debts');
      
    } catch (e) {
      print('❌ Error fixing product data: $e');
      rethrow;
    }
  }
  
  // Validate that all debts have complete product data (for debugging)
  void validateDebtProductData() {
    print('🔍 Validating debt product data integrity...');
    
    int totalDebts = _debts.length;
    int completeDebts = 0;
    int incompleteDebts = 0;
    
    for (final debt in _debts) {
      if (debt.originalCostPrice != null && 
          debt.originalSellingPrice != null && 
          debt.subcategoryId != null) {
        completeDebts++;
      } else {
        incompleteDebts++;
        print('❌ Incomplete debt: ${debt.description}');
        print('  - Cost Price: ${debt.originalCostPrice}');
        print('  - Selling Price: ${debt.originalSellingPrice}');
        print('  - Subcategory ID: ${debt.subcategoryId}');
      }
    }
    
    print('📊 Debt Product Data Summary:');
    print('  - Total Debts: $totalDebts');
    print('  - Complete: $completeDebts');
    print('  - Incomplete: $incompleteDebts');
    print('  - Integrity: ${(completeDebts / totalDebts * 100).toStringAsFixed(1)}%');
  }
  

  
  // Fix product data for a single debt
  Future<void> _fixSingleDebtProductData(Debt debt) async {
    try {
      print('🔧 Fixing product data for debt: ${debt.description}');
      
      // Try to find existing product by name
      Subcategory? existingProduct;
      for (final category in _categories) {
        for (final subcategory in category.subcategories) {
          if (subcategory.name.toLowerCase() == debt.description.toLowerCase()) {
            existingProduct = subcategory;
            print('Found existing product: ${subcategory.name}');
            break;
          }
        }
        if (existingProduct != null) break;
      }
      
      // If no existing product found, create one with reasonable defaults
      if (existingProduct == null) {
        print('Creating new product for: ${debt.description}');
        
        // Use debt amount as selling price, estimate cost as 70% of selling price
        final estimatedCost = debt.amount * 0.7;
        final estimatedSelling = debt.amount;
        
        final defaultCategory = _categories.isNotEmpty ? _categories.first : null;
        if (defaultCategory != null) {
          final newProduct = Subcategory(
            id: '${debt.description.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
            name: debt.description,
            costPrice: estimatedCost,
            sellingPrice: estimatedSelling,
            createdAt: DateTime.now(),
            costPriceCurrency: 'USD',
            sellingPriceCurrency: 'USD',
          );
          
          // Add to default category
          final updatedCategory = defaultCategory.copyWith(
            subcategories: [...defaultCategory.subcategories, newProduct],
          );
          
          await _dataService.updateCategory(updatedCategory);
          
          // Update the local list
          final categoryIndex = _categories.indexWhere((c) => c.id == defaultCategory.id);
          if (categoryIndex != -1) {
            _categories[categoryIndex] = updatedCategory;
          }
          
          existingProduct = newProduct;
          print('✅ Created new product: ${newProduct.name} (Cost: \$${newProduct.costPrice}, Selling: \$${newProduct.sellingPrice})');
        }
      }
      
      if (existingProduct != null) {
        // Update the debt with product information
        final updatedDebt = debt.copyWith(
          subcategoryId: existingProduct.id,
          subcategoryName: existingProduct.name,
          originalCostPrice: existingProduct.costPrice,
          originalSellingPrice: existingProduct.sellingPrice,
          categoryName: _categories.firstWhere((c) => c.subcategories.any((s) => s.id == existingProduct!.id)).name,
        );
        
        await _dataService.updateDebt(updatedDebt);
        
        // Update the local debt list
        final debtIndex = _debts.indexWhere((d) => d.id == debt.id);
        if (debtIndex != -1) {
          _debts[debtIndex] = updatedDebt;
        }
        
        print('✅ Fixed debt "${debt.description}" with product data');
        print('  - Cost Price: \$${updatedDebt.originalCostPrice}');
        print('  - Selling Price: \$${updatedDebt.originalSellingPrice}');
        print('  - Revenue: \$${updatedDebt.originalRevenue}');
      } else {
        print('❌ Failed to create or find product for: ${debt.description}');
      }
      
    } catch (e) {
      print('❌ Error fixing debt ${debt.description}: $e');
    }
  }

} 