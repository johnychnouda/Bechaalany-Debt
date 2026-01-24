import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus {
  trial,
  active,
  expired,
  cancelled,
}

enum SubscriptionType {
  monthly,
  yearly,
}

class Subscription {
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionType? type;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Subscription({
    required this.userId,
    required this.status,
    this.type,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.createdAt,
    required this.lastUpdated,
  });

  // Convert from Firestore document
  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      userId: doc.id,
      status: _statusFromString(data['subscriptionStatus'] as String? ?? 'trial'),
      type: data['subscriptionType'] != null
          ? _typeFromString(data['subscriptionType'] as String)
          : null,
      trialStartDate: data['trialStartDate'] != null
          ? (data['trialStartDate'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      subscriptionStartDate: data['subscriptionStartDate'] != null
          ? (data['subscriptionStartDate'] as Timestamp).toDate()
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'subscriptionStatus': _statusToString(status),
      'subscriptionType': type != null ? _typeToString(type!) : null,
      'trialStartDate': trialStartDate != null
          ? Timestamp.fromDate(trialStartDate!)
          : null,
      'trialEndDate':
          trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'subscriptionStartDate': subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Helper methods
  static SubscriptionStatus _statusFromString(String status) {
    switch (status) {
      case 'trial':
        return SubscriptionStatus.trial;
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.trial;
    }
  }

  static String _statusToString(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
    }
  }

  static SubscriptionType _typeFromString(String type) {
    switch (type) {
      case 'monthly':
        return SubscriptionType.monthly;
      case 'yearly':
        return SubscriptionType.yearly;
      default:
        return SubscriptionType.monthly;
    }
  }

  static String _typeToString(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 'monthly';
      case SubscriptionType.yearly:
        return 'yearly';
    }
  }

  // Check if user has active access
  bool get hasActiveAccess {
    // Cancelled subscriptions never have access
    if (status == SubscriptionStatus.cancelled) {
      return false;
    }
    
    // Expired status never has access
    if (status == SubscriptionStatus.expired) {
      return false;
    }
    
    if (status == SubscriptionStatus.active) {
      if (subscriptionEndDate != null) {
        return DateTime.now().isBefore(subscriptionEndDate!);
      }
      return true;
    }
    if (status == SubscriptionStatus.trial) {
      if (trialEndDate != null) {
        return DateTime.now().isBefore(trialEndDate!);
      }
      return true;
    }
    return false;
  }

  // Get days remaining in trial
  int? get trialDaysRemaining {
    if (status != SubscriptionStatus.trial || trialEndDate == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(trialEndDate!)) {
      return 0;
    }
    return trialEndDate!.difference(now).inDays;
  }

  // Get days remaining in subscription
  int? get subscriptionDaysRemaining {
    if (status != SubscriptionStatus.active || subscriptionEndDate == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(subscriptionEndDate!)) {
      return 0;
    }
    return subscriptionEndDate!.difference(now).inDays;
  }

  // Check if trial is expired
  bool get isTrialExpired {
    if (status != SubscriptionStatus.trial || trialEndDate == null) {
      return false;
    }
    return DateTime.now().isAfter(trialEndDate!);
  }

  // Check if subscription is expired
  bool get isSubscriptionExpired {
    if (status != SubscriptionStatus.active || subscriptionEndDate == null) {
      return false;
    }
    return DateTime.now().isAfter(subscriptionEndDate!);
  }
}
