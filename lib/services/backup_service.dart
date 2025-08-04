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
    final nextBackup = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    
    final delay = nextBackup.difference(now);
    
    _dailyBackupTimer = Timer(delay, () {
      _performDailyBackup();
      // Schedule the next backup
      _scheduleNextDayBackup();
    });
    
    debugPrint('Daily backup scheduled for: $nextBackup (in ${delay.inHours}h ${delay.inMinutes % 60}m)');
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
    
    debugPrint('Next daily backup scheduled for: $nextBackup');
  }

  Future<void> _performDailyBackup() async {
    try {
      debugPrint('Starting automatic daily backup...');
      
      // Create backup
      await _dataService.createBackup();
      
      // Show notification
      await _notificationService.showSuccessNotification(
        title: 'Daily Backup Complete',
        body: 'Your data has been automatically backed up',
      );
      
      debugPrint('Daily backup completed successfully');
      
    } catch (e) {
      debugPrint('Error during daily backup: $e');
      
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

  // Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_backup_timestamp');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set last backup time
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

  // Dispose resources
  void dispose() {
    _dailyBackupTimer?.cancel();
  }
} 