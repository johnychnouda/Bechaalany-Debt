import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// import 'dart:io'; // Removed unused import
import 'ios18_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  // iOS 18.6+ specific features - removed unused static fields

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize iOS 18.6+ notification capabilities
    await _initializeIOS18Features();
    
    _isInitialized = true;
  }

  /// Initialize iOS 18.6+ specific features
  Future<void> _initializeIOS18Features() async {
    // Initialize iOS 18.6+ notification service
    await IOS18Service.initialize();
    
    // iOS 18.6+ notification categories and actions
    await _setupNotificationCategories();
    
    // Configure interruption levels for different notification types
    await _configureInterruptionLevels();
    
    // Enable background app refresh for smart notifications
    await _enableBackgroundProcessing();
  }

  /// Setup notification categories for iOS 18.6+
  Future<void> _setupNotificationCategories() async {
    // iOS 18.6+ notification categories are handled by IOS18Service
    print('Setting up iOS 18.6+ notification categories');
  }

  /// Configure interruption levels for different notification types
  Future<void> _configureInterruptionLevels() async {
    // iOS 18.6+ interruption levels:
    // - active: Standard notifications
    // - timeSensitive: Important but not critical
    // - critical: Emergency notifications
    // - passive: Silent notifications
    print('Configuring iOS 18.6+ interruption levels');
  }

  /// Enable background processing for smart notifications
  Future<void> _enableBackgroundProcessing() async {
    // iOS 18.6+ background processing capabilities
    print('Enabling iOS 18.6+ background processing');
  }

  /// Send smart notification with iOS 18.6+ features
  Future<void> _sendSmartNotification({
    required String title,
    required String body,
    required String category,
    required String interruptionLevel,
    String? payload,
  }) async {
    // Use iOS 18.6+ service for smart notifications
    await IOS18Service.sendSmartNotification(
      title: title,
      body: body,
      category: category,
      interruptionLevel: interruptionLevel,
      payload: payload,
      userInfo: {
        'app': 'Bechaalany Debt App',
        'version': '1.0.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      threadIdentifier: category,
    );
  }

  /// Send immediate smart notification
  Future<void> _sendImmediateSmartNotification({
    required String title,
    required String body,
    String? payload,
    String interruptionLevel = 'active',
  }) async {
    await _sendSmartNotification(
      title: title,
      body: body,
      category: 'immediate',
      interruptionLevel: interruptionLevel,
      payload: payload,
    );
  }

  // ===== IMMEDIATE ACTION NOTIFICATIONS =====

  /// Show success notification with iOS 18.6+ features
  Future<void> showSuccessNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _sendImmediateSmartNotification(
      title: title,
      body: body,
      payload: payload,
      interruptionLevel: 'active',
    );
  }

  /// Show error notification with iOS 18.6+ features
  Future<void> showErrorNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _sendImmediateSmartNotification(
      title: title,
      body: body,
      payload: payload,
      interruptionLevel: 'timeSensitive',
    );
  }

  /// Show info notification with iOS 18.6+ features
  Future<void> showInfoNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _sendImmediateSmartNotification(
      title: title,
      body: body,
      payload: payload,
      interruptionLevel: 'passive',
    );
  }

  /// Show warning notification with iOS 18.6+ features
  Future<void> showWarningNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _sendImmediateSmartNotification(
      title: title,
      body: body,
      payload: payload,
      interruptionLevel: 'active',
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
      title: 'Payment Received',
      body: '${debt.customerName} has paid \$${debt.amount.toStringAsFixed(2)}',
      payload: 'debt_paid_${debt.id}',
    );
  }

  Future<void> showDebtDeletedNotification(String customerName, double amount) async {
    await showInfoNotification(
      title: 'Debt Removed',
      body: 'Debt of \$${amount.toStringAsFixed(2)} for $customerName has been deleted',
      payload: 'debt_deleted',
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
  Future<void> showProductDeletedNotification(String productName) async {
    await showInfoNotification(
      title: 'Product Deleted',
      body: '$productName has been removed from inventory',
      payload: 'product_deleted',
    );
  }

  Future<void> showProductUpdatedNotification(String productName) async {
    await showSuccessNotification(
      title: 'Product Updated',
      body: '$productName has been updated successfully',
      payload: 'product_updated',
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

  // ===== SYSTEM NOTIFICATIONS =====

  // Settings and system notifications
  Future<void> showDataExportedNotification() async {
    await showSuccessNotification(
      title: 'Data Exported',
      body: 'Your data has been exported successfully',
      payload: 'data_exported',
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

  Future<void> cancelNotification(int id) async {
    // Cancel specific notification using iOS 18.6+ service
    await IOS18Service.cancelNotification(id.toString());
  }

  Future<void> cancelAllNotifications() async {
    // Cancel all notifications using iOS 18.6+ service
    await IOS18Service.cancelAllNotifications();
  }

  Future<List<dynamic>> getPendingNotifications() async {
    // Get pending notifications using iOS 18.6+ service
    return await IOS18Service.getPendingNotifications();
  }

  /// Update notification settings for iOS 18.6+
  Future<void> updateNotificationSettings({
    required bool paymentRemindersEnabled,
    required bool dailySummaryEnabled,
    required bool weeklyReportEnabled,
    required TimeOfDay dailySummaryTime,
    required int weeklyReportWeekday,
    required TimeOfDay weeklyReportTime,
    required String interruptionLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('payment_reminders_enabled', paymentRemindersEnabled);
    await prefs.setBool('daily_summary_enabled', dailySummaryEnabled);
    await prefs.setBool('weekly_report_enabled', weeklyReportEnabled);
    await prefs.setInt('daily_summary_hour', dailySummaryTime.hour);
    await prefs.setInt('daily_summary_minute', dailySummaryTime.minute);
    await prefs.setInt('weekly_report_weekday', weeklyReportWeekday);
    await prefs.setInt('weekly_report_hour', weeklyReportTime.hour);
    await prefs.setInt('weekly_report_minute', weeklyReportTime.minute);
    await prefs.setString('interruption_level', interruptionLevel);

    // Update iOS 18.6+ notification settings
    await IOS18Service.updateNotificationSettings(
      paymentRemindersEnabled: paymentRemindersEnabled,
      dailySummaryEnabled: dailySummaryEnabled,
      weeklyReportEnabled: weeklyReportEnabled,
      interruptionLevel: interruptionLevel,
      focusModeIntegration: true,
      dynamicIslandEnabled: true,
      liveActivitiesEnabled: true,
    );
  }

  /// Load notification settings
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'paymentRemindersEnabled': prefs.getBool('payment_reminders_enabled') ?? true,
      'dailySummaryEnabled': prefs.getBool('daily_summary_enabled') ?? true,
      'weeklyReportEnabled': prefs.getBool('weekly_report_enabled') ?? true,
      'dailySummaryHour': prefs.getInt('daily_summary_hour') ?? 9,
      'dailySummaryMinute': prefs.getInt('daily_summary_minute') ?? 0,
      'weeklyReportWeekday': prefs.getInt('weekly_report_weekday') ?? DateTime.monday,
      'weeklyReportHour': prefs.getInt('weekly_report_hour') ?? 10,
      'weeklyReportMinute': prefs.getInt('weekly_report_minute') ?? 0,
      'interruptionLevel': prefs.getString('interruption_level') ?? 'active',
    };
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool enabled,
    required bool pendingPayments,
    required bool dailySummary,
    required TimeOfDay reminderTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    await prefs.setBool('notifications_pending_payments', pendingPayments);
    await prefs.setBool('notifications_daily_summary', dailySummary);
    await prefs.setInt('notifications_reminder_hour', reminderTime.hour);
    await prefs.setInt('notifications_reminder_minute', reminderTime.minute);
  }

  // Load notification preferences
  Future<Map<String, dynamic>> loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'pendingPayments': prefs.getBool('notifications_pending_payments') ?? true,
      'dailySummary': prefs.getBool('notifications_daily_summary') ?? true,
      'reminderHour': prefs.getInt('notifications_reminder_hour') ?? 9,
      'reminderMinute': prefs.getInt('notifications_reminder_minute') ?? 0,
    };
  }

  /// Dispose resources
  void dispose() {
    // No timers to dispose since we removed scheduled notifications
  }
} 