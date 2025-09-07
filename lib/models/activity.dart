import 'debt.dart';

enum ActivityType {
  newDebt,
  payment,
}

class Activity {
  final String id;
  final DateTime date;
  final ActivityType type;
  final String customerName;
  final String customerId;
  final String description;
  final double amount;
  final double? paymentAmount;
  final DebtStatus? oldStatus;
  final DebtStatus? newStatus;
  final String? debtId; // Reference to the original debt (if still exists)
  final String? notes; // Additional notes for revenue tracking and audit purposes

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
    this.notes,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
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

    return Activity(
      id: json['id'] as String,
      date: parseDateTime(json['date']),
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
      notes: json['notes'] as String?,
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
      'notes': notes,
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
    String? notes,
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
      notes: notes ?? this.notes,
    );
  }
  
  // Helper method to determine if a payment activity completed a debt
  bool get isPaymentCompleted {
    if (type != ActivityType.payment || paymentAmount == null) {
      return false;
    }
    
    // A payment is considered completed if the new status is 'paid'
    // This is the authoritative source of truth for whether the debt was completed
    return newStatus == DebtStatus.paid;
  }
} 