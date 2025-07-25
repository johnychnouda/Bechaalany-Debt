import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  Box<Customer>? _customerBox;
  Box<Debt>? _debtBox;
  Box<ProductCategory>? _categoryBox;
  Box<ProductPurchase>? _productPurchaseBox;
  Box<CurrencySettings>? _currencySettingsBox;
  
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

  // Customer methods
  List<Customer> get customers {
    try {
      return _customerBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing customers box: $e');
      return [];
    }
  }
  
  Future<void> addCustomer(Customer customer) async {
    try {
      _customerBoxSafe.put(customer.id, customer);
      print('Customer added successfully to local storage');
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }
  
  Future<void> updateCustomer(Customer customer) async {
    try {
      _customerBoxSafe.put(customer.id, customer);
      print('Customer updated successfully in local storage');
    } catch (e) {
      print('Error updating customer: $e');
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
      print('Customer and related debts deleted successfully from local storage');
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }
  
  Customer? getCustomer(String customerId) {
    try {
      return _customerBoxSafe.get(customerId);
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Debt methods
  List<Debt> get debts {
    try {
      return _debtBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing debts box: $e');
      return [];
    }
  }
  
  List<Debt> getDebtsByCustomer(String customerId) {
    try {
      return _debtBoxSafe.values.where((d) => d.customerId == customerId).toList();
    } catch (e) {
      print('Error getting customer debts: $e');
      return [];
    }
  }
  
  Future<void> addDebt(Debt debt) async {
    try {
      _debtBoxSafe.put(debt.id, debt);
      print('Debt added successfully to local storage');
    } catch (e) {
      print('Error adding debt: $e');
      rethrow;
    }
  }
  
    Future<void> updateDebt(Debt debt) async {
    try {
      _debtBoxSafe.put(debt.id, debt);
      print('Debt updated successfully in local storage');
    } catch (e) {
      print('Error updating debt: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      _debtBoxSafe.delete(debtId);
      print('Debt deleted successfully from local storage');
    } catch (e) {
      print('Error deleting debt: $e');
      rethrow;
    }
  }
  
  Future<void> markDebtAsPaid(String debtId) async {
    try {
      final debt = _debtBoxSafe.get(debtId);
      if (debt != null) {
        final updated = debt.copyWith(
          status: DebtStatus.paid,
          paidAmount: debt.amount,
          paidAt: DateTime.now(),
        );
        _debtBoxSafe.put(debtId, updated);
        print('Debt marked as paid in local storage');
      }
    } catch (e) {
      print('Error marking debt as paid: $e');
      rethrow;
    }
  }

  // Statistics methods
  double get totalDebt {
    return debts
        .where((d) => !d.isFullyPaid)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }
  
  double get totalPaid {
    return debts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
  }
  
  int get pendingDebtsCount {
    return debts.where((d) => !d.isFullyPaid).length;
  }
  
  int get paidDebtsCount {
    return debts.where((d) => d.isFullyPaid).length;
  }

  int get partiallyPaidDebtsCount {
    return debts.where((d) => d.isPartiallyPaid).length;
  }

  // Recent debts (last 5)
  List<Debt> get recentDebts {
    final sortedDebts = List<Debt>.from(debts);
    sortedDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedDebts.take(5).toList();
  }

  // Generate unique IDs
  String generateCustomerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String generateDebtId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Category methods
  List<ProductCategory> get categories {
    try {
      return _categoryBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing categories box: $e');
      return [];
    }
  }

  Future<void> addCategory(ProductCategory category) async {
    try {
      _categoryBoxSafe.put(category.id, category);
      print('Category added successfully to local storage');
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(ProductCategory category) async {
    try {
      _categoryBoxSafe.put(category.id, category);
      print('Category updated successfully in local storage');
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      _categoryBoxSafe.delete(categoryId);
      print('Category deleted successfully from local storage');
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  ProductCategory? getCategory(String categoryId) {
    try {
      return _categoryBoxSafe.get(categoryId);
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  // Product Purchase methods
  List<ProductPurchase> get productPurchases {
    try {
      return _productPurchaseBoxSafe.values.toList();
    } catch (e) {
      print('Error accessing product purchases box: $e');
      return [];
    }
  }

  List<ProductPurchase> getProductPurchasesByCustomer(String customerId) {
    try {
      return _productPurchaseBoxSafe.values.where((p) => p.customerId == customerId).toList();
    } catch (e) {
      print('Error getting customer product purchases: $e');
      return [];
    }
  }

  Future<void> addProductPurchase(ProductPurchase purchase) async {
    try {
      _productPurchaseBoxSafe.put(purchase.id, purchase);
      print('Product purchase added successfully to local storage');
    } catch (e) {
      print('Error adding product purchase: $e');
      rethrow;
    }
  }

  Future<void> updateProductPurchase(ProductPurchase purchase) async {
    try {
      _productPurchaseBoxSafe.put(purchase.id, purchase);
      print('Product purchase updated successfully in local storage');
    } catch (e) {
      print('Error updating product purchase: $e');
      rethrow;
    }
  }

  Future<void> deleteProductPurchase(String purchaseId) async {
    try {
      _productPurchaseBoxSafe.delete(purchaseId);
      print('Product purchase deleted successfully from local storage');
    } catch (e) {
      print('Error deleting product purchase: $e');
      rethrow;
    }
  }

  Future<void> markProductPurchaseAsPaid(String purchaseId) async {
    try {
      final purchase = _productPurchaseBoxSafe.get(purchaseId);
      if (purchase != null) {
        purchase.isPaid = true;
        purchase.paidAt = DateTime.now();
        _productPurchaseBoxSafe.put(purchaseId, purchase);
        print('Product purchase marked as paid successfully');
      }
    } catch (e) {
      print('Error marking product purchase as paid: $e');
      rethrow;
    }
  }

  ProductPurchase? getProductPurchase(String purchaseId) {
    try {
      return _productPurchaseBoxSafe.get(purchaseId);
    } catch (e) {
      print('Error getting product purchase: $e');
      return null;
    }
  }

  String generateCategoryId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String generateProductPurchaseId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Currency Settings methods
  Box<CurrencySettings> get _currencySettingsBoxSafe {
    _currencySettingsBox ??= Hive.box<CurrencySettings>('currency_settings');
    return _currencySettingsBox!;
  }

  CurrencySettings? get currencySettings {
    try {
      final settings = _currencySettingsBoxSafe.values.firstOrNull;
      if (settings == null) {
        // Create default settings if none exist
        final defaultSettings = CurrencySettings(
          baseCurrency: 'USD',
          targetCurrency: 'LBP',
          exchangeRate: 89500.0, // Default rate for Lebanon
          lastUpdated: DateTime.now(),
          notes: 'Default settings for Lebanon',
        );
        _currencySettingsBoxSafe.put('default', defaultSettings);
        return defaultSettings;
      }
      return settings;
    } catch (e) {
      print('Error accessing currency settings: $e');
      return null;
    }
  }

  Future<void> updateCurrencySettings(CurrencySettings settings) async {
    try {
      _currencySettingsBoxSafe.clear(); // Clear existing settings
      _currencySettingsBoxSafe.put('default', settings);
      print('Currency settings updated successfully');
    } catch (e) {
      print('Error updating currency settings: $e');
      rethrow;
    }
  }

  // Convert amount using current exchange rate
  double convertAmount(double amount) {
    final settings = currencySettings;
    if (settings != null) {
      return settings.convertAmount(amount);
    }
    return amount; // Return original amount if no settings
  }

  // Convert amount back to base currency
  double convertBack(double amount) {
    final settings = currencySettings;
    if (settings != null) {
      return settings.convertBack(amount);
    }
    return amount; // Return original amount if no settings
  }
} 