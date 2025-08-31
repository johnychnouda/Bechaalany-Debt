class ProductPurchase {
  // Define all required fields
  final String id;
  final String customerId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final double totalAmount;
  final DateTime purchaseDate;
  bool isPaid;

  // Add ProductPurchaseStatus enum if missing
  // enum ProductPurchaseStatus { pending, paid }

  ProductPurchase({
    required this.id,
    required this.customerId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.totalAmount,
    required this.purchaseDate,
    this.isPaid = false,
  });

  double get profit => (sellingPrice - costPrice) * quantity;
  double get profitPercentage => costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  ProductPurchase copyWith({
    String? id,
    String? customerId,
    String? subcategoryId,
    String? categoryName,
    String? subcategoryName,
    int? quantity,
    double? costPrice,
    double? sellingPrice,
    double? totalAmount,
    DateTime? purchaseDate,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return ProductPurchase(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'subcategoryId': subcategoryId,
      'categoryName': categoryName,
      'subcategoryName': subcategoryName,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'totalAmount': totalAmount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory ProductPurchase.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic dateTime) {
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

    return ProductPurchase(
      id: json['id'],
      customerId: json['customerId'],
      subcategoryId: json['subcategoryId'],
      categoryName: json['categoryName'],
      subcategoryName: json['subcategoryName'],
      quantity: json['quantity'],
      costPrice: json['costPrice'].toDouble(),
      sellingPrice: json['sellingPrice'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      purchaseDate: parseDateTime(json['purchaseDate']),
      isPaid: json['isPaid'] ?? false,
    );
  }
} 