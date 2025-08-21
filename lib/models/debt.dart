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
  @HiveField(15)
  final double? originalCostPrice; // Original cost price at time of debt creation - CRITICAL for revenue calculation
  @HiveField(16)
  final String? storedCurrency; // Original currency when debt was created (LBP or USD)

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
    this.originalCostPrice,
    this.storedCurrency,
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
      originalCostPrice: json['originalCostPrice'] != null 
          ? (json['originalCostPrice'] as num).toDouble() 
          : null,
      storedCurrency: json['storedCurrency'] as String?,
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
      'originalCostPrice': originalCostPrice,
      'storedCurrency': storedCurrency,
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
    double? originalCostPrice,
    String? storedCurrency,
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
      originalCostPrice: originalCostPrice ?? this.originalCostPrice,
      storedCurrency: storedCurrency ?? this.storedCurrency,
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

  double get remainingAmount {
    final remaining = amount - paidAmount;
    // Fix floating-point precision issues by rounding to 2 decimal places
    return ((remaining * 100).round() / 100);
  }

  bool get isFullyPaid => paidAmount >= amount;

  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < amount;
  
  // NOTE: These getters only check individual debt status
  // For customer-level status, use AppState methods that consider all customer debts

  // PROFESSIONAL REVENUE CALCULATION PROPERTIES
  /// Original revenue (profit) for this debt at creation time
  double get originalRevenue {
    if (originalSellingPrice == null || originalCostPrice == null) return 0.0;
    final revenue = originalSellingPrice! - originalCostPrice!;
    // Round to 2 decimal places to avoid floating-point precision errors
    return ((revenue * 100).round() / 100);
  }

  /// Revenue per dollar of debt amount (for proportional calculations)
  double get revenuePerDollar {
    if (amount <= 0) return 0.0;
    final revenuePerDollar = originalRevenue / amount;
    // Round to 2 decimal places to avoid floating-point precision errors
    return ((revenuePerDollar * 100).round() / 100);
  }

  /// Revenue earned from paid amount (proportional)
  double get earnedRevenue {
    final earned = revenuePerDollar * paidAmount;
    // Round to 2 decimal places to avoid floating-point precision errors
    return ((earned * 100).round() / 100);
  }

  /// Remaining potential revenue
  double get remainingRevenue {
    final remaining = revenuePerDollar * remainingAmount;
    // Round to 2 decimal places to avoid floating-point precision errors
    return ((remaining * 100).round() / 100);
  }
} 