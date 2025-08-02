import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/currency_settings.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../providers/app_state.dart';

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
    _loadCurrencySettings();
  }

  @override
  void dispose() {
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentSettings = _dataService.currencySettings;
      
      // Always start with empty field - don't load existing values
      _exchangeRateController.text = '';
    } catch (e) {
      // Handle error silently
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
      
      // Refresh AppState to apply new currency settings throughout the app
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.refresh();
      
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Settings Updated',
          body: 'Currency settings updated successfully',
        );
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
            '1 $_baseCurrency = ${_addThousandsSeparators(_currentSettings!.exchangeRate.toInt().toString())} $_targetCurrency',
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
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
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
    
    // Parse as integer and format with commas
    final number = int.tryParse(digitsOnly);
    if (number != null) {
      final formatted = _addThousandsSeparators(number.toString());
      
      // Only update if the formatted text is different
      if (formatted != value) {
        final cursorPosition = _exchangeRateController.selection.baseOffset;
        final newCursorPosition = _calculateNewCursorPosition(value, formatted, cursorPosition);
        
        _exchangeRateController.text = formatted;
        _exchangeRateController.selection = TextSelection.collapsed(offset: newCursorPosition);
      }
    }
  }

  int _calculateNewCursorPosition(String oldText, String newText, int oldCursorPosition) {
    // Count commas before cursor in old text
    final commasBeforeCursorInOld = oldText.substring(0, oldCursorPosition).split(',').length - 1;
    
    // Count commas before cursor in new text
    final commasBeforeCursorInNew = newText.substring(0, oldCursorPosition).split(',').length - 1;
    
    // Adjust cursor position based on comma difference
    final commaDifference = commasBeforeCursorInNew - commasBeforeCursorInOld;
    final newCursorPosition = oldCursorPosition + commaDifference;
    
    // Ensure cursor position is within bounds
    return newCursorPosition.clamp(0, newText.length);
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