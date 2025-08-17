import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';


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
              
              // WhatsApp Automation Settings
              _buildSection(
                'WhatsApp Automation',
                [
                  _buildSwitchRow(
                    'Enable Automated Messages',
                    'Send WhatsApp messages when debts are fully settled',
                    CupertinoIcons.chat_bubble_2,
                    Provider.of<AppState>(context).whatsappAutomationEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setWhatsappAutomationEnabled(value),
                  ),
                  if (Provider.of<AppState>(context).whatsappAutomationEnabled) ...[
                    _buildMessageButtonRow(
                      'Custom Message',
                      'Personalize your debt settlement message',
                      CupertinoIcons.text_bubble,
                      Provider.of<AppState>(context).whatsappCustomMessage,
                      () => _showCustomMessageDialog(context),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Data Management
              _buildSection(
                'Data Management',
                [

                  _buildNavigationRow(
                    'Clear Debts & Activities',
                    'Remove all debts, activities, and all payment records',
                    CupertinoIcons.trash,
                    () => _showClearDataDialog(),
                  ),
                  _buildNavigationRow(
                    'Data Recovery',
                    'Recover data from backups',
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
                  _buildInfoRow(
                    'Developer',
                    'Johny Chnouda',
                    CupertinoIcons.person_circle,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.dynamicPrimary(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
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
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.dynamicPrimary(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.dynamicPrimary(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
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

  Widget _buildMessageButtonRow(String title, String subtitle, IconData icon, String currentMessage, VoidCallback onTap) {
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
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.dynamicPrimary(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'About Bechaalany Debt App',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'A professional debt tracking application designed for businesses and individuals to manage customer debts, track payments, and maintain financial records.\n\nBuilt with Flutter for iOS and Android.',
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.dynamicPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  void _showClearDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Clear Debts & Activities',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete all debts, activities, and payment records. Your customers and products will be preserved.',
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              showCupertinoDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => CupertinoAlertDialog(
                  content: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Clearing debts and activities...',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              
              // Clear all data
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.clearAllData();
              
              // Hide loading and show success
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debts and activities cleared successfully!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Clear Debts',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show custom message dialog
  void _showCustomMessageDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentMessage = appState.whatsappCustomMessage;
    final textController = TextEditingController(text: currentMessage);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width * 0.98, // 98% of screen width
        constraints: const BoxConstraints(
          maxWidth: 800, // Much larger maximum width
          minWidth: 500, // Larger minimum width
        ),
        child: CupertinoAlertDialog(
          title: Text(
            'Custom WhatsApp Message',
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            children: [
              Text(
                'Debt Settlement Message:',
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: textController,
                placeholder: 'Enter your message here...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.dynamicTextPrimary(context),
                ),
                decoration: BoxDecoration(
                  color: AppColors.dynamicBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.dynamicBorder(context),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                maxLines: 5,
                minLines: 4,
                textAlignVertical: TextAlignVertical.top,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final newMessage = textController.text.trim();
                appState.setWhatsappCustomMessage(newMessage);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
