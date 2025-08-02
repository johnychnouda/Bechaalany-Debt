import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';
import '../models/customer.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  // Enhanced notification methods for different app actions
  Future<void> showSuccessNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      payload: payload,
      category: 'success',
    );
  }

  Future<void> showErrorNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      payload: payload,
      category: 'error',
    );
  }

  Future<void> showInfoNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      payload: payload,
      category: 'info',
    );
  }

  Future<void> showWarningNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      payload: payload,
      category: 'warning',
    );
  }

  // Customer-related notifications
  Future<void> showCustomerAddedNotification(Customer customer) async {
    await showSuccessNotification(
      title: 'Customer Added',
      body: '${customer.name} has been added successfully',
      payload: 'customer_added_${customer.id}',
    );
  }

  Future<void> showCustomerUpdatedNotification(Customer customer) async {
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
  Future<void> showDebtAddedNotification(Debt debt) async {
    await showSuccessNotification(
      title: 'Debt Recorded',
      body: '${debt.customerName} owes ${_formatCurrency(debt.amount)}',
      payload: 'debt_added_${debt.id}',
    );
  }

  Future<void> showDebtUpdatedNotification(Debt debt) async {
    await showSuccessNotification(
      title: 'Debt Updated',
      body: '${debt.customerName}\'s debt has been updated',
      payload: 'debt_updated_${debt.id}',
    );
  }

  Future<void> showDebtPaidNotification(Debt debt) async {
    await showSuccessNotification(
      title: 'Payment Received',
      body: '${debt.customerName} has paid ${_formatCurrency(debt.amount)}',
      payload: 'debt_paid_${debt.id}',
    );
  }

  Future<void> showDebtDeletedNotification(String customerName, double amount) async {
    await showInfoNotification(
      title: 'Debt Removed',
      body: 'Debt of ${_formatCurrency(amount)} for $customerName has been deleted',
      payload: 'debt_deleted',
    );
  }

  // Payment-related notifications
  Future<void> showPaymentAppliedNotification(Debt debt, double paymentAmount) async {
    await showSuccessNotification(
      title: 'Payment Applied',
      body: '${_formatCurrency(paymentAmount)} applied to ${debt.customerName}\'s debt',
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

  // Debt reminder notifications - Removed as per user request

  // Private method to show notifications with proper iOS configuration
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
    required String category,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'app_notifications',
      'App Notifications',
      channelDescription: 'Notifications for app events and actions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'app_actions',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Helper method to format currency
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
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
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
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
} 