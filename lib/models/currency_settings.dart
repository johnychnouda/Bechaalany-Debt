import 'package:hive/hive.dart';

part 'currency_settings.g.dart';

@HiveType(typeId: 8)
class CurrencySettings extends HiveObject {
  @HiveField(0)
  String baseCurrency;

  @HiveField(1)
  String targetCurrency;

  @HiveField(2)
  double exchangeRate;

  @HiveField(3)
  DateTime lastUpdated;

  @HiveField(4)
  String? notes;

  CurrencySettings({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.exchangeRate,
    required this.lastUpdated,
    this.notes,
  });

  // Convert amount from base currency to target currency
  double convertAmount(double amount) {
    return amount * exchangeRate;
  }

  // Convert amount from target currency to base currency
  double convertBack(double amount) {
    return amount / exchangeRate;
  }

  // Helper method to determine decimal places based on currency
  int _getDecimalPlaces(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'EUR':
      case 'GBP':
      case 'CAD':
      case 'AUD':
      case 'JPY':
        return 2;
      case 'LBP':
      case 'IQD':
      case 'IRR':
        return 0;
      default:
        return 2; // Default to 2 decimals for unknown currencies
    }
  }

  // Get formatted exchange rate string
  String get formattedRate {
    final targetDecimals = _getDecimalPlaces(targetCurrency);
    return '1 $baseCurrency = ${exchangeRate.toStringAsFixed(targetDecimals)} $targetCurrency';
  }

  // Get reverse formatted exchange rate string
  String get reverseFormattedRate {
    final baseDecimals = _getDecimalPlaces(baseCurrency);
    return '1 $targetCurrency = ${(1 / exchangeRate).toStringAsFixed(baseDecimals)} $baseCurrency';
  }

  // Copy with method
  CurrencySettings copyWith({
    String? baseCurrency,
    String? targetCurrency,
    double? exchangeRate,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return CurrencySettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'exchangeRate': exchangeRate,
      'lastUpdated': lastUpdated.toIso8601String(),
      'notes': notes,
    };
  }

  // From JSON
  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      baseCurrency: json['baseCurrency'] ?? 'USD',
      targetCurrency: json['targetCurrency'] ?? 'LBP',
      exchangeRate: (json['exchangeRate'] ?? 1.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }
}

 