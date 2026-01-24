import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-editable subscription pricing stored in Firestore.
/// Users can read; only admins can update.
class SubscriptionPricing {
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;

  const SubscriptionPricing({
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.currency = 'USD',
  });

  static const SubscriptionPricing defaults = SubscriptionPricing(
    monthlyPrice: 9.99,
    yearlyPrice: 99.99,
    currency: 'USD',
  );

  factory SubscriptionPricing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final monthly = (data['monthlyPrice'] as num?)?.toDouble() ?? defaults.monthlyPrice;
    final yearly = (data['yearlyPrice'] as num?)?.toDouble() ?? defaults.yearlyPrice;
    final curr = data['currency'] as String? ?? defaults.currency;
    return SubscriptionPricing(
      monthlyPrice: monthly,
      yearlyPrice: yearly,
      currency: curr.trim().isEmpty ? defaults.currency : curr,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'currency': currency,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  String formatMonthly() => _format(monthlyPrice);
  String formatYearly() => _format(yearlyPrice);

  String _format(double value) {
    if (currency.toUpperCase() == 'USD') {
      return '\$${value.toStringAsFixed(2)}';
    }
    return '$value $currency';
  }
}
