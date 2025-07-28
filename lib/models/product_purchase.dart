import 'package:hive/hive.dart';

part 'product_purchase.g.dart';

@HiveType(typeId: 7)
class ProductPurchase extends HiveObject {
  // Define all required fields
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerId;
  @HiveField(2)
  final String categoryName;
  @HiveField(3)
  final String subcategoryId;
  @HiveField(4)
  final String subcategoryName;
  @HiveField(5)
  final double costPrice;
  @HiveField(6)
  final double sellingPrice;
  @HiveField(7)
  final int quantity;
  @HiveField(8)
  final double totalAmount;
  @HiveField(9)
  final DateTime purchaseDate;
  @HiveField(10)
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
      purchaseDate: DateTime.parse(json['purchaseDate']),
      isPaid: json['isPaid'] ?? false,
    );
  }
} 