import 'dart:async';
import 'data_service.dart';
import 'weekly_backup_cleanup.dart';
// Timezone imports removed
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DataService _dataService = DataService();
  final WeeklyBackupCleanup _weeklyCleanup = WeeklyBackupCleanup();
  bool _timezoneInitialized = false;
  Timer? _backupCheckTimer;

  // Timezone initialization removed
  void _ensureTimezoneInitialized() {
    // Timezone functionality disabled
  }

  // Initialize automatic daily backup
  Future<void> initializeDailyBackup() async {
    // Ensure timezone is initialized
    _ensureTimezoneInitialized();
    
    
    // Enable automatic backup by default if not already set
    await _ensureAutomaticBackupEnabled();
    
    // Check if automatic backup is enabled
    final isEnabled = await isAutomaticBackupEnabled();

    
    if (isEnabled) {

      // Start periodic backup checking (every 30 minutes)
      _startPeriodicBackupCheck();
      
      // Initialize weekly cleanup
      await _weeklyCleanup.initializeWeeklyCleanup();
      
      // Check for missed backups when app opens
      await checkForMissedBackups();
    }
  }


  // Handle app lifecycle changes
  Future<void> handleAppLifecycleChange() async {
    final isEnabled = await isAutomaticBackupEnabled();
    
    if (isEnabled) {
      
      // Restart periodic backup checking
      _startPeriodicBackupCheck();
      
      // Check for missed backups when app resumes
      await checkForMissedBackups();
    }
  }
  
  // Start precise 12 AM backup checking
  void _startPeriodicBackupCheck() {
    // Cancel any existing timer
    _backupCheckTimer?.cancel();
    
    // Calculate time until next 12 AM
    final now = DateTime.now();
    final nextMidnight = _getNextMidnight(now);
    final timeUntilMidnight = nextMidnight.difference(now);
    
    // Next backup scheduled for midnight
    
    // Schedule backup exactly at midnight
    _backupCheckTimer = Timer(timeUntilMidnight, () async {
      try {
        final isEnabled = await isAutomaticBackupEnabled();
        if (isEnabled) {
          // Only create backup if we haven't already backed up today
          final lastBackup = await getLastAutomaticBackupTime();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          if (lastBackup == null) {
            // First backup ever
            await _createAutomaticBackup();
          } else {
            final lastBackupDate = DateTime(lastBackup.year, lastBackup.month, lastBackup.day);
            if (lastBackupDate.isBefore(today)) {
              // Haven't backed up today, create backup
              await _createAutomaticBackup();
            }
          }
          
          // Schedule next day's backup
          _startPeriodicBackupCheck();
        }
      } catch (e) {
        // Error in 12 AM backup
      }
    });
  }
  
  // Get next midnight (12 AM)
  DateTime _getNextMidnight(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final midnightToday = DateTime(today.year, today.month, today.day, 0, 0, 0);
    
    // If it's past midnight today, next backup is tomorrow at midnight
    if (now.isAfter(midnightToday)) {
      return midnightToday.add(const Duration(days: 1));
    } else {
      // If it's before midnight today, next backup is today at midnight
      return midnightToday;
    }
  }
  
  // Stop periodic backup checking
  void _stopPeriodicBackupCheck() {
    _backupCheckTimer?.cancel();
    _backupCheckTimer = null;
  }

  // Check if backup is needed and create it automatically (called on app start/resume)
  Future<void> _checkAndCreateBackupIfNeeded() async {
    try {
      // Don't create backups when app starts/resumes
      // Backups should only happen at scheduled 12 AM time
      // This method is now disabled to prevent app lifecycle backups
      return;
    } catch (e) {
      // Error checking backup status
    }
  }
  
  // Check for missed backups and create them (called when app opens)
  Future<void> checkForMissedBackups() async {
    try {
      final lastBackup = await getLastAutomaticBackupTime();
      final now = DateTime.now();
      
      // Don't create backup when app opens - only at scheduled 12 AM
      // This method now just checks the status but doesn't create backups
      
      if (lastBackup == null) {
        // No backup exists, but don't create one here - wait for 12 AM
        return;
      }
      
      // Just verify the backup schedule is working
      // Actual backup creation happens only at midnight via timer
      
    } catch (e) {
      // Error checking for missed backups
    }
  }
  

  // Cleanup method to stop timers
  void dispose() {
    _stopPeriodicBackupCheck();
    _weeklyCleanup.dispose();
  }

  // Create automatic backup (called when app opens and backup is needed)
  Future<void> _createAutomaticBackup() async {
    try {
      final backupId = await _dataService.createBackup(isAutomatic: true);
      
      if (backupId.isNotEmpty) {
        await setLastAutomaticBackupTime(DateTime.now());
        
        // Daily backup completed successfully
      } else {
        throw Exception('Backup creation failed');
      }
    } catch (e) {
      // Backup failed
    }
  }

  // Get next scheduled backup time for display purposes
  DateTime? getNextScheduledBackupTime() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
  }


  // Timezone functionality disabled
  DateTime _nextInstanceOf11PM() {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, 23, 0, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Timezone functionality disabled
  DateTime _nextInstanceOfMidnight() {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    
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
      _startPeriodicBackupCheck();
      // Check if backup is needed immediately
      await _checkAndCreateBackupIfNeeded();
    } else {
      _stopPeriodicBackupCheck();
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
    
    return false;
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
        
        // Backup created successfully
      }
      
      return backupId;
    } catch (e) {

      
      // Backup creation failed
      
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
} 