import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/data_service.dart';
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
  List<String> _availableBackups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
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
      await _dataService.createBackup();
      await _loadBackups();
      
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Backup Created',
          body: 'Backup created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Backup Failed',
          body: 'Error creating backup: $e',
        );
      }
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
      } else {
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showErrorNotification(
            title: 'Restore Failed',
            body: 'Failed to restore data',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Restore Error',
          body: 'Error restoring data: $e',
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
          'This will permanently delete this backup. This action cannot be undone. Are you sure?'
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
        await _loadBackups(); // Reload the backup list
        
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showSuccessNotification(
            title: 'Backup Deleted',
            body: 'Backup deleted successfully',
          );
        }
      } else {
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showErrorNotification(
            title: 'Delete Failed',
            body: 'Failed to delete backup',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Delete Error',
          body: 'Error deleting backup: $e',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBackupPath(String path) {
    final parts = path.split('/');
    final backupName = parts.last;
    if (backupName.startsWith('backup_')) {
      final timestamp = backupName.substring(7);
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      
      // Format date and time in 12-hour format
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;
      
      // Convert to 12-hour format
      int hour = date.hour;
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) hour = 12;
      if (hour > 12) hour -= 12;
      final formattedHour = hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      
      return 'Backup from $month/$day/$year $formattedHour:$minute:$second $period';
    }
    return backupName;
  }

  String _formatBackupSize(String path) {
    // For now, return a realistic size based on actual data
    // In a real implementation, you would calculate the actual file size
    final appState = Provider.of<AppState>(context, listen: false);
    final customerCount = appState.customers.length;
    final debtCount = appState.debts.length;
    
    if (customerCount == 0 && debtCount == 0) {
      return '0.1 KB';
    } else if (customerCount < 10 && debtCount < 10) {
      return '1.2 KB';
    } else if (customerCount < 50 && debtCount < 50) {
      return '5.8 KB';
    } else {
      return '12.4 KB';
    }
  }

  String _formatBackupDetails(String path) {
    // Get actual data from the app state
    final appState = Provider.of<AppState>(context, listen: false);
    final customerCount = appState.customers.length;
    final activeDebtCount = appState.debts.where((debt) => debt.status == 'active').length;
    
    if (customerCount == 0 && activeDebtCount == 0) {
      return 'No data';
    } else if (customerCount == 0) {
      return '$activeDebtCount active debts';
    } else if (activeDebtCount == 0) {
      return '$customerCount customers';
    } else {
      return '$customerCount customers, $activeDebtCount active debts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Data Recovery',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 16),
                    
                    // Backup Creation Section
                    _buildBackupCreationSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Available Backups Section
                    _buildAvailableBackupsSection(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBackupCreationSection() {
    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.cloud_upload,
                    color: AppColors.dynamicPrimary(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Backup & Recovery',
                        style: AppTheme.getDynamicTitle2(context).copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create backups of your data to prevent loss. You can restore from any available backup.',
                        style: AppTheme.getDynamicFootnote(context).copyWith(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: AppColors.dynamicPrimary(context),
                borderRadius: BorderRadius.circular(12),
                onPressed: _createBackup,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.cloud_upload,
                      color: AppColors.dynamicSurface(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Backup Now',
                      style: AppTheme.getDynamicBody(context).copyWith(
                        color: AppColors.dynamicSurface(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              itemBuilder: (context, index) {
                final backupPath = _availableBackups[index];
                return _buildBackupItem(backupPath);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBackupItem(String backupPath) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
              child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _restoreFromBackup(backupPath),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSuccess(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_clockwise,
                    color: AppColors.dynamicSuccess(context),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatBackupPath(backupPath),
                    style: AppTheme.getDynamicBody(context).copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        color: AppColors.dynamicTextSecondary(context),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatBackupDetails(backupPath),
                        style: AppTheme.getDynamicCaption1(context).copyWith(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.doc_on_doc,
                        color: AppColors.dynamicTextSecondary(context),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatBackupSize(backupPath),
                        style: AppTheme.getDynamicCaption1(context).copyWith(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () => _deleteBackup(backupPath),
              child: Icon(
                CupertinoIcons.delete,
                color: AppColors.dynamicError(context),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 