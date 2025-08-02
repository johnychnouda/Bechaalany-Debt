import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/notification_service.dart';
import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';
import 'export_data_screen.dart';
import 'import_data_screen.dart';

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
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.info_circle, color: AppColors.dynamicPrimary(context)),
          onPressed: () => _showAppInfo(),
        ),
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
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
                    () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const ExportDataScreen(),
                      ),
                    ),
                  ),
                  _buildNavigationRow(
                    'Import Data',
                    'Import from other debt management apps',
                    CupertinoIcons.square_arrow_down,
                    () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const ImportDataScreen(),
                      ),
                    ),
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
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextSecondary(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
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
                color: AppColors.dynamicPrimary(context).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.dynamicPrimary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
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
                color: AppColors.dynamicPrimary(context).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.dynamicTextSecondary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
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
                color: AppColors.dynamicPrimary(context).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextSecondary(context),
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
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.iCloudSyncEnabled) {
      return 'Sync disabled';
    }
    
    // Check if user is signed in to CloudKit
    // For now, return a simple status
    return 'Ready to sync';
  }

  void _showAppInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('App Info'),
        content: const Text('Bechaalany Connect v1.0.0\n\nA comprehensive debt management app for tracking customers, debts, and payments.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showCurrencySettings() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const CurrencySettingsScreen(),
      ),
    );
  }



  void _showHelpSupportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Help & Support'),
        content: const Text('For help and support, please contact our support team.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Our privacy policy will be available soon.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('Our terms of service will be available soon.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
} 