import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/access_service.dart';
import '../services/admin_service.dart';
import '../screens/contact_owner_screen.dart';
import '../models/access.dart';

class AccessChecker {
  static final AccessService _accessService = AccessService();
  static final AdminService _adminService = AdminService();

  static AccessDeniedReason _determineAccessDeniedReason(Access? access) {
    if (access == null) {
      return AccessDeniedReason.trialExpired;
    }
    if (access.status == AccessStatus.cancelled) {
      return AccessDeniedReason.accessRevoked;
    }
    if (access.status == AccessStatus.expired) {
      return AccessDeniedReason.accessExpired;
    }
    if (access.status == AccessStatus.active &&
        access.accessEndDate != null &&
        DateTime.now().isAfter(access.accessEndDate!)) {
      return AccessDeniedReason.accessExpired;
    }
    if (access.status == AccessStatus.trial &&
        access.trialEndDate != null &&
        DateTime.now().isAfter(access.trialEndDate!)) {
      return AccessDeniedReason.trialExpired;
    }
    return AccessDeniedReason.trialExpired;
  }

  /// Check if user has active access, if not show contact owner screen.
  /// Admins always have access regardless of access status.
  static Future<bool> checkAccess(BuildContext context) async {
    try {
      final isAdmin = await _adminService.isAdmin();
      if (isAdmin) return true;

      final hasAccess = await _accessService.hasActiveAccess();
      if (!hasAccess) {
        final access = await _accessService.getCurrentUserAccess();
        final reason = _determineAccessDeniedReason(access);
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
      return true;
    }
  }

  static Future<void> executeWithAccessCheck(
    BuildContext context,
    VoidCallback action,
  ) async {
    final hasAccess = await checkAccess(context);
    if (hasAccess && context.mounted) {
      action();
    }
  }
}
