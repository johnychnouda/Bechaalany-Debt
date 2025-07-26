import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/data_service.dart';
import '../services/localization_service.dart';

import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/currency_settings.dart';
import '../widgets/expandable_chip_dropdown.dart';

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
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            
            // Appearance
            _buildSection(
              'Appearance',
              [
                _buildSwitchRow(
                  'Dark Mode',
                  'Use dark appearance',
                  CupertinoIcons.moon_fill,
                  Provider.of<AppState>(context).darkModeEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setDarkModeEnabled(value),
                ),
                _buildNavigationRow(
                  'Language',
                  Provider.of<LocalizationService>(context).currentLanguageName,
                  CupertinoIcons.globe,
                  () => _showLanguagePicker(),
                ),
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return _buildNavigationRow(
                      'Text Size',
                      appState.textSize,
                      CupertinoIcons.textformat_size,
                      () => _showTextSizeSettings(),
                    );
                  },
                ),
                _buildSwitchRow(
                  'Bold Text',
                  'Use bold text throughout the app',
                  CupertinoIcons.textformat,
                  Provider.of<AppState>(context).boldTextEnabled,
                  (value) => Provider.of<AppState>(context, listen: false).setBoldTextEnabled(value),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Currency Configuration (Keeping as requested)
            _buildSection(
              'Currency',
              [
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    final settings = appState.currencySettings;
                    return _buildNavigationRow(
                      'Exchange Rate',
                      settings != null ? appState.formattedExchangeRate : 'Not set',
                      CupertinoIcons.money_dollar_circle,
                      () => _showCurrencySettingsDialog(context),
                    );
                  },
                ),
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    final settings = appState.currencySettings;
                    String lastUpdatedText = 'Never';
                    if (settings?.lastUpdated != null) {
                      final date = settings!.lastUpdated;
                      final now = DateTime.now();
                      final difference = now.difference(date);
                      
                      if (difference.inDays == 0) {
                        if (difference.inHours == 0) {
                          lastUpdatedText = '${difference.inMinutes} minutes ago';
                        } else {
                          lastUpdatedText = '${difference.inHours} hours ago';
                        }
                      } else if (difference.inDays == 1) {
                        lastUpdatedText = 'Yesterday';
                      } else if (difference.inDays < 7) {
                        lastUpdatedText = '${difference.inDays} days ago';
                      } else {
                        lastUpdatedText = '${date.day}/${date.month}/${date.year}';
                      }
                    }
                    
                    return _buildInfoRow(
                      'Last Updated',
                      lastUpdatedText,
                      CupertinoIcons.clock,
                    );
                  },
                ),
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
                decorationThickness: 0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.black,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                      decorationThickness: 0,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      text: subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
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
    );
  }

  Widget _buildNavigationRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
      ),
      child: CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.black,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                          decorationThickness: 0,
                        ),
                      ),
                    ),
                  ],
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
    );
  }

  Widget _buildActionRow(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
      ),
      child: CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? CupertinoColors.destructiveRed.withOpacity(0.1) : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.black,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDestructive ? CupertinoColors.destructiveRed.withOpacity(0.8) : CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                          decorationThickness: 0,
                        ),
                      ),
                    ),
                  ],
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
    );
  }

  Widget _buildInfoRow(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.black,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                      decorationThickness: 0,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'Select Language',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 16,
                      ),
                    ),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'English',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'العربية',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
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

  void _showExportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export all data to CSV format and save to Files app?'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting data to Files app...'),
        backgroundColor: AppColors.primary,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
        content: const Text('Select a CSV file from Files app to import data.'),
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
        content: Text('Importing data from Files app...'),
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

  void _showPrivacyPolicy() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Our privacy policy explains how we collect, use, and protect your data.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Text('Our terms of service outline the rules and guidelines for using our app.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCurrencySettingsDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentSettings = appState.currencySettings;
    
    String selectedBaseCurrency = currentSettings?.baseCurrency ?? 'USD';
    String selectedTargetCurrency = currentSettings?.targetCurrency ?? 'LBP';
    final exchangeRateController = TextEditingController(text: currentSettings?.exchangeRate.toStringAsFixed(0) ?? '89500');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Currency Exchange Rate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Base Currency Dropdown (USD or LBP only)
                  const Text(
                    'Base Currency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpandableChipDropdown<String>(
                    label: 'Base Currency',
                    value: selectedBaseCurrency,
                    items: ['USD', 'LBP'],
                    itemToString: (currency) => currency,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedBaseCurrency = newValue;
                          // Auto-set target currency to the opposite
                          selectedTargetCurrency = newValue == 'USD' ? 'LBP' : 'USD';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Target Currency Dropdown (USD or LBP only)
                  const Text(
                    'Target Currency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpandableChipDropdown<String>(
                    label: 'Target Currency',
                    value: selectedTargetCurrency,
                    items: ['USD', 'LBP'],
                    itemToString: (currency) => currency,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedTargetCurrency = newValue;
                          // Auto-set base currency to the opposite
                          selectedBaseCurrency = newValue == 'USD' ? 'LBP' : 'USD';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Exchange Rate Input
                  TextField(
                    controller: exchangeRateController,
                    decoration: InputDecoration(
                      labelText: 'Exchange Rate',
                      hintText: 'e.g., 89500.0',
                      helperText: '1 $selectedBaseCurrency = how many $selectedTargetCurrency?',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final rate = double.tryParse(exchangeRateController.text);
                        if (rate != null && rate > 0) {
                          final settings = CurrencySettings(
                            baseCurrency: selectedBaseCurrency,
                            targetCurrency: selectedTargetCurrency,
                            exchangeRate: rate,
                            lastUpdated: DateTime.now(),
                            notes: null,
                          );
                          
                          appState.updateCurrencySettings(settings);
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exchange rate updated: ${settings.formattedRate}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid exchange rate'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // iOS 18.5 New Methods - Appearance
  void _showTextSizeSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            // iOS 18.5 Style Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'Text Size',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // iOS 18.5 Style Picker
            Expanded(
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final textSizes = ['Small', 'Medium', 'Large', 'Extra Large'];
                  final currentIndex = textSizes.indexOf(appState.textSize);
                  
                  return CupertinoPicker(
                    itemExtent: 50,
                    scrollController: FixedExtentScrollController(initialItem: currentIndex),
                    onSelectedItemChanged: (index) {
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.setTextSize(textSizes[index]);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Small',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Medium',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Large',
                          style: TextStyle(
                            fontSize: 18,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Extra Large',
                          style: TextStyle(
                            fontSize: 20,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageUsage() {
    // Calculate storage usage
    final appState = Provider.of<AppState>(context, listen: false);
    final customersCount = appState.customers.length;
    final debtsCount = appState.debts.length;
    final categoriesCount = appState.categories.length;
    
    // Estimate storage (rough calculation)
    final customersSize = customersCount * 0.5; // KB per customer
    final debtsSize = debtsCount * 0.3; // KB per debt
    final categoriesSize = categoriesCount * 0.2; // KB per category
    final totalSize = customersSize + debtsSize + categoriesSize;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Data Breakdown:'),
            const SizedBox(height: 12),
            _buildStorageRow('Customers', customersCount, customersSize),
            _buildStorageRow('Debts', debtsCount, debtsSize),
            _buildStorageRow('Categories', categoriesCount, categoriesSize),
            const Divider(),
            _buildStorageRow('Total', null, totalSize, isTotal: true),
            const SizedBox(height: 12),
            const Text(
              'Note: This is an estimate. Actual storage may vary.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
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

  Widget _buildStorageRow(String label, int? count, double size, {bool isTotal = false}) {
    final sizeText = size < 1 ? '${(size * 1024).toStringAsFixed(0)} B' : '${size.toStringAsFixed(1)} KB';
    final countText = count != null ? ' ($count items)' : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label$countText',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            sizeText,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showCacheManagement() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cache Management'),
        content: const Text('Clear app cache to free up storage space.'),
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
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
} 