import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';
import 'export_data_screen.dart';

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
              
              // Data & Export (Enhanced)
              _buildSection(
                'Data & Export',
                [
                  _buildNavigationRow(
                    'Export Data',
                    'Export to PDF format',
                    CupertinoIcons.square_arrow_up,
                    () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const ExportDataScreen(),
                      ),
                    ),
                  ),
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
              activeColor: AppColors.primary,
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

  void _showClearDataDialog() {
    final dataService = DataService();
    final stats = dataService.getDataStatistics();
    
    final title = 'Clear Debts & Activities';
    final message = 'This will permanently delete:\n'
        '• ${stats['debts']} debts\n'
        '• ${stats['activities']} activities\n'
        '• ${stats['partial_payments']} payment records\n\n'
        '⚠️ This action cannot be undone!\n'
        '💾 Customers & products will be preserved';
    final actionText = 'Clear Debts & Activities';
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(actionText),
            onPressed: () async {
              Navigator.pop(context);
              await _performDataClearing();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performDataClearing() async {
    final dataService = DataService();
    final notificationService = NotificationService();
    
    try {
      // Show loading dialog
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
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Clear only debts and activities
      await dataService.clearDebts();
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success notification
      await notificationService.showSuccessNotification(
        title: 'Debts & Activities Cleared',
        body: 'Debts and activities have been removed. Your customers and products are preserved.',
      );
      
      // Refresh the app state
      Provider.of<AppState>(context, listen: false).refreshData();
      
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error notification
      await notificationService.showErrorNotification(
        title: 'Error Clearing Data',
        body: 'Failed to clear debts and activities: $e',
      );
    }
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title, and edit button
            Row(
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.dynamicTextPrimary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit button
                          CupertinoButton(
                            padding: const EdgeInsets.all(8),
                            minSize: 0,
                            onPressed: onTap,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.dynamicPrimary(context).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.dynamicPrimary(context).withAlpha(50),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.pencil,
                                size: 22,
                                color: AppColors.dynamicPrimary(context),
                              ),
                            ),
                          ),
                        ],
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
            
            const SizedBox(height: 16),
            

            

          ],
        ),
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
