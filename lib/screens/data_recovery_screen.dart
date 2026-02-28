import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
  static const String _arabicIndicNumerals = '٠١٢٣٤٥٦٧٨٩';

  static String _toArabicNumerals(String s) {
    return s.replaceAllMapped(RegExp(r'\d'), (m) => _arabicIndicNumerals[int.parse(m.group(0)!)]);
  }

  static String _formatNumbersForLocale(BuildContext context, String s) {
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return _toArabicNumerals(s);
    }
    return s;
  }

  final DataService _dataService = DataService();
  final BackupService _backupService = BackupService();
  // Background services removed - no longer needed
  List<String> _availableBackups = [];
  Map<String, Map<String, dynamic>> _backupMetadata = {};
  bool _isAutomaticBackupEnabled = false;
  bool _isBackgroundBackupAvailable = false;
  bool _isBackgroundAppRefreshAvailable = false;
  DateTime? _lastBackupTime;
  int _nextBackupHours = 0;
  int _nextBackupMinutes = 0;
  int _nextBackupSeconds = 0;

  // Timer to automatically refresh the countdown every second
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

    if (hours != _nextBackupHours || minutes != _nextBackupMinutes || seconds != _nextBackupSeconds) {
      setState(() {
        _nextBackupHours = hours;
        _nextBackupMinutes = minutes;
        _nextBackupSeconds = seconds;
      });
    }
  }

  String _formatNextBackupCountdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = _nextBackupHours.toString();
    final m = _nextBackupMinutes.toString().padLeft(2, '0');
    final s = _nextBackupSeconds.toString().padLeft(2, '0');
    final timeStr = '${h}${l10n.hoursShort} ${m}${l10n.minutesShort} ${s}${l10n.secondsShort}';
    return _formatNumbersForLocale(context, timeStr);
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return CupertinoAlertDialog(
          title: Text(l10n.restoreData),
          content: Text(l10n.restoreDataConfirm),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: Text(l10n.restore),
            ),
          ],
        );
      },
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return CupertinoAlertDialog(
          title: Text(l10n.deleteBackup),
          content: Text(l10n.deleteBackupConfirm),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: Text(l10n.delete),
            ),
          ],
        );
      },
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
          AppLocalizations.of(context)!.dataRecovery,
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
          AppLocalizations.of(context)!.manualBackup,
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
                        AppLocalizations.of(context)!.createBackup,
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
                      AppLocalizations.of(context)!.backupButton,
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
          AppLocalizations.of(context)!.automaticBackup,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Text(
                        AppLocalizations.of(context)!.dailyBackupAt12AM,
                        style: AppTheme.getDynamicTitle3(context).copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        AppLocalizations.of(context)!.nextBackupIn(_formatNextBackupCountdown(context)),
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
                          AppLocalizations.of(context)!.lastBackup(_formatLastBackupTime(context)),
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

  String _formatLastBackupTime(BuildContext context) {
    if (_lastBackupTime == null) return AppLocalizations.of(context)!.never;

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final backupDate = DateTime(_lastBackupTime!.year, _lastBackupTime!.month, _lastBackupTime!.day);

    final locale = Localizations.localeOf(context).toString();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final timeFormat = intl.DateFormat.jm(locale);
    String timeString = timeFormat.format(_lastBackupTime!);
    if (isArabic) timeString = _toArabicNumerals(timeString);

    if (backupDate == today) {
      return l10n.todayAtTime(timeString);
    } else if (backupDate == yesterday) {
      return l10n.yesterdayAtTime(timeString);
    } else {
      final dateFormat = intl.DateFormat.yMMMd(locale);
      String dateStr = dateFormat.format(_lastBackupTime!);
      if (isArabic) dateStr = _toArabicNumerals(dateStr);
      return l10n.dateAtTime(dateStr, timeString);
    }
  }


  String _formatBackupFileName(BuildContext context, String fileName) {
    // Extract timestamp from backup filename (e.g., "backup_1754326124601")
    if (fileName.startsWith('backup_')) {
      try {
        final timestamp = fileName.substring(7); // Remove "backup_" prefix
        final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
        final locale = Localizations.localeOf(context).toString();
        final formatter = intl.DateFormat.yMd(locale).add_jm();
        String result = formatter.format(dateTime);
        if (Localizations.localeOf(context).languageCode == 'ar') {
          result = _toArabicNumerals(result);
        }
        return result;
      } catch (e) {
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
          AppLocalizations.of(context)!.availableBackups,
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
                          ? AppLocalizations.of(context)!.noBackupsAvailable
                          : AppLocalizations.of(context)!.signInToViewBackups,
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
              final formattedDate = _formatBackupFileName(context, fileName);
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
                                isAutomatic
                                    ? AppLocalizations.of(context)!.automaticBackupLabel
                                    : AppLocalizations.of(context)!.manualBackupLabel,
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
                                  AppLocalizations.of(context)!.restore,
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
                                  AppLocalizations.of(context)!.delete,
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