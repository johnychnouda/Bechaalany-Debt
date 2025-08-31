class CurrencySettings {
  String baseCurrency;

  String targetCurrency;

  double? exchangeRate;

  DateTime lastUpdated;

  String? notes;

  CurrencySettings({
    required this.baseCurrency,
    required this.targetCurrency,
    this.exchangeRate,
    required this.lastUpdated,
    this.notes,
  });

  // Convert amount from base currency to target currency
  double? convertAmount(double amount) {
    if (exchangeRate == null) return null;
    return amount * exchangeRate!;
  }

  // Convert amount from target currency to base currency
  double? convertBack(double amount) {
    if (exchangeRate == null) return null;
    return amount / exchangeRate!;
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
  String? get formattedRate {
    if (exchangeRate == null) return null;
    final targetDecimals = _getDecimalPlaces(targetCurrency);
    return '1 $baseCurrency = ${exchangeRate!.toStringAsFixed(targetDecimals)} $targetCurrency';
  }

  // Get reverse formatted exchange rate string
  String? get reverseFormattedRate {
    if (exchangeRate == null) return null;
    final baseDecimals = _getDecimalPlaces(baseCurrency);
    return '1 $targetCurrency = ${(1 / exchangeRate!).toStringAsFixed(baseDecimals)} $baseCurrency';
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
    DateTime parseLastUpdated(dynamic lastUpdated) {
      if (lastUpdated is String) {
        return DateTime.parse(lastUpdated);
      } else if (lastUpdated is DateTime) {
        return lastUpdated;
      } else if (lastUpdated != null) {
        // Handle Firebase Timestamp or other types
        try {
          if (lastUpdated.toString().contains('Timestamp')) {
            // Firebase Timestamp - convert to DateTime
            return DateTime.fromMillisecondsSinceEpoch(
              lastUpdated.millisecondsSinceEpoch,
            );
          }
        } catch (e) {
          // Fallback to current time if parsing fails
        }
      }
      return DateTime.now();
    }

    return CurrencySettings(
      baseCurrency: json['baseCurrency'] ?? 'USD',
      targetCurrency: json['targetCurrency'] ?? 'LBP',
      exchangeRate: json['exchangeRate'] != null ? json['exchangeRate'].toDouble() : null,
      lastUpdated: parseLastUpdated(json['lastUpdated']),
      notes: json['notes'],
    );
  }
}

 