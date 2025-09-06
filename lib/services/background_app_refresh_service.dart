import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'notification_service.dart';

class BackgroundAppRefreshService {
  static final BackgroundAppRefreshService _instance = BackgroundAppRefreshService._internal();
  factory BackgroundAppRefreshService() => _instance;
  BackgroundAppRefreshService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  Timer? _midnightTimer;

  // Initialize Background App Refresh service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure background fetch with better settings for Background App Refresh
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // Minimum 15 minutes between fetches
          stopOnTerminate: false, // Continue running when app is terminated
          enableHeadless: true, // Allow background execution
          startOnBoot: true, // Start when device boots
          requiredNetworkType: NetworkType.NONE, // Work offline
          forceAlarmManager: false, // Use iOS Background App Refresh
        ),
        _onBackgroundFetch,
        _onBackgroundFetchTimeout,
      );

      // Check if background app refresh is available
      final status = await BackgroundFetch.status;
      print('Background App Refresh status: $status');

      // Schedule midnight backup check
      await _scheduleMidnightBackup();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing Background App Refresh: $e');
    }
  }

  // Background fetch callback - called by iOS when Background App Refresh runs
  static Future<void> _onBackgroundFetch(String taskId) async {
    print('Background App Refresh started: $taskId');
    
    try {
      final service = BackgroundAppRefreshService();
      await service._performBackgroundBackup();
      
      // Mark task as completed
      BackgroundFetch.finish(taskId);
    } catch (e) {
      print('Background App Refresh error: $e');
      BackgroundFetch.finish(taskId);
    }
  }

  // Background fetch timeout callback
  static Future<void> _onBackgroundFetchTimeout(String taskId) async {
    print('Background App Refresh timeout: $taskId');
    BackgroundFetch.finish(taskId);
  }

  // Schedule midnight backup check using local timer
  Future<void> _scheduleMidnightBackup() async {
    try {
      // Cancel existing timer
      _midnightTimer?.cancel();

      // Calculate next midnight
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
      
      // Calculate duration until next midnight
      final duration = nextMidnight.difference(now);
      
      print('Scheduling next backup check at: $nextMidnight');
      print('Time until next check: ${duration.inHours}h ${duration.inMinutes % 60}m');

      // Schedule timer for next midnight
      _midnightTimer = Timer(duration, () async {
        await _checkAndCreateMidnightBackup();
        // Reschedule for next day
        await _scheduleMidnightBackup();
      });
    } catch (e) {
      print('Error scheduling midnight backup: $e');
    }
  }

  // Check and create backup at midnight
  Future<void> _checkAndCreateMidnightBackup() async {
    try {
      print('Midnight backup check triggered');
      
      // Check if automatic backup is enabled
      final isEnabled = await _isAutomaticBackupEnabled();
      if (!isEnabled) {
        print('Automatic backup is disabled');
        return;
      }

      // Check if backup is needed
      final needsBackup = await _checkIfBackupNeeded();
      if (!needsBackup) {
        print('Backup not needed at midnight');
        return;
      }

      print('Creating midnight backup...');
      
      // Create backup
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        // Update last backup time
        await _setLastAutomaticBackupTime(DateTime.now());
        
        print('Midnight backup completed: $backupId');
        
        // Send success notification
        await _notificationService.showSuccessNotification(
          title: 'Midnight Backup Complete',
          body: 'Your data has been automatically backed up at midnight',
        );
      } else {
        print('Midnight backup failed');
        
        // Send error notification
        await _notificationService.showErrorNotification(
          title: 'Midnight Backup Failed',
          body: 'Automatic backup could not be completed at midnight',
        );
      }
    } catch (e) {
      print('Midnight backup error: $e');
      
      // Send error notification
      await _notificationService.showErrorNotification(
        title: 'Midnight Backup Error',
        body: 'An error occurred during midnight backup',
      );
    }
  }

  // Perform backup in background (called by iOS Background App Refresh)
  Future<void> _performBackgroundBackup() async {
    try {
      // Check if automatic backup is enabled
      final isEnabled = await _isAutomaticBackupEnabled();
      if (!isEnabled) {
        print('Automatic backup is disabled');
        return;
      }

      // Check if backup is needed
      final needsBackup = await _checkIfBackupNeeded();
      if (!needsBackup) {
        print('Backup not needed at this time');
        return;
      }

      print('Starting Background App Refresh backup...');
      
      // Create backup
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        // Update last backup time
        await _setLastAutomaticBackupTime(DateTime.now());
        
        print('Background App Refresh backup completed: $backupId');
        
        // Send success notification
        await _notificationService.showSuccessNotification(
          title: 'Background Backup Complete',
          body: 'Your data has been automatically backed up',
        );
      } else {
        print('Background App Refresh backup failed');
        
        // Send error notification
        await _notificationService.showErrorNotification(
          title: 'Background Backup Failed',
          body: 'Automatic backup could not be completed',
        );
      }
    } catch (e) {
      print('Background App Refresh backup error: $e');
      
      // Send error notification
      await _notificationService.showErrorNotification(
        title: 'Background Backup Error',
        body: 'An error occurred during automatic backup',
      );
    }
  }

  // Check if automatic backup is enabled
  Future<bool> _isAutomaticBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('automatic_backup_enabled') ?? false;
    } catch (e) {
      print('Error checking backup setting: $e');
      return false;
    }
  }

  // Check if backup is needed
  Future<bool> _checkIfBackupNeeded() async {
    try {
      final lastBackup = await _getLastAutomaticBackupTime();
      final now = DateTime.now();
      
      if (lastBackup == null) {
        // No backup exists, create one
        return true;
      }
      
      // Check if it's time for the next scheduled backup (12 AM)
      final today = DateTime(now.year, now.month, now.day);
      final lastBackupDate = DateTime(lastBackup.year, lastBackup.month, lastBackup.day);
      
      // If we haven't backed up today and it's past midnight, create backup
      return lastBackupDate.isBefore(today);
    } catch (e) {
      print('Error checking backup need: $e');
      return false;
    }
  }

  // Get last automatic backup time
  Future<DateTime?> _getLastAutomaticBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_automatic_backup_timestamp');
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      print('Error getting last backup time: $e');
      return null;
    }
  }

  // Set last automatic backup time
  Future<void> _setLastAutomaticBackupTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_automatic_backup_timestamp', time.millisecondsSinceEpoch);
    } catch (e) {
      print('Error setting last backup time: $e');
    }
  }

  // Start Background App Refresh
  Future<void> start() async {
    try {
      await BackgroundFetch.start();
      print('Background App Refresh started');
    } catch (e) {
      print('Error starting Background App Refresh: $e');
    }
  }

  // Stop Background App Refresh
  Future<void> stop() async {
    try {
      await BackgroundFetch.stop();
      _midnightTimer?.cancel();
      print('Background App Refresh stopped');
    } catch (e) {
      print('Error stopping Background App Refresh: $e');
    }
  }

  // Check if Background App Refresh is available
  Future<bool> isAvailable() async {
    try {
      final status = await BackgroundFetch.status;
      return status == 1; // 1 = available, 0 = denied
    } catch (e) {
      print('Error checking Background App Refresh availability: $e');
      return false;
    }
  }

  // Get Background App Refresh status
  Future<int> getStatus() async {
    try {
      return await BackgroundFetch.status;
    } catch (e) {
      print('Error getting Background App Refresh status: $e');
      return 0; // 0 = denied
    }
  }

  // Get next scheduled backup time
  DateTime? getNextScheduledBackupTime() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
  }

  // Dispose resources
  void dispose() {
    _midnightTimer?.cancel();
  }
}
