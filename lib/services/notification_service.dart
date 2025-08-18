import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
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
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    if (Platform.isIOS) {
      try {
        // iOS notification permissions are handled automatically by the initialization
        // The DarwinInitializationSettings already requests permissions
  
      } catch (e) {
        // Handle iOS notification permission request error
        
      }
    }
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
      'paymentRemindersEnabled': prefs.getBool('paymentRemindersEnabled') ?? false,
      'dailySummaryEnabled': prefs.getBool('dailySummaryEnabled') ?? false,
      'weeklyReportEnabled': prefs.getBool('weeklyReportEnabled') ?? false,
      'dailySummaryTime': prefs.getString('dailySummaryTime'),
      'weeklyReportWeekday': prefs.getInt('weeklyReportWeekday') ?? DateTime.monday,
      'weeklyReportTime': prefs.getString('weeklyReportTime'),
    };
  }

  /// Update notification settings and save to SharedPreferences
  Future<void> updateNotificationSettings({
    bool? paymentRemindersEnabled,
    bool? dailySummaryEnabled,
    bool? weeklyReportEnabled,
    TimeOfDay? dailySummaryTime,
    int? weeklyReportWeekday,
    TimeOfDay? weeklyReportTime,
    String? interruptionLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (paymentRemindersEnabled != null) {
      await prefs.setBool('paymentRemindersEnabled', paymentRemindersEnabled);
    }
    if (dailySummaryEnabled != null) {
      await prefs.setBool('dailySummaryEnabled', dailySummaryEnabled);
    }
    if (weeklyReportEnabled != null) {
      await prefs.setBool('weeklyReportEnabled', weeklyReportEnabled);
    }
    if (dailySummaryTime != null) {
      await prefs.setString('dailySummaryTime', '${dailySummaryTime.hour}:${dailySummaryTime.minute}');
    }
    if (weeklyReportWeekday != null) {
      await prefs.setInt('weeklyReportWeekday', weeklyReportWeekday);
    }
    if (weeklyReportTime != null) {
      await prefs.setString('weeklyReportTime', '${weeklyReportTime.hour}:${weeklyReportTime.minute}');
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
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bechaalany_debt_app',
      'Bechaalany Debt App',
      channelDescription: 'Notifications for debt management app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    
  }

  // Customer-related notifications
  Future<void> showCustomerAddedNotification(dynamic customer) async {
    await showSuccessNotification(
      title: 'Customer Added',
      body: '${customer.name} has been added successfully',
      payload: 'customer_added_${customer.id}',
    );
  }

  Future<void> showCustomerUpdatedNotification(dynamic customer) async {
    await showSuccessNotification(
      title: 'Customer Updated',
      body: 'Contact information for ${customer.name} has been updated',
      payload: 'customer_updated_${customer.id}',
    );
  }

  Future<void> showCustomerDeletedNotification(String customerName) async {
    await showInfoNotification(
      title: 'Customer Deleted',
      body: '$customerName has been removed from your records',
      payload: 'customer_deleted',
    );
  }

  // Debt-related notifications
  Future<void> showDebtAddedNotification(dynamic debt) async {
    await showSuccessNotification(
      title: 'Debt Recorded',
      body: '${debt.customerName} owes \$${debt.amount.toStringAsFixed(2)}',
      payload: 'debt_added_${debt.id}',
    );
  }

  Future<void> showDebtUpdatedNotification(dynamic debt) async {
    await showSuccessNotification(
      title: 'Debt Updated',
      body: '${debt.customerName}\'s debt has been updated',
      payload: 'debt_updated_${debt.id}',
    );
  }

  Future<void> showDebtPaidNotification(dynamic debt) async {
    await showSuccessNotification(
      title: 'Debt Paid',
      body: '${debt.customerName} has paid \$${debt.amount.toStringAsFixed(2)}',
      payload: 'debt_paid_${debt.id}',
    );
  }

  Future<void> showPartialPaymentNotification(dynamic debt, double amount) async {
    await showInfoNotification(
      title: 'Partial Payment',
      body: '${debt.customerName} paid \$${amount.toStringAsFixed(2)}',
      payload: 'partial_payment_${debt.id}',
    );
  }

  Future<void> showDebtDeletedNotification(String customerName, double amount) async {
    await showInfoNotification(
      title: 'Debt Deleted',
      body: 'Removed \$${amount.toStringAsFixed(2)} debt for $customerName',
      payload: 'debt_deleted',
    );
  }

  // Payment reminder notifications
  Future<void> showPaymentReminderNotification(dynamic debt) async {
    await showWarningNotification(
      title: 'Payment Reminder',
      body: '${debt.customerName} owes \$${debt.remainingAmount.toStringAsFixed(2)}',
      payload: 'payment_reminder_${debt.id}',
    );
  }

  Future<void> showOverduePaymentNotification(dynamic debt) async {
    await showErrorNotification(
      title: 'Overdue Payment',
      body: '${debt.customerName} has an overdue payment of \$${debt.remainingAmount.toStringAsFixed(2)}',
      payload: 'overdue_payment_${debt.id}',
    );
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





  // Settings notifications
  Future<void> showSettingsUpdatedNotification() async {
    await showSuccessNotification(
      title: 'Settings Updated',
      body: 'Your app settings have been saved',
      payload: 'settings_updated',
    );
  }

  // Daily summary notifications
  Future<void> showDailySummaryNotification({
    required int totalCustomers,
    required int totalDebts,
    required double totalAmount,
    required double totalPaid,
  }) async {
    await showInfoNotification(
      title: 'Daily Summary',
      body: '$totalCustomers customers, $totalDebts debts, \$${totalAmount.toStringAsFixed(2)} total, \$${totalPaid.toStringAsFixed(2)} paid',
      payload: 'daily_summary',
    );
  }

  // Weekly report notifications
  Future<void> showWeeklyReportNotification({
    required int newCustomers,
    required int newDebts,
    required double totalRevenue,
  }) async {
    await showInfoNotification(
      title: 'Weekly Report',
      body: '$newCustomers new customers, $newDebts new debts, \$${totalRevenue.toStringAsFixed(2)} revenue',
      payload: 'weekly_report',
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

  // Category-related notifications
  Future<void> showCategoryAddedNotification(String categoryName) async {
    await showSuccessNotification(
      title: 'Category Added',
      body: '$categoryName category has been created successfully',
      payload: 'category_added',
    );
  }

  Future<void> showCategoryUpdatedNotification(String categoryName) async {
    await showSuccessNotification(
      title: 'Category Updated',
      body: '$categoryName category has been updated',
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

  // Product-related notifications
  Future<void> showProductUpdatedNotification(String productName) async {
    await showSuccessNotification(
      title: 'Product Updated',
      body: '$productName has been updated successfully',
      payload: 'product_updated',
    );
  }

  Future<void> showProductDeletedNotification(String productName) async {
    await showInfoNotification(
      title: 'Product Deleted',
      body: '$productName has been removed from inventory',
      payload: 'product_deleted',
    );
  }

  // Product purchase notifications
  Future<void> showProductPurchaseAddedNotification(String productName) async {
    await showSuccessNotification(
      title: 'Purchase Recorded',
      body: '$productName purchase has been added to inventory',
      payload: 'purchase_added',
    );
  }

  Future<void> showProductPurchaseUpdatedNotification(String productName) async {
    await showSuccessNotification(
      title: 'Purchase Updated',
      body: '$productName purchase has been updated',
      payload: 'purchase_updated',
    );
  }

  Future<void> showProductPurchaseDeletedNotification(String productName) async {
    await showInfoNotification(
      title: 'Purchase Deleted',
      body: '$productName purchase has been removed',
      payload: 'purchase_deleted',
    );
  }

  // Payment-related notifications
  Future<void> showPaymentAppliedNotification(dynamic debt, double paymentAmount) async {
    await showSuccessNotification(
      title: 'Payment Applied',
      body: '\$${paymentAmount.toStringAsFixed(2)} applied to ${debt.customerName}\'s debt',
      payload: 'payment_applied_${debt.id}',
    );
  }



  Future<void> showDataImportedNotification() async {
    await showSuccessNotification(
      title: 'Data Imported',
      body: 'Your data has been imported successfully',
      payload: 'data_imported',
    );
  }

  Future<void> showCacheClearedNotification() async {
    await showInfoNotification(
      title: 'Cache Cleared',
      body: 'App cache has been cleared successfully',
      payload: 'cache_cleared',
    );
  }

  Future<void> showSyncCompletedNotification() async {
    await showSuccessNotification(
      title: 'Sync Complete',
      body: 'Your data has been synchronized',
      payload: 'sync_completed',
    );
  }

  Future<void> showSyncFailedNotification() async {
    await showErrorNotification(
      title: 'Sync Failed',
      body: 'Unable to sync data. Please check your connection.',
      payload: 'sync_failed',
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