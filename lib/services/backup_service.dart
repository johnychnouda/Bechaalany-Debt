import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'notification_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Timer? _dailyBackupTimer;
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();

  // Initialize automatic daily backup
  Future<void> initializeDailyBackup() async {
    // Cancel any existing timer
    _dailyBackupTimer?.cancel();
    
    // Schedule daily backup at 12 AM
    _scheduleDailyBackup();
    
    // Also schedule backup for tomorrow if app is running
    _scheduleNextDayBackup();
  }

  void _scheduleDailyBackup() {
    final now = DateTime.now();
    
    // Calculate next backup time (12 AM today or tomorrow)
    DateTime nextBackup;
    if (now.hour >= 12) {
      // If it's past 12 PM, schedule for 12 AM tomorrow
      nextBackup = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    } else {
      // If it's before 12 PM, schedule for 12 AM today
      nextBackup = DateTime(now.year, now.month, now.day, 0, 0, 0);
    }
    
    final delay = nextBackup.difference(now);
    
    _dailyBackupTimer = Timer(delay, () {
      _performDailyBackup();
      // Schedule the next backup
      _scheduleNextDayBackup();
    });
    

  }

  void _scheduleNextDayBackup() {
    _dailyBackupTimer?.cancel();
    
    final now = DateTime.now();
    final nextBackup = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    
    final delay = nextBackup.difference(now);
    
    _dailyBackupTimer = Timer(delay, () {
      _performDailyBackup();
      // Schedule the next backup
      _scheduleNextDayBackup();
    });
    

  }

  Future<void> _performDailyBackup() async {
    try {

      
      // Check if we already have a backup today to prevent duplicates
      final lastBackup = await getLastAutomaticBackupTime();
      if (lastBackup != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastBackupDate = DateTime(lastBackup.year, lastBackup.month, lastBackup.day);
        
        if (lastBackupDate == today) {
          return;
        }
      }
      
      // Create backup
      await _dataService.createBackup();
      
      // Update last automatic backup time
      await setLastAutomaticBackupTime(DateTime.now());
      
      // Show notification
      await _notificationService.showSuccessNotification(
        title: 'Daily Backup Complete',
        body: 'Your data has been automatically backed up',
      );
      

      
    } catch (e) {
      
      // Show error notification
      await _notificationService.showErrorNotification(
        title: 'Backup Failed',
        body: 'Daily backup failed: $e',
      );
    }
  }

  // Enable/disable automatic backups
  Future<void> setAutomaticBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('automatic_backup_enabled', enabled);
    
    if (enabled) {
      await initializeDailyBackup();
    } else {
      _dailyBackupTimer?.cancel();
    }
  }

  // Check if automatic backup is enabled
  Future<bool> isAutomaticBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('automatic_backup_enabled') ?? true; // Default to enabled
  }

  // Get last automatic backup time - with validation that backup actually exists
  Future<DateTime?> getLastAutomaticBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_automatic_backup_timestamp');
    
    if (timestamp == null) return null;
    
    final storedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Validate that a backup actually exists for this timestamp
    final dataService = DataService();
    final backups = await dataService.getAvailableBackups();
    
    // Check if any backup exists with a timestamp close to the stored time
    for (final backup in backups) {
      try {
        final fileName = backup.split('/').last;
        if (fileName.startsWith('backup_')) {
          final backupTimestamp = fileName.substring(7);
          final backupTime = DateTime.fromMillisecondsSinceEpoch(int.parse(backupTimestamp));
          
          // If backup time is within 5 minutes of stored time, consider it valid
          if (backupTime.difference(storedTime).inMinutes.abs() <= 5) {
            return storedTime;
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    // No valid backup found, clear the invalid timestamp
    await prefs.remove('last_automatic_backup_timestamp');
    
    return null;
  }

  // Set last automatic backup time
  Future<void> setLastAutomaticBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_automatic_backup_timestamp', time.millisecondsSinceEpoch);
  }

  // Get last manual backup time (for backward compatibility)
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_backup_timestamp');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set last backup time (for backward compatibility)
  Future<void> setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_backup_timestamp', time.millisecondsSinceEpoch);
  }

  // Manual backup with notification
  Future<void> createManualBackup() async {
    try {
      await _dataService.createBackup();
      await setLastBackupTime(DateTime.now());
      
      await _notificationService.showSuccessNotification(
        title: 'Backup Created',
        body: 'Manual backup completed successfully',
      );
    } catch (e) {
      await _notificationService.showErrorNotification(
        title: 'Backup Failed',
        body: 'Manual backup failed: $e',
      );
      rethrow;
    }
  }

  // Clean up duplicate backups from today (keep only the latest one)
  Future<void> cleanupDuplicateBackupsFromToday() async {
    try {
      final dataService = DataService();
      final backups = await dataService.getAvailableBackups();
      
      if (backups.isEmpty) return;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Group backups by date
      final backupsByDate = <String, List<String>>{};
      
      for (final backup in backups) {
        try {
          // Extract timestamp from backup path
          final fileName = backup.split('/').last;
          if (fileName.startsWith('backup_')) {
            final timestamp = fileName.substring(7);
            final backupDate = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
            final backupDateOnly = DateTime(backupDate.year, backupDate.month, backupDate.day);
            
            final dateKey = '${backupDate.year}-${backupDate.month.toString().padLeft(2, '0')}-${backupDate.day.toString().padLeft(2, '0')}';
            backupsByDate.putIfAbsent(dateKey, () => []).add(backup);
          }
        } catch (e) {
          // Skip invalid backup names
          continue;
        }
      }
      
      // For each date, keep only the latest backup and delete the rest
      for (final dateKey in backupsByDate.keys) {
        final dateBackups = backupsByDate[dateKey]!;
        if (dateBackups.length > 1) {
          // Sort by timestamp (newest first)
          dateBackups.sort((a, b) => b.compareTo(a));
          
          // Keep the first (newest) one, delete the rest
          for (int i = 1; i < dateBackups.length; i++) {
            await dataService.deleteBackup(dateBackups[i]);
    
          }
        }
      }
      
      // Special case: If today is 08/18/2025 and we have multiple backups, 
      // keep only the latest one and delete the 1:33 AM backup
      if (today.year == 2025 && today.month == 8 && today.day == 18) {
        final todaysBackups = backupsByDate['2025-08-18'] ?? [];
        if (todaysBackups.isNotEmpty) {
          // Keep only the latest backup for today
          final latestBackup = todaysBackups.first;
          for (final backup in todaysBackups) {
            if (backup != latestBackup) {
              await dataService.deleteBackup(backup);
      
            }
          }
        }
      }
    } catch (e) {

    }
  }

  // Force cleanup of all backups except the latest one for today
  Future<void> forceCleanupTodayBackups() async {
    try {
      final dataService = DataService();
      final backups = await dataService.getAvailableBackups();
      
      if (backups.isEmpty) return;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Find all backups from today
      final todaysBackups = <String>[];
      
      for (final backup in backups) {
        try {
          final fileName = backup.split('/').last;
          if (fileName.startsWith('backup_')) {
            final timestamp = fileName.substring(7);
            final backupDate = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
            final backupDateOnly = DateTime(backupDate.year, backupDate.month, backupDate.day);
            
            if (backupDateOnly == today) {
              todaysBackups.add(backup);
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      if (todaysBackups.length > 1) {
        // Sort by timestamp (newest first)
        todaysBackups.sort((a, b) => b.compareTo(a));
        
        // Keep only the latest backup, delete all others
        final latestBackup = todaysBackups.first;
        for (int i = 1; i < todaysBackups.length; i++) {
          await dataService.deleteBackup(todaysBackups[i]);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Clear all invalid backup timestamps when no backup files exist
  Future<void> clearInvalidBackupTimestamps() async {
    try {
      final dataService = DataService();
      final backups = await dataService.getAvailableBackups();
      
      if (backups.isEmpty) {
        // No backup files exist, clear all stored timestamps
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_automatic_backup_timestamp');
        await prefs.remove('last_backup_timestamp');

        // If automatic backup is enabled but no backups exist, disable it
        final isEnabled = await isAutomaticBackupEnabled();
        if (isEnabled) {
          await setAutomaticBackupEnabled(false);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Specifically remove the problematic 1:33 AM backup from 08/18/2025
  Future<void> removeSpecificBackup() async {
    try {
      final dataService = DataService();
      final backups = await dataService.getAvailableBackups();
      
      for (final backup in backups) {
        try {
          final fileName = backup.split('/').last;
          if (fileName.startsWith('backup_')) {
            final timestamp = fileName.substring(7);
            final backupDate = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
            
            // Check if this is the 1:33 AM backup from 08/18/2025
            if (backupDate.year == 2025 && 
                backupDate.month == 8 && 
                backupDate.day == 18 && 
                backupDate.hour == 1 && 
                backupDate.minute == 33) {
              
              await dataService.deleteBackup(backup);
              return;
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Dispose resources
  void dispose() {
    _dailyBackupTimer?.cancel();
  }
} 