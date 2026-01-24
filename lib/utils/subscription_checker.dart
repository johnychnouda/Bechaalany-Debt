import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/subscription_service.dart';
import '../services/admin_service.dart';
import '../screens/contact_owner_screen.dart';
import '../models/subscription.dart';

class SubscriptionChecker {
  static final SubscriptionService _subscriptionService = SubscriptionService();
  static final AdminService _adminService = AdminService();

  /// Determine the reason for access denial
  static AccessDeniedReason _determineAccessDeniedReason(Subscription? subscription) {
    if (subscription == null) {
      return AccessDeniedReason.trialExpired;
    }
    
    if (subscription.status == SubscriptionStatus.cancelled) {
      return AccessDeniedReason.subscriptionCancelled;
    }
    
    if (subscription.status == SubscriptionStatus.expired) {
      return AccessDeniedReason.subscriptionExpired;
    }
    
    if (subscription.status == SubscriptionStatus.active && 
        subscription.subscriptionEndDate != null &&
        DateTime.now().isAfter(subscription.subscriptionEndDate!)) {
      return AccessDeniedReason.subscriptionExpired;
    }
    
    if (subscription.status == SubscriptionStatus.trial &&
        subscription.trialEndDate != null &&
        DateTime.now().isAfter(subscription.trialEndDate!)) {
      return AccessDeniedReason.trialExpired;
    }
    
    // Default to trial expired
    return AccessDeniedReason.trialExpired;
  }

  /// Check if user has active access, if not show contact owner screen.
  /// Admins always have access regardless of subscription status.
  /// Returns true if user has access, false if blocked
  static Future<bool> checkAccess(BuildContext context) async {
    try {
      final isAdmin = await _adminService.isAdmin();
      if (isAdmin) {
        return true;
      }

      final hasAccess = await _subscriptionService.hasActiveAccess();
      
      if (!hasAccess) {
        // Determine the reason and show contact owner screen
        final subscription = await _subscriptionService.getCurrentUserSubscription();
        final reason = _determineAccessDeniedReason(subscription);
        
        if (context.mounted) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ContactOwnerScreen(reason: reason),
            ),
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      // If there's an error checking subscription, allow access (fail open)
      return true;
    }
  }

  /// Check subscription and execute action if user has access
  static Future<void> executeWithSubscriptionCheck(
    BuildContext context,
    VoidCallback action,
  ) async {
    final hasAccess = await checkAccess(context);
    if (hasAccess && context.mounted) {
      action();
    }
  }
}
