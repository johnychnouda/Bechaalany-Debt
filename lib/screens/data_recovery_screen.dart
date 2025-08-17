import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/data_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
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
  List<String> _availableBackups = [];
  bool _isLoading = false;
  bool _isAutomaticBackupEnabled = true;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final isEnabled = await _backupService.isAutomaticBackupEnabled();
    final lastAutomaticBackup = await _backupService.getLastAutomaticBackupTime();
    
    // Validate backup state - if no backups exist but toggle is ON, fix it
    if (isEnabled && lastAutomaticBackup == null) {
      await _backupService.clearInvalidBackupTimestamps();
      // Reload settings after fixing
      final correctedIsEnabled = await _backupService.isAutomaticBackupEnabled();
      final correctedLastBackup = await _backupService.getLastAutomaticBackupTime();
      
      setState(() {
        _isAutomaticBackupEnabled = correctedIsEnabled;
        _lastBackupTime = correctedLastBackup;
      });
    } else {
      setState(() {
        _isAutomaticBackupEnabled = isEnabled;
        _lastBackupTime = lastAutomaticBackup;
      });
    }
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backups = await _dataService.getAvailableBackups();
      setState(() {
        _availableBackups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Backup Error',
          body: 'Error loading backups: $e',
        );
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.createManualBackup();
      await _loadBackups();
      await _loadBackupSettings();
    } catch (e) {
      // Error notification is handled by backup service
    } finally {
      setState(() {
        _isLoading = false;
      });
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

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _dataService.restoreFromBackup(backupPath);
      
      if (success) {
        // Reload app state
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.initialize();
        
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showSuccessNotification(
            title: 'Data Restored',
            body: 'Data restored successfully',
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Restore Error',
          body: 'Failed to restore data: $e',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _dataService.deleteBackup(backupPath);
      
      if (success) {
        await _loadBackups();
        
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showSuccessNotification(
            title: 'Backup Deleted',
            body: 'Backup file deleted successfully',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Delete Error',
          body: 'Failed to delete backup: $e',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackupSection(),
                    const SizedBox(height: 24),
                    _buildAutomaticBackupSection(),
                    const SizedBox(height: 24),
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
        const SizedBox(height: 12),
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
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.cloud_upload,
                    color: AppColors.dynamicPrimary(context),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Backup',
                        style: AppTheme.getDynamicTitle2(context).copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a backup of all your data',
                        style: AppTheme.getDynamicFootnote(context).copyWith(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 14,
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
                      horizontal: 16,
                      vertical: 8,
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
        const SizedBox(height: 12),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary(context).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.clock,
                        color: AppColors.dynamicPrimary(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Backup at 12 AM',
                            style: AppTheme.getDynamicTitle3(context).copyWith(
                              color: AppColors.dynamicTextPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Automatically backup your data daily',
                            style: AppTheme.getDynamicFootnote(context).copyWith(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 14,
                            ),
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
                      },
                      activeColor: AppColors.dynamicPrimary(context),
                    ),
                  ],
                ),
                if (_lastBackupTime != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicBackground(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.dynamicBorder(context),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 16,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last backup: ${_formatLastBackupTime()}',
                          style: AppTheme.getDynamicFootnote(context).copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                            fontSize: 14,
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
        
        return '$month/$day/$year at $formattedHour:$minute $period';
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
        const SizedBox(height: 12),
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
                      'No backups available. Create your first backup to get started.',
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.dynamicBorder(context),
                width: 0.5,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableBackups.length,
              separatorBuilder: (context, index) => Container(
                height: 0.5,
                color: AppColors.dynamicBorder(context),
              ),
              itemBuilder: (context, index) {
                final backupPath = _availableBackups[index];
                final fileName = backupPath.split('/').last;
                final formattedDate = _formatBackupFileName(fileName);

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface(context),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSuccess(context).withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.doc_text,
                            color: AppColors.dynamicSuccess(context),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: AppTheme.getDynamicBody(context).copyWith(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Backup file',
                                style: AppTheme.getDynamicCaption1(context).copyWith(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            CupertinoButton(
                              onPressed: () => _restoreFromBackup(backupPath),
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicPrimary(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Restore',
                                  style: AppTheme.getDynamicCaption1(context).copyWith(
                                    color: AppColors.dynamicSurface(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              onPressed: () => _deleteBackup(backupPath),
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicError(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Delete',
                                  style: AppTheme.getDynamicCaption1(context).copyWith(
                                    color: AppColors.dynamicSurface(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
              },
            ),
          ),
      ],
    );
  }
} 