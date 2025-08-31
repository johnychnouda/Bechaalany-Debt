class PartialPayment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime paidAt;
  final String? notes;

  PartialPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paidAt,
    this.notes,
  });

  factory PartialPayment.fromJson(Map<String, dynamic> json) {
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

    return PartialPayment(
      id: json['id'] as String,
      debtId: json['debtId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: parseDateTime(json['paidAt']),
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