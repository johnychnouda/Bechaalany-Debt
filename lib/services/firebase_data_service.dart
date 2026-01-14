import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../models/product_purchase.dart';
import '../models/currency_settings.dart';
import '../models/activity.dart';

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
  
  // Check Firebase connection health
  Future<Map<String, dynamic>> checkFirebaseHealth() async {
    final health = <String, dynamic>{
      'isAuthenticated': isAuthenticated,
      'userId': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (!isAuthenticated) {
      health['error'] = 'User not authenticated';
      return health;
    }
    
    try {
      // Test basic Firestore connectivity
      final testDoc = _firestore.collection('_health_check').doc('test');
      await testDoc.set({'test': true, 'timestamp': FieldValue.serverTimestamp()});
      
      // Verify the document was saved
      final savedDoc = await testDoc.get();
      if (savedDoc.exists) {
        health['firestore_connected'] = true;
        health['firestore_writable'] = true;
        
        // Clean up test document
        await testDoc.delete();
      } else {
        health['firestore_connected'] = false;
        health['error'] = 'Document verification failed';
      }
    } catch (e) {
      health['firestore_connected'] = false;
      health['error'] = e.toString();
    }
    
    return health;
  }

  // Local storage for partial payments
  // Note: Partial payments are now handled as activities only

  // ===== CUSTOMERS =====
  
  // Add/Update customer
  Future<void> addOrUpdateCustomer(Customer customer) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final customerData = customer.toJson();
    customerData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('customers')
        .doc(customer.id)
        .set(customerData, SetOptions(merge: true));
  }

  // Get all customers for current user
  Stream<List<Customer>> getCustomersStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('customers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('customers')
        .doc(customerId)
        .delete();
  }

  // Get all categories for current user
  Stream<List<ProductCategory>> getCategoriesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get categories directly
  Future<List<ProductCategory>> getCategoriesDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      // Get categories from user-specific subcollection
      var querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('categories')
          .get();
      
      // No need for fallback since data is user-specific
      
      final categories = querySnapshot.docs
          .map((doc) => ProductCategory.fromJson(doc.data()))
          .toList();
      
      return categories;
    } catch (e) {
      return [];
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // ===== CATEGORIES =====
  
  // Add/Update category
  Future<void> addOrUpdateCategory(ProductCategory category) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final categoryData = category.toJson();
    categoryData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
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
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('product_purchases')
        .doc(purchase.id)
        .set(purchaseData, SetOptions(merge: true));
  }

  // Get all product purchases for current user
  Stream<List<ProductPurchase>> getProductPurchasesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('product_purchases')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get product purchases directly
  Future<List<ProductPurchase>> getProductPurchasesDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      // Get product purchases from user-specific subcollection
      var querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('product_purchases')
          .get();
      
      // No need for fallback since data is user-specific
      
      final productPurchases = querySnapshot.docs
          .map((doc) => ProductPurchase.fromJson(doc.data()))
          .toList();
      
      return productPurchases;
    } catch (e) {
      return [];
    }
  }

  // Delete product purchase
  Future<void> deleteProductPurchase(String purchaseId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('product_purchases')
        .doc(purchaseId)
        .delete();
  }

  // ===== DEBTS =====
  
  // Add/Update debt
  Future<void> addOrUpdateDebt(Debt debt) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final debtData = debt.toJson();
    debtData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('debts')
        .doc(debt.id)
        .set(debtData, SetOptions(merge: true));
  }

  // Get all debts for current user
  Stream<List<Debt>> getDebtsStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('debts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // Get debts directly
  Future<List<Debt>> getDebtsDirectly() async {
    if (!isAuthenticated) return [];
    
    try {
      // Get debts from user-specific subcollection
      var querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('debts')
          .get();
      
      // No need for fallback since data is user-specific
      
      final debts = querySnapshot.docs
          .map((doc) => Debt.fromJson(doc.data()))
          .toList();
      
      return debts;
    } catch (e) {
      return [];
    }
  }

  // Delete debt
  Future<void> deleteDebt(String debtId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    // Get the current user and verify authentication
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found. Please sign in again.');
    }
    
    // Force get a fresh ID token to ensure auth is current
    String? idToken;
    try {
      idToken = await user.getIdToken(true); // Force refresh
    } catch (e) {
      throw Exception('Failed to refresh authentication token. Please sign out and sign back in.');
    }
    
    // Reload user to ensure auth token is fresh
    try {
      await user.reload();
      // Get fresh user after reload
      final freshUser = _auth.currentUser;
      if (freshUser == null) {
        throw Exception('User authentication lost after reload. Please sign in again.');
      }
    } catch (e) {
      // If reload fails, check if user still exists
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User authentication failed. Please sign in again.');
      }
    }
    
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User ID is null. Please sign out and sign back in.');
    }
    
    // Verify the userId matches the authenticated user's UID
    if (userId != user.uid) {
      throw Exception('User ID mismatch. Expected: ${user.uid}, Got: $userId. Please sign out and sign back in.');
    }
    
    // Verify the path matches the rules: /users/{userId}/debts/{debtId}
    final debtRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('debts')
        .doc(debtId);
    
    // First verify we can read the document (this tests read permissions)
    try {
      final doc = await debtRef.get();
      
      if (!doc.exists) {
        throw Exception('Debt document does not exist at path: /users/$userId/debts/$debtId\n\nPlease check Firebase Console to verify the document exists.');
      }
      
      // Verify the document data contains expected fields
      final data = doc.data();
      if (data == null) {
        throw Exception('Debt document exists but has no data. Debt ID: $debtId');
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        // Check if it's a read permission issue
        throw Exception('Permission denied: Cannot read debt document.\n\nThis means Firestore rules are blocking READ access.\n\nUser ID: $userId\nAuth UID: ${user.uid}\nDebt ID: $debtId\nPath: /users/$userId/debts/$debtId\n\nPlease verify in Firebase Console:\n1. Document exists at: https://console.firebase.google.com/project/bechaalany-debt-app-e1bb0/firestore/data/users/$userId/debts/$debtId\n2. Rules allow read: https://console.firebase.google.com/project/bechaalany-debt-app-e1bb0/firestore/rules\n\nRule should be: allow read: if request.auth != null && request.auth.uid == userId;');
      }
      rethrow;
    }
    
    // Attempt deletion with better error handling
    try {
      await debtRef.delete();
    } catch (e) {
      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Cannot delete debt.\n\nUser ID: $userId\nAuth UID: ${user.uid}\nDebt ID: $debtId\nPath: /users/$userId/debts/$debtId\n\nPlease verify:\n1. User ID matches Auth UID (should both be: $userId)\n2. Document exists at the path above\n3. Firestore rules allow delete operations:\nhttps://console.firebase.google.com/project/bechaalany-debt-app-e1bb0/firestore/rules\n\nRule should be: allow delete: if request.auth != null && request.auth.uid == userId;');
      }
      // Re-throw with more context
      throw Exception('Failed to delete debt: ${e.toString()}. User ID: $userId, Debt ID: $debtId');
    }
  }

  // Note: Partial payments are now handled as activities only

  // Note: Partial payments are now handled as activities only
  
  // Note: Partial payments are now handled as activities only

  // Note: Partial payments are now handled as activities only

  // ===== CURRENCY SETTINGS =====
  
  // Add/Update currency settings
  Future<void> addOrUpdateCurrencySettings(CurrencySettings settings) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final settingsData = settings.toJson();
    settingsData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('currency_settings')
        .doc('settings')
        .set(settingsData, SetOptions(merge: true));
  }

  // Get currency settings for current user
  Stream<CurrencySettings?> getCurrencySettingsStream() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('currency_settings')
        .doc('settings')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return CurrencySettings.fromJson(snapshot.data()!);
          }
          return null;
        });
  }

  // Get currency settings directly (for immediate access)
  Future<CurrencySettings?> getCurrencySettings() async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('currency_settings')
          .doc('settings')
          .get();
      
      if (doc.exists && doc.data() != null) {
        return CurrencySettings.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all activities for current user
  Stream<List<Activity>> getActivitiesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('activities')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          return activities;
        });
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
        // Note: Partial payments are now handled as activities only
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
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== SEARCH & FILTER METHODS =====
  
  // Get customer by ID
  Future<Customer?> getCustomer(String customerId) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .doc(customerId)
          .get();
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
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get();
      
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
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get();
      
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
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get();
      
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
          .collection('users')
          .doc(currentUserId!)
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
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('debts')
          .get();
      
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
      final snapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
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
      final snapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
      final snapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
      final snapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('debts')
        .doc(debtId)
        .update({
      'paidAmount': FieldValue.increment(1000000), // Large number to ensure it's marked as paid
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Note: Debt history is now handled by activities only
  
  // Note: Partial payments are now handled as activities only
  
  // Note: Partial payments are now handled as activities only
  
  // Note: Partial payments are now handled as activities only
  
  // Note: Partial payments are now handled as activities only
  
  // Get product purchases by customer
  Future<List<ProductPurchase>> getProductPurchasesByCustomer(String customerId) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('product_purchases')
          .where('userId', isEqualTo: currentUserId)
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
          .where('userId', isEqualTo: currentUserId)
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
      final snapshot = await _firestore
          .collection('product_purchases')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
      final snapshot = await _firestore
          .collection('product_purchases')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('product_purchases')
        .doc(purchaseId)
        .update({
      'isPaid': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Get product purchase history
  Future<List<ProductPurchase>> getProductPurchaseHistory(String purchaseId) async {
    if (!isAuthenticated) return [];
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('product_purchases')
          .doc(purchaseId)
          .get();
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
    if (!isAuthenticated) {
      return;
    }
    
    final activityData = activity.toJson();
    activityData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    
    // Rate limiting: Add delay between activity saves to prevent throttling
    await Future.delayed(Duration(milliseconds: 500));
    
    // Simplified approach: Save without aggressive verification
    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .doc(activity.id);
      await docRef.set(activityData, SetOptions(merge: true));
      
      // Simple verification with multiple attempts to handle eventual consistency
      bool verified = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 1000 + (i * 500)));
        try {
          final savedDoc = await docRef.get();
          if (savedDoc.exists) {
            verified = true;
            break;
          }
        } catch (verifyError) {
        }
      }
      
      if (!verified) {
      }
      
    } catch (e) {
    }
  }
  
  // Update activity
  Future<void> updateActivity(Activity activity) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final activityData = activity.toJson();
    activityData['lastUpdated'] = FieldValue.serverTimestamp();
    // Remove userId from data since it's now implicit in the path structure
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('activities')
        .doc(activity.id)
        .set(activityData, SetOptions(merge: true));
  }
  
  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('activities')
        .doc(activityId)
        .delete();
  }
  
  // Get activities by type
  Future<List<Activity>> getActivitiesByType(String type) async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUserId)
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
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
          .where('userId', isEqualTo: currentUserId)
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
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
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
  

  // Get all activities from Firebase (for manual refresh)
  Future<List<Activity>> getAllActivities() async {
    if (!isAuthenticated) {
      return [];
    }
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // ===== ADVANCED SEARCH METHODS =====
  
  // Global search across all collections
  Future<Map<String, List<dynamic>>> globalSearch(String query) async {
    if (!isAuthenticated) return {};
    
    try {
      final queryLower = query.toLowerCase();
      final results = <String, List<dynamic>>{};
      
      // Search customers
      final customersSnapshot = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: currentUserId)
          .get();
      final customers = customersSnapshot.docs
          .map((doc) => Customer.fromJson({...doc.data(), 'id': doc.id}))
          .where((customer) => 
            customer.name.toLowerCase().contains(queryLower) ||
            customer.id.toLowerCase().contains(queryLower))
          .toList();
      results['customers'] = customers;
      
      // Search debts
      final debtsSnapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
      final debts = debtsSnapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .where((debt) => 
            debt.customerName.toLowerCase().contains(queryLower) ||
            debt.customerId.toLowerCase().contains(queryLower))
          .toList();
      results['debts'] = debts;
      
      // Search products
      final productsSnapshot = await _firestore
          .collection('product_purchases')
          .where('userId', isEqualTo: currentUserId)
          .get();
      final products = productsSnapshot.docs
          .map((doc) => ProductPurchase.fromJson({...doc.data(), 'id': doc.id}))
          .where((product) => 
            product.subcategoryName.toLowerCase().contains(queryLower) ||
            product.categoryName.toLowerCase().contains(queryLower))
          .toList();
      results['products'] = products;
      
      // Search activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUserId)
          .get();
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
      final snapshot = await _firestore
          .collection('debts')
          .where('userId', isEqualTo: currentUserId)
          .get();
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
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get all user data for backup
      final customersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get();
      
      final debtsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('debts')
          .get();
      
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('categories')
          .get();
      
      final purchasesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('product_purchases')
          .get();
      
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('partial_payments')
          .get();
      
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .get();
      
      final settingsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('currency_settings')
          .get();
      
      // Prepare backup data with actual user data
      final backupData = <String, dynamic>{
        'id': backupId,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toIso8601String(),
        'isAutomatic': isAutomatic,
        'backupType': isAutomatic ? 'automatic' : 'manual',
        'status': 'created',
        'data': {
          'customers': customersSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'debts': debtsSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'categories': categoriesSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'product_purchases': purchasesSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'partial_payments': paymentsSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'activities': activitiesSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
          'currency_settings': settingsSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList(),
        },
      };
      
      // Store backup with actual data in user-specific collection
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('backups')
          .doc(backupId)
          .set(backupData);
      
      return backupId;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }
  
  // Get available backups
  Future<List<String>> getAvailableBackups() async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Get backup metadata
  Future<Map<String, dynamic>?> getBackupMetadata(String backupId) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('backups')
          .doc(backupId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Restore from backup
  Future<bool> restoreFromBackup(String backupId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Get backup data
      final backupDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('backups')
          .doc(backupId)
          .get();
      
      if (!backupDoc.exists || backupDoc.data() == null) {
        return false;
      }
      
      final backupData = backupDoc.data()!;
      final userData = backupData['data'] as Map<String, dynamic>?;
      
      if (userData == null) {
        return false;
      }
      
      // Clear existing data first
      await _clearUserData();
      
      // Restore data from backup using batch writes for efficiency
      final batch = _firestore.batch();
      
      // Restore customers
      if (userData.containsKey('customers')) {
        final customers = userData['customers'] as List<dynamic>;
        for (final customerData in customers) {
          final customerMap = customerData as Map<String, dynamic>;
          final customerId = customerMap['id'] as String;
          customerMap.remove('id'); // Remove id from data before storing
          
          final customerRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('customers')
              .doc(customerId);
          batch.set(customerRef, customerMap);
        }
      }
      
      // Restore categories
      if (userData.containsKey('categories')) {
        final categories = userData['categories'] as List<dynamic>;
        for (final categoryData in categories) {
          final categoryMap = categoryData as Map<String, dynamic>;
          final categoryId = categoryMap['id'] as String;
          categoryMap.remove('id');
          
          final categoryRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('categories')
              .doc(categoryId);
          batch.set(categoryRef, categoryMap);
        }
      }
      
      // Restore debts
      if (userData.containsKey('debts')) {
        final debts = userData['debts'] as List<dynamic>;
        for (final debtData in debts) {
          final debtMap = debtData as Map<String, dynamic>;
          final debtId = debtMap['id'] as String;
          debtMap.remove('id');
          
          final debtRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('debts')
              .doc(debtId);
          batch.set(debtRef, debtMap);
        }
      }
      
      // Restore product purchases
      if (userData.containsKey('product_purchases')) {
        final purchases = userData['product_purchases'] as List<dynamic>;
        for (final purchaseData in purchases) {
          final purchaseMap = purchaseData as Map<String, dynamic>;
          final purchaseId = purchaseMap['id'] as String;
          purchaseMap.remove('id');
          
          final purchaseRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('product_purchases')
              .doc(purchaseId);
          batch.set(purchaseRef, purchaseMap);
        }
      }
      
      // Restore partial payments
      if (userData.containsKey('partial_payments')) {
        final payments = userData['partial_payments'] as List<dynamic>;
        for (final paymentData in payments) {
          final paymentMap = paymentData as Map<String, dynamic>;
          final paymentId = paymentMap['id'] as String;
          paymentMap.remove('id');
          
          final paymentRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('partial_payments')
              .doc(paymentId);
          batch.set(paymentRef, paymentMap);
        }
      }
      
      // Restore activities
      if (userData.containsKey('activities')) {
        final activities = userData['activities'] as List<dynamic>;
        for (final activityData in activities) {
          final activityMap = activityData as Map<String, dynamic>;
          final activityId = activityMap['id'] as String;
          activityMap.remove('id');
          
          final activityRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('activities')
              .doc(activityId);
          batch.set(activityRef, activityMap);
        }
      }
      
      // Restore currency settings
      if (userData.containsKey('currency_settings')) {
        final settings = userData['currency_settings'] as List<dynamic>;
        for (final settingData in settings) {
          final settingMap = settingData as Map<String, dynamic>;
          final settingId = settingMap['id'] as String;
          settingMap.remove('id');
          
          final settingRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('currency_settings')
              .doc(settingId);
          batch.set(settingRef, settingMap);
        }
      }
      
      // Commit all changes
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
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('backups')
          .doc(backupId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Clear all user data (used before restore)
  Future<void> _clearUserData() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final batch = _firestore.batch();
      
      // Clear customers
      final customersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get();
      for (final doc in customersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear debts
      final debtsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('debts')
          .get();
      for (final doc in debtsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear categories
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('categories')
          .get();
      for (final doc in categoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear product purchases
      final purchasesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('product_purchases')
          .get();
      for (final doc in purchasesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear partial payments
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('partial_payments')
          .get();
      for (final doc in paymentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear activities
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .get();
      for (final doc in activitiesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear currency settings
      final settingsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('currency_settings')
          .get();
      for (final doc in settingsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
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
  
  // Get revenue by period (now using activities)
  Future<double> getRevenueByPeriod(DateTime start, DateTime end) async {
    if (!isAuthenticated) return 0.0;
    
    try {
      // Get payment activities for the period
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .where('type', isEqualTo: 'payment')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      
      double totalRevenue = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['amount'] != null) {
          totalRevenue += (data['amount'] as num).toDouble();
        }
      }
      
      return totalRevenue;
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
      
      final totalDebt = debts.fold(0.0, (total, debt) => total + debt.amount);
      final totalPaid = debts.fold(0.0, (total, debt) => total + debt.paidAmount);
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
  
  // Get payment trends (now using activities)
  Future<List<Map<String, dynamic>>> getPaymentTrends(DateTime start, DateTime end) async {
    if (!isAuthenticated) return [];
    
    try {
      // Get payment activities for the period
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .where('type', isEqualTo: 'payment')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      
      // Group by date
      final groupedPayments = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        groupedPayments[dateKey] = (groupedPayments[dateKey] ?? 0.0) + amount;
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
      final activitiesSnapshot = await _firestore.collection('activities').get();
      
      final totalDebt = debtsSnapshot.docs
          .map((doc) => Debt.fromJson({...doc.data(), 'id': doc.id}))
          .fold(0.0, (total, debt) => total + debt.amount);
      
      // Calculate total paid from payment activities
      double totalPaid = 0.0;
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'payment' && data['amount'] != null) {
          totalPaid += (data['amount'] as num).toDouble();
        }
      }
      
      return {
        'totalCustomers': customersSnapshot.docs.length,
        'totalDebts': debtsSnapshot.docs.length,
        'totalCategories': categoriesSnapshot.docs.length,
        'totalProductPurchases': purchasesSnapshot.docs.length,
        'totalPartialPayments': 0, // Note: Partial payments are now handled as activities
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
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Get all debts for current user only
      final debtsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('debts')
          .get()
          .timeout(const Duration(seconds: 30)); // Add timeout protection
      
      if (debtsSnapshot.docs.isEmpty) {
        return;
      }
      
      // Delete each debt document
      final batch = _firestore.batch();
      for (final doc in debtsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion with timeout
      await batch.commit().timeout(const Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing debts. Please try again.');
      }
      rethrow;
    }
  }
  
  // Note: Partial payments are now handled as activities only
  
  // Clear all activities for current user
  Future<void> clearActivities() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Get all activities for current user only
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('activities')
          .get()
          .timeout(const Duration(seconds: 30)); // Add timeout protection
      
      if (activitiesSnapshot.docs.isEmpty) {
        return;
      }
      
      // Delete each activity document
      final batch = _firestore.batch();
      for (final doc in activitiesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion with timeout
      await batch.commit().timeout(const Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing activities. Please try again.');
      }
      rethrow;
    }
  }

  // Remove phantom activities - activities that don't have corresponding debts
  Future<void> removePhantomActivities() async {
    try {
      // Get all activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (activitiesSnapshot.docs.isEmpty) {
        return;
      }
      
      // Get all debt IDs
      final debtsSnapshot = await _firestore
          .collection('debts')
          .get()
          .timeout(const Duration(seconds: 30));
      
      final debtIds = debtsSnapshot.docs.map((doc) => doc.id).toSet();
      
      // Find phantom activities (activities with debtId that no longer exists)
      final phantomActivities = <String>[];
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final debtId = data['debtId'] as String?;
        
        // If activity has a debtId but that debt no longer exists, it's a phantom
        if (debtId != null && !debtIds.contains(debtId)) {
          phantomActivities.add(doc.id);
        }
      }
      
      // Remove phantom activities
      if (phantomActivities.isNotEmpty) {
        final batch = _firestore.batch();
        for (final activityId in phantomActivities) {
          batch.delete(_firestore.collection('activities').doc(activityId));
        }
        await batch.commit().timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      // Handle error silently - don't break the app
    }
  }
  
  // Clear all data for current user (customers, debts, products, activities, payments)
  Future<void> clearAllData() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Clear all collections for current user only
      await clearDebts();
      // Note: Partial payments are now handled as activities only
      await clearActivities();
      
      // Clear customers for current user
      final customersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('customers')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (customersSnapshot.docs.isNotEmpty) {
        final customersBatch = _firestore.batch();
        for (final doc in customersSnapshot.docs) {
          customersBatch.delete(doc.reference);
        }
        await customersBatch.commit().timeout(const Duration(seconds: 30));
      }
      
      // Clear categories for current user
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('categories')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (categoriesSnapshot.docs.isNotEmpty) {
        final categoriesBatch = _firestore.batch();
        for (final doc in categoriesSnapshot.docs) {
          categoriesBatch.delete(doc.reference);
        }
        await categoriesBatch.commit().timeout(const Duration(seconds: 30));
      }
      
      // Clear product purchases for current user
      final purchasesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('product_purchases')
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (purchasesSnapshot.docs.isNotEmpty) {
        final purchasesBatch = _firestore.batch();
        for (final doc in purchasesSnapshot.docs) {
          purchasesBatch.delete(doc.reference);
        }
        await purchasesBatch.commit().timeout(const Duration(seconds: 30));
      }
      
      // Clear currency settings for current user
      final settingsDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('currency_settings')
          .doc('settings')
          .get();
      
      if (settingsDoc.exists) {
        await settingsDoc.reference.delete();
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Timeout while clearing all data. Please try again.');
      }
      rethrow;
    }
  }

}
