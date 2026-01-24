import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_pricing.dart';
import 'admin_service.dart';

/// Fetches and updates subscription pricing (monthly/yearly).
/// All authenticated users can read; only admins can update.
/// Updates go through a callable Cloud Function (Admin SDK) to avoid Firestore rule issues.
class SubscriptionPricingService {
  static final SubscriptionPricingService _instance =
      SubscriptionPricingService._internal();
  factory SubscriptionPricingService() => _instance;
  SubscriptionPricingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminService _adminService = AdminService();

  static const String _collection = 'subscription_pricing';
  static const String _docId = 'config';

  /// Get current subscription pricing. Returns defaults if missing.
  Future<SubscriptionPricing> getPricing() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_docId).get();
      if (doc.exists) {
        return SubscriptionPricing.fromFirestore(doc);
      }
      return SubscriptionPricing.defaults;
    } catch (e) {
      return SubscriptionPricing.defaults;
    }
  }

  /// Stream of subscription pricing (real-time updates for UI).
  Stream<SubscriptionPricing> getPricingStream() {
    return _firestore
        .collection(_collection)
        .doc(_docId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SubscriptionPricing.fromFirestore(doc);
      }
      return SubscriptionPricing.defaults;
    });
  }

  /// Update pricing (admin only). Uses callable Cloud Function to avoid Firestore permission issues.
  /// Throws if not admin or validation fails.
  Future<void> updatePricing({
    required double monthlyPrice,
    required double yearlyPrice,
    String currency = 'USD',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await _adminService.isAdmin();
    if (!isAdmin) throw Exception('Only admins can update subscription pricing');

    if (monthlyPrice < 0 || yearlyPrice < 0) {
      throw Exception('Prices cannot be negative');
    }

    final trimmedCurrency = currency.trim().isEmpty ? 'USD' : currency.trim();
    final data = <String, dynamic>{
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'currency': trimmedCurrency,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('updateSubscriptionPricing');
      await callable.call(<String, dynamic>{
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'currency': trimmedCurrency,
      });
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? e.code;
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Please sign in to update pricing.');
        case 'permission-denied':
          throw Exception('Only admins can update subscription pricing.');
        case 'invalid-argument':
          throw Exception(msg);
        case 'not-found':
        case 'NOT_FOUND':
          // Cloud Function not deployed (e.g. Spark plan). Fall back to direct Firestore write.
          await _writePricingToFirestore(data);
          return;
        default:
          throw Exception(msg);
      }
    }
  }

  /// Direct Firestore write. Used when callable is not deployed (e.g. Spark plan).
  Future<void> _writePricingToFirestore(Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(_docId).set(
          data,
          SetOptions(merge: true),
        );
  }
}
