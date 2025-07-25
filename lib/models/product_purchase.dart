import 'package:hive/hive.dart';

part 'product_purchase.g.dart';

@HiveType(typeId: 7)
class ProductPurchase extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String subcategoryId;

  @HiveField(3)
  String categoryName;

  @HiveField(4)
  String subcategoryName;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  double costPrice; // Fixed at purchase time

  @HiveField(7)
  double sellingPrice; // Fixed at purchase time

  @HiveField(8)
  double totalAmount; // quantity * sellingPrice

  @HiveField(9)
  DateTime purchaseDate;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  bool isPaid;

  @HiveField(12)
  DateTime? paidAt;

  ProductPurchase({
    required this.id,
    required this.customerId,
    required this.subcategoryId,
    required this.categoryName,
    required this.subcategoryName,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalAmount,
    required this.purchaseDate,
    this.notes,
    this.isPaid = false,
    this.paidAt,
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
    String? notes,
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
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
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
      'notes': notes,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
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
      notes: json['notes'],
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
} 