import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';

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

  Box<CurrencySettings> get _currencySettingsBoxSafe {
    _currencySettingsBox ??= Hive.box<CurrencySettings>('currency_settings');
    return _currencySettingsBox!;
  }

  Box<Activity> get _activityBoxSafe {
    _activityBox ??= Hive.box<Activity>('activities');
    return _activityBox!;
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
  
  List<Debt> getDebtsByCustomer(String customerId) {
    try {
      return _debtBoxSafe.values.where((d) => d.customerId == customerId).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addDebt(Debt debt) async {
    try {
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
      print('DataService: Retrieved ${activities.length} activities');
      return activities;
    } catch (e) {
      print('DataService: Error retrieving activities: $e');
      return [];
    }
  }
  
  Future<void> addActivity(Activity activity) async {
    try {
      _activityBoxSafe.put(activity.id, activity);
    } catch (e) {
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