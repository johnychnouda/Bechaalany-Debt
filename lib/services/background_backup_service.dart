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

      _isInitialized = true;
    } catch (e) {
    }
  }

  // Background fetch callback
  static Future<void> _onBackgroundFetch(String taskId) async {
    
    try {
      final service = BackgroundBackupService();
      await service._performBackgroundBackup();
      
      // Mark task as completed
      BackgroundFetch.finish(taskId);
    } catch (e) {
      BackgroundFetch.finish(taskId);
    }
  }

  // Background fetch timeout callback
  static Future<void> _onBackgroundFetchTimeout(String taskId) async {
    BackgroundFetch.finish(taskId);
  }

  // Perform backup in background
  Future<void> _performBackgroundBackup() async {
    try {
      // Check if automatic backup is enabled
      final isEnabled = await _isAutomaticBackupEnabled();
      if (!isEnabled) {
        return;
      }

      // Check if backup is needed
      final needsBackup = await _checkIfBackupNeeded();
      if (!needsBackup) {
        return;
      }

      
      // Create backup
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId != null) {
        // Update last backup time
        await _setLastAutomaticBackupTime(DateTime.now());
        
        
        // Send success notification
        await _notificationService.showSuccessNotification(
          title: 'Background Backup Complete',
          body: 'Your data has been automatically backed up',
        );
      } else {
        
        // Send error notification
        await _notificationService.showErrorNotification(
          title: 'Background Backup Failed',
          body: 'Automatic backup could not be completed',
        );
      }
    } catch (e) {
      
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
      return null;
    }
  }

  // Set last automatic backup time
  Future<void> _setLastAutomaticBackupTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_automatic_backup_timestamp', time.millisecondsSinceEpoch);
    } catch (e) {
    }
  }

  // Start background fetch
  Future<void> start() async {
    try {
      await BackgroundFetch.start();
    } catch (e) {
    }
  }

  // Stop background fetch
  Future<void> stop() async {
    try {
      await BackgroundFetch.stop();
    } catch (e) {
    }
  }

  // Check if background fetch is available
  Future<bool> isAvailable() async {
    try {
      final status = await BackgroundFetch.status;
      return status == 1; // 1 = available, 0 = denied
    } catch (e) {
      return false;
    }
  }

  // Get background fetch status
  Future<int> getStatus() async {
    try {
      return await BackgroundFetch.status;
    } catch (e) {
      return 0; // 0 = denied
    }
  }
}
