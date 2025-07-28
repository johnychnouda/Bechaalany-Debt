import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.settings),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.info_circle),
          onPressed: () => _showAppInfo(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            
            // Appearance & Accessibility
            _buildSection(
              'Appearance & Accessibility',
              [
                _buildSwitchRow(
                  'Dark Mode',
                  'Use dark appearance',
                  CupertinoIcons.moon,
                  Provider.of<AppState>(context).isDarkMode,
                  (value) => Provider.of<AppState>(context, listen: false).setDarkModeEnabled(value),
                ),
                _buildSwitchRow(
                  'Bold Text',
                  'Use bold text throughout',
                  CupertinoIcons.textformat_size,
                  Provider.of<AppState>(context).boldTextEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setBoldTextEnabled(value),
                ),
                _buildSwitchRow(
                  'Reduce Motion',
                  'Minimize animations',
                  CupertinoIcons.speedometer,
                  Provider.of<AppState>(context).reduceMotionEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setReduceMotionEnabled(value),
                ),
                _buildNavigationRow(
                  'Text Size',
                  'Adjust text size',
                  CupertinoIcons.textformat_abc,
                  () => _showTextSizeDialog(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Notifications
            _buildSection(
              'Notifications',
              [
                _buildSwitchRow(
                  'Enable Notifications',
                  'Receive payment reminders',
                  CupertinoIcons.bell,
                  Provider.of<AppState>(context).notificationsEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setNotificationsEnabled(value),
                ),
                if (Provider.of<AppState>(context).notificationsEnabled) ...[
                  _buildSwitchRow(
                    'Payment Due Reminders',
                    'Get notified about due payments',
                    CupertinoIcons.clock,
                    Provider.of<AppState>(context).paymentDueRemindersEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setPaymentDueRemindersEnabled(value),
                  ),
                  _buildSwitchRow(
                    'Weekly Reports',
                    'Receive weekly summaries',
                    CupertinoIcons.calendar,
                    Provider.of<AppState>(context).weeklyReportsEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setWeeklyReportsEnabled(value),
                  ),
                  _buildSwitchRow(
                    'Monthly Reports',
                    'Receive monthly summaries',
                    CupertinoIcons.calendar_badge_plus,
                    Provider.of<AppState>(context).monthlyReportsEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setMonthlyReportsEnabled(value),
                  ),
                  _buildSwitchRow(
                    'Quiet Hours',
                    'Silence notifications at night',
                    CupertinoIcons.moon_zzz,
                    Provider.of<AppState>(context).quietHoursEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setQuietHoursEnabled(value),
                  ),
                  if (Provider.of<AppState>(context).quietHoursEnabled) ...[
                    _buildNavigationRow(
                      'Quiet Hours Time',
                      '${Provider.of<AppState>(context).quietHoursStart} - ${Provider.of<AppState>(context).quietHoursEnd}',
                      CupertinoIcons.time,
                      () => _showQuietHoursDialog(),
                    ),
                  ],
                ],
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Data & Storage
            _buildSection(
              'Data & Storage',
              [
                _buildSwitchRow(
                  'iCloud Sync',
                  'Sync data across devices',
                  CupertinoIcons.cloud,
                  Provider.of<AppState>(context).iCloudSyncEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setICloudSyncEnabled(value),
                ),
                if (Provider.of<AppState>(context).iCloudSyncEnabled) ...[
                  _buildInfoRow(
                    'Sync Status',
                    _getCloudKitStatusText(context),
                    CupertinoIcons.info_circle,
                  ),
                ],
                _buildNavigationRow(
                  'Storage Usage',
                  'Detailed storage breakdown',
                  CupertinoIcons.chart_bar,
                  () => _showStorageUsage(),
                ),
                _buildNavigationRow(
                  'Cache Management',
                  'Clear app cache',
                  CupertinoIcons.trash,
                  () => _showCacheManagement(),
                ),
                _buildNavigationRow(
                  'Export Data',
                  'Save to Files app',
                  CupertinoIcons.square_arrow_up,
                  () => _showExportDialog(),
                ),
                _buildNavigationRow(
                  'Import Data',
                  'Import from Files app',
                  CupertinoIcons.square_arrow_down,
                  () => _showImportDialog(),
                ),
                _buildActionRow(
                  'Clear All Data',
                  'Delete all data permanently',
                  CupertinoIcons.delete,
                  () => _showClearDataDialog(),
                  isDestructive: true,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Currency & Localization
            _buildSection(
              'Currency & Localization',
              [
                _buildNavigationRow(
                  'Language',
                  Provider.of<AppState>(context).selectedLanguage,
                  CupertinoIcons.globe,
                  () => _showLanguageDialog(),
                ),
                _buildNavigationRow(
                  'Currency Settings',
                  'Configure exchange rates',
                  CupertinoIcons.money_dollar,
                  () => _showCurrencySettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Support & Legal
            _buildSection(
              'Support & Legal',
              [
                _buildNavigationRow(
                  'Help & Support',
                  'Get help and contact us',
                  CupertinoIcons.question_circle,
                  () => _showHelpSupportDialog(),
                ),
                _buildNavigationRow(
                  'Privacy Policy',
                  'Read our privacy policy',
                  CupertinoIcons.shield,
                  () => _showPrivacyPolicy(),
                ),
                _buildNavigationRow(
                  'Terms of Service',
                  'Read our terms of service',
                  CupertinoIcons.doc_text,
                  () => _showTermsOfService(),
                ),
                _buildInfoRow(
                  'App Version',
                  '1.0.0',
                  CupertinoIcons.info_circle,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: AppTheme.getDynamicCaption1(context).copyWith(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.5,
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: CupertinoColors.systemGrey,
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

  Widget _buildActionRow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? CupertinoColors.systemRed.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? CupertinoColors.systemRed
                    : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive 
                          ? CupertinoColors.systemRed
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicCaption1(context).copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getCloudKitStatusText(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.isSyncing) {
      return 'Syncing...';
    } else if (appState.isOnline) {
      return 'Connected';
    } else {
      return 'Offline';
    }
  }

  // Dialog methods
  void _showAppInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('About Bechaalany Debt'),
        content: const Text('A modern debt management app with the latest iOS features and design patterns.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showTextSizeDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Text Size'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Small'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).setTextSize('Small');
              Navigator.of(context).pop();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Medium'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).setTextSize('Medium');
              Navigator.of(context).pop();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Large'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).setTextSize('Large');
              Navigator.of(context).pop();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Extra Large'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).setTextSize('Extra Large');
              Navigator.of(context).pop();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    // Implementation for quiet hours dialog
  }

  void _showLanguageDialog() {
    // Implementation for language dialog
  }

  void _showCurrencySettings() {
    // Implementation for currency settings
  }

  void _showStorageUsage() {
    // Implementation for storage usage
  }

  void _showCacheManagement() {
    // Implementation for cache management
  }

  void _showExportDialog() {
    // Implementation for export dialog
  }

  void _showImportDialog() {
    // Implementation for import dialog
  }

  void _showClearDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete All Data'),
            onPressed: () {
              // Implementation for clearing data
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    // Implementation for help and support
  }

  void _showPrivacyPolicy() {
    // Implementation for privacy policy
  }

  void _showTermsOfService() {
    // Implementation for terms of service
  }
} 