import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'data_service.dart';
import 'notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize automatic daily backup
  Future<void> initializeDailyBackup() async {
    print('🚀 Initializing daily backup service...');
    
    // Initialize notifications
    await _initializeNotifications();
    
    // Check if automatic backup is enabled
    final isEnabled = await isAutomaticBackupEnabled();
    print('🚀 Automatic backup enabled: $isEnabled');
    
    if (isEnabled) {
      // Schedule daily backup notification
      await _scheduleDailyBackupNotification();
      print('🚀 Daily backup notification scheduled');
      
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
        print('🔄 No previous backup found, creating first backup...');
        await _createAutomaticBackup();
        return;
      }
      
      // Check if it's been more than 24 hours since last backup
      final timeSinceLastBackup = now.difference(lastBackup);
      final hoursSinceLastBackup = timeSinceLastBackup.inHours;
      
      print('🔄 Hours since last backup: $hoursSinceLastBackup');
      
      if (hoursSinceLastBackup >= 24) {
        print('🔄 More than 24 hours since last backup, creating automatic backup...');
        await _createAutomaticBackup();
      } else {
        print('🔄 Less than 24 hours since last backup, skipping...');
      }
    } catch (e) {
      print('❌ Error checking backup status: $e');
    }
  }

  // Create automatic backup (called when app opens and backup is needed)
  Future<void> _createAutomaticBackup() async {
    try {
      print('🔄 Creating automatic backup...');
      
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        await setLastAutomaticBackupTime(DateTime.now());
        print('✅ Automatic backup created successfully: $backupId');
        
        // Show success notification
        await _notificationService.showSuccessNotification(
          title: 'Daily Backup Complete',
          body: 'Your data has been automatically backed up',
        );
      }
    } catch (e) {
      print('❌ Error creating automatic backup: $e');
      
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
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    print('⏰ Daily backup notification scheduled for: ${nextBackup.toString()}');
  }

  // Get next instance of midnight (12 AM)
  tz.TZDateTime _nextInstanceOfMidnight() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Enable/disable automatic backups
  Future<void> setAutomaticBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('automatic_backup_enabled', enabled);
    
    if (enabled) {
      await _scheduleDailyBackupNotification();
      // Check if backup is needed immediately
      await _checkAndCreateBackupIfNeeded();
    } else {
      await _notifications.cancelAll();
    }
    
    print('✅ Automatic backup ${enabled ? 'enabled' : 'disabled'}');
  }

  // Check if automatic backup is enabled
  Future<bool> isAutomaticBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('automatic_backup_enabled') ?? false;
    return value;
  }

  // Get last automatic backup time
  Future<DateTime?> getLastAutomaticBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_automatic_backup_timestamp');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set last automatic backup time
  Future<void> setLastAutomaticBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_automatic_backup_timestamp', time.millisecondsSinceEpoch);
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
      print('🔍 Searching for backups...');
      final backups = await _dataService.getAvailableBackups();
      print('🔍 Found ${backups.length} backups');
      return backups;
    } catch (e) {
      print('❌ Error getting available backups: $e');
      return [];
    }
  }

  // Get backup metadata
  Future<Map<String, dynamic>?> getBackupMetadata(String backupId) async {
    try {
      return await _dataService.getBackupMetadata(backupId);
    } catch (e) {
      print('❌ Error getting backup metadata: $e');
      return null;
    }
  }

  // Create manual backup
  Future<String?> createManualBackup() async {
    try {
      print('📱 Creating manual backup...');
      final backupId = await _dataService.createBackup(isAutomatic: false);
      
      if (backupId != null) {
        await setLastAutomaticBackupTime(DateTime.now());
        print('✅ Manual backup created successfully: $backupId');
        
        // Show success notification
        await _notificationService.showSuccessNotification(
          title: 'Backup Created',
          body: 'Your data has been backed up successfully',
        );
      }
      
      return backupId;
    } catch (e) {
      print('❌ Error creating manual backup: $e');
      
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
        print('✅ Backup deleted successfully: $backupPath');
      }
      return success;
    } catch (e) {
      print('❌ Error deleting backup: $e');
      return false;
    }
  }

  // Restore from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final success = await _dataService.restoreFromBackup(backupPath);
      if (success) {
        print('✅ Backup restored successfully: $backupPath');
      }
      return success;
    } catch (e) {
      print('❌ Error restoring backup: $e');
      return false;
    }
  }

  // Handle backup notification tap (now just opens the app)
  Future<void> handleBackupNotificationTap() async {
    // The notification now just serves as a reminder to open the app
    // The actual backup creation happens automatically when the app opens
    print('📱 Backup notification tapped - app opened');
    
    // Check if backup is needed
    await _checkAndCreateBackupIfNeeded();
  }
} 