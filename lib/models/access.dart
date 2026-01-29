import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_access_keys.dart';

enum AccessStatus {
  trial,
  active,
  expired,
  cancelled,
}

enum AccessType {
  monthly,
  yearly,
}

class Access {
  final String userId;
  final AccessStatus status;
  final AccessType? type;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? accessStartDate;
  final DateTime? accessEndDate;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Access({
    required this.userId,
    required this.status,
    this.type,
    this.trialStartDate,
    this.trialEndDate,
    this.accessStartDate,
    this.accessEndDate,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory Access.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusStr = data[FirestoreAccessKeys.status];
    final typeVal = data[FirestoreAccessKeys.type];
    final startVal = data[FirestoreAccessKeys.startDate];
    final endVal = data[FirestoreAccessKeys.endDate];
    return Access(
      userId: doc.id,
      status: _statusFromString((statusStr as String?) ?? 'trial'),
      type: typeVal != null ? _typeFromString(typeVal as String) : null,
      trialStartDate: data['trialStartDate'] != null
          ? (data['trialStartDate'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      accessStartDate: startVal != null ? (startVal as Timestamp).toDate() : null,
      accessEndDate: endVal != null ? (endVal as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      FirestoreAccessKeys.status: _statusToString(status),
      FirestoreAccessKeys.type: type != null ? _typeToString(type!) : null,
      'trialStartDate': trialStartDate != null
          ? Timestamp.fromDate(trialStartDate!)
          : null,
      'trialEndDate':
          trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      FirestoreAccessKeys.startDate: accessStartDate != null
          ? Timestamp.fromDate(accessStartDate!)
          : null,
      FirestoreAccessKeys.endDate: accessEndDate != null
          ? Timestamp.fromDate(accessEndDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  static AccessStatus _statusFromString(String status) {
    switch (status) {
      case 'trial':
        return AccessStatus.trial;
      case 'active':
        return AccessStatus.active;
      case 'expired':
        return AccessStatus.expired;
      case 'cancelled':
        return AccessStatus.cancelled;
      default:
        return AccessStatus.trial;
    }
  }

  static String _statusToString(AccessStatus status) {
    switch (status) {
      case AccessStatus.trial:
        return 'trial';
      case AccessStatus.active:
        return 'active';
      case AccessStatus.expired:
        return 'expired';
      case AccessStatus.cancelled:
        return 'cancelled';
    }
  }

  static AccessType _typeFromString(String type) {
    switch (type) {
      case 'monthly':
        return AccessType.monthly;
      case 'yearly':
        return AccessType.yearly;
      default:
        return AccessType.monthly;
    }
  }

  static String _typeToString(AccessType type) {
    switch (type) {
      case AccessType.monthly:
        return 'monthly';
      case AccessType.yearly:
        return 'yearly';
    }
  }

  bool get hasActiveAccess {
    if (status == AccessStatus.cancelled) return false;
    if (status == AccessStatus.expired) return false;
    if (status == AccessStatus.active) {
      if (accessEndDate != null) {
        return DateTime.now().isBefore(accessEndDate!);
      }
      return true;
    }
    if (status == AccessStatus.trial) {
      if (trialEndDate != null) {
        return DateTime.now().isBefore(trialEndDate!);
      }
      return true;
    }
    return false;
  }

  int? get trialDaysRemaining {
    if (status != AccessStatus.trial || trialEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(trialEndDate!)) return 0;
    return trialEndDate!.difference(now).inDays;
  }

  int? get accessDaysRemaining {
    if (status != AccessStatus.active || accessEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(accessEndDate!)) return 0;
    return accessEndDate!.difference(now).inDays;
  }

  bool get isTrialExpired {
    if (status != AccessStatus.trial || trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  bool get isAccessExpired {
    if (status != AccessStatus.active || accessEndDate == null) return false;
    return DateTime.now().isAfter(accessEndDate!);
  }
}
