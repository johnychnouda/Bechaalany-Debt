import 'package:hive/hive.dart';
part 'partial_payment.g.dart';

@HiveType(typeId: 11)
class PartialPayment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String debtId;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime paidAt;
  @HiveField(4)
  final String? notes;

  PartialPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paidAt,
    this.notes,
  });

  factory PartialPayment.fromJson(Map<String, dynamic> json) {
    return PartialPayment(
      id: json['id'] as String,
      debtId: json['debtId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paidAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'paidAt': paidAt.toIso8601String(),
      'notes': notes,
    };
  }

  PartialPayment copyWith({
    String? id,
    String? debtId,
    double? amount,
    DateTime? paidAt,
    String? notes,
  }) {
    return PartialPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
    );
  }
} 