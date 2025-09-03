
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
  
  // Get customer by ID from Firebase
  Future<Customer?> getCustomerFromFirebase(String customerId) async {
    return await _firebaseService.getCustomer(customerId);
  }
  
  // Search customers by query
  Future<List<Customer>> searchCustomers(String query) async {
    return await _firebaseService.searchCustomers(query);
  }
  
  // Get customers by date range
  Future<List<Customer>> getCustomersByDateRange(DateTime start, DateTime end) async {
    return await _firebaseService.getCustomersByDateRange(start, end);
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
  
  // Get debts by customer from Firebase
  Future<List<Debt>> getDebtsByCustomerFromFirebase(String customerId) async {
    return await _firebaseService.getDebtsByCustomer(customerId);
  }
  
  // Search debts by query
  Future<List<Debt>> searchDebts(String query) async {
    return await _firebaseService.searchDebts(query);
  }
  
  // Get debts by status
  Future<List<Debt>> getDebtsByStatus(String status) async {
    return await _firebaseService.getDebtsByStatus(status);
  }
  
  // Get debts by date range
  Future<List<Debt>> getDebtsByDateRange(DateTime start, DateTime end) async {
    return await _firebaseService.getDebtsByDateRange(start, end);
  }
  
  // Get debts by amount range
  Future<List<Debt>> getDebtsByAmountRange(double min, double max) async {
    return await _firebaseService.getDebtsByAmountRange(min, max);
  }
  
  // Get debts by category
  Future<List<Debt>> getDebtsByCategory(String categoryId) async {
    return await _firebaseService.getDebtsByCategory(categoryId);
  }
  
  // Mark debt as paid
  Future<void> markDebtAsPaid(String debtId) async {
    await _firebaseService.markDebtAsPaid(debtId);
  }
  
  // Get debt history
  Future<List<PartialPayment>> getDebtHistory(String debtId) async {
    return await _firebaseService.getDebtHistory(debtId);
  }
  
  // Advanced debt search
  Future<List<Debt>> advancedDebtSearch(Map<String, dynamic> filters) async {
    return await _firebaseService.advancedDebtSearch(filters);
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
    await _firebaseService.clearDebts();
  }

  Future<void> deleteCustomerDebts(String customerId) async {
    await _firebaseService.deleteCustomerDebts(customerId);
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
  
  Stream<List<Debt>> get debtsFirebaseStream {
    return _firebaseService.getDebtsStream();
  }
  
  Stream<List<ProductCategory>> get categoriesFirebaseStream {
    return _firebaseService.getCategoriesStream();
  }

  // ===== USER AUTHENTICATION =====
  
  // Get current user ID
  String? get currentUserId => _firebaseService.currentUserId;
  
  // Check if user is authenticated
  bool get isAuthenticated => _firebaseService.isAuthenticated;
  
  Stream<List<ProductPurchase>> get productPurchasesFirebaseStream {
    return _firebaseService.getProductPurchasesStream();
  }
  
  Stream<List<PartialPayment>> get partialPaymentsFirebaseStream {
    return _firebaseService.getPartialPaymentsStream();
  }
  
  Stream<CurrencySettings?> get currencySettingsFirebaseStream {
    return _firebaseService.getCurrencySettingsStream();
  }

  // Get currency settings directly
  Future<CurrencySettings?> getCurrencySettings() async {
    return await _firebaseService.getCurrencySettings();
  }
  
  // ===== DIRECT DATA FETCHING (for web app) =====
  
  // Fetch categories directly from Firebase
  Future<List<ProductCategory>> getCategoriesDirectly() async {
    try {

      return await _firebaseService.getCategoriesDirectly();
    } catch (e) {

      return [];
    }
  }
  
  // Fetch debts directly from Firebase
  Future<List<Debt>> getDebtsDirectly() async {
    try {

      return await _firebaseService.getDebtsDirectly();
    } catch (e) {

      return [];
    }
  }
  
  // Fetch partial payments directly from Firebase
  Future<List<PartialPayment>> getPartialPaymentsDirectly() async {
    try {

      return await _firebaseService.getPartialPaymentsDirectly();
    } catch (e) {

      return [];
    }
  }
  
  // Fetch product purchases directly from Firebase
  Future<List<ProductPurchase>> getProductPurchasesDirectly() async {
    try {

      return await _firebaseService.getProductPurchasesDirectly();
    } catch (e) {

      return [];
    }
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
    await _firebaseService.markProductPurchaseAsPaid(purchaseId);
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
    await _firebaseService.addActivity(activity);
  }

  Future<void> updateActivity(Activity activity) async {
    await _firebaseService.updateActivity(activity);
  }

  Future<void> deleteActivity(String activityId) async {
    await _firebaseService.deleteActivity(activityId);
  }
  
  // Get activities by type
  Future<List<Activity>> getActivitiesByType(String type) async {
    return await _firebaseService.getActivitiesByType(type);
  }
  
  // Get activities by date range
  Future<List<Activity>> getActivitiesByDateRange(DateTime start, DateTime end) async {
    return await _firebaseService.getActivitiesByDateRange(start, end);
  }
  
  // Get activities by customer
  Future<List<Activity>> getActivitiesByCustomer(String customerId) async {
    return await _firebaseService.getActivitiesByCustomer(customerId);
  }
  
  // Search activities
  Future<List<Activity>> searchActivities(String query) async {
    return await _firebaseService.searchActivities(query);
  }
  
  // Get activities stream
  Stream<List<Activity>> get activitiesFirebaseStream {
    return _firebaseService.getActivitiesStream();
  }

  Future<void> clearActivities() async {
    await _firebaseService.clearActivities();
  }

  Future<void> clearPartialPayments() async {
    await _firebaseService.clearPartialPayments();
  }

  // ===== BACKUP METHODS =====
  
  Future<String> createBackup({bool isAutomatic = false}) async {
    return await _firebaseService.createBackup(isAutomatic: isAutomatic);
  }

  Future<List<String>> getAvailableBackups() async {
    return await _firebaseService.getAvailableBackups();
  }

  Future<Map<String, dynamic>?> getBackupMetadata(String backupId) async {
    return await _firebaseService.getBackupMetadata(backupId);
  }

  Future<bool> restoreFromBackup(String backupId) async {
    return await _firebaseService.restoreFromBackup(backupId);
  }

  Future<bool> deleteBackup(String backupId) async {
    return await _firebaseService.deleteBackup(backupId);
  }
  
  // Export data
  Future<Map<String, dynamic>> exportData(String format) async {
    return await _firebaseService.exportData(format);
  }

  // ===== DATA CLEARING METHODS =====
  
  Future<void> clearAllData() async {
    await _firebaseService.clearAllData();
  }

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
  
  // ===== ANALYTICS & REPORTING =====
  
  // Get revenue by period
  Future<double> getRevenueByPeriod(DateTime start, DateTime end) async {
    return await _firebaseService.getRevenueByPeriod(start, end);
  }
  
  // Get customer debt summary
  Future<Map<String, dynamic>> getCustomerDebtSummary(String customerId) async {
    return await _firebaseService.getCustomerDebtSummary(customerId);
  }
  
  // Get payment trends
  Future<List<Map<String, dynamic>>> getPaymentTrends(DateTime start, DateTime end) async {
    return await _firebaseService.getPaymentTrends(start, end);
  }
  
  // Get product performance
  Future<List<Map<String, dynamic>>> getProductPerformance(String categoryId) async {
    return await _firebaseService.getProductPerformance(categoryId);
  }
  
  // Get customer payment history
  Future<List<Map<String, dynamic>>> getCustomerPaymentHistory(String customerId) async {
    return await _firebaseService.getCustomerPaymentHistory(customerId);
  }
  
  // ===== DATA VALIDATION & INTEGRITY =====
  
  // Validate data integrity
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    return await _firebaseService.validateDataIntegrity();
  }
  
  // Fix data inconsistencies
  Future<bool> fixDataInconsistencies() async {
    return await _firebaseService.fixDataInconsistencies();
  }
  
  // Get data statistics
  Future<Map<String, dynamic>> getDataStatistics() async {
    return await _firebaseService.getDataStatistics();
  }
  
  // ===== GLOBAL SEARCH =====
  
  // Global search across all collections
  Future<Map<String, List<dynamic>>> globalSearch(String query) async {
    return await _firebaseService.globalSearch(query);
  }
  
  // ===== PARTIAL PAYMENT METHODS =====
  
  // Get partial payments by debt
  Future<List<PartialPayment>> getPartialPaymentsByDebt(String debtId) async {
    return await _firebaseService.getPartialPaymentsByDebt(debtId);
  }
  
  // Get partial payments by customer
  Future<List<PartialPayment>> getPartialPaymentsByCustomer(String customerId) async {
    return await _firebaseService.getPartialPaymentsByCustomer(customerId);
  }
  
  // Get partial payments by date range
  Future<List<PartialPayment>> getPartialPaymentsByDateRange(DateTime start, DateTime end) async {
    return await _firebaseService.getPartialPaymentsByDateRange(start, end);
  }
  
  // Search partial payments
  Future<List<PartialPayment>> searchPartialPayments(String query) async {
    return await _firebaseService.searchPartialPayments(query);
  }
  
  // ===== PRODUCT PURCHASE METHODS =====
  
  // Get product purchases by customer
  Future<List<ProductPurchase>> getProductPurchasesByCustomer(String customerId) async {
    return await _firebaseService.getProductPurchasesByCustomer(customerId);
  }
  
  // Get product purchases by category
  Future<List<ProductPurchase>> getProductPurchasesByCategory(String categoryId) async {
    return await _firebaseService.getProductPurchasesByCategory(categoryId);
  }
  
  // Get product purchases by date range
  Future<List<ProductPurchase>> getProductPurchasesByDateRange(DateTime start, DateTime end) async {
    return await _firebaseService.getProductPurchasesByDateRange(start, end);
  }
  
  // Search product purchases
  Future<List<ProductPurchase>> searchProductPurchases(String query) async {
    return await _firebaseService.searchProductPurchases(query);
  }
  
  // Get product purchase history
  Future<List<ProductPurchase>> getProductPurchaseHistory(String purchaseId) async {
    return await _firebaseService.getProductPurchaseHistory(purchaseId);
  }
  
  // ===== NOTIFICATION METHODS =====
  
  // Send notification
  Future<void> sendNotification(String userId, String message) async {
    await _firebaseService.sendNotification(userId, message);
  }
  
  // Schedule notification
  Future<void> scheduleNotification(String userId, String message, DateTime time) async {
    await _firebaseService.scheduleNotification(userId, message, time);
  }
  
  // Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    return await _firebaseService.getNotificationHistory(userId);
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firebaseService.markNotificationAsRead(notificationId);
  }
} 