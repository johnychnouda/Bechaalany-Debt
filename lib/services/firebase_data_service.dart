import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';
import '../models/partial_payment.dart';

class FirebaseDataService {
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // ===== CUSTOMERS =====
  
  // Add/Update customer
  Future<void> addOrUpdateCustomer(Customer customer) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final customerData = customer.toJson();
    customerData['lastUpdated'] = FieldValue.serverTimestamp();
    customerData['userId'] = currentUserId;
    
    print('➕ Creating customer with userId: $currentUserId');
    
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .set(customerData, SetOptions(merge: true));
        
    print('✅ Customer created successfully');
  }

  // Get all customers for current user
  Stream<List<Customer>> getCustomersStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    // TODO: Re-enable userId filtering once user account strategy is finalized
    return _firestore
        .collection('customers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('customers').doc(customerId).delete();
  }

  // Get all categories for current user
  Stream<List<ProductCategory>> getCategoriesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get categories directly (for web app)
  Future<List<ProductCategory>> getCategoriesDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      print('🌐 FirebaseDataService: Fetching categories directly for userId: $currentUserId');
      
      // First try with user ID filter
      var querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('🌐 No categories found with userId filter, trying without filter...');
        // If no categories found with user ID, try without filter (for web app)
        querySnapshot = await _firestore
            .collection('categories')
            .get();
      }
      
      final categories = querySnapshot.docs
          .map((doc) => ProductCategory.fromJson(doc.data()))
          .toList();
      
      print('🌐 FirebaseDataService: Found ${categories.length} categories directly');
      return categories;
    } catch (e) {
      print('❌ Error fetching categories directly: $e');
      return [];
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // ===== CATEGORIES =====
  
  // Add/Update category
  Future<void> addOrUpdateCategory(ProductCategory category) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final categoryData = category.toJson();
    categoryData['lastUpdated'] = FieldValue.serverTimestamp();
    categoryData['userId'] = currentUserId;
    
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(categoryData, SetOptions(merge: true));
  }

  // ===== PRODUCT PURCHASES =====
  
  // Add/Update product purchase
  Future<void> addOrUpdateProductPurchase(ProductPurchase purchase) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final purchaseData = purchase.toJson();
    purchaseData['lastUpdated'] = FieldValue.serverTimestamp();
    purchaseData['userId'] = currentUserId;
    
    await _firestore
        .collection('product_purchases')
        .doc(purchase.id)
        .set(purchaseData, SetOptions(merge: true));
  }

  // Get all product purchases for current user
  Stream<List<ProductPurchase>> getProductPurchasesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    return _firestore
        .collection('product_purchases')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get product purchases directly (for web app)
  Future<List<ProductPurchase>> getProductPurchasesDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      print('🌐 FirebaseDataService: Fetching product purchases directly for userId: $currentUserId');
      
      // First try with user ID filter
      var querySnapshot = await _firestore
          .collection('product_purchases')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('🌐 No product purchases found with userId filter, trying without filter...');
        // If no product purchases found with user ID, try without filter (for web app)
        querySnapshot = await _firestore
            .collection('product_purchases')
            .get();
      }
      
      final productPurchases = querySnapshot.docs
          .map((doc) => ProductPurchase.fromJson(doc.data()))
          .toList();
      
      print('🌐 FirebaseDataService: Found ${productPurchases.length} product purchases directly');
      return productPurchases;
    } catch (e) {
      print('❌ Error fetching product purchases directly: $e');
      return [];
    }
  }

  // Delete product purchase
  Future<void> deleteProductPurchase(String purchaseId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('product_purchases').doc(purchaseId).delete();
  }

  // ===== DEBTS =====
  
  // Add/Update debt
  Future<void> addOrUpdateDebt(Debt debt) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final debtData = debt.toJson();
    debtData['lastUpdated'] = FieldValue.serverTimestamp();
    debtData['userId'] = currentUserId;
    
    await _firestore
        .collection('debts')
        .doc(debt.id)
        .set(debtData, SetOptions(merge: true));
  }

  // Get all debts for current user
  Stream<List<Debt>> getDebtsStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    return _firestore
        .collection('debts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get debts directly (for web app)
  Future<List<Debt>> getDebtsDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      print('🌐 FirebaseDataService: Fetching debts directly for userId: $currentUserId');
      
      // First try with user ID filter
      var querySnapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('🌐 No debts found with userId filter, trying without filter...');
        // If no debts found with user ID, try without filter (for web app)
        querySnapshot = await _firestore
            .collection('debts')
            .get();
      }
      
      final debts = querySnapshot.docs
          .map((doc) => Debt.fromJson(doc.data()))
          .toList();
      
      print('🌐 FirebaseDataService: Found ${debts.length} debts directly');
      return debts;
    } catch (e) {
      print('❌ Error fetching debts directly: $e');
      return [];
    }
  }

  // Delete debt
  Future<void> deleteDebt(String debtId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('debts').doc(debtId).delete();
  }

  // ===== PARTIAL PAYMENTS =====
  
  // Add/Update partial payment
  Future<void> addOrUpdatePartialPayment(PartialPayment payment) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final paymentData = payment.toJson();
    paymentData['lastUpdated'] = FieldValue.serverTimestamp();
    paymentData['userId'] = currentUserId;
    
    await _firestore
        .collection('partial_payments')
        .doc(payment.id)
        .set(paymentData, SetOptions(merge: true));
  }

  // Get all partial payments for current user
  Stream<List<PartialPayment>> getPartialPaymentsStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    return _firestore
        .collection('partial_payments')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get partial payments directly (for web app)
  Future<List<PartialPayment>> getPartialPaymentsDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      print('🌐 FirebaseDataService: Fetching partial payments directly for userId: $currentUserId');
      
      // First try with user ID filter
      var querySnapshot = await _firestore
          .collection('partial_payments')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('🌐 No partial payments found with userId filter, trying without filter...');
        // If no partial payments found with user ID, try without filter (for web app)
        querySnapshot = await _firestore
            .collection('partial_payments')
            .get();
      }
      
      final partialPayments = querySnapshot.docs
          .map((doc) => PartialPayment.fromJson(doc.data()))
          .toList();
      
      print('🌐 FirebaseDataService: Found ${partialPayments.length} partial payments directly');
      return partialPayments;
    } catch (e) {
      print('❌ Error fetching partial payments directly: $e');
      return [];
    }
  }

  // Delete partial payment
  Future<void> deletePartialPayment(String paymentId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('partial_payments').doc(paymentId).delete();
  }

  // ===== CURRENCY SETTINGS =====
  
  // Add/Update currency settings
  Future<void> addOrUpdateCurrencySettings(CurrencySettings settings) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final settingsData = settings.toJson();
    settingsData['lastUpdated'] = FieldValue.serverTimestamp();
    settingsData['userId'] = currentUserId;
    
    await _firestore
        .collection('currency_settings')
        .doc('default')
        .set(settingsData, SetOptions(merge: true));
  }

  // Get currency settings for current user
  Stream<CurrencySettings?> getCurrencySettingsStream() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }
    
    // TEMPORARY: Remove userId filter to allow access to all data during development
    return _firestore
        .collection('currency_settings')
        .doc('default')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            print('📱 Firebase: Currency settings found: ${doc.data()}');
            return CurrencySettings.fromJson(doc.data()!);
          }
          print('📱 Firebase: No currency settings document found');
          return null;
        });
  }

  // Get currency settings directly (for immediate access)
  Future<CurrencySettings?> getCurrencySettings() async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('currency_settings')
          .doc('default')
          .get();
      
      if (doc.exists && doc.data() != null) {
        print('📱 Firebase: Direct currency settings fetch: ${doc.data()}');
        return CurrencySettings.fromJson(doc.data()!);
      }
      print('📱 Firebase: Direct fetch - no currency settings found');
      return null;
    } catch (e) {
      print('❌ Firebase: Error fetching currency settings: $e');
      return null;
    }
  }

  // ===== DATA MIGRATION METHODS =====
  
  // Generic add/update method
  Future<void> addOrUpdate(String collectionName, dynamic item) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    switch (collectionName) {
      case 'customers':
        await addOrUpdateCustomer(item as Customer);
        break;
      case 'categories':
        await addOrUpdateCategory(item as ProductCategory);
        break;
      case 'product_purchases':
        await addOrUpdateProductPurchase(item as ProductPurchase);
        break;
      case 'debts':
        await addOrUpdateDebt(item as Debt);
        break;
      case 'partial_payments':
        await addOrUpdatePartialPayment(item as PartialPayment);
        break;
      case 'currency_settings':
        await addOrUpdateCurrencySettings(item as CurrencySettings);
        break;
      default:
        // For other collections, add generic support
        final itemData = (item as dynamic).toJson();
        itemData['lastUpdated'] = FieldValue.serverTimestamp();
        itemData['userId'] = currentUserId;
        
        await _firestore
            .collection(collectionName)
            .doc(itemData['id'])
            .set(itemData, SetOptions(merge: true));
        break;
    }
  }

  // Generic get stream method
  Stream<List<Map<String, dynamic>>> getStream(String collectionName) {
    if (!isAuthenticated) return Stream.value([]);
    
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Generic delete method
  Future<void> delete(String collectionName, String documentId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection(collectionName).doc(documentId).delete();
  }

  Future<void> migrateAllDataToFirebase() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // This will be called from the migration service
      // For now, just ensure we're authenticated
      print('Firebase migration service ready');
    } catch (e) {
      print('Firebase migration failed: $e');
      rethrow;
    }
  }
  
  // ===== SEARCH & FILTER METHODS =====
  
  // Get customer by ID
  Future<Customer?> getCustomer(String customerId) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (doc.exists && doc.data() != null) {
        return Customer.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Search customers by query
  Future<List<Customer>> searchCustomers(String query) async {
    if (!isAuthenticated) return [];
    
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('customers').get();
      
      return snapshot.docs
          .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
          .where((customer) => 
            customer.name.toLowerCase().contains(queryLower) ||
            customer.id.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get customers by date range
  Future<List<Customer>> getCustomersByDateRange(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('customers').get();
      
      return snapshot.docs
          .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
          .where((customer) => 
            customer.createdAt.isAfter(start) && customer.createdAt.isBefore(end))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get customers by status
  Future<List<Customer>> getCustomersByStatus(String status) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('customers').get();
      
      return snapshot.docs
          .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
          .where((customer) {
            // Determine customer status based on their debts
            // This would need to be implemented based on your business logic
            // For now, return all customers
            return true;
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get debts by customer
  Future<List<Debt>> getDebtsByCustomer(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('debts')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      return snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search debts by query
  Future<List<Debt>> searchDebts(String query) async {
    if (!isAuthenticated) return [];
    
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('debts').get();
      
      return snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => 
            debt.customerName.toLowerCase().contains(queryLower) ||
            debt.customerId.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get debts by status
  Future<List<Debt>> getDebtsByStatus(String status) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('debts').get();
      final allDebts = snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      return allDebts.where((debt) {
        if (status == 'pending') return debt.paidAmount == 0;
        if (status == 'partially paid') return debt.paidAmount > 0 && debt.paidAmount < debt.amount;
        if (status == 'fully paid') return debt.paidAmount >= debt.amount;
        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get debts by date range
  Future<List<Debt>> getDebtsByDateRange(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('debts').get();
      
      return snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => 
            debt.createdAt.isAfter(start) && debt.createdAt.isBefore(end))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get debts by amount range
  Future<List<Debt>> getDebtsByAmountRange(double min, double max) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('debts').get();
      
      return snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => debt.amount >= min && debt.amount <= max)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get debts by category
  Future<List<Debt>> getDebtsByCategory(String categoryId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('debts').get();
      
      return snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => debt.categoryName == categoryId)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Mark debt as paid
  Future<void> markDebtAsPaid(String debtId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('debts').doc(debtId).update({
      'paidAmount': FieldValue.increment(1000000), // Large number to ensure it's marked as paid
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Get debt history
  Future<List<PartialPayment>> getDebtHistory(String debtId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('partial_payments')
          .where('debtId', isEqualTo: debtId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get partial payments by debt
  Future<List<PartialPayment>> getPartialPaymentsByDebt(String debtId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('partial_payments')
          .where('debtId', isEqualTo: debtId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get partial payments by customer
  Future<List<PartialPayment>> getPartialPaymentsByCustomer(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('partial_payments')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get partial payments by date range
  Future<List<PartialPayment>> getPartialPaymentsByDateRange(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('partial_payments').get();
      
      return snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .where((payment) => 
            payment.paidAt.isAfter(start) && payment.paidAt.isBefore(end))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search partial payments
  Future<List<PartialPayment>> searchPartialPayments(String query) async {
    if (!isAuthenticated) return [];
    
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('partial_payments').get();
      
      return snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .where((payment) => 
            payment.debtId.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get product purchases by customer
  Future<List<ProductPurchase>> getProductPurchasesByCustomer(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('product_purchases')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get product purchases by category
  Future<List<ProductPurchase>> getProductPurchasesByCategory(String categoryId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('product_purchases')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get product purchases by date range
  Future<List<ProductPurchase>> getProductPurchasesByDateRange(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('product_purchases').get();
      
      return snapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .where((purchase) => 
            purchase.purchaseDate.isAfter(start) && purchase.purchaseDate.isBefore(end))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search product purchases
  Future<List<ProductPurchase>> searchProductPurchases(String query) async {
    if (!isAuthenticated) return [];
    
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('product_purchases').get();
      
      return snapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .where((purchase) => 
            purchase.subcategoryName.toLowerCase().contains(queryLower) ||
            purchase.categoryName.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Mark product purchase as paid
  Future<void> markProductPurchaseAsPaid(String purchaseId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('product_purchases').doc(purchaseId).update({
      'isPaid': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Get product purchase history
  Future<List<ProductPurchase>> getProductPurchaseHistory(String purchaseId) async {
    if (!isAuthenticated) return [];
    
    try {
      final doc = await _firestore.collection('product_purchases').doc(purchaseId).get();
      if (doc.exists && doc.data() != null) {
        return [ProductPurchase.fromJson({...doc.data()!, 'id': doc.id})];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // Delete customer debts
  Future<void> deleteCustomerDebts(String customerId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final debtsSnapshot = await _firestore
          .collection('debts')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in debtsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== ACTIVITY METHODS =====
  
  // Add activity
  Future<void> addActivity(Activity activity) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final activityData = activity.toJson();
    activityData['lastUpdated'] = FieldValue.serverTimestamp();
    activityData['userId'] = currentUserId;
    
    await _firestore
        .collection('activities')
        .doc(activity.id)
        .set(activityData, SetOptions(merge: true));
  }
  
  // Update activity
  Future<void> updateActivity(Activity activity) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final activityData = activity.toJson();
    activityData['lastUpdated'] = FieldValue.serverTimestamp();
    activityData['userId'] = currentUserId;
    
    await _firestore
        .collection('activities')
        .doc(activity.id)
        .set(activityData, SetOptions(merge: true));
  }
  
  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('activities').doc(activityId).delete();
  }
  
  // Get activities by type
  Future<List<Activity>> getActivitiesByType(String type) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get activities by date range
  Future<List<Activity>> getActivitiesByDateRange(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('activities').get();
      
      return snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .where((activity) => 
            activity.date.isAfter(start) && activity.date.isBefore(end))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get activities by customer
  Future<List<Activity>> getActivitiesByCustomer(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search activities
  Future<List<Activity>> searchActivities(String query) async {
    if (!isAuthenticated) return [];
    
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('activities').get();
      
      return snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .where((activity) => 
            activity.description.toLowerCase().contains(queryLower) ||
            activity.type.toString().toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get activities stream
  Stream<List<Activity>> getActivitiesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('activities')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // ===== ADVANCED SEARCH METHODS =====
  
  // Global search across all collections
  Future<Map<String, List<dynamic>>> globalSearch(String query) async {
    if (!isAuthenticated) return {};
    
    try {
      final queryLower = query.toLowerCase();
      final results = <String, List<dynamic>>{};
      
      // Search customers
      final customersSnapshot = await _firestore.collection('customers').get();
      final customers = customersSnapshot.docs
          .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
          .where((customer) => 
            customer.name.toLowerCase().contains(queryLower) ||
            customer.id.toLowerCase().contains(queryLower))
          .toList();
      results['customers'] = customers;
      
      // Search debts
      final debtsSnapshot = await _firestore.collection('debts').get();
      final debts = debtsSnapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => 
            debt.customerName.toLowerCase().contains(queryLower) ||
            debt.customerId.toLowerCase().contains(queryLower))
          .toList();
      results['debts'] = debts;
      
      // Search products
      final productsSnapshot = await _firestore.collection('product_purchases').get();
      final products = productsSnapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .where((product) => 
            product.subcategoryName.toLowerCase().contains(queryLower) ||
            product.categoryName.toLowerCase().contains(queryLower))
          .toList();
      results['products'] = products;
      
      // Search activities
      final activitiesSnapshot = await _firestore.collection('activities').get();
      final activities = activitiesSnapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .where((activity) => 
            activity.description.toLowerCase().contains(queryLower) ||
            activity.type.toString().toLowerCase().contains(queryLower))
          .toList();
      results['activities'] = activities;
      
      return results;
    } catch (e) {
      return {};
    }
  }
  
  // Advanced search with multiple criteria
  Future<List<Debt>> advancedDebtSearch(Map<String, dynamic> filters) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('debts').get();
      List<Debt> debts = snapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      // Apply filters
      if (filters.containsKey('customerId') && filters['customerId'] != null) {
        debts = debts.where((debt) => debt.customerId == filters['customerId']).toList();
      }
      
      if (filters.containsKey('status') && filters['status'] != null) {
        final status = filters['status'];
        debts = debts.where((debt) {
          if (status == 'pending') return debt.paidAmount == 0;
          if (status == 'partially paid') return debt.paidAmount > 0 && debt.paidAmount < debt.amount;
          if (status == 'fully paid') return debt.paidAmount >= debt.amount;
          return true;
        }).toList();
      }
      
      if (filters.containsKey('minAmount') && filters['minAmount'] != null) {
        debts = debts.where((debt) => debt.amount >= filters['minAmount']).toList();
      }
      
      if (filters.containsKey('maxAmount') && filters['maxAmount'] != null) {
        debts = debts.where((debt) => debt.amount <= filters['maxAmount']).toList();
      }
      
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        debts = debts.where((debt) => debt.createdAt.isAfter(filters['startDate'])).toList();
      }
      
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        debts = debts.where((debt) => debt.createdAt.isBefore(filters['endDate'])).toList();
      }
      
      return debts;
    } catch (e) {
      return [];
    }
  }
  
  // ===== BACKUP & DATA MANAGEMENT =====
  
  // Create backup
  Future<String> createBackup({bool isAutomatic = false}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      print('💾 Starting backup creation for userId: $currentUserId');
      
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = <String, dynamic>{
        'id': backupId,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toIso8601String(),
        'isAutomatic': isAutomatic,
        'backupType': isAutomatic ? 'automatic' : 'manual',
      };
      
      print('💾 Collecting data for backup...');
      
      // Get all data for backup
      final customersSnapshot = await _firestore.collection('customers').get();
      final debtsSnapshot = await _firestore.collection('debts').get();
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final purchasesSnapshot = await _firestore.collection('product_purchases').get();
      final paymentsSnapshot = await _firestore.collection('partial_payments').get();
      final activitiesSnapshot = await _firestore.collection('activities').get();
      final settingsSnapshot = await _firestore.collection('currency_settings').get();
      
      print('💾 Data collected:');
      print('   - Customers: ${customersSnapshot.docs.length}');
      print('   - Debts: ${debtsSnapshot.docs.length}');
      print('   - Categories: ${categoriesSnapshot.docs.length}');
      print('   - Product Purchases: ${purchasesSnapshot.docs.length}');
      print('   - Partial Payments: ${paymentsSnapshot.docs.length}');
      print('   - Activities: ${activitiesSnapshot.docs.length}');
      print('   - Currency Settings: ${settingsSnapshot.docs.length}');
      
      backupData['customers'] = customersSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['debts'] = debtsSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['categories'] = categoriesSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['product_purchases'] = purchasesSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['partial_payments'] = paymentsSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['activities'] = activitiesSnapshot.docs.map((doc) => doc.data()).toList();
      backupData['currency_settings'] = settingsSnapshot.docs.map((doc) => doc.data()).toList();
      
      print('💾 Saving backup to Firestore with ID: $backupId');
      await _firestore.collection('backups').doc(backupId).set(backupData);
      
      print('✅ Backup created successfully: $backupId');
      return backupId;
    } catch (e) {
      print('❌ Error creating backup: $e');
      rethrow;
    }
  }
  
  // Get available backups
  Future<List<String>> getAvailableBackups() async {
    if (!isAuthenticated) return [];
    
    try {
      print('🔍 Searching for backups for userId: $currentUserId');
      
      // Get all backups and filter in memory to avoid composite index requirement
      var snapshot = await _firestore
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('🔍 Found ${snapshot.docs.length} total backups');
      
      // Filter by userId in memory
      final userBackups = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['userId'] == currentUserId;
      }).toList();
      
      print('🔍 Found ${userBackups.length} backups for current user');
      
      final backupIds = userBackups.map((doc) => doc.id).toList();
      print('🔍 Returning backup IDs: $backupIds');
      return backupIds;
    } catch (e) {
      print('❌ Error getting available backups: $e');
      return [];
    }
  }

  // Get backup metadata
  Future<Map<String, dynamic>?> getBackupMetadata(String backupId) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore.collection('backups').doc(backupId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = doc.data()!;
      return {
        'id': backupId,
        'isAutomatic': data['isAutomatic'] ?? false,
        'backupType': data['backupType'] ?? 'manual',
        'timestamp': data['timestamp'],
        'createdAt': data['createdAt'],
      };
    } catch (e) {
      print('❌ Error getting backup metadata: $e');
      return null;
    }
  }
  
  // Restore from backup
  Future<bool> restoreFromBackup(String backupId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final backupDoc = await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists || backupDoc.data() == null) {
        return false;
      }
      
      final backupData = backupDoc.data()!;
      
      // Clear existing data first
      await clearAllData();
      
      // Restore data from backup
      final batch = _firestore.batch();
      
      // Restore customers
      if (backupData.containsKey('customers')) {
        for (final customerData in backupData['customers']) {
          final customerRef = _firestore.collection('customers').doc();
          batch.set(customerRef, customerData);
        }
      }
      
      // Restore categories
      if (backupData.containsKey('categories')) {
        for (final categoryData in backupData['categories']) {
          final categoryRef = _firestore.collection('categories').doc();
          batch.set(categoryRef, categoryData);
        }
      }
      
      // Restore debts
      if (backupData.containsKey('debts')) {
        for (final debtData in backupData['debts']) {
          final debtRef = _firestore.collection('debts').doc();
          batch.set(debtRef, debtData);
        }
      }
      
      // Restore product purchases
      if (backupData.containsKey('product_purchases')) {
        for (final purchaseData in backupData['product_purchases']) {
          final purchaseRef = _firestore.collection('product_purchases').doc();
          batch.set(purchaseRef, purchaseData);
        }
      }
      
      // Restore partial payments
      if (backupData.containsKey('partial_payments')) {
        for (final paymentData in backupData['partial_payments']) {
          final paymentRef = _firestore.collection('partial_payments').doc();
          batch.set(paymentRef, paymentData);
        }
      }
      
      // Restore activities
      if (backupData.containsKey('activities')) {
        for (final activityData in backupData['activities']) {
          final activityRef = _firestore.collection('activities').doc();
          batch.set(activityRef, activityData);
        }
      }
      
      // Restore currency settings
      if (backupData.containsKey('currency_settings')) {
        for (final settingData in backupData['currency_settings']) {
          final settingRef = _firestore.collection('currency_settings').doc();
          batch.set(settingRef, settingData);
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Delete backup
  Future<bool> deleteBackup(String backupId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      await _firestore.collection('backups').doc(backupId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Export data
  Future<Map<String, dynamic>> exportData(String format) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final customersSnapshot = await _firestore.collection('customers').get();
      final debtsSnapshot = await _firestore.collection('debts').get();
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final purchasesSnapshot = await _firestore.collection('product_purchases').get();
      final paymentsSnapshot = await _firestore.collection('partial_payments').get();
      final activitiesSnapshot = await _firestore.collection('activities').get();
      
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'format': format,
        'customers': customersSnapshot.docs.map((doc) => doc.data()).toList(),
        'debts': debtsSnapshot.docs.map((doc) => doc.data()).toList(),
        'categories': categoriesSnapshot.docs.map((doc) => doc.data()).toList(),
        'product_purchases': purchasesSnapshot.docs.map((doc) => doc.data()).toList(),
        'partial_payments': paymentsSnapshot.docs.map((doc) => doc.data()).toList(),
        'activities': activitiesSnapshot.docs.map((doc) => doc.data()).toList(),
      };
      
      return exportData;
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== ANALYTICS & REPORTING =====
  
  // Get revenue by period
  Future<double> getRevenueByPeriod(DateTime start, DateTime end) async {
    if (!isAuthenticated) return 0.0;
    
    try {
      final snapshot = await _firestore.collection('partial_payments').get();
      
      final List<PartialPayment> payments = snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .where((payment) => 
            payment.paidAt.isAfter(start) && payment.paidAt.isBefore(end))
          .toList();
      
      return payments.fold<double>(0.0, (double sum, PartialPayment payment) => sum + payment.amount);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Get customer debt summary
  Future<Map<String, dynamic>> getCustomerDebtSummary(String customerId) async {
    if (!isAuthenticated) return {};
    
    try {
      final debtsSnapshot = await _firestore
          .collection('debts')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      final debts = debtsSnapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      final totalDebt = debts.fold(0.0, (sum, debt) => sum + debt.amount);
      final totalPaid = debts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
      final pendingAmount = totalDebt - totalPaid;
      
      return {
        'totalDebt': totalDebt,
        'totalPaid': totalPaid,
        'pendingAmount': pendingAmount,
        'debtsCount': debts.length,
        'pendingDebtsCount': debts.where((d) => d.paidAmount < d.amount).length,
      };
    } catch (e) {
      return {};
    }
  }
  
  // Get payment trends
  Future<List<Map<String, dynamic>>> getPaymentTrends(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('partial_payments').get();
      
      final payments = snapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .where((payment) => 
            payment.paidAt.isAfter(start) && payment.paidAt.isBefore(end))
          .toList();
      
      // Group by date
      final groupedPayments = <String, double>{};
      for (final payment in payments) {
        final dateKey = '${payment.paidAt.year}-${payment.paidAt.month.toString().padLeft(2, '0')}-${payment.paidAt.day.toString().padLeft(2, '0')}';
        groupedPayments[dateKey] = (groupedPayments[dateKey] ?? 0.0) + payment.amount;
      }
      
      return groupedPayments.entries
          .map((entry) => {
            'date': entry.key,
            'amount': entry.value,
          })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } catch (e) {
      return [];
    }
  }
  
  // Get product performance
  Future<List<Map<String, dynamic>>> getProductPerformance(String categoryId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore.collection('product_purchases').get();
      
      final purchases = snapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .where((purchase) => purchase.categoryName == categoryId)
          .toList();
      
      // Group by subcategory
      final groupedPurchases = <String, List<ProductPurchase>>{};
      for (final purchase in purchases) {
        groupedPurchases.putIfAbsent(purchase.subcategoryName, () => []).add(purchase);
      }
      
      return groupedPurchases.entries
          .map((entry) => {
            'subcategory': entry.key,
            'count': entry.value.length,
            'totalAmount': entry.value.fold(0.0, (sum, p) => sum + p.sellingPrice),
            'totalCost': entry.value.fold(0.0, (sum, p) => sum + p.costPrice),
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get customer payment history
  Future<List<Map<String, dynamic>>> getCustomerPaymentHistory(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final paymentsSnapshot = await _firestore
          .collection('partial_payments')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return paymentsSnapshot.docs
          .map((doc) => {
            'id': doc.id,
            'amount': doc.data()['amount'],
            'date': doc.data()['createdAt'],
            'debtId': doc.data()['debtId'],
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // ===== NOTIFICATION & COMMUNICATION =====
  
  // Send notification
  Future<void> sendNotification(String userId, String message) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final notificationData = {
        'id': 'notification_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderId': currentUserId,
      };
      
      await _firestore
          .collection('notifications')
          .doc(notificationData['id'] as String)
          .set(notificationData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Schedule notification
  Future<void> scheduleNotification(String userId, String message, DateTime time) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final notificationData = {
        'id': 'scheduled_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'message': message,
        'scheduledFor': time.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderId': currentUserId,
        'status': 'scheduled',
      };
      
      await _firestore
          .collection('scheduled_notifications')
          .doc(notificationData['id'] as String)
          .set(notificationData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      return snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== DATA VALIDATION & INTEGRITY =====
  
  // Validate data integrity
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    if (!isAuthenticated) return {};
    
    try {
      final issues = <String, List<String>>{};
      
      // Check for orphaned debts (debts without customers)
      final customersSnapshot = await _firestore.collection('customers').get();
      final customerIds = customersSnapshot.docs.map((doc) => doc.id).toSet();
      
      final debtsSnapshot = await _firestore.collection('debts').get();
      final orphanedDebts = debtsSnapshot.docs
          .where((doc) => !customerIds.contains(doc.data()['customerId']))
          .map((doc) => doc.id)
          .toList();
      
      if (orphanedDebts.isNotEmpty) {
        issues['orphanedDebts'] = orphanedDebts;
      }
      
      // Check for orphaned payments (payments without debts)
      final debtIds = debtsSnapshot.docs.map((doc) => doc.id).toSet();
      final paymentsSnapshot = await _firestore.collection('partial_payments').get();
      final orphanedPayments = paymentsSnapshot.docs
          .where((doc) => !debtIds.contains(doc.data()['debtId']))
          .map((doc) => doc.id)
          .toList();
      
      if (orphanedPayments.isNotEmpty) {
        issues['orphanedPayments'] = orphanedPayments;
      }
      
      // Check for data consistency
      final totalDebts = debtsSnapshot.docs.length;
      final totalCustomers = customersSnapshot.docs.length;
      final totalPayments = paymentsSnapshot.docs.length;
      
      return {
        'issues': issues,
        'statistics': {
          'totalCustomers': totalCustomers,
          'totalDebts': totalDebts,
          'totalPayments': totalPayments,
          'orphanedDebts': orphanedDebts.length,
          'orphanedPayments': orphanedPayments.length,
        },
        'isValid': issues.isEmpty,
      };
    } catch (e) {
      return {'error': e.toString(), 'isValid': false};
    }
  }
  
  // Fix data inconsistencies
  Future<bool> fixDataInconsistencies() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final validation = await validateDataIntegrity();
      if (validation['isValid'] == true) {
        return true; // No issues to fix
      }
      
      final issues = validation['issues'] as Map<String, List<String>>;
      final batch = _firestore.batch();
      
      // Fix orphaned payments
      if (issues.containsKey('orphanedPayments')) {
        for (final paymentId in issues['orphanedPayments']!) {
          batch.delete(_firestore.collection('partial_payments').doc(paymentId));
        }
      }
      
      // Fix orphaned debts
      if (issues.containsKey('orphanedDebts')) {
        for (final debtId in issues['orphanedDebts']!) {
          batch.delete(_firestore.collection('debts').doc(debtId));
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get data statistics
  Future<Map<String, dynamic>> getDataStatistics() async {
    if (!isAuthenticated) return {};
    
    try {
      final customersSnapshot = await _firestore.collection('customers').get();
      final debtsSnapshot = await _firestore.collection('debts').get();
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final purchasesSnapshot = await _firestore.collection('product_purchases').get();
      final paymentsSnapshot = await _firestore.collection('partial_payments').get();
      final activitiesSnapshot = await _firestore.collection('activities').get();
      
      final totalDebt = debtsSnapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .fold(0.0, (sum, debt) => sum + debt.amount);
      
      final totalPaid = paymentsSnapshot.docs
          .map((doc) => PartialPayment.fromJson({...doc.data(), 'id': doc.id}))
          .fold(0.0, (sum, payment) => sum + payment.amount);
      
      return {
        'totalCustomers': customersSnapshot.docs.length,
        'totalDebts': debtsSnapshot.docs.length,
        'totalCategories': categoriesSnapshot.docs.length,
        'totalProductPurchases': purchasesSnapshot.docs.length,
        'totalPartialPayments': paymentsSnapshot.docs.length,
        'totalActivities': activitiesSnapshot.docs.length,
        'totalDebtAmount': totalDebt,
        'totalPaidAmount': totalPaid,
        'pendingAmount': totalDebt - totalPaid,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // ===== DATA CLEARING METHODS =====
  
  // Clear all debts for current user
  Future<void> clearDebts() async {
    try {
      print('🔄 Starting to clear debts...');
      
      // Get all debts (no userId filter since app is running without authentication)
      final debtsSnapshot = await _firestore
          .collection('debts')
          .get()
          .timeout(const Duration(seconds: 30)); // Add timeout protection
      
      if (debtsSnapshot.docs.isEmpty) {
        print('✅ No debts found to clear');
        return;
      }
      
      print('🔄 Found ${debtsSnapshot.docs.length} debts to clear');
      
      // Delete each debt document
      final batch = _firestore.batch();
      for (final doc in debtsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion with timeout
      await batch.commit().timeout(const Duration(seconds: 30));
      
      print('✅ Successfully cleared ${debtsSnapshot.docs.length} debts from Firebase');
    } catch (e) {
      print('❌ Error clearing debts: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing debts. Please try again.');
      }
      rethrow;
    }
  }
  
  // Clear all partial payments for current user
  Future<void> clearPartialPayments() async {
    try {
      print('🔄 Starting to clear partial payments...');
      
      // Get all partial payments (no userId filter since app is running without authentication)
      final paymentsSnapshot = await _firestore
          .collection('partial_payments')
          .get()
          .timeout(const Duration(seconds: 30)); // Add timeout protection
      
      if (paymentsSnapshot.docs.isEmpty) {
        print('✅ No partial payments found to clear');
        return;
      }
      
      print('🔄 Found ${paymentsSnapshot.docs.length} partial payments to clear');
      
      // Delete each payment document
      final batch = _firestore.batch();
      for (final doc in paymentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion with timeout
      await batch.commit().timeout(const Duration(seconds: 30));
      
      print('✅ Successfully cleared ${paymentsSnapshot.docs.length} partial payments from Firebase');
    } catch (e) {
      print('❌ Error clearing partial payments: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing partial payments. Please try again.');
      }
      rethrow;
    }
  }
  
  // Clear all activities for current user
  Future<void> clearActivities() async {
    try {
      print('🔄 Starting to clear activities...');
      
      // Get all activities (no userId filter since app is running without authentication)
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .get()
          .timeout(const Duration(seconds: 30)); // Add timeout protection
      
      if (activitiesSnapshot.docs.isEmpty) {
        print('✅ No activities found to clear');
        return;
      }
      
      print('🔄 Found ${activitiesSnapshot.docs.length} activities to clear');
      
      // Delete each activity document
      final batch = _firestore.batch();
      for (final doc in activitiesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion with timeout
      await batch.commit().timeout(const Duration(seconds: 30));
      
      print('✅ Successfully cleared ${activitiesSnapshot.docs.length} activities from Firebase');
    } catch (e) {
      print('❌ Error clearing activities: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing activities. Please try again.');
      }
      rethrow;
    }
  }
  
  // Clear all data for current user (customers, debts, products, activities, payments)
  Future<void> clearAllData() async {
    try {
      print('🔄 Starting to clear all data...');
      
      // Clear all collections (no userId filter since app is running without authentication)
      await clearDebts();
      await clearPartialPayments();
      await clearActivities();
      
      // Clear customers
      final customersSnapshot = await _firestore
          .collection('customers')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (customersSnapshot.docs.isNotEmpty) {
        final customersBatch = _firestore.batch();
        for (final doc in customersSnapshot.docs) {
          customersBatch.delete(doc.reference);
        }
        await customersBatch.commit().timeout(const Duration(seconds: 30));
        print('✅ Cleared ${customersSnapshot.docs.length} customers');
      }
      
      // Clear categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (categoriesSnapshot.docs.isNotEmpty) {
        final categoriesBatch = _firestore.batch();
        for (final doc in categoriesSnapshot.docs) {
          categoriesBatch.delete(doc.reference);
        }
        await categoriesBatch.commit().timeout(const Duration(seconds: 30));
        print('✅ Cleared ${categoriesSnapshot.docs.length} categories');
      }
      
      // Clear product purchases
      final purchasesSnapshot = await _firestore
          .collection('product_purchases')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (purchasesSnapshot.docs.isNotEmpty) {
        final purchasesBatch = _firestore.batch();
        for (final doc in purchasesSnapshot.docs) {
          purchasesBatch.delete(doc.reference);
        }
        await purchasesBatch.commit().timeout(const Duration(seconds: 30));
        print('✅ Cleared ${purchasesSnapshot.docs.length} product purchases');
      }
      
      print('✅ Successfully cleared all data from Firebase');
    } catch (e) {
      print('❌ Error clearing all data: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing all data. Please try again.');
      }
      rethrow;
    }
  }
}
