import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/firebase_data_service.dart';
import '../services/firebase_auth_service.dart';

import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';
import 'payment_reminders_screen.dart';

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
                    'Send WhatsApp messages for debt settlements and payment reminders',
                    CupertinoIcons.chat_bubble_2,
                    Provider.of<AppState>(context).whatsappAutomationEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setWhatsappAutomationEnabled(value),
                  ),
                  if (Provider.of<AppState>(context).whatsappAutomationEnabled) ...[
                    _buildMessageButtonRow(
                      'Custom Settlement Message',
                      'Personalize your debt settlement message',
                      CupertinoIcons.text_bubble,
                      Provider.of<AppState>(context).whatsappCustomMessage,
                      () => _showCustomMessageDialog(context),
                    ),
                    _buildNavigationRow(
                      'Send Payment Reminders',
                      'Manually send WhatsApp reminders to customers with remaining debts',
                      CupertinoIcons.bell,
                      () => _showPaymentRemindersScreen(context),
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
                    'Remove all debts, activities, and payment records',
                    CupertinoIcons.trash,
                    () => _showClearDebtsDialog(),
                  ),
                  _buildNavigationRow(
                    'Data Recovery',
                    'Recover data from backups',
                    CupertinoIcons.arrow_clockwise,
                    () => Navigator.push(
                      context,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
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
                  const SizedBox(height: 4),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dynamicTextSecondary(context),
          ),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          color: AppColors.dynamicTextSecondary(context),
          size: 16,
        ),
        onTap: onTap,
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.dynamicTextSecondary(context),
          ),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dynamicTextSecondary(context),
          ),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          color: AppColors.dynamicTextSecondary(context),
          size: 16,
        ),
        onTap: onTap,
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

  void _showAppInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'App Information',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bechaalany Debt App',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A comprehensive debt management application for tracking customer debts, payments, and business revenue.',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Customer debt tracking\n• Payment management\n• Revenue calculations\n• Product catalog\n• WhatsApp automation\n• Data backup & recovery',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
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

  void _showCustomMessageDialog(BuildContext context) {
    final messageController = TextEditingController(
      text: Provider.of<AppState>(context, listen: false).whatsappCustomMessage,
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Custom WhatsApp Message',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Personalize the message sent when a debt is fully settled:',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: messageController,
              placeholder: 'Enter your custom message...',
              maxLines: 3,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dynamicBorder(context)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.setWhatsappCustomMessage(messageController.text.trim());
              Navigator.pop(context);
            },
            child: Text(
              'Save',
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

  void _showClearDebtsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Clear Debts & Activities',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete all debts, activities, and payment records. Products and customers will be preserved. This action cannot be undone.\n\nAre you sure you want to proceed?',
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              
              // Store the context to ensure we can dismiss the loading dialog
              final currentContext = context;
              
              // Show loading indicator
              showCupertinoDialog(
                context: currentContext,
                barrierDismissible: false,
                builder: (loadingContext) => CupertinoAlertDialog(
                  content: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Clearing debts and activities...',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(loadingContext),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              
              // Add a safety timeout to automatically dismiss the loading dialog
              Timer? safetyTimer;
              safetyTimer = Timer(const Duration(seconds: 100), () {
                if (currentContext.mounted) {
                  try {
                    Navigator.pop(currentContext);
                    // Show timeout message
                    showCupertinoDialog(
                      context: currentContext,
                      builder: (timeoutContext) => CupertinoAlertDialog(
                        title: Text(
                          'Operation Timeout',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(timeoutContext),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'The operation took longer than expected. Local data has been cleared. Please restart the app to ensure Firebase sync.',
                          style: TextStyle(
                            color: AppColors.dynamicTextSecondary(timeoutContext),
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.pop(timeoutContext),
                            child: Text(
                              'OK',
                              style: TextStyle(
                                color: AppColors.dynamicPrimary(timeoutContext),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    // Silently handle timeout dismissal errors
                  }
                }
              });
              
              // Add a final safety net to force dismiss if operation takes too long
              Timer(const Duration(seconds: 95), () {
                if (currentContext.mounted) {
                  try {
                    Navigator.pop(currentContext);
                  } catch (e) {
                    // Silently handle timeout dismissal errors
                  }
                }
              });
              
              try {
                final appState = Provider.of<AppState>(currentContext, listen: false);
                
                // Wait for Firebase clearing to complete (with timeout)
                await appState.clearDebtsAndActivities()
                    .timeout(const Duration(seconds: 90)); // Match app state timeout
                
                // Cancel safety timer and hide loading indicator
                safetyTimer?.cancel();
                if (currentContext.mounted) {
                  Navigator.pop(currentContext);
                }
                
                // Show success message
                if (currentContext.mounted) {
                  showCupertinoDialog(
                    context: currentContext,
                    builder: (successContext) => CupertinoAlertDialog(
                      title: Text(
                        'Success',
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(successContext),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'All debts, activities, and payment records have been cleared successfully. Products and customers have been preserved.',
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(successContext),
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(successContext),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: AppColors.dynamicPrimary(successContext),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                // Cancel safety timer and hide loading indicator
                safetyTimer?.cancel();
                if (currentContext.mounted) {
                  Navigator.pop(currentContext);
                }
                
                // Show error message
                if (currentContext.mounted) {
                  showCupertinoDialog(
                    context: currentContext,
                    builder: (errorContext) => CupertinoAlertDialog(
                      title: Text(
                        'Error',
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(errorContext),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'Firebase operation failed, but local data has been cleared. Please restart the app to ensure Firebase sync.',
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(errorContext),
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(errorContext),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: AppColors.dynamicTextPrimary(errorContext),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
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

  /// Show fix alfa currency dialog
  void _showFixAlfaCurrencyDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Fix Alfa Product Currency',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will fix the alfa debt to match the correct product pricing. The debt amount will be set to 4.50\$ with a cost of 2.00\$ to give 2.50\$ revenue, matching the product settings.\n\nDo you want to proceed?',
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              // Hide dialog
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
                        CupertinoActivityIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Fixing alfa product currency...',
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
              
              try {
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.fixAlfaProductCurrency();
                
                // Hide loading indicator
                Navigator.pop(context);
                
                // Show success message
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text(
                      'Success',
                      style: TextStyle(
                        color: AppColors.dynamicTextPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                            content: Text(
          'Alfa debt has been fixed successfully! The debt amount now matches the product pricing: 4.50\$ debt with 2.50\$ revenue.',
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                // Hide loading indicator
                Navigator.pop(context);
                
                // Show error message
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text(
                      'Error',
                      style: TextStyle(
                        color: AppColors.dynamicTextPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Failed to fix alfa product currency: $e',
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text(
              'Fix Currency',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.dynamicPrimary(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dynamicTextSecondary(context),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
  
  void _showPaymentRemindersScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const PaymentRemindersScreen(),
      ),
    );
  }


}
