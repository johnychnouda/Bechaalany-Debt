
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';
import '../models/partial_payment.dart';
import 'firebase_data_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  // Firebase service for all data operations
  final FirebaseDataService _firebaseService = FirebaseDataService();

  // ===== CUSTOMER METHODS =====
  
  List<Customer> get customers {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addCustomer(Customer customer) async {
    await _firebaseService.addOrUpdateCustomer(customer);
  }
  
  Future<void> updateCustomer(Customer customer) async {
    await _firebaseService.addOrUpdateCustomer(customer);
  }
  
  Future<void> deleteCustomer(String customerId) async {
    await _firebaseService.deleteCustomer(customerId);
  }
  
  Customer? getCustomer(String customerId) {
    // This will be replaced by Firebase streams
    return null;
  }

  // ===== DEBT METHODS =====
  
  List<Debt> get debts {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  List<Debt> getDebtsByCustomer(String customerId) {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addDebt(Debt debt) async {
    await _firebaseService.addOrUpdateDebt(debt);
  }
  
  Future<void> updateDebt(Debt debt) async {
    await _firebaseService.addOrUpdateDebt(debt);
  }

  Future<void> deleteDebt(String debtId) async {
    await _firebaseService.delete('debts', debtId);
  }

  Future<void> clearDebts() async {
    // TODO: Implement bulk delete in Firebase
  }

  Future<void> deleteCustomerDebts(String customerId) async {
    // TODO: Implement customer debt deletion in Firebase
  }

  // ===== PARTIAL PAYMENTS =====
  
  List<PartialPayment> get partialPayments {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addPartialPayment(PartialPayment payment) async {
    await _firebaseService.addOrUpdatePartialPayment(payment);
  }

  // ===== FIREBASE STREAM ACCESS =====
  
  // Get Firebase streams for real-time data
  Stream<List<Customer>> get customersFirebaseStream {
    return _firebaseService.getCustomersStream();
  }

  // ===== CATEGORY METHODS =====
  
  List<ProductCategory> get categories {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addCategory(ProductCategory category) async {
    await _firebaseService.addOrUpdateCategory(category);
  }
  
  Future<void> updateCategory(ProductCategory category) async {
    await _firebaseService.addOrUpdateCategory(category);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firebaseService.delete('categories', categoryId);
  }

  // ===== PRODUCT PURCHASE METHODS =====
  
  List<ProductPurchase> get productPurchases {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addProductPurchase(ProductPurchase purchase) async {
    await _firebaseService.addOrUpdateProductPurchase(purchase);
  }

  Future<void> updateProductPurchase(ProductPurchase purchase) async {
    await _firebaseService.addOrUpdateProductPurchase(purchase);
  }

  Future<void> deleteProductPurchase(String purchaseId) async {
    await _firebaseService.delete('product_purchases', purchaseId);
  }

  Future<void> markProductPurchaseAsPaid(String purchaseId) async {
    // TODO: Implement in Firebase
  }

  // ===== CURRENCY SETTINGS METHODS =====
  
  CurrencySettings? get currencySettings {
    // Return null - will be populated by Firebase streams
    return null;
  }
  
  Future<void> updateCurrencySettings(CurrencySettings settings) async {
    await _firebaseService.addOrUpdateCurrencySettings(settings);
  }

  Future<void> saveCurrencySettings(CurrencySettings settings) async {
    await _firebaseService.addOrUpdateCurrencySettings(settings);
  }

  // ===== ACTIVITY METHODS =====
  
  List<Activity> get activities {
    // Return empty list - will be populated by Firebase streams
    return [];
  }
  
  Future<void> addActivity(Activity activity) async {
    // TODO: Add Firebase activity methods
    // For now, just log the activity
    print('Activity logged: ${activity.type} - ${activity.description}');
  }

  Future<void> updateActivity(Activity activity) async {
    // TODO: Implement in Firebase
  }

  Future<void> deleteActivity(String activityId) async {
    // TODO: Implement in Firebase
  }

  // ===== BACKUP METHODS (STUBBED OUT) =====
  
  Future<void> createBackup() async {
    // TODO: Implement Firebase backup
  }

  Future<List<String>> getAvailableBackups() async {
    // TODO: Implement Firebase backup listing
    return [];
  }

  Future<bool> restoreFromBackup(String backupPath) async {
    // TODO: Implement Firebase backup restoration
    return false;
  }

  Future<bool> deleteBackup(String backupPath) async {
    // TODO: Implement Firebase backup deletion
    return false;
  }

  // ===== DATA CLEARING METHODS =====
  
  Future<void> clearAllData() async {
    // TODO: Implement in Firebase
  }

  // ===== FIREBASE AUTHENTICATION =====
  
  bool get isAuthenticated => _firebaseService.isAuthenticated;
  
  // ===== GENERIC METHODS =====
  
  Future<void> addOrUpdate(String collectionName, dynamic item) async {
    await _firebaseService.addOrUpdate(collectionName, item);
  }

  Stream<List<Map<String, dynamic>>> getStream(String collectionName) {
    return _firebaseService.getStream(collectionName);
  }

  Future<void> delete(String collectionName, String documentId) async {
    await _firebaseService.delete(collectionName, documentId);
  }
} 