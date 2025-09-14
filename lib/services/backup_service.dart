import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'data_service.dart';
import 'notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _timezoneInitialized = false;

  // Ensure timezone is initialized
  void _ensureTimezoneInitialized() {
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  // Initialize automatic daily backup
  Future<void> initializeDailyBackup() async {
    // Ensure timezone is initialized
    _ensureTimezoneInitialized();
    
    // Initialize notifications
    await _initializeNotifications();
    
    // Enable automatic backup by default if not already set
    await _ensureAutomaticBackupEnabled();
    
    // Check if automatic backup is enabled
    final isEnabled = await isAutomaticBackupEnabled();

    
    if (isEnabled) {
      // Schedule daily backup notification
      await _scheduleDailyBackupNotification();

      
      // Check if we need to create a backup now (app just opened)
      await _checkAndCreateBackupIfNeeded();
    }
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
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
  }

  // Handle app lifecycle changes
  Future<void> handleAppLifecycleChange() async {
    final isEnabled = await isAutomaticBackupEnabled();
    
    if (isEnabled) {
      // Re-schedule notification when app comes to foreground
      await _scheduleDailyBackupNotification();
      
      // Check if we need to create a backup (app resumed)
      await _checkAndCreateBackupIfNeeded();
    }
  }

  // Check if backup is needed and create it automatically
  Future<void> _checkAndCreateBackupIfNeeded() async {
    try {
      final lastBackup = await getLastAutomaticBackupTime();
      final now = DateTime.now();
      
      if (lastBackup == null) {
        // No backup exists, create one

        await _createAutomaticBackup();
        return;
      }
      
      // Check if it's time for the next scheduled backup (12 AM)
      final today = DateTime(now.year, now.month, now.day);
      final lastBackupDate = DateTime(lastBackup.year, lastBackup.month, lastBackup.day);
      
      // If we haven't backed up today and it's past midnight, create backup
      if (lastBackupDate.isBefore(today)) {

        await _createAutomaticBackup();
      } else {

      }
    } catch (e) {

    }
  }

  // Create automatic backup (called when app opens and backup is needed)
  Future<void> _createAutomaticBackup() async {
    try {

      
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        await setLastAutomaticBackupTime(DateTime.now());

        
        // Show success notification
        await _notificationService.showSuccessNotification(
          title: 'Daily Backup Complete',
          body: 'Your data has been automatically backed up',
        );
      }
    } catch (e) {

      
      // Show error notification
      await _notificationService.showErrorNotification(
        title: 'Backup Failed',
        body: 'Automatic backup failed: $e',
      );
    }
  }

  // Get next scheduled backup time for display purposes
  DateTime? getNextScheduledBackupTime() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
  }

  // Schedule daily backup notification at 12 AM
  Future<void> _scheduleDailyBackupNotification() async {
    // Ensure timezone is initialized
    _ensureTimezoneInitialized();
    
    // Cancel any existing notifications
    await _notifications.cancelAll();
    
    // Calculate next 12 AM
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextBackup = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
    
    // Schedule notification
    await _notifications.zonedSchedule(
      1001, // Unique ID for backup notification
      'Daily Backup Reminder',
      'Open the app to create your daily backup and keep your data safe',
      _nextInstanceOfMidnight(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'backup_channel',
          'Backup Reminders',
          channelDescription: 'Daily backup reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    

  }

  // Get next instance of midnight (12 AM)
  tz.TZDateTime _nextInstanceOfMidnight() {
    // Ensure timezone is initialized
    _ensureTimezoneInitialized();
    
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Enable/disable automatic backups
  Future<void> setAutomaticBackupEnabled(bool enabled) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
          'automatic_backup_enabled': enabled,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error saving setting
    }
    
    if (enabled) {
      await _scheduleDailyBackupNotification();
      // Check if backup is needed immediately
      await _checkAndCreateBackupIfNeeded();
    } else {
      await _notifications.cancelAll();
    }
  }

  // Ensure automatic backup is enabled by default
  Future<void> _ensureAutomaticBackupEnabled() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        // Only set if not already set (preserve user's choice if they've changed it)
        if (!doc.exists || !doc.data()!.containsKey('automatic_backup_enabled')) {
          await FirebaseFirestore.instance
              .collection('user_settings')
              .doc(user.uid)
              .set({
            'automatic_backup_enabled': true,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if automatic backup is enabled
  Future<bool> isAutomaticBackupEnabled() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          return doc.data()!['automatic_backup_enabled'] ?? true; // Default to enabled
        }
      }
    } catch (e) {
      // Return default on error
    }
    return true; // Default to enabled
  }

  // Get last automatic backup time
  Future<DateTime?> getLastAutomaticBackupTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final timestamp = doc.data()!['last_automatic_backup_time'];
          return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
        }
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  // Set last automatic backup time
  Future<void> setLastAutomaticBackupTime(DateTime time) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
          'last_automatic_backup_time': time.millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error saving time
    }
  }

  // Get last manual backup time
  Future<DateTime?> getLastManualBackupTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final timestamp = doc.data()!['last_manual_backup_time'];
          return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
        }
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  // Set last manual backup time
  Future<void> setLastManualBackupTime(DateTime time) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(user.uid)
            .set({
          'last_manual_backup_time': time.millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error saving time
    }
  }

  // Check if the backup service is already initialized
  bool get isInitialized => true;

  // Check if the backup service is in a valid state
  Future<bool> isInValidState() async {
    final isEnabled = await isAutomaticBackupEnabled();
    
    if (!isEnabled) {
      return true; // If disabled, state is valid
    }
    
    // Check if notification is scheduled
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.any((notification) => notification.id == 1001);
  }

  // Get available backups
  Future<List<String>> getAvailableBackups() async {
    try {

      final backups = await _dataService.getAvailableBackups();

      return backups;
    } catch (e) {

      return [];
    }
  }

  // Get backup metadata
  Future<Map<String, dynamic>?> getBackupMetadata(String backupId) async {
    try {
      return await _dataService.getBackupMetadata(backupId);
    } catch (e) {

      return null;
    }
  }

  // Create manual backup
  Future<String?> createManualBackup() async {
    try {

      final backupId = await _dataService.createBackup(isAutomatic: false);
      
      if (backupId != null) {
        // Track manual backup time separately
        await setLastManualBackupTime(DateTime.now());
        
        // Show success notification
        await _notificationService.showSuccessNotification(
          title: 'Backup Created',
          body: 'Your data has been backed up successfully',
        );
      }
      
      return backupId;
    } catch (e) {

      
      // Show error notification
      await _notificationService.showErrorNotification(
        title: 'Backup Failed',
        body: 'Failed to create backup: $e',
      );
      
      return null;
    }
  }

  // Delete backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final success = await _dataService.deleteBackup(backupPath);
      if (success) {

      }
      return success;
    } catch (e) {

      return false;
    }
  }

  // Restore from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final success = await _dataService.restoreFromBackup(backupPath);
      if (success) {

      }
      return success;
    } catch (e) {

      return false;
    }
  }

  // Handle backup notification tap (now just opens the app)
  Future<void> handleBackupNotificationTap() async {
    // The notification now just serves as a reminder to open the app
    // The actual backup creation happens automatically when the app opens

    
    // Check if backup is needed
    await _checkAndCreateBackupIfNeeded();
  }
} 