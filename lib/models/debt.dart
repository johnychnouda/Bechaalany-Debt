import 'package:hive/hive.dart';
part 'debt.g.dart';

@HiveType(typeId: 1)
enum DebtStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
}

@HiveType(typeId: 2)
enum DebtType {
  @HiveField(0)
  credit,
  @HiveField(1)
  payment,
}

@HiveType(typeId: 3)
class Debt extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerId;
  @HiveField(2)
  final String customerName;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final DebtType type;
  @HiveField(6)
  final DebtStatus status;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime? paidAt;
  @HiveField(9)
  final String? notes;
  @HiveField(10)
  final double paidAmount; // Amount that has been paid
  @HiveField(11)
  final String? subcategoryId; // ID of the subcategory if debt was created from a product
  @HiveField(12)
  final String? subcategoryName; // Name of the subcategory at time of debt creation
  @HiveField(13)
  final double? originalSellingPrice; // Original selling price at time of debt creation
  @HiveField(14)
  final String? categoryName; // Category name at time of debt creation

  Debt({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.notes,
    this.paidAmount = 0.0,
    this.subcategoryId,
    this.subcategoryName,
    this.originalSellingPrice,
    this.categoryName,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      type: DebtType.values.firstWhere(
        (e) => e.toString() == 'DebtType.${json['type']}',
      ),
      status: DebtStatus.values.firstWhere(
        (e) => e.toString() == 'DebtStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt'] as String) 
          : null,
      notes: json['notes'] as String?,
      paidAmount: (json['paidAmount'] as num).toDouble(),
      subcategoryId: json['subcategoryId'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      originalSellingPrice: json['originalSellingPrice'] != null 
          ? (json['originalSellingPrice'] as num).toDouble() 
          : null,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'notes': notes,
      'paidAmount': paidAmount,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'originalSellingPrice': originalSellingPrice,
      'categoryName': categoryName,
    };
  }

  Debt copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    String? description,
    DebtType? type,
    DebtStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? notes,
    double? paidAmount,
    String? subcategoryId,
    String? subcategoryName,
    double? originalSellingPrice,
    String? categoryName,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      paidAmount: paidAmount ?? this.paidAmount,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      originalSellingPrice: originalSellingPrice ?? this.originalSellingPrice,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  String get statusText {
    if (paidAmount >= amount) {
      return 'Paid';
    } else if (paidAmount > 0) {
      return 'Partially Paid';
    } else {
      return 'Pending';
    }
  }

  double get remainingAmount => amount - paidAmount;

  bool get isFullyPaid => paidAmount >= amount;

  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < amount;
} 