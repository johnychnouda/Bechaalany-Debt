import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    
    // Initialize notification settings for iOS with supported features
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
      requestProvisionalPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
    
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    
    if (Platform.isIOS) {
      try {
        // Request notification permissions explicitly using supported features
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        // Handle error silently
      }
    }
  }

  // Public method to re-request permissions (for app lifecycle handling)
  Future<void> reRequestPermissions() async {
    await _requestPermissions();
  }
  
  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    
    if (Platform.isIOS) {
      try {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        return result?.isEnabled ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  // ===== NOTIFICATION SETTINGS =====

  /// Load notification settings from Firebase
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          return {
            'interruptionLevel': data['interruptionLevel'] ?? 'active',
            'dailySummaryEnabled': data['dailySummaryEnabled'] ?? true,
            'weeklyReportEnabled': data['weeklyReportEnabled'] ?? true,
            'monthlyReportEnabled': data['monthlyReportEnabled'] ?? true,
            'yearlyReportEnabled': data['yearlyReportEnabled'] ?? true,
            'dailySummaryTime': data['dailySummaryTime'] ?? '23:59',
            'weeklyReportWeekday': data['weeklyReportWeekday'] ?? DateTime.sunday,
            'weeklyReportTime': data['weeklyReportTime'] ?? '23:59',
            'monthlyReportDay': data['monthlyReportDay'] ?? 31,
            'monthlyReportTime': data['monthlyReportTime'] ?? '23:59',
            'yearlyReportMonth': data['yearlyReportMonth'] ?? 12,
            'yearlyReportDay': data['yearlyReportDay'] ?? 31,
            'yearlyReportTime': data['yearlyReportTime'] ?? '23:59',
          };
        }
      }
    } catch (e) {
      // Return defaults if error
    }
    
    return {
      'interruptionLevel': 'active',
      'dailySummaryEnabled': true,
      'weeklyReportEnabled': true,
      'monthlyReportEnabled': true,
      'yearlyReportEnabled': true,
      'dailySummaryTime': '23:59',
      'weeklyReportWeekday': DateTime.sunday,
      'weeklyReportTime': '23:59',
      'monthlyReportDay': 31,
      'monthlyReportTime': '23:59',
      'yearlyReportMonth': 12,
      'yearlyReportDay': 31,
      'yearlyReportTime': '23:59',
    };
  }

  /// Update notification settings and save to Firebase
  Future<void> updateNotificationSettings({
    bool? dailySummaryEnabled,
    bool? weeklyReportEnabled,
    bool? monthlyReportEnabled,
    bool? yearlyReportEnabled,
    TimeOfDay? dailySummaryTime,
    int? weeklyReportWeekday,
    TimeOfDay? weeklyReportTime,
    int? monthlyReportDay,
    TimeOfDay? monthlyReportTime,
    int? yearlyReportMonth,
    int? yearlyReportDay,
    TimeOfDay? yearlyReportTime,
    String? interruptionLevel,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> updates = {};
        
        if (dailySummaryEnabled != null) {
          updates['dailySummaryEnabled'] = dailySummaryEnabled;
        }
        if (weeklyReportEnabled != null) {
          updates['weeklyReportEnabled'] = weeklyReportEnabled;
        }
        if (monthlyReportEnabled != null) {
          updates['monthlyReportEnabled'] = monthlyReportEnabled;
        }
        if (yearlyReportEnabled != null) {
          updates['yearlyReportEnabled'] = yearlyReportEnabled;
        }
        if (dailySummaryTime != null) {
          updates['dailySummaryTime'] = '${dailySummaryTime.hour.toString().padLeft(2, '0')}:${dailySummaryTime.minute.toString().padLeft(2, '0')}';
        }
        if (weeklyReportWeekday != null) {
          updates['weeklyReportWeekday'] = weeklyReportWeekday;
        }
        if (weeklyReportTime != null) {
          updates['weeklyReportTime'] = '${weeklyReportTime.hour.toString().padLeft(2, '0')}:${weeklyReportTime.minute.toString().padLeft(2, '0')}';
        }
        if (monthlyReportDay != null) {
          updates['monthlyReportDay'] = monthlyReportDay;
        }
        if (monthlyReportTime != null) {
          updates['monthlyReportTime'] = '${monthlyReportTime.hour.toString().padLeft(2, '0')}:${monthlyReportTime.minute.toString().padLeft(2, '0')}';
        }
        if (yearlyReportMonth != null) {
          updates['yearlyReportMonth'] = yearlyReportMonth;
        }
        if (yearlyReportDay != null) {
          updates['yearlyReportDay'] = yearlyReportDay;
        }
        if (yearlyReportTime != null) {
          updates['yearlyReportTime'] = '${yearlyReportTime.hour.toString().padLeft(2, '0')}:${yearlyReportTime.minute.toString().padLeft(2, '0')}';
        }
        if (interruptionLevel != null) {
          updates['interruptionLevel'] = interruptionLevel;
        }
        
        if (updates.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('user_settings')
              .doc(user.uid)
              .set(updates, SetOptions(merge: true));
        }
      }
    } catch (e) {
      // Error saving settings
    }
  }

  // ===== IMMEDIATE ACTION NOTIFICATIONS =====

  /// Show success notification
  Future<void> showSuccessNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647, // Keep within 32-bit int limit
      title: title,
      body: body,
      payload: payload,
      type: 'success',
    );
  }

  /// Show error notification
  Future<void> showErrorNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647, // Keep within 32-bit int limit
      title: title,
      body: body,
      payload: payload,
      type: 'error',
    );
  }

  /// Show info notification
  Future<void> showInfoNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647, // Keep within 32-bit int limit
      title: title,
      body: body,
      payload: payload,
      type: 'info',
    );
  }

  /// Show warning notification
  Future<void> showWarningNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647, // Keep within 32-bit int limit
      title: title,
      body: body,
      payload: payload,
      type: 'warning',
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String type,
  }) async {
    
    if (!_isInitialized) {
      await initialize();
    }

    // Generate a unique ID to avoid collisions
    final uniqueId = DateTime.now().millisecondsSinceEpoch + (id % 1000);
    
    // iOS 18+ styled notification with modern features
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active,
      threadIdentifier: 'payment_success',
      categoryIdentifier: 'payment_success',
      attachments: [],
      badgeNumber: 1,
      subtitle: 'Bechaalany Connect',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      // Add a small delay to ensure proper timing
      await Future.delayed(Duration(milliseconds: 100));
      
      await _notifications.show(
        uniqueId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
    } catch (e) {
      // Handle error silently
    }
  }

  // ===== BUSINESS OPERATION NOTIFICATIONS =====

  // Customer-related notifications
  Future<void> showCustomerAddedNotification(String customerName) async {
    await showSuccessNotification(
      title: 'Customer Added',
      body: '$customerName has been added successfully',
      payload: 'customer_added',
    );
  }

  Future<void> showCustomerUpdatedNotification(String customerName) async {
    await showSuccessNotification(
      title: 'Customer Updated',
      body: 'Contact information for $customerName has been updated',
      payload: 'customer_updated',
    );
  }

  Future<void> showCustomerDeletedNotification(String customerName) async {
    await showInfoNotification(
      title: 'Customer Deleted',
      body: '$customerName has been removed from your records',
      payload: 'customer_deleted',
    );
  }

  // Category-related notifications
  Future<void> showCategoryAddedNotification(String categoryName) async {
    await showSuccessNotification(
      title: 'Category Added',
      body: '$categoryName category has been added successfully',
      payload: 'category_added',
    );
  }

  Future<void> showCategoryUpdatedNotification(String categoryName) async {
    await showSuccessNotification(
      title: 'Category Updated',
      body: '$categoryName category has been updated successfully',
      payload: 'category_updated',
    );
  }

  Future<void> showCategoryDeletedNotification(String categoryName) async {
    await showInfoNotification(
      title: 'Category Deleted',
      body: '$categoryName category has been removed',
      payload: 'category_deleted',
    );
  }

  // Debt-related notifications
  Future<void> showDebtAddedNotification(String customerName, double amount) async {
    await showSuccessNotification(
      title: 'Debt Recorded',
      body: '$customerName owes \$${amount.toStringAsFixed(2)}',
      payload: 'debt_added',
    );
  }



  Future<void> showPaymentAppliedNotification(String customerName, double amount) async {
    await showSuccessNotification(
      title: 'Payment Applied',
      body: '\$${amount.toStringAsFixed(2)} applied to $customerName\'s debt',
      payload: 'payment_applied',
    );
  }

  Future<void> showPaymentSuccessfulNotification(String customerName) async {
    // Force re-initialization to ensure proper setup
    await initialize();
    
    // Check if notifications are enabled
    final notificationsEnabled = await areNotificationsEnabled();
    
    if (!notificationsEnabled) {
      await reRequestPermissions();
    }
    
    // Try to show the notification
    try {
      await showSuccessNotification(
        title: 'Payment Successful',
        body: '$customerName has fully paid all their debts',
        payload: 'payment_successful',
      );
    } catch (e) {
      // Handle error silently
    }
  }



  // Backup notifications
  Future<void> showBackupCreatedNotification() async {
    await showSuccessNotification(
      title: 'Backup Created',
      body: 'Your data has been backed up successfully',
      payload: 'backup_created',
    );
  }

  Future<void> showBackupRestoredNotification() async {
    await showSuccessNotification(
      title: 'Backup Restored',
      body: 'Your data has been restored from backup',
      payload: 'backup_restored',
    );
  }

  Future<void> showBackupFailedNotification(String error) async {
    await showErrorNotification(
      title: 'Backup Failed',
      body: 'Failed to create backup: $error',
      payload: 'backup_failed',
    );
  }


  // ===== BUSINESS INTELLIGENCE NOTIFICATIONS =====

  /// Show auto-reminder sent notification
  Future<void> showAutoReminderSentNotification(int customerCount) async {
    await showSuccessNotification(
      title: 'Auto-Reminder Sent',
      body: 'Payment reminder sent to $customerCount customer${customerCount == 1 ? '' : 's'}',
      payload: 'auto_reminder_sent',
    );
  }


  /// Show daily backup success notification
  Future<void> showDailyBackupSuccessNotification() async {
    await showSuccessNotification(
      title: 'Backup Success',
      body: 'Daily backup completed successfully',
      payload: 'daily_backup_success',
    );
  }

  /// Show auto-backup notification
  Future<void> showAutoBackupNotification(String time) async {
    await showSuccessNotification(
      title: 'Auto-Backup',
      body: 'Automatic backup completed at $time',
      payload: 'auto_backup',
    );
  }

  // ===== REPORT NOTIFICATIONS =====

  /// Show daily summary notification
  Future<void> showDailySummaryNotification({
    required double totalPaid,
    required double totalRevenue,
  }) async {
    await showInfoNotification(
      title: 'Daily Summary',
      body: 'Today: \$${totalPaid.toStringAsFixed(2)} paid, \$${totalRevenue.toStringAsFixed(2)} revenue',
      payload: 'daily_summary',
    );
  }

  /// Show weekly report notification
  Future<void> showWeeklyReportNotification({
    required double totalPaid,
    required double totalRevenue,
  }) async {
    await showInfoNotification(
      title: 'Weekly Report',
      body: 'This week: \$${totalPaid.toStringAsFixed(2)} paid, \$${totalRevenue.toStringAsFixed(2)} revenue',
      payload: 'weekly_report',
    );
  }

  /// Show monthly report notification
  Future<void> showMonthlyReportNotification({
    required double totalPaid,
    required double totalRevenue,
  }) async {
    await showInfoNotification(
      title: 'Monthly Report',
      body: 'This month: \$${totalPaid.toStringAsFixed(2)} paid, \$${totalRevenue.toStringAsFixed(2)} revenue',
      payload: 'monthly_report',
    );
  }

  /// Show yearly report notification
  Future<void> showYearlyReportNotification({
    required double totalPaid,
    required double totalRevenue,
  }) async {
    await showInfoNotification(
      title: 'Yearly Report',
      body: 'This year: \$${totalPaid.toStringAsFixed(2)} paid, \$${totalRevenue.toStringAsFixed(2)} revenue',
      payload: 'yearly_report',
    );
  }


  // ===== SYSTEM NOTIFICATIONS =====

  /// Show app update notification
  Future<void> showAppUpdateNotification(String version) async {
    await showInfoNotification(
      title: 'App Updated',
      body: 'App has been updated to version $version',
      payload: 'app_updated',
    );
  }

  /// Show system maintenance notification
  Future<void> showSystemMaintenanceNotification(String message) async {
    await showWarningNotification(
      title: 'System Maintenance',
      body: message,
      payload: 'system_maintenance',
    );
  }

  /// Show app update available notification
  Future<void> showAppUpdateAvailableNotification(String version) async {
    await showInfoNotification(
      title: 'App Update Available',
      body: 'New version $version with improved features available',
      payload: 'app_update_available',
    );
  }



  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Test notification method
  Future<void> testNotification() async {
    await showSuccessNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working',
      payload: 'test',
    );
  }

  // Legacy methods for backward compatibility
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showInfoNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

} 