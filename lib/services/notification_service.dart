import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';

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

  Future<void> scheduleDebtReminders(List<Debt> dueToday, List<Debt> overdue) async {
    if (!_isInitialized) await initialize();

    // Cancel existing notifications
    await _notifications.cancelAll();

    // For now, just show immediate notifications instead of scheduling
    // This avoids timezone issues and is simpler for testing
    for (final debt in dueToday) {
      await showImmediateNotification(
        title: 'Payment Due Today',
        body: '${debt.customerName} owes \$${debt.amount.toStringAsFixed(0)}',
        payload: debt.id,
      );
    }

    for (final debt in overdue) {
      await showImmediateNotification(
        title: 'Payment Overdue',
        body: '${debt.customerName} owes \$${debt.amount.toStringAsFixed(0)} (${_getDaysOverdue(debt)} days overdue)',
        payload: debt.id,
      );
    }

    if (dueToday.isNotEmpty || overdue.isNotEmpty) {
      await showImmediateNotification(
        title: 'Daily Debt Summary',
        body: '${dueToday.length} payments due today, ${overdue.length} overdue',
        payload: 'summary',
      );
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'immediate_notifications',
      'Immediate Notifications',
      channelDescription: 'Immediate notifications for app events',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
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

  int _getDaysOverdue(Debt debt) {
    final now = DateTime.now();
    final dueDate = DateTime(debt.dueDate.year, debt.dueDate.month, debt.dueDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(dueDate).inDays;
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool enabled,
    required bool dueToday,
    required bool overdue,
    required bool dailySummary,
    required TimeOfDay reminderTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    await prefs.setBool('notifications_due_today', dueToday);
    await prefs.setBool('notifications_overdue', overdue);
    await prefs.setBool('notifications_daily_summary', dailySummary);
    await prefs.setInt('notifications_reminder_hour', reminderTime.hour);
    await prefs.setInt('notifications_reminder_minute', reminderTime.minute);
  }

  // Load notification preferences
  Future<Map<String, dynamic>> loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'dueToday': prefs.getBool('notifications_due_today') ?? true,
      'overdue': prefs.getBool('notifications_overdue') ?? true,
      'dailySummary': prefs.getBool('notifications_daily_summary') ?? true,
      'reminderHour': prefs.getInt('notifications_reminder_hour') ?? 9,
      'reminderMinute': prefs.getInt('notifications_reminder_minute') ?? 0,
    };
  }
} 