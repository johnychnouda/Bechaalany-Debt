import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data_service.dart';
// Notification service import removed

class BackgroundAppRefreshService {
  static final BackgroundAppRefreshService _instance = BackgroundAppRefreshService._internal();
  factory BackgroundAppRefreshService() => _instance;
  BackgroundAppRefreshService._internal();

  final DataService _dataService = DataService();
  // Notification service removed
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

      // Schedule midnight backup check
      await _scheduleMidnightBackup();

      _isInitialized = true;
    } catch (e) {
    }
  }

  // Background fetch callback - called by iOS when Background App Refresh runs
  static Future<void> _onBackgroundFetch(String taskId) async {
    
    try {
      final service = BackgroundAppRefreshService();
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
      

      // Schedule timer for next midnight
      _midnightTimer = Timer(duration, () async {
        await _checkAndCreateMidnightBackup();
        // Reschedule for next day
        await _scheduleMidnightBackup();
      });
    } catch (e) {
    }
  }

  // Check and create backup at midnight
  Future<void> _checkAndCreateMidnightBackup() async {
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
        
        
        // Backup completed successfully
      } else {
        
        // Backup failed
      }
    } catch (e) {
      
      // Backup error occurred
    }
  }

  // Perform backup in background (called by iOS Background App Refresh)
  Future<void> _performBackgroundBackup() async {
    try {
      final now = DateTime.now();
      
      // Only allow backups at midnight (12:00 AM to 12:01 AM)
      final isAroundMidnight = now.hour == 0 && now.minute <= 1;
      if (!isAroundMidnight) {
        return; // Not midnight, don't backup
      }
      
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
        
        // Backup completed successfully
      } else {
        // Backup failed
      }
    } catch (e) {
      // Backup error occurred
    }
  }

  // Check if automatic backup is enabled
  Future<bool> _isAutomaticBackupEnabled() async {
    try {
      // SharedPreferences removed - using Firebase only
      return true; // Default to enabled
    } catch (e) {
      return true; // Default to enabled even on error
    }
  }

  // Check if backup is needed
  Future<bool> _checkIfBackupNeeded() async {
    try {
      final lastBackup = await _getLastAutomaticBackupTime();
      final now = DateTime.now();
      
      // Only create backup if:
      // 1. It's exactly midnight (12 AM) - within a 1-minute window
      // 2. We haven't backed up today
      
      // Check if it's around midnight (12:00 AM to 12:01 AM)
      final isAroundMidnight = now.hour == 0 && now.minute <= 1;
      
      if (!isAroundMidnight) {
        return false; // Not midnight, don't backup
      }
      
      if (lastBackup == null) {
        // No backup exists and it's midnight, create one
        return true;
      }
      
      final today = DateTime(now.year, now.month, now.day);
      final lastBackupDate = DateTime(lastBackup.year, lastBackup.month, lastBackup.day);
      
      // Only backup if we haven't backed up today and it's midnight
      return lastBackupDate.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  // Get last automatic backup time
  Future<DateTime?> _getLastAutomaticBackupTime() async {
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
      return null;
    }
    return null;
  }

  // Set last automatic backup time
  Future<void> _setLastAutomaticBackupTime(DateTime time) async {
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
      // Error saving setting
    }
  }

  // Start Background App Refresh
  Future<void> start() async {
    
    try {
      await BackgroundFetch.start();
    } catch (e) {
    }
  }

  // Stop Background App Refresh
  Future<void> stop() async {
    
    try {
      await BackgroundFetch.stop();
      _midnightTimer?.cancel();
    } catch (e) {
    }
  }

  // Check if Background App Refresh is available
  Future<bool> isAvailable() async {
    
    try {
      final status = await BackgroundFetch.status;
      return status == 1; // 1 = available, 0 = denied
    } catch (e) {
      return false;
    }
  }

  // Get Background App Refresh status
  Future<int> getStatus() async {
    
    try {
      return await BackgroundFetch.status;
    } catch (e) {
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
