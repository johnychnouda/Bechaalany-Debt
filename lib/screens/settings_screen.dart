import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/firebase_data_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_service.dart';

import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';
import 'payment_reminders_screen.dart';
import 'sign_in_screen.dart';
import 'subscription_status_screen.dart';
import '../services/admin_service.dart';
import '../services/business_name_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.1.1'; // Default fallback
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkAdminStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Keep default version if loading fails
    }
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
              
              // Account Section
              _buildSection(
                'Account',
                [
                  // Subscription Status (hidden for admins)
                  if (!_isCheckingAdmin && !_isAdmin)
                    _buildNavigationRow(
                      'Subscription Status',
                      'View your subscription and trial information',
                      CupertinoIcons.calendar,
                      () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const SubscriptionStatusScreen(),
                        ),
                      ),
                    ),
                  _buildNavigationRow(
                    'Sign Out',
                    'Sign out of your account',
                    CupertinoIcons.square_arrow_right,
                    () => _showSignOutDialog(),
                  ),
                ],
              ),
              
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
                  // Business Name (only for non-admin users)
                  if (!_isCheckingAdmin && !_isAdmin)
                    _buildNavigationRow(
                      'Business Name',
                      'Set your business name for receipts and messages',
                      CupertinoIcons.building_2_fill,
                      () => _showBusinessNameDialog(),
                    ),
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
                    _appVersion,
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



  void _showCurrencySettings() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const CurrencySettingsScreen(),
      ),
    );
  }

  void _showBusinessNameDialog() async {
    final businessNameService = BusinessNameService();
    String currentBusinessName = '';
    bool isLoading = true;

    // Load current business name
    try {
      currentBusinessName = await businessNameService.getBusinessName();
    } catch (e) {
      // Keep empty if error
    }
    isLoading = false;

    final TextEditingController controller = TextEditingController(text: currentBusinessName);

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text(
            'Business Name',
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: CupertinoActivityIndicator(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Your business name will appear on receipts, payment reminders, and all customer communications.',
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: controller,
                      placeholder: 'Enter your business name',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface(context),
                        border: Border.all(
                          color: AppColors.dynamicBorder(context),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      style: TextStyle(
                        color: AppColors.dynamicTextPrimary(context),
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    if (controller.text.trim().isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Business name is required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        await businessNameService.setBusinessName(controller.text);
                        Navigator.pop(context);
                        
                        // Show success message
                        if (context.mounted) {
                          showCupertinoDialog(
                            context: context,
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
                                'Business name has been updated successfully.',
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
                        Navigator.pop(context);
                        
                        // Show error message
                        if (context.mounted) {
                          showCupertinoDialog(
                            context: context,
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
                                'Failed to update business name: ${e.toString().replaceAll('Exception: ', '')}',
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
                'Save',
                style: TextStyle(
                  color: controller.text.trim().isEmpty
                      ? AppColors.dynamicTextSecondary(context)
                      : AppColors.dynamicPrimary(context),
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
              
              try {
                final appState = Provider.of<AppState>(context, listen: false);
                
                // Clear debts and activities immediately without any loading indicators
                await appState.quickClearDebtsAndActivities();
                
                // Show success message
                if (context.mounted) {
                  showCupertinoDialog(
                    context: context,
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
                // Show error message
                if (context.mounted) {
                  showCupertinoDialog(
                    context: context,
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
                        e.toString().replaceAll('Exception: ', ''),
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
                
                // Check if widget is still mounted before using context
                if (mounted) {
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
                }
              } catch (e) {
                // Check if widget is still mounted before using context
                if (mounted) {
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

  void _showSignOutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You will need to sign in again to access your data.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(context);
              
              // Sign out immediately using AuthService
              final authService = AuthService();
              await authService.signOut();
              
              // Force navigation to sign-in screen after a short delay
              await Future.delayed(const Duration(milliseconds: 200));
              
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }


}
