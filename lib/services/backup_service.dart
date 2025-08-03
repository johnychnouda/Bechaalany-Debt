import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'notification_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  Timer? _dailyBackupTimer;
  bool _isInitialized = false;

  // Initialize the backup service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if daily backup is enabled
      final prefs = await SharedPreferences.getInstance();
      final isDailyBackupEnabled = prefs.getBool('dailyBackupEnabled') ?? true;
      
      if (isDailyBackupEnabled) {
        await _scheduleDailyBackup();
      }
      
      _isInitialized = true;
    } catch (e) {
      // Handle initialization error
    }
  }

  // Schedule daily backup at 12 AM
  Future<void> _scheduleDailyBackup() async {
    try {
      // Cancel existing timer if any
      _dailyBackupTimer?.cancel();
      
      // Calculate time until next 12 AM
      final now = DateTime.now();
      final nextBackupTime = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
      final timeUntilBackup = nextBackupTime.difference(now);
      
      // Schedule the timer
      _dailyBackupTimer = Timer(timeUntilBackup, () {
        _performDailyBackup();
        // Schedule the next daily backup
        _scheduleDailyBackup();
      });
      
    } catch (e) {
      // Handle scheduling error
    }
  }

  // Perform the daily backup
  Future<void> _performDailyBackup() async {
    try {
      // Create backup
      await _dataService.createBackup();
      
      // Show notification
      await _notificationService.showSuccessNotification(
        title: 'Daily Backup Complete',
        body: 'Your data has been automatically backed up',
      );
      
    } catch (e) {
      // Show error notification
      await _notificationService.showErrorNotification(
        title: 'Daily Backup Failed',
        body: 'Failed to create automatic backup: $e',
      );
    }
  }

  // Enable/disable daily backup
  Future<void> setDailyBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dailyBackupEnabled', enabled);
      
      if (enabled) {
        await _scheduleDailyBackup();
      } else {
        _dailyBackupTimer?.cancel();
        _dailyBackupTimer = null;
      }
    } catch (e) {
      // Handle error
    }
  }

  // Check if daily backup is enabled
  Future<bool> isDailyBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('dailyBackupEnabled') ?? true;
    } catch (e) {
      return false;
    }
  }

  // Get next backup time
  DateTime getNextBackupTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
  }

  // Format backup time for display
  String formatNextBackupTime() {
    final nextBackup = getNextBackupTime();
    final now = DateTime.now();
    final difference = nextBackup.difference(now);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Dispose resources
  void dispose() {
    _dailyBackupTimer?.cancel();
    _dailyBackupTimer = null;
  }
} 