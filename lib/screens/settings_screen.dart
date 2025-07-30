import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';


import '../providers/app_state.dart';

import 'data_recovery_screen.dart';

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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
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
            
            // Appearance (App-specific only)
            _buildSection(
              'Appearance',
              [
                _buildSwitchRow(
                  'Dark Mode',
                  'Use dark appearance',
                  CupertinoIcons.moon,
                  Provider.of<AppState>(context).isDarkMode,
                  (value) => Provider.of<AppState>(context, listen: false).setDarkModeEnabled(value),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Business Settings (Essential only)
            _buildSection(
              'Business Settings',
              [
                _buildNavigationRow(
                  'Currency & Exchange Rates',
                  'Configure currency settings and rates',
                  CupertinoIcons.money_dollar,
                  () => _showCurrencySettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Data & Sync (Enhanced)
            _buildSection(
              'Data & Sync',
              [
                _buildSwitchRow(
                  'iCloud Sync',
                  'Sync data across all your devices',
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
                  'Export Data',
                  'Export to PDF, CSV, or Excel formats',
                  CupertinoIcons.square_arrow_up,
                  () => _showExportDialog(),
                ),
                _buildNavigationRow(
                  'Import Data',
                  'Import from other debt management apps',
                  CupertinoIcons.square_arrow_down,
                  () => _showImportDialog(),
                ),
                _buildNavigationRow(
                  'Data Recovery',
                  'Backup and restore your data',
                  CupertinoIcons.arrow_clockwise,
                  () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const DataRecoveryScreen(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // App Info
            _buildSection(
              'App Info',
              [
                _buildNavigationRow(
                  'Help & Support',
                  'Get help and contact support',
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
              style: TextStyle(
                fontSize: 13,
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
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator,
                width: 0.5,
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
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.systemBlue,
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: CupertinoColors.systemBlue,
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
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.systemBlue,
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
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
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.systemBlue,
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
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

  void _showCurrencySettings() {
    // Implementation for currency settings
  }

  void _showExportDialog() {
    // Implementation for export dialog
  }

  void _showImportDialog() {
    // Implementation for import dialog
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