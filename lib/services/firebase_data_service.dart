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
    
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .set(customerData, SetOptions(merge: true));
  }

  // Get all customers for current user
  Stream<List<Customer>> getCustomersStream() {
    if (!isAuthenticated) return Stream.value([]);
    
    return _firestore
        .collection('customers')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromJson(doc.data()))
            .toList());
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection('customers').doc(customerId).delete();
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

  // ===== GENERIC METHODS FOR TESTING =====
  
  // Generic add/update method for testing
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

  // Generic get stream method for testing
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

  // Generic delete method for testing
  Future<void> delete(String collectionName, String documentId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    await _firestore.collection(collectionName).doc(documentId).delete();
  }

  // ===== DATA MIGRATION METHODS =====
  

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

  // Test Firebase connection
  Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').doc('connection').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  // Test Firestore write
  Future<bool> testWrite() async {
    try {
      await _firestore.collection('test').doc('write_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase is working!',
        'platform': 'web',
      });
      return true;
    } catch (e) {
      print('Firestore write test failed: $e');
      return false;
    }
  }

  // Test Firestore read
  Future<Map<String, dynamic>?> testRead() async {
    try {
      final doc = await _firestore.collection('test').doc('write_test').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Firestore read test failed: $e');
      return null;
    }
  }
}
