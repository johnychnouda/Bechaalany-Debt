import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Skip initialization for web platform
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    
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
    // Skip platform-specific code for web
    if (kIsWeb) {
      return;
    }
    
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
    if (kIsWeb) return false;
    
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

  /// Load notification settings from SharedPreferences
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'interruptionLevel': prefs.getString('interruptionLevel') ?? 'active',
      'dailySummaryEnabled': prefs.getBool('dailySummaryEnabled') ?? true,
      'weeklyReportEnabled': prefs.getBool('weeklyReportEnabled') ?? true,
      'monthlyReportEnabled': prefs.getBool('monthlyReportEnabled') ?? true,
      'yearlyReportEnabled': prefs.getBool('yearlyReportEnabled') ?? true,
      'dailySummaryTime': prefs.getString('dailySummaryTime') ?? '23:59',
      'weeklyReportWeekday': prefs.getInt('weeklyReportWeekday') ?? DateTime.sunday,
      'weeklyReportTime': prefs.getString('weeklyReportTime') ?? '23:59',
      'monthlyReportDay': prefs.getInt('monthlyReportDay') ?? 31,
      'monthlyReportTime': prefs.getString('monthlyReportTime') ?? '23:59',
      'yearlyReportMonth': prefs.getInt('yearlyReportMonth') ?? 12,
      'yearlyReportDay': prefs.getInt('yearlyReportDay') ?? 31,
      'yearlyReportTime': prefs.getString('yearlyReportTime') ?? '23:59',
    };
  }

  /// Update notification settings and save to SharedPreferences
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
    final prefs = await SharedPreferences.getInstance();
    
    if (dailySummaryEnabled != null) {
      await prefs.setBool('dailySummaryEnabled', dailySummaryEnabled);
    }
    if (weeklyReportEnabled != null) {
      await prefs.setBool('weeklyReportEnabled', weeklyReportEnabled);
    }
    if (monthlyReportEnabled != null) {
      await prefs.setBool('monthlyReportEnabled', monthlyReportEnabled);
    }
    if (yearlyReportEnabled != null) {
      await prefs.setBool('yearlyReportEnabled', yearlyReportEnabled);
    }
    if (dailySummaryTime != null) {
      await prefs.setString('dailySummaryTime', '${dailySummaryTime.hour.toString().padLeft(2, '0')}:${dailySummaryTime.minute.toString().padLeft(2, '0')}');
    }
    if (weeklyReportWeekday != null) {
      await prefs.setInt('weeklyReportWeekday', weeklyReportWeekday);
    }
    if (weeklyReportTime != null) {
      await prefs.setString('weeklyReportTime', '${weeklyReportTime.hour.toString().padLeft(2, '0')}:${weeklyReportTime.minute.toString().padLeft(2, '0')}');
    }
    if (monthlyReportDay != null) {
      await prefs.setInt('monthlyReportDay', monthlyReportDay);
    }
    if (monthlyReportTime != null) {
      await prefs.setString('monthlyReportTime', '${monthlyReportTime.hour.toString().padLeft(2, '0')}:${monthlyReportTime.minute.toString().padLeft(2, '0')}');
    }
    if (yearlyReportMonth != null) {
      await prefs.setInt('yearlyReportMonth', yearlyReportMonth);
    }
    if (yearlyReportDay != null) {
      await prefs.setInt('yearlyReportDay', yearlyReportDay);
    }
    if (yearlyReportTime != null) {
      await prefs.setString('yearlyReportTime', '${yearlyReportTime.hour.toString().padLeft(2, '0')}:${yearlyReportTime.minute.toString().padLeft(2, '0')}');
    }
    if (interruptionLevel != null) {
      await prefs.setString('interruptionLevel', interruptionLevel);
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
    // Skip notifications for web platform
    if (kIsWeb) {
      return;
    }
    
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
    // Skip for web platform
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    // Skip for web platform
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    // Skip for web platform
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }

  // Test notification method for debugging
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