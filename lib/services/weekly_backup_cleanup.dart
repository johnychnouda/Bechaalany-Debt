import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Notification service import removed

class WeeklyBackupCleanup {
  static final WeeklyBackupCleanup _instance = WeeklyBackupCleanup._internal();
  factory WeeklyBackupCleanup() => _instance;
  WeeklyBackupCleanup._internal();

  // Notification service removed
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _weeklyCleanupTimer;

  // Initialize weekly cleanup scheduler
  Future<void> initializeWeeklyCleanup() async {
    try {
      await _scheduleNextCleanup();
    } catch (e) {
      // Handle error silently
    }
  }

  // Schedule next cleanup for Sunday 2 AM
  Future<void> _scheduleNextCleanup() async {
    _weeklyCleanupTimer?.cancel();
    
    final now = DateTime.now();
    final nextSunday = _getNextSunday2AM(now);
    final timeUntilCleanup = nextSunday.difference(now);
    
    _weeklyCleanupTimer = Timer(timeUntilCleanup, () async {
      await _deleteAllBackups();
      // Reschedule for next week
      await _scheduleNextCleanup();
    });
  }

  DateTime _getNextSunday2AM(DateTime now) {
    // Find next Sunday
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    
    // Set to 2:00 AM
    final sunday2AM = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 2, 0, 0);
    
    // If it's already past 2 AM on Sunday, schedule for next Sunday
    if (now.weekday == DateTime.sunday && now.hour >= 2) {
      return sunday2AM.add(Duration(days: 7));
    }
    
    return sunday2AM;
  }

  // Delete all backups
  Future<void> _deleteAllBackups() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all backups
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .get();

      if (snapshot.docs.isEmpty) {
        return; // No backups to delete
      }

      int deletedCount = 0;
      
      // Delete all backups
      for (final doc in snapshot.docs) {
        try {
          await doc.reference.delete();
          deletedCount++;
        } catch (e) {
          // Continue with other backups if one fails
        }
      }

      // Show notification
      if (deletedCount > 0) {
        // Weekly cleanup completed successfully
      }
    } catch (e) {
      // Cleanup failed
    }
  }

  // Manual cleanup trigger
  Future<void> runManualCleanup() async {
    await _deleteAllBackups();
  }

  // Get next scheduled cleanup time
  DateTime? getNextScheduledCleanupTime() {
    final now = DateTime.now();
    return _getNextSunday2AM(now);
  }

  // Dispose resources
  void dispose() {
    _weeklyCleanupTimer?.cancel();
  }
}
