import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'data_service.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        await _notificationService.showBackupCreatedNotification();
      } else {
        
        // Send error notification
        await _notificationService.showBackupFailedNotification('Automatic backup could not be completed');
      }
    } catch (e) {
      
      // Send error notification
      await _notificationService.showBackupFailedNotification('An error occurred during automatic backup');
    }
  }

  // Check if automatic backup is enabled
  Future<bool> _isAutomaticBackupEnabled() async {
    try {
      // SharedPreferences removed - using Firebase only
      return true; // Default value
    } catch (e) {
      return true; // Default to enabled even on error
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
      // SharedPreferences removed - using Firebase only
      final timestamp = 0; // Default value
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      return null;
    }
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
          'background_backup_enabled': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error saving setting
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
