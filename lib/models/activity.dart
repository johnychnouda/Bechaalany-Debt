import 'package:hive/hive.dart';
import 'debt.dart';
part 'activity.g.dart';

@HiveType(typeId: 9)
enum ActivityType {
  @HiveField(0)
  newDebt,
  @HiveField(1)
  payment,
  @HiveField(2)
  debtCleared,
}

@HiveType(typeId: 10)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final ActivityType type;
  @HiveField(3)
  final String customerName;
  @HiveField(4)
  final String customerId;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final double amount;
  @HiveField(7)
  final double? paymentAmount;
  @HiveField(8)
  final DebtStatus? oldStatus;
  @HiveField(9)
  final DebtStatus? newStatus;
  @HiveField(10)
  final String? debtId; // Reference to the original debt (if still exists)

  Activity({
    required this.id,
    required this.date,
    required this.type,
    required this.customerName,
    required this.customerId,
    required this.description,
    required this.amount,
    this.paymentAmount,
    this.oldStatus,
    this.newStatus,
    this.debtId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
      ),
      customerName: json['customerName'] as String,
      customerId: json['customerId'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentAmount: json['paymentAmount'] != null 
          ? (json['paymentAmount'] as num).toDouble() 
          : null,
      oldStatus: json['oldStatus'] != null 
          ? DebtStatus.values.firstWhere(
              (e) => e.toString() == 'DebtStatus.${json['oldStatus']}',
            )
          : null,
      newStatus: json['newStatus'] != null 
          ? DebtStatus.values.firstWhere(
              (e) => e.toString() == 'DebtStatus.${json['newStatus']}',
            )
          : null,
      debtId: json['debtId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'customerName': customerName,
      'customerId': customerId,
      'description': description,
      'amount': amount,
      'paymentAmount': paymentAmount,
      'oldStatus': oldStatus?.toString().split('.').last,
      'newStatus': newStatus?.toString().split('.').last,
      'debtId': debtId,
    };
  }

  Activity copyWith({
    String? id,
    DateTime? date,
    ActivityType? type,
    String? customerName,
    String? customerId,
    String? description,
    double? amount,
    double? paymentAmount,
    DebtStatus? oldStatus,
    DebtStatus? newStatus,
    String? debtId,
  }) {
    return Activity(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      oldStatus: oldStatus ?? this.oldStatus,
      newStatus: newStatus ?? this.newStatus,
      debtId: debtId ?? this.debtId,
    );
  }
} 