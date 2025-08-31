import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/currency_settings.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../providers/app_state.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Format with thousands separators
    String formatted = NumberFormat('#,###').format(int.parse(digitsOnly));
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final DataService _dataService = DataService();
  CurrencySettings? _currentSettings;
  bool _isLoading = true;
  
  // Form controllers
  final TextEditingController _exchangeRateController = TextEditingController();
  
  // Fixed currencies
  final String _baseCurrency = 'USD';
  final String _targetCurrency = 'LBP';

  @override
  void initState() {
    super.initState();
    
    // Listen to currency settings changes in real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onAppStateChanged);
      
      // Load currency settings after AppState is ready
      _loadCurrencySettings();
    });
  }



  void _onAppStateChanged() {
    if (mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currencySettings != _currentSettings) {
        setState(() {
          _currentSettings = appState.currencySettings;
          // Update the input field with current value
          if (_currentSettings?.exchangeRate != null) {
            // Format with thousands separators for better readability
            final formattedRate = NumberFormat('#,###').format(_currentSettings!.exchangeRate!.toInt());
            _exchangeRateController.text = formattedRate;
            print('📱 Currency Settings: Updated input field with: ${_currentSettings!.exchangeRate} (formatted: $formattedRate)');
          } else {
            _exchangeRateController.text = '';
            print('📱 Currency Settings: Cleared input field - no exchange rate');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove listener when disposing
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.removeListener(_onAppStateChanged);
    } catch (e) {
      // AppState might not be available during dispose
    }
    _exchangeRateController.dispose();
    super.dispose();
  }



  Future<void> _loadCurrencySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get currency settings from AppState first
      final appState = Provider.of<AppState>(context, listen: false);
      _currentSettings = appState.currencySettings;
      
      // If AppState doesn't have it, try to fetch directly from Firebase
      if (_currentSettings?.exchangeRate == null) {
        print('📱 Currency Settings: AppState has no exchange rate, trying direct fetch...');
        try {
          _currentSettings = await _dataService.getCurrencySettings();
          print('📱 Currency Settings: Direct fetch result: ${_currentSettings?.exchangeRate}');
        } catch (e) {
          print('❌ Currency Settings: Direct fetch failed: $e');
        }
      }
      
      // Show current exchange rate if it exists
      if (_currentSettings?.exchangeRate != null) {
        // Format with thousands separators for better readability
        final formattedRate = NumberFormat('#,###').format(_currentSettings!.exchangeRate!.toInt());
        _exchangeRateController.text = formattedRate;
        print('📱 Currency Settings: Loaded exchange rate: ${_currentSettings!.exchangeRate} (formatted: $formattedRate)');
      } else {
        _exchangeRateController.text = '';
        print('📱 Currency Settings: No exchange rate found');
      }
    } catch (e) {
      print('❌ Currency Settings: Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrencySettings() async {
    try {
      // Check if input is empty
      if (_exchangeRateController.text.trim().isEmpty) {
        return;
      }
      
      // Parse the exchange rate (remove commas for parsing)
      final cleanText = _exchangeRateController.text.replaceAll(',', '');
      final exchangeRate = double.tryParse(cleanText);
      if (exchangeRate == null || exchangeRate <= 0) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Invalid Exchange Rate',
          body: 'Please enter a valid exchange rate',
        );
        return;
      }
      
      final settings = CurrencySettings(
        baseCurrency: _baseCurrency,
        targetCurrency: _targetCurrency,
        exchangeRate: exchangeRate,
        lastUpdated: DateTime.now(),
        notes: null,
      );

      await _dataService.saveCurrencySettings(settings);
      
      // Update AppState to apply new currency settings throughout the app
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.updateCurrencySettings(settings);
      
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSettingsUpdatedNotification();
        
        // Don't clear the input field - keep the value user entered
        // The AppState listener will update the display automatically
        
        // Reload the settings to show the updated values
        _loadCurrencySettings();
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Update Failed',
          body: 'Error saving currency settings: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Currency Settings',
          style: AppTheme.getDynamicTitle3(context).copyWith(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Update',
            style: AppTheme.getDynamicBody(context).copyWith(
              color: AppColors.dynamicPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          onPressed: _saveCurrencySettings,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Material(
                color: Colors.transparent,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const SizedBox(height: 16),
                    
                    // Current Settings Section
                    if (_currentSettings != null) _buildCurrentSettingsSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Exchange Rate Input Section
                    _buildExchangeRateSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Help Text
                    _buildHelpText(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Current Exchange Rate',
            _currentSettings!.exchangeRate != null 
                ? '1 $_baseCurrency = ${_addThousandsSeparators(_currentSettings!.exchangeRate!.toInt().toString())} $_targetCurrency'
                : 'Not set',
            CupertinoIcons.money_dollar,
            AppColors.dynamicSuccess(context),
          ),
          _buildInfoRow(
            'Last Updated',
            _formatDate(_currentSettings!.lastUpdated),
            CupertinoIcons.time,
            AppColors.dynamicPrimary(context),
            showBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Exchange Rate',
              style: AppTheme.getDynamicBody(context).copyWith(
                color: AppColors.dynamicTextPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _exchangeRateController,
              placeholder: 'Enter exchange rate',
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                _formatInputOnChange(value);
              },
              style: AppTheme.getDynamicBody(context).copyWith(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.dynamicBackground(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dynamicBorder(context),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle, IconData icon, Color iconColor, {bool showBorder = true}) {
    return Container(
      decoration: showBorder ? BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dynamicBorder(context),
            width: 0.5,
          ),
        ),
      ) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.getDynamicBody(context).copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.getDynamicFootnote(context).copyWith(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 15,
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

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: AppColors.dynamicPrimary(context),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The exchange rate will be used to convert USD amounts to LBP in all calculations and reports.',
              style: AppTheme.getDynamicCaption1(context).copyWith(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _formatInputOnChange(String value) {
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return; // Don't format empty input
    }
    
    // Parse as integer and format with commas using NumberFormat
    final number = int.tryParse(digitsOnly);
    if (number != null) {
      final formatted = NumberFormat('#,###').format(number);
      
      // Only update if the formatted text is different
      if (formatted != value) {
        _exchangeRateController.text = formatted;
        _exchangeRateController.selection = TextSelection.collapsed(offset: formatted.length);
      }
    }
  }



  String _addThousandsSeparators(String number) {
    final buffer = StringBuffer();
    final length = number.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }
} 