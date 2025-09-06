import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'notification_service.dart';

class BackgroundBackupService {
  static final BackgroundBackupService _instance = BackgroundBackupService._internal();
  factory BackgroundBackupService() => _instance;
  BackgroundBackupService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  // Initialize background backup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure background fetch
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // Minimum 15 minutes between fetches
          stopOnTerminate: false, // Continue running when app is terminated
          enableHeadless: true, // Allow background execution
          startOnBoot: true, // Start when device boots
          requiredNetworkType: NetworkType.NONE, // Work offline
        ),
        _onBackgroundFetch,
        _onBackgroundFetchTimeout,
      );

      // Check if background fetch is available
      final status = await BackgroundFetch.status;
      print('Background fetch status: $status');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing background backup: $e');
    }
  }

  // Background fetch callback
  static Future<void> _onBackgroundFetch(String taskId) async {
    print('Background fetch started: $taskId');
    
    try {
      final service = BackgroundBackupService();
      await service._performBackgroundBackup();
      
      // Mark task as completed
      BackgroundFetch.finish(taskId);
    } catch (e) {
      print('Background backup error: $e');
      BackgroundFetch.finish(taskId);
    }
  }

  // Background fetch timeout callback
  static Future<void> _onBackgroundFetchTimeout(String taskId) async {
    print('Background fetch timeout: $taskId');
    BackgroundFetch.finish(taskId);
  }

  // Perform backup in background
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

      print('Starting background backup...');
      
      // Create backup
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        // Update last backup time
        await _setLastAutomaticBackupTime(DateTime.now());
        
        print('Background backup completed: $backupId');
        
        // Send success notification
        await _notificationService.showSuccessNotification(
          title: 'Background Backup Complete',
          body: 'Your data has been automatically backed up',
        );
      } else {
        print('Background backup failed');
        
        // Send error notification
        await _notificationService.showErrorNotification(
          title: 'Background Backup Failed',
          body: 'Automatic backup could not be completed',
        );
      }
    } catch (e) {
      print('Background backup error: $e');
      
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

  // Start background fetch
  Future<void> start() async {
    try {
      await BackgroundFetch.start();
      print('Background fetch started');
    } catch (e) {
      print('Error starting background fetch: $e');
    }
  }

  // Stop background fetch
  Future<void> stop() async {
    try {
      await BackgroundFetch.stop();
      print('Background fetch stopped');
    } catch (e) {
      print('Error stopping background fetch: $e');
    }
  }

  // Check if background fetch is available
  Future<bool> isAvailable() async {
    try {
      final status = await BackgroundFetch.status;
      return status == 1; // 1 = available, 0 = denied
    } catch (e) {
      print('Error checking background fetch availability: $e');
      return false;
    }
  }

  // Get background fetch status
  Future<int> getStatus() async {
    try {
      return await BackgroundFetch.status;
    } catch (e) {
      print('Error getting background fetch status: $e');
      return 0; // 0 = denied
    }
  }
}
