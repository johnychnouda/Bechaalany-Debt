import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/data_service.dart';
import '../services/backup_service.dart';
// Background services removed - no longer needed
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class DataRecoveryScreen extends StatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  State<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends State<DataRecoveryScreen> {
  final DataService _dataService = DataService();
  final BackupService _backupService = BackupService();
  // Background services removed - no longer needed
  List<String> _availableBackups = [];
  Map<String, Map<String, dynamic>> _backupMetadata = {};
  bool _isAutomaticBackupEnabled = false;
  bool _isBackgroundBackupAvailable = false;
  bool _isBackgroundAppRefreshAvailable = false;
  DateTime? _lastBackupTime;
  String _nextBackupTime = '';
  
  // Timer to automatically refresh the countdown every minute
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Load everything without showing any loader
    _loadBackups();
    // Delay loading backup settings to ensure backup service is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadBackupSettings();
        _calculateNextBackupTime();
        _startAutoRefresh();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBackupSettings() async {
    try {
      final isEnabled = await _backupService.isAutomaticBackupEnabled();
      final lastAutomaticBackupTime = await _backupService.getLastAutomaticBackupTime();
      final lastManualBackupTime = await _backupService.getLastManualBackupTime();
      // Background services removed - no longer available
      final isBackgroundAvailable = false;
      final isBackgroundAppRefreshAvailable = false;
      
      // Show the most recent backup time (either manual or automatic)
      DateTime? mostRecentBackup;
      if (lastAutomaticBackupTime != null && lastManualBackupTime != null) {
        mostRecentBackup = lastAutomaticBackupTime.isAfter(lastManualBackupTime) 
            ? lastAutomaticBackupTime 
            : lastManualBackupTime;
      } else if (lastAutomaticBackupTime != null) {
        mostRecentBackup = lastAutomaticBackupTime;
      } else if (lastManualBackupTime != null) {
        mostRecentBackup = lastManualBackupTime;
      }
      
      setState(() {
        _isAutomaticBackupEnabled = isEnabled;
        _isBackgroundBackupAvailable = isBackgroundAvailable;
        _isBackgroundAppRefreshAvailable = isBackgroundAppRefreshAvailable;
        _lastBackupTime = mostRecentBackup;
      });
      
      // If automatic backup is enabled, calculate the next backup time
      if (isEnabled) {
        _calculateNextBackupTime();
      }
    } catch (e) {
      // Retry after a short delay if there's an error
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _loadBackupSettings();
        }
      });
    }
  }

  void _calculateNextBackupTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final midnightToday = DateTime(today.year, today.month, today.day, 0, 0, 0);
    final midnightTomorrow = midnightToday.add(const Duration(days: 1));
    
    // If it's past midnight today, next backup is tomorrow at midnight
    // If it's before midnight today, next backup is today at midnight
    final nextBackup = now.isAfter(midnightToday) ? midnightTomorrow : midnightToday;
    final timeRemaining = nextBackup.difference(now);
    
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    final seconds = timeRemaining.inSeconds % 60;
    
    final newTimeString = '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    
    // Only update state if the time string has changed
    if (_nextBackupTime != newTimeString) {
      setState(() {
        _nextBackupTime = newTimeString;
      });
      

    }
  }

  // Start automatic refresh timer
  void _startAutoRefresh() {
    // Refresh countdown every second for real-time countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isAutomaticBackupEnabled) {
        _calculateNextBackupTime();
      }
    });
    
    // Also verify state every 5 seconds to ensure sync
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _verifyAndSyncBackupState();
      }
    });
  }

  // Verify backup service state and sync with UI
  Future<void> _verifyAndSyncBackupState() async {
    try {
      final serviceState = await _backupService.isAutomaticBackupEnabled();
      
      if (serviceState != _isAutomaticBackupEnabled) {
        setState(() {
          _isAutomaticBackupEnabled = serviceState;
        });
        
        if (serviceState) {
          _calculateNextBackupTime();
          _refreshTimer?.cancel();
          _startAutoRefresh();
        } else {
          _refreshTimer?.cancel();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }









  Future<void> _loadBackups() async {
    // Load backups without showing any loader
    try {
      final backups = await _backupService.getAvailableBackups();
      
      // Load metadata for each backup
      final metadata = <String, Map<String, dynamic>>{};
      for (final backupId in backups) {
        try {
          final backupMeta = await _backupService.getBackupMetadata(backupId);
          if (backupMeta != null) {
            metadata[backupId] = backupMeta;
          }
        } catch (e) {
          // Handle error silently
        }
      }
      
      setState(() {
        _availableBackups = backups;
        _backupMetadata = metadata;
      });
    } catch (e) {
      // Handle error silently - no loader, no notification
      setState(() {
        _availableBackups = [];
        _backupMetadata = {};
      });
    }
  }


  Future<void> _createBackup() async {
    try {
      await _backupService.createManualBackup();
      await _loadBackups();
      // Refresh backup settings to update last backup time
      await _loadBackupSettings();
    } catch (e) {
      // Error notification is handled by backup service
    }
  }

  Future<void> _restoreFromBackup(String backupPath) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'This will replace all current data with the backup. This action cannot be undone. Are you sure?'
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _backupService.restoreFromBackup(backupPath);
      
      if (success) {
        // Reload app state
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.initialize();
        
        // Refresh backup settings
        await _loadBackupSettings();
        
        if (mounted) {
          // Backup restored successfully
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        // Restore error occurred
      }
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Backup'),
        content: const Text(
          'This will permanently delete the backup file. This action cannot be undone. Are you sure?'
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _backupService.deleteBackup(backupPath);
      
      if (success) {
        await _loadBackups();
        
        if (mounted) {
          // Backup deleted successfully
        }
      }
    } catch (e) {
      if (mounted) {
        // Delete error occurred
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Data Recovery',
          style: AppTheme.getDynamicTitle2(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackupSection(),
              const SizedBox(height: 20),
              _buildAutomaticBackupSection(),
              const SizedBox(height: 20),
              _buildAvailableBackupsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Backup',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    CupertinoIcons.cloud_upload,
                    color: AppColors.dynamicPrimary(context),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Backup',
                        style: AppTheme.getDynamicTitle3(context).copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ],
                  ),
                ),
                CupertinoButton(
                  onPressed: _createBackup,
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Backup',
                      style: AppTheme.getDynamicBody(context).copyWith(
                        color: AppColors.dynamicSurface(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomaticBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic Backup',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary(context).withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        CupertinoIcons.clock,
                        color: AppColors.dynamicPrimary(context),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:                                                   Text(
                          _isBackgroundAppRefreshAvailable 
                              ? 'Daily Background App Refresh at 12 AM'
                              : _isBackgroundBackupAvailable 
                                  ? 'Daily Background Backup at 12 AM'
                                  : 'Daily Backup at 12 AM',
                          style: AppTheme.getDynamicTitle3(context).copyWith(
                            color: AppColors.dynamicTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                          value: _isAutomaticBackupEnabled,
                          onChanged: (value) async {
                            await _backupService.setAutomaticBackupEnabled(value);
                            
                            setState(() {
                              _isAutomaticBackupEnabled = value;
                            });
                            
                            // Recalculate next backup time when toggle changes
                            if (value) {
                              _calculateNextBackupTime();
                              // Restart auto-refresh for the new state
                              _refreshTimer?.cancel();
                              _startAutoRefresh();
                            } else {
                              // Cancel timer when turning off
                              _refreshTimer?.cancel();
                            }
                            
                            // Verify the state was actually saved
                            await Future.delayed(const Duration(milliseconds: 100));
                            await _backupService.isAutomaticBackupEnabled();
                          },
                          activeColor: AppColors.dynamicPrimary(context),
                        ),
                  ],
                ),
                if (_isAutomaticBackupEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicBackground(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.dynamicBorder(context),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Next backup in: $_nextBackupTime',
                        style: AppTheme.getDynamicFootnote(context).copyWith(
                          color: AppColors.dynamicPrimary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_lastBackupTime != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicBackground(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.dynamicBorder(context),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 14,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last backup: ${_formatLastBackupTime()}',
                          style: AppTheme.getDynamicFootnote(context).copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],



              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatLastBackupTime() {
    if (_lastBackupTime == null) return 'Never';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final backupDate = DateTime(_lastBackupTime!.year, _lastBackupTime!.month, _lastBackupTime!.day);
    
    // Convert to 12-hour format with AM/PM and seconds
    int hour12 = _lastBackupTime!.hour == 0 ? 12 : (_lastBackupTime!.hour > 12 ? _lastBackupTime!.hour - 12 : _lastBackupTime!.hour);
    String minute = _lastBackupTime!.minute.toString().padLeft(2, '0');
    String second = _lastBackupTime!.second.toString().padLeft(2, '0');
    String ampm = _lastBackupTime!.hour < 12 ? 'am' : 'pm';
    String timeString = '$hour12:$minute:$second $ampm';
    
    if (backupDate == today) {
      return 'Today at $timeString';
    } else if (backupDate == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      // Show full date and time for backups older than yesterday
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      String month = months[_lastBackupTime!.month - 1];
      String day = _lastBackupTime!.day.toString().padLeft(2, '0');
      String year = _lastBackupTime!.year.toString();
      
      return '$month $day, $year at $timeString';
    }
  }


  String _formatBackupFileName(String fileName) {
    // Extract timestamp from backup filename (e.g., "backup_1754326124601")
    if (fileName.startsWith('backup_')) {
      try {
        final timestamp = fileName.substring(7); // Remove "backup_" prefix
        final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
        
        // Format date and time in 12-hour format
        final month = dateTime.month.toString().padLeft(2, '0');
        final day = dateTime.day.toString().padLeft(2, '0');
        final year = dateTime.year;
        
        // Convert to 12-hour format
        int hour = dateTime.hour;
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        if (hour > 12) hour -= 12;
        final formattedHour = hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        
        return '$month/$day/$year $formattedHour:$minute $period';
      } catch (e) {
        // If parsing fails, return the original filename
        return fileName;
      }
    }
    return fileName;
  }

  Widget _buildAvailableBackupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Backups',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (_availableBackups.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.dynamicBorder(context),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicTextSecondary(context).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.info_circle,
                      color: AppColors.dynamicTextSecondary(context),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Provider.of<AppState>(context, listen: false).isAuthenticated
                          ? 'No backups available. Create your first backup to get started.'
                          : 'Please sign in to view and manage your backups.',
                      style: AppTheme.getDynamicFootnote(context).copyWith(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _availableBackups.asMap().entries.map((entry) {
              final index = entry.key;
              final backupPath = entry.value;
              final fileName = backupPath.split('/').last;
              final formattedDate = _formatBackupFileName(fileName);
              final metadata = _backupMetadata[backupPath];
              final isAutomatic = metadata?['isAutomatic'] ?? false;
              final backupType = metadata?['backupType'] ?? 'manual';

                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface(context),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.dynamicBorder(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isAutomatic ? CupertinoIcons.clock : CupertinoIcons.doc_text,
                          color: isAutomatic 
                              ? AppColors.dynamicPrimary(context)
                              : AppColors.dynamicSuccess(context),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedDate,
                                style: AppTheme.getDynamicCaption1(context).copyWith(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isAutomatic ? 'Automatic backup' : 'Manual backup',
                                style: AppTheme.getDynamicCaption1(context).copyWith(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoButton(
                              onPressed: () => _restoreFromBackup(backupPath),
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicPrimary(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Restore',
                                  style: AppTheme.getDynamicCaption1(context).copyWith(
                                    color: AppColors.dynamicSurface(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            CupertinoButton(
                              onPressed: () => _deleteBackup(backupPath),
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicError(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Delete',
                                  style: AppTheme.getDynamicCaption1(context).copyWith(
                                    color: AppColors.dynamicSurface(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
            }).toList(),
          ),
      ],
    );
  }
} 