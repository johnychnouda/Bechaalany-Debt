
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class IOS18Service {
  static const MethodChannel _channel = MethodChannel('ios18_notifications');
  
  // iOS 18.6+ notification categories
  static const String _debtManagementCategory = 'debt_management';
  static const String _paymentRemindersCategory = 'payment_reminders';
  static const String _dailySummaryCategory = 'daily_summary';
  static const String _weeklyReportCategory = 'weekly_report';
  static const String _overduePaymentsCategory = 'overdue_payments';

  // iOS 18.6+ interruption levels - removed unused static fields

  /// Initialize iOS 18.6+ notification capabilities
  static Future<void> initialize() async {
    if (!Platform.isIOS) return;

    try {
      // Request notification permissions with iOS 18.6+ features
      await _requestNotificationPermissions();
      
      // Setup notification categories
      await _setupNotificationCategories();
      
      // Configure background processing
      await _configureBackgroundProcessing();
      
      // Enable smart notifications
      await _enableSmartNotifications();
      
      print('iOS 18.6+ notification service initialized successfully');
    } catch (e) {
      print('Error initializing iOS 18.6+ service: $e');
    }
  }

  /// Request notification permissions with iOS 18.6+ features
  static Future<void> _requestNotificationPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestNotificationPermissions', {
        'alert': true,
        'badge': true,
        'sound': true,
        'criticalAlert': false, // Only for critical health alerts
        'provisional': false, // Provisional notifications
        'announcement': false, // Announcement notifications
        'interruptionLevel': 'active',
      });
      
      print('Notification permissions result: $result');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  /// Setup notification categories for iOS 18.6+
  static Future<void> _setupNotificationCategories() async {
    try {
      // Debt Management Category
      await _channel.invokeMethod('createNotificationCategory', {
        'identifier': _debtManagementCategory,
        'actions': [
          {
            'identifier': 'mark_paid',
            'title': 'Mark as Paid',
            'options': ['foreground'],
          },
          {
            'identifier': 'snooze',
            'title': 'Snooze 1 Day',
            'options': ['destructive'],
          },
          {
            'identifier': 'contact_customer',
            'title': 'Contact Customer',
            'options': ['foreground'],
          },
        ],
        'intentIdentifiers': [],
        'options': ['allowAnnouncement'],
      });

      // Payment Reminders Category
      await _channel.invokeMethod('createNotificationCategory', {
        'identifier': _paymentRemindersCategory,
        'actions': [
          {
            'identifier': 'mark_paid',
            'title': 'Mark as Paid',
            'options': ['foreground'],
          },
          {
            'identifier': 'snooze',
            'title': 'Snooze 1 Day',
            'options': ['destructive'],
          },
        ],
        'intentIdentifiers': [],
        'options': ['allowAnnouncement'],
      });

      // Daily Summary Category
      await _channel.invokeMethod('createNotificationCategory', {
        'identifier': _dailySummaryCategory,
        'actions': [
          {
            'identifier': 'view_summary',
            'title': 'View Summary',
            'options': ['foreground'],
          },
        ],
        'intentIdentifiers': [],
        'options': ['allowAnnouncement'],
      });

      // Weekly Report Category
      await _channel.invokeMethod('createNotificationCategory', {
        'identifier': _weeklyReportCategory,
        'actions': [
          {
            'identifier': 'view_report',
            'title': 'View Report',
            'options': ['foreground'],
          },
        ],
        'intentIdentifiers': [],
        'options': ['allowAnnouncement'],
      });

      // Overdue Payments Category
      await _channel.invokeMethod('createNotificationCategory', {
        'identifier': _overduePaymentsCategory,
        'actions': [
          {
            'identifier': 'mark_paid',
            'title': 'Mark as Paid',
            'options': ['foreground'],
          },
          {
            'identifier': 'contact_customer',
            'title': 'Contact Customer',
            'options': ['foreground'],
          },
          {
            'identifier': 'send_reminder',
            'title': 'Send Reminder',
            'options': ['foreground'],
          },
        ],
        'intentIdentifiers': [],
        'options': ['allowAnnouncement'],
      });

      print('iOS 18.6+ notification categories setup complete');
    } catch (e) {
      print('Error setting up notification categories: $e');
    }
  }

  /// Configure background processing for iOS 18.6+
  static Future<void> _configureBackgroundProcessing() async {
    try {
      await _channel.invokeMethod('configureBackgroundProcessing', {
        'backgroundAppRefresh': true,
        'backgroundProcessing': true,
        'backgroundFetch': true,
        'backgroundTasks': [
          'checkOverduePayments',
          'generateDailySummary',
          'generateWeeklyReport',
          'sendPaymentReminders',
        ],
      });
      
      print('iOS 18.6+ background processing configured');
    } catch (e) {
      print('Error configuring background processing: $e');
    }
  }

  /// Enable smart notifications for iOS 18.6+
  static Future<void> _enableSmartNotifications() async {
    try {
      await _channel.invokeMethod('enableSmartNotifications', {
        'focusModeIntegration': true,
        'dynamicIslandIntegration': true,
        'liveActivities': true,
        'smartStack': true,
        'aiFeatures': true,
      });
      
      print('iOS 18.6+ smart notifications enabled');
    } catch (e) {
      print('Error enabling smart notifications: $e');
    }
  }

  /// Send smart notification with iOS 18.6+ features
  static Future<void> sendSmartNotification({
    required String title,
    required String body,
    required String category,
    required String interruptionLevel,
    String? payload,
    Map<String, dynamic>? userInfo,
    String? threadIdentifier,
    String? targetContentIdentifier,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('sendSmartNotification', {
        'title': title,
        'body': body,
        'category': category,
        'interruptionLevel': interruptionLevel,
        'payload': payload,
        'userInfo': userInfo ?? {},
        'threadIdentifier': threadIdentifier,
        'targetContentIdentifier': targetContentIdentifier,
        'sound': 'default',
        'badge': 1,
        'presentAlert': true,
        'presentBadge': true,
        'presentSound': true,
      });
      
      print('iOS 18.6+ smart notification sent: $title');
    } catch (e) {
      print('Error sending smart notification: $e');
    }
  }

  /// Schedule notification with iOS 18.6+ features
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required String category,
    required String interruptionLevel,
    required DateTime scheduledDate,
    String? payload,
    Map<String, dynamic>? userInfo,
    String? threadIdentifier,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('scheduleNotification', {
        'title': title,
        'body': body,
        'category': category,
        'interruptionLevel': interruptionLevel,
        'scheduledDate': scheduledDate.millisecondsSinceEpoch,
        'payload': payload,
        'userInfo': userInfo ?? {},
        'threadIdentifier': threadIdentifier,
        'sound': 'default',
        'badge': 1,
        'presentAlert': true,
        'presentBadge': true,
        'presentSound': true,
      });
      
      print('iOS 18.6+ notification scheduled: $title');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(String identifier) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('cancelNotification', {
        'identifier': identifier,
      });
      
      print('iOS 18.6+ notification cancelled: $identifier');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('cancelAllNotifications');
      print('All iOS 18.6+ notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  static Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    if (!Platform.isIOS) return [];

    try {
      final result = await _channel.invokeMethod('getPendingNotifications');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Update notification settings for iOS 18.6+
  static Future<void> updateNotificationSettings({
    required bool paymentRemindersEnabled,
    required bool dailySummaryEnabled,
    required bool weeklyReportEnabled,
    required String interruptionLevel,
    required bool focusModeIntegration,
    required bool dynamicIslandEnabled,
    required bool liveActivitiesEnabled,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('updateNotificationSettings', {
        'paymentRemindersEnabled': paymentRemindersEnabled,
        'dailySummaryEnabled': dailySummaryEnabled,
        'weeklyReportEnabled': weeklyReportEnabled,
        'interruptionLevel': interruptionLevel,
        'focusModeIntegration': focusModeIntegration,
        'dynamicIslandEnabled': dynamicIslandEnabled,
        'liveActivitiesEnabled': liveActivitiesEnabled,
      });
      
      print('iOS 18.6+ notification settings updated');
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  /// Enable Focus mode integration
  static Future<void> enableFocusModeIntegration() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('enableFocusModeIntegration');
      print('iOS 18.6+ Focus mode integration enabled');
    } catch (e) {
      print('Error enabling Focus mode integration: $e');
    }
  }

  /// Enable Dynamic Island integration
  static Future<void> enableDynamicIslandIntegration() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('enableDynamicIslandIntegration');
      print('iOS 18.6+ Dynamic Island integration enabled');
    } catch (e) {
      print('Error enabling Dynamic Island integration: $e');
    }
  }

  /// Enable Live Activities
  static Future<void> enableLiveActivities() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('enableLiveActivities');
      print('iOS 18.6+ Live Activities enabled');
    } catch (e) {
      print('Error enabling Live Activities: $e');
    }
  }

  /// Start Live Activity for debt tracking
  static Future<void> startDebtTrackingActivity({
    required String activityId,
    required String customerName,
    required double amount,
    required DateTime dueDate,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('startLiveActivity', {
        'activityId': activityId,
        'activityType': 'debt_tracking',
        'customerName': customerName,
        'amount': amount,
        'dueDate': dueDate.millisecondsSinceEpoch,
      });
      
      print('iOS 18.6+ Live Activity started for debt tracking');
    } catch (e) {
      print('Error starting Live Activity: $e');
    }
  }

  /// Update Live Activity
  static Future<void> updateLiveActivity({
    required String activityId,
    Map<String, dynamic>? data,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('updateLiveActivity', {
        'activityId': activityId,
        'data': data ?? {},
      });
      
      print('iOS 18.6+ Live Activity updated');
    } catch (e) {
      print('Error updating Live Activity: $e');
    }
  }

  /// End Live Activity
  static Future<void> endLiveActivity(String activityId) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('endLiveActivity', {
        'activityId': activityId,
      });
      
      print('iOS 18.6+ Live Activity ended');
    } catch (e) {
      print('Error ending Live Activity: $e');
    }
  }

  /// Check if device supports iOS 18.6+ features
  static Future<bool> isIOS186Supported() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('isIOS186Supported');
      return result as bool;
    } catch (e) {
      print('Error checking iOS 18.6+ support: $e');
      return false;
    }
  }

  /// Get device capabilities
  static Future<Map<String, bool>> getDeviceCapabilities() async {
    if (!Platform.isIOS) return {};

    try {
      final result = await _channel.invokeMethod('getDeviceCapabilities');
      return Map<String, bool>.from(result);
    } catch (e) {
      print('Error getting device capabilities: $e');
      return {};
    }
  }
} 