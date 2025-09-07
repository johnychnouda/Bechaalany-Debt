enum DebtStatus {
  pending,
  paid,
}

enum DebtType {
  credit,
  payment,
}

class Debt {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final String description;
  final DebtType type;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? notes;
  final double paidAmount; // Amount that has been paid
  final String? subcategoryId; // ID of the subcategory if debt was created from a product
  final String? subcategoryName; // Name of the subcategory at time of debt creation
  final double? originalSellingPrice; // Original selling price at time of debt creation
  final String? categoryName; // Category name at time of debt creation
  final double? originalCostPrice; // Original cost price at time of debt creation - CRITICAL for revenue calculation
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
      createdAt: parseDateTime(json['createdAt']),
      paidAt: json['paidAt'] != null 
          ? parseDateTime(json['paidAt']) 
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
    // Round to 4 decimal places to avoid floating-point precision errors in subsequent calculations
    return ((revenuePerDollar * 10000).round() / 10000);
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
    final result = ((remaining * 100).round() / 100);
    
    print('DEBUG: Debt $id remainingRevenue calculation: revenuePerDollar=$revenuePerDollar, remainingAmount=$remainingAmount, result=$result');
    
    return result;
  }
} 