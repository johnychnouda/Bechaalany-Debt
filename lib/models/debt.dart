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
    );
  }

  String get statusText {
    switch (status) {
      case DebtStatus.pending:
        return 'Pending';
      case DebtStatus.paid:
        return 'Paid';
    }
  }
} 