class ProductCategory {
  String id;

  String name;

  String? description;

  DateTime createdAt;

  List<Subcategory> subcategories;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    List<Subcategory>? subcategories,
  }) : subcategories = subcategories ?? [];

  // Helper function to parse DateTime from various formats
  static DateTime parseDateTime(dynamic dateTime) {
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is DateTime) {
      return dateTime;
    } else if (dateTime != null) {
      // Handle Firebase Timestamp or other types
      try {
        if (dateTime.toString().contains('Timestamp')) {
          // Firebase Timestamp - convert to DateTime
          return DateTime.fromMillisecondsSinceEpoch(
            dateTime.millisecondsSinceEpoch,
          );
        }
      } catch (e) {
        // Fallback to current time if parsing fails
      }
    }
    return DateTime.now();
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Subcategory>? subcategories,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'subcategories': subcategories.map((s) => s.toJson()).toList(),
    };
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: parseDateTime(json['createdAt']),
      subcategories: (json['subcategories'] as List?)
          ?.map((s) => Subcategory.fromJson(s))
          .toList() ?? [],
    );
  }
}

class Subcategory {
  String id;

  String name;

  String? description;

  double costPrice;

  double sellingPrice;

  DateTime createdAt;

  List<PriceHistory> priceHistory;

  String costPriceCurrency;

  String sellingPriceCurrency;

  Subcategory({
    required this.id,
    required this.name,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.createdAt,
    List<PriceHistory>? priceHistory,
    required this.costPriceCurrency,
    required this.sellingPriceCurrency,
  }) : priceHistory = priceHistory ?? [];

  // Helper function to parse DateTime from various formats
  static DateTime parseDateTime(dynamic dateTime) {
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is DateTime) {
      return dateTime;
    } else if (dateTime != null) {
      // Handle Firebase Timestamp or other types
      try {
        if (dateTime.toString().contains('Timestamp')) {
          // Firebase Timestamp - convert to DateTime
          return DateTime.fromMillisecondsSinceEpoch(
            dateTime.millisecondsSinceEpoch,
          );
        }
      } catch (e) {
        // Fallback to current time if parsing fails
      }
    }
    return DateTime.now();
  }

  double get profit => sellingPrice - costPrice;
  double get profitPercentage => costPrice > 0 ? (profit / costPrice) * 100 : 0;

  /// Validates that the product has reasonable prices for its currency
  /// This helps prevent corrupted data from being stored
  bool get hasValidPrices {
    if (costPriceCurrency == 'LBP') {
      // LBP prices can be in millions (e.g., 3,000,000 LBP = 30 USD at 100,000 rate)
      // Allow up to 100,000,000 LBP (1,000 USD at 100,000 rate) which is reasonable
      return costPrice > 0 && costPrice < 100000000 && 
             sellingPrice > 0 && sellingPrice < 100000000;
    } else if (costPriceCurrency == 'USD') {
      // USD prices should typically be reasonable amounts
      // Very high amounts (> 10,000) might indicate corruption
      return costPrice > 0 && costPrice < 10000 && 
             sellingPrice > 0 && sellingPrice < 10000;
    }
    return costPrice > 0 && sellingPrice > 0;
  }

  /// Gets a human-readable description of any price validation issues
  String? get priceValidationMessage {
    if (!hasValidPrices) {
      if (costPriceCurrency == 'LBP' && (costPrice > 100000000 || sellingPrice > 100000000)) {
        return 'LBP prices seem unusually high (over 100,000,000 LBP). Please verify the amounts.';
      } else if (costPriceCurrency == 'USD' && (costPrice > 10000 || sellingPrice > 10000)) {
        return 'USD prices seem unusually high (over 10,000 USD). Please verify the amounts.';
      }
      return 'Product prices seem invalid. Please check the amounts.';
    }
    return null;
  }

  void updatePrices({
    double? newCostPrice,
    double? newSellingPrice,
  }) {
    if (newCostPrice != null || newSellingPrice != null) {
      // Add current prices to history before updating
      priceHistory.add(PriceHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        changedAt: DateTime.now(),
      ));

      if (newCostPrice != null) costPrice = newCostPrice;
      if (newSellingPrice != null) sellingPrice = newSellingPrice;
    }
  }

  Subcategory copyWith({
    String? id,
    String? name,
    String? description,
    double? costPrice,
    double? sellingPrice,
    DateTime? createdAt,
    List<PriceHistory>? priceHistory,
    String? costPriceCurrency,
    String? sellingPriceCurrency,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      createdAt: createdAt ?? this.createdAt,
      priceHistory: priceHistory ?? this.priceHistory,
      costPriceCurrency: costPriceCurrency ?? this.costPriceCurrency,
      sellingPriceCurrency: sellingPriceCurrency ?? this.sellingPriceCurrency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'createdAt': createdAt.toIso8601String(),
      'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
      'costPriceCurrency': costPriceCurrency,
      'sellingPriceCurrency': sellingPriceCurrency,
    };
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      costPrice: json['costPrice'].toDouble(),
      sellingPrice: json['sellingPrice'].toDouble(),
      createdAt: parseDateTime(json['createdAt']),
      priceHistory: (json['priceHistory'] as List?)
          ?.map((p) => PriceHistory.fromJson(p))
          .toList() ?? [],
      costPriceCurrency: json['costPriceCurrency'] ?? 'USD',
      sellingPriceCurrency: json['sellingPriceCurrency'] ?? 'USD',
    );
  }
}

class PriceHistory {
  String id;

  double costPrice;

  double sellingPrice;

  DateTime changedAt;

  PriceHistory({
    required this.id,
    required this.costPrice,
    required this.sellingPrice,
    required this.changedAt,
  });

  // Helper function to parse DateTime from various formats
  static DateTime parseDateTime(dynamic dateTime) {
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is DateTime) {
      return dateTime;
    } else if (dateTime != null) {
      // Handle Firebase Timestamp or other types
      try {
        if (dateTime.toString().contains('Timestamp')) {
          // Firebase Timestamp - convert to DateTime
          return DateTime.fromMillisecondsSinceEpoch(
            dateTime.millisecondsSinceEpoch,
          );
        }
      } catch (e) {
        // Fallback to current time if parsing fails
      }
    }
    return DateTime.now();
  }

  double get profit => sellingPrice - costPrice;

  PriceHistory copyWith({
    String? id,
    double? costPrice,
    double? sellingPrice,
    DateTime? changedAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['id'],
      costPrice: json['costPrice'].toDouble(),
      sellingPrice: json['sellingPrice'].toDouble(),
      changedAt: parseDateTime(json['changedAt']),
    );
  }
} 