import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/firebase_data_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_service.dart';
import '../services/account_deletion_service.dart';

import 'data_recovery_screen.dart';
import 'currency_settings_screen.dart';
import 'payment_reminders_screen.dart';
import 'sign_in_screen.dart';
import 'request_access_screen.dart';
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
        middle: Text(AppLocalizations.of(context)!.settingsTitle, style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
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
                AppLocalizations.of(context)!.sectionAccount,
                [
                  // Access Status (hidden for admins)
                  if (!_isCheckingAdmin && !_isAdmin)
                    _buildNavigationRow(
                      AppLocalizations.of(context)!.accessStatus,
                      AppLocalizations.of(context)!.accessStatusSubtitle,
                      CupertinoIcons.person_circle,
                      () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const RequestAccessScreen(),
                        ),
                      ),
                    ),
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.signOut,
                    AppLocalizations.of(context)!.signOutSubtitle,
                    CupertinoIcons.square_arrow_right,
                    () => _showSignOutDialog(),
                  ),
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.deleteAccount,
                    AppLocalizations.of(context)!.deleteAccountSubtitle,
                    CupertinoIcons.delete,
                    () => _showDeleteAccountDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Language
              _buildSection(
                AppLocalizations.of(context)!.sectionAppearance,
                [
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.language,
                    AppLocalizations.of(context)!.languageSubtitle,
                    CupertinoIcons.globe,
                    () => _showLanguagePicker(),
                  ),
                  _buildSwitchRow(
                    AppLocalizations.of(context)!.darkMode,
                    AppLocalizations.of(context)!.darkModeSubtitle,
                    CupertinoIcons.moon,
                    Provider.of<AppState>(context).isDarkMode,
                    (value) => Provider.of<AppState>(context, listen: false).setDarkModeEnabled(value),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Business Settings (Essential only)
              _buildSection(
                AppLocalizations.of(context)!.sectionBusinessSettings,
                [
                  // Business Name (only for non-admin users)
                  if (!_isCheckingAdmin && !_isAdmin)
                    _buildNavigationRow(
                      AppLocalizations.of(context)!.businessName,
                      AppLocalizations.of(context)!.businessNameSubtitle,
                      CupertinoIcons.building_2_fill,
                      () => _showBusinessNameDialog(),
                    ),
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.currencyAndRates,
                    AppLocalizations.of(context)!.currencyAndRatesSubtitle,
                    CupertinoIcons.money_dollar,
                    () => _showCurrencySettings(),
                  ),
                ],
              ),
              
              
              const SizedBox(height: 20),
              
              // WhatsApp Automation Settings
              _buildSection(
                AppLocalizations.of(context)!.sectionWhatsAppAutomation,
                [
                  _buildSwitchRow(
                    AppLocalizations.of(context)!.enableAutomatedMessages,
                    AppLocalizations.of(context)!.enableAutomatedMessagesSubtitle,
                    CupertinoIcons.chat_bubble_2,
                    Provider.of<AppState>(context).whatsappAutomationEnabled,
                    (value) => Provider.of<AppState>(context, listen: false).setWhatsappAutomationEnabled(value),
                  ),
                  if (Provider.of<AppState>(context).whatsappAutomationEnabled) ...[
                    _buildNavigationRow(
                      AppLocalizations.of(context)!.sendPaymentReminders,
                      AppLocalizations.of(context)!.sendPaymentRemindersSubtitle,
                      CupertinoIcons.bell,
                      () => _showPaymentRemindersScreen(context),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Data Management
              _buildSection(
                AppLocalizations.of(context)!.sectionDataManagement,
                [
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.clearDebtsAndActivities,
                    AppLocalizations.of(context)!.clearDebtsAndActivitiesSubtitle,
                    CupertinoIcons.trash,
                    () => _showClearDebtsDialog(),
                  ),
                  _buildNavigationRow(
                    AppLocalizations.of(context)!.dataRecovery,
                    AppLocalizations.of(context)!.dataRecoverySubtitle,
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
                AppLocalizations.of(context)!.sectionAppInfo,
                [
                  _buildInfoRow(
                    AppLocalizations.of(context)!.developer,
                    'Johny Chnouda',
                    CupertinoIcons.person_circle,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.appVersion,
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

  Widget _buildNavigationRow(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
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
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.1)
                : AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : AppColors.dynamicPrimary(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : AppColors.dynamicTextPrimary(context),
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



  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Material(
          color: AppColors.dynamicSurface(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(l10n.languageEnglish),
                  trailing: appState.localeCode == 'en'
                      ? Icon(CupertinoIcons.checkmark, color: AppColors.dynamicPrimary(context))
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await appState.setLocale('en');
                  },
                ),
                ListTile(
                  title: Text(l10n.languageArabic),
                  trailing: appState.localeCode == 'ar'
                      ? Icon(CupertinoIcons.checkmark, color: AppColors.dynamicPrimary(context))
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await appState.setLocale('ar');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
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

    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text(
            l10n.businessNameDialogTitle,
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
                      l10n.businessNameDialogHint,
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: controller,
                      placeholder: l10n.enterBusinessName,
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
                        l10n.businessNameRequired,
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
                l10n.cancel,
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
                          final l10nSuccess = AppLocalizations.of(context)!;
                          showCupertinoDialog(
                            context: context,
                            builder: (successContext) => CupertinoAlertDialog(
                              title: Text(
                                l10nSuccess.success,
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(successContext),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                l10nSuccess.businessNameUpdated,
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(successContext),
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () => Navigator.pop(successContext),
                                  child: Text(
                                    l10nSuccess.ok,
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
                          final l10nErr = AppLocalizations.of(context)!;
                          showCupertinoDialog(
                            context: context,
                            builder: (errorContext) => CupertinoAlertDialog(
                              title: Text(
                                l10nErr.error,
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(errorContext),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                l10nErr.businessNameUpdateFailed(e.toString().replaceAll('Exception: ', '')),
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(errorContext),
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () => Navigator.pop(errorContext),
                                  child: Text(
                                    l10nErr.ok,
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
                l10n.save,
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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          l10n.appInfoTitle,
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
              l10n.appInfoName,
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appInfoDescription,
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appInfoFeaturesTitle,
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appInfoFeaturesList,
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
              l10n.ok,
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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          l10n.clearDebtsDialogTitle,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          l10n.clearDebtsDialogContent,
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
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
                  final l10nSuccess = AppLocalizations.of(context)!;
                  showCupertinoDialog(
                    context: context,
                    builder: (successContext) => CupertinoAlertDialog(
                      title: Text(
                        l10nSuccess.success,
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(successContext),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        l10nSuccess.clearDebtsSuccess,
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(successContext),
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(successContext),
                          child: Text(
                            l10nSuccess.ok,
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
                  final l10nErr = AppLocalizations.of(context)!;
                  showCupertinoDialog(
                    context: context,
                    builder: (errorContext) => CupertinoAlertDialog(
                      title: Text(
                        l10nErr.error,
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
                            l10nErr.ok,
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
              l10n.clearDebtsButton,
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
          'This will fix the alfa debt to match the correct product cost/selling. The debt amount will be set to 4.50\$ with a cost of 2.00\$ to give 2.50\$ revenue, matching the product settings.\n\nDo you want to proceed?',
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
          'Alfa debt has been fixed successfully! The debt amount now matches the product cost/selling: 4.50\$ debt with 2.50\$ revenue.',
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

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          l10n.deleteAccount,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        message: Text(
          l10n.deleteAccountDialogMessage,
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteAccount();
            },
            child: Text(
              l10n.deleteAccount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(
              color: AppColors.dynamicPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    // Show second confirmation action sheet
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          l10n.finalConfirmation,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        message: Text(
          l10n.finalConfirmationDeleteMessage,
          style: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.cancel,
            style: TextStyle(
              color: AppColors.dynamicPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    // Show loading dialog
    if (!context.mounted) return;
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
                'Deleting account...',
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
      final accountDeletionService = AccountDeletionService();
      
      if (!accountDeletionService.canDeleteAccount()) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog('No user is currently signed in.');
        }
        return;
      }

      // Delete the account
      await accountDeletionService.deleteAccount();

      // Close loading dialog and go straight to login — account is fully deleted from Firebase
      if (context.mounted) {
        Navigator.pop(context); // close loading
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        _showErrorDialog('Failed to delete account: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Error',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
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


}
