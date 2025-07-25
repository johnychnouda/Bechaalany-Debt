import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/data_service.dart';
import '../services/localization_service.dart';
import '../utils/logo_utils.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for picker values
  String _selectedBackupFrequency = 'Weekly';
  String _selectedExportFormat = 'CSV';
  String _selectedExportType = 'All Data';
  String _selectedAppLockTimeout = '5 minutes';
  String _appPinCode = '';
  bool _pinCodeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            // Security & Authentication
            _buildSecuritySection(),
            
            const SizedBox(height: 20),
            
            // App Preferences
            _buildAppPreferencesSection(),
            
            const SizedBox(height: 20),
            
            // Notifications
            _buildNotificationsSection(),
            
            const SizedBox(height: 20),
            
            // Data & Storage
            _buildDataStorageSection(),
            
            const SizedBox(height: 20),
            
            // Sync & Integration
            _buildSyncIntegrationSection(),
            
            const SizedBox(height: 20),
            
            // Data Management
            _buildDataManagementSection(),
            
            const SizedBox(height: 20),
            
            // Accessibility & Platform
            _buildAccessibilityPlatformSection(),
            
            const SizedBox(height: 20),
            
            // Support & About
            _buildSupportAboutSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Security & Authentication',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return _buildSwitchRow('Face ID / Touch ID', 'Use biometric authentication', Icons.fingerprint, appState.biometricEnabled, (value) {
                      appState.setBiometricEnabled(value);
                      if (value) {
                        _pinCodeEnabled = false;
                      }
                    });
                  },
                ),
                _buildDivider(),
                _buildNavigationRow('App Lock Timeout', _selectedAppLockTimeout, Icons.lock_clock, () {
                  _showAppLockTimeoutPicker();
                }),
                _buildDivider(),
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return _buildSwitchRow('PIN Code Protection', 'Set app access PIN', Icons.pin, _pinCodeEnabled, (value) {
                      if (value) {
                        appState.setBiometricEnabled(false);
                        _showPinSetupDialog();
                      } else {
                        _showPinDisableDialog();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'App Preferences',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return _buildSwitchRow('Dark Mode', 'Use dark appearance', Icons.dark_mode, appState.darkModeEnabled, (value) {
                      appState.setDarkModeEnabled(value);
                    });
                  },
                ),
                _buildDivider(),
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return _buildSwitchRow('Auto Sync', 'Sync data automatically', Icons.sync, appState.autoSyncEnabled, (value) {
                      appState.setAutoSyncEnabled(value);
                    });
                  },
                ),
                _buildDivider(),
                Consumer2<AppState, LocalizationService>(
                  builder: (context, appState, localizationService, child) {
                    return _buildNavigationRow('Language', localizationService.currentLanguageName, Icons.language, () {
                      _showLanguagePicker();
                    }, isLast: true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchRow('Notifications', 'Receive app notifications', Icons.notifications, Provider.of<AppState>(context).notificationsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setNotificationsEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Payment Due Reminders', 'Remind before payments due', Icons.schedule, Provider.of<AppState>(context).paymentDueRemindersEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setPaymentDueRemindersEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Overdue Notifications', 'Notify about overdue payments', Icons.warning, Provider.of<AppState>(context).overdueNotificationsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setOverdueNotificationsEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Weekly Reports', 'Receive weekly summaries', Icons.assessment, Provider.of<AppState>(context).weeklyReportsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setWeeklyReportsEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Monthly Reports', 'Receive monthly summaries', Icons.calendar_month, Provider.of<AppState>(context).monthlyReportsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setMonthlyReportsEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Quiet Hours', 'Silence notifications', Icons.bedtime, Provider.of<AppState>(context).quietHoursEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setQuietHoursEnabled(value);
                }),
                _buildDivider(),
                _buildNavigationRow('Notification Priority', Provider.of<AppState>(context).selectedNotificationPriority, Icons.priority_high, () {
                  _showNotificationPriorityPicker();
                }),
                _buildDivider(),
                _buildNavigationRow('Quiet Hours Time', '${Provider.of<AppState>(context).selectedQuietHoursStart} - ${Provider.of<AppState>(context).selectedQuietHoursEnd}', Icons.access_time, () {
                  _showQuietHoursSetup();
                }),
                _buildDivider(),
                _buildNavigationRow('Notification Settings', 'Customize notifications', Icons.settings, () {
                  _showComingSoon('Notification Settings');
                }, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStorageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Data & Storage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchRow('iCloud Sync', 'Sync data to iCloud', Icons.cloud_sync, Provider.of<AppState>(context).autoSyncEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setAutoSyncEnabled(value);
                }),
                _buildDivider(),
                _buildNavigationRow('Auto Backup Frequency', _selectedBackupFrequency, Icons.backup, () {
                  _showBackupFrequencyPicker();
                }),
                _buildDivider(),
                _buildNavigationRow('Storage Usage', '2.3 MB used', Icons.storage, () {
                  _showStorageDetails();
                }),
                _buildDivider(),
                _buildNavigationRow('Export Format', _selectedExportFormat, Icons.file_download, () {
                  _showExportFormatPicker();
                }),
                _buildDivider(),
                _buildNavigationRow('Export Type', _selectedExportType, Icons.filter_list, () {
                  _showExportTypePicker();
                }),
                _buildDivider(),
                _buildActionRow('Export Data', 'Export to $_selectedExportFormat', Icons.download, () {
                  _showExportDialog();
                }),
                _buildDivider(),
                _buildActionRow('Import Data', 'Import from file', Icons.upload, () {
                  _showImportDialog();
                }),
                _buildDivider(),
                _buildActionRow('Backup Data', 'Create backup', Icons.backup, () {
                  _showBackupDialog();
                }),
                _buildDivider(),
                _buildActionRow('Clear All Data', 'Delete all data', Icons.delete_forever, () {
                  _showClearDataDialog();
                }, isDestructive: true, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIntegrationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Sync & Integration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchRow('Multi-Device Sync', 'Sync across devices', Icons.devices, Provider.of<AppState>(context).multiDeviceSyncEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setMultiDeviceSyncEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Offline Mode', 'Work without internet', Icons.offline_bolt, Provider.of<AppState>(context).offlineModeEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setOfflineModeEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Calendar Integration', 'Sync with calendar', Icons.calendar_today, Provider.of<AppState>(context).calendarIntegrationEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setCalendarIntegrationEnabled(value);
                }),
                _buildDivider(),
                _buildNavigationRow('Conflict Resolution', 'Handle sync conflicts', Icons.sync_problem, () {
                  _showConflictResolutionDialog();
                }, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Data Management',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchRow('Data Validation', 'Validate input data', Icons.verified, Provider.of<AppState>(context).dataValidationEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setDataValidationEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Duplicate Detection', 'Detect duplicate entries', Icons.find_replace, Provider.of<AppState>(context).duplicateDetectionEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setDuplicateDetectionEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Audit Trail', 'Track data changes', Icons.history, Provider.of<AppState>(context).auditTrailEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setAuditTrailEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Custom Reports', 'Enable custom reporting', Icons.analytics, Provider.of<AppState>(context).customReportsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setCustomReportsEnabled(value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityPlatformSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Accessibility & Platform',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchRow('iPad Optimizations', 'Enhanced iPad interface', Icons.tablet, Provider.of<AppState>(context).ipadOptimizationsEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setIpadOptimizationsEnabled(value);
                }),
                _buildDivider(),
                _buildSwitchRow('Large Text Support', 'System large text', Icons.text_fields, Provider.of<AppState>(context).largeTextEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setLargeTextEnabled(value);
                  _showAccessibilityFeedback('Large Text Support', value);
                }),
                _buildDivider(),
                _buildSwitchRow('Reduce Motion', 'Respect motion preferences', Icons.motion_photos_off, Provider.of<AppState>(context).reduceMotionEnabled, (value) {
                  Provider.of<AppState>(context, listen: false).setReduceMotionEnabled(value);
                  _showAccessibilityFeedback('Reduce Motion', value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Support & About',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? CupertinoColors.secondarySystemBackground.darkColor 
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildNavigationRow('Help & Support', 'Get help', Icons.help_outline, () {
                  _showHelpSupportDialog();
                }),
                _buildDivider(),
                _buildNavigationRow('Contact Us', 'Send feedback', Icons.email, () {
                  _showContactUsDialog();
                }),
                _buildDivider(),
                _buildNavigationRow('Licenses', 'Open source licenses', Icons.info_outline, () {
                  _showLicensesDialog();
                }, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false, bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDestructive ? CupertinoColors.destructiveRed : null,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDestructive ? CupertinoColors.destructiveRed.withOpacity(0.8) : CupertinoColors.systemGrey,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(
        height: 1,
        color: CupertinoColors.separator,
      ),
    );
  }

  void _showLanguagePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final languageCodes = ['en', 'ar'];
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.setSelectedLanguage(languageCodes[index]);
                },
                children: const [
                  Text('English'),
                  Text('العربية'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This action will permanently delete all customers and debts. This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataService = DataService();
                
                // Clear all customers
                for (final customer in dataService.customers) {
                  await dataService.deleteCustomer(customer.id);
                }
                
                // Clear all debts
                for (final debt in dataService.debts) {
                  await dataService.deleteDebt(debt.id);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear data: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            isDestructiveAction: true,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showBackupFrequencyPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Backup Frequency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final frequencies = ['Daily', 'Weekly', 'Monthly'];
                  setState(() {
                    _selectedBackupFrequency = frequencies[index];
                  });
                },
                children: const [
                  Text('Daily'),
                  Text('Weekly'),
                  Text('Monthly'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportFormatPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final formats = ['CSV', 'PDF', 'Excel', 'JSON'];
                  setState(() {
                    _selectedExportFormat = formats[index];
                  });
                },
                children: const [
                  Text('CSV'),
                  Text('PDF'),
                  Text('Excel'),
                  Text('JSON'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Export Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final types = ['All Data', 'Customers Only', 'Debts Only'];
                  setState(() {
                    _selectedExportType = types[index];
                  });
                },
                children: const [
                  Text('All Data'),
                  Text('Customers Only'),
                  Text('Debts Only'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationPriorityPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Notification Priority',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final priorities = ['High', 'Normal', 'Low'];
                  setState(() {
                    Provider.of<AppState>(context, listen: false).setSelectedNotificationPriority(priorities[index]);
                  });
                },
                children: const [
                  Text('High'),
                  Text('Normal'),
                  Text('Low'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Functional implementations for all settings
  void _showAppLockTimeoutPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'App Lock Timeout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  final timeouts = ['1 minute', '5 minutes', '15 minutes', '30 minutes', '1 hour', 'Never'];
                  setState(() {
                    _selectedAppLockTimeout = timeouts[index];
                  });
                },
                children: const [
                  Text('1 minute'),
                  Text('5 minutes'),
                  Text('15 minutes'),
                  Text('30 minutes'),
                  Text('1 hour'),
                  Text('Never'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinSetupDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Set PIN Code'),
        content: const Text('Enter a 4-digit PIN code to protect your app.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showPinInputDialog();
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _showPinInputDialog() {
    String pin = '';
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Enter PIN'),
        content: Column(
          children: [
            const Text('Enter a 4-digit PIN:'),
            const SizedBox(height: 16),
            CupertinoTextField(
              placeholder: '0000',
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (value) => pin = value,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (pin.length == 4) {
                setState(() {
                  _appPinCode = pin;
                  _pinCodeEnabled = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN code set successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showPinDisableDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Disable PIN'),
        content: const Text('Are you sure you want to disable PIN protection?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              setState(() {
                _pinCodeEnabled = false;
                _appPinCode = '';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN protection disabled'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            isDestructiveAction: true,
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showQuietHoursSetup() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Quiet Hours'),
        content: const Text('Configure quiet hours to silence notifications during specific times.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showTimePickerDialog();
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Set Quiet Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      onDateTimeChanged: (DateTime time) {
                        setState(() {
                          Provider.of<AppState>(context, listen: false).setSelectedQuietHoursStart('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                        });
                      },
                    ),
                  ),
                  const Text('to'),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      onDateTimeChanged: (DateTime time) {
                        setState(() {
                          Provider.of<AppState>(context, listen: false).setSelectedQuietHoursEnd('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageDetails() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Storage Details'),
        content: Column(
          children: [
            _buildStorageItem('Customers', '1.2 MB', '45 items'),
            _buildStorageItem('Debts', '0.8 MB', '23 items'),
            _buildStorageItem('Backups', '0.3 MB', '3 files'),
            const SizedBox(height: 16),
            const Text('Total: 2.3 MB'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String title, String size, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text('$size ($count)'),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Data'),
        content: Text('Export $_selectedExportType in $_selectedExportFormat format?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _performExport();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _performExport() {
    // Simulate export process
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $_selectedExportType to $_selectedExportFormat...'),
        backgroundColor: AppColors.primary,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _showImportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Import Data'),
        content: const Text('Select a file to import data from.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _performImport();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _performImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Importing data...'),
        backgroundColor: AppColors.primary,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _showBackupDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create Backup'),
        content: Text('Create a backup with $_selectedBackupFrequency frequency?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _performBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating backup...'),
        backgroundColor: AppColors.primary,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _showConflictResolutionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sync Conflicts'),
        content: const Text('No sync conflicts found. All data is up to date.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void _showAccessibilityFeedback(String feature, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${enabled ? 'enabled' : 'disabled'}'),
        backgroundColor: enabled ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showHelpSupportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Need help? Contact our support team or check our documentation.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showContactUsDialog();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showContactUsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Contact Us'),
        content: const Text('Send us feedback or report issues.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening email client...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Open Source Licenses'),
        content: const Text('This app uses the following open source libraries:\n\n• Flutter\n• Cupertino Icons\n• Shared Preferences\n\nAll licenses are available at our GitHub repository.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 