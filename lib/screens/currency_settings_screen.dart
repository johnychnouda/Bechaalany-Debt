import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import '../models/currency_settings.dart';
import '../services/data_service.dart';

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter an exchange rate'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Parse the exchange rate (remove commas for parsing)
      final cleanText = _exchangeRateController.text.replaceAll(',', '');
      final exchangeRate = double.tryParse(cleanText);
      if (exchangeRate == null || exchangeRate <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid exchange rate'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currency settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving currency settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text('Currency Settings', style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Save', style: TextStyle(color: AppColors.dynamicPrimary(context))),
          onPressed: _saveCurrencySettings,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Material(
                color: Colors.transparent,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Current Settings Section
                    _buildSection(
                      'Current Settings',
                      [
                                                 if (_currentSettings != null) ...[
                           _buildInfoRow(
                             'Exchange Rate',
                             '1 $_baseCurrency = ${_addThousandsSeparators(_currentSettings!.exchangeRate.toInt().toString())} $_targetCurrency',
                             CupertinoIcons.money_dollar,
                           ),
                          _buildInfoRow(
                            'Last Updated',
                            _formatDate(_currentSettings!.lastUpdated),
                            CupertinoIcons.time,
                          ),

                        ] else ...[
                          _buildInfoRow(
                            'No Settings',
                            'Configure your currency settings below',
                            CupertinoIcons.info_circle,
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Currency Configuration Section
                    _buildSection(
                      'Currency Configuration',
                      [
                        _buildInfoRow(
                          'Base Currency',
                          _baseCurrency,
                          CupertinoIcons.money_dollar,
                        ),
                        _buildInfoRow(
                          'Target Currency',
                          _targetCurrency,
                          CupertinoIcons.money_dollar,
                        ),
                        Container(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exchange Rate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CupertinoTextField(
                                  controller: _exchangeRateController,
                                  placeholder: 'Enter exchange rate',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                  onChanged: (value) {
                                    // Format the input as user types
                                    _formatInputOnChange(value);
                                  },
                                  style: TextStyle(
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.dynamicBorder(context),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),

                              ],
                            ),
                          ),
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

  String _formatExchangeRatePreview(String rateText) {
    if (rateText.isEmpty) return "0";
    
    final rate = double.tryParse(rateText);
    if (rate == null) return rateText;
    
    // Format LBP with thousands separators
    final formattedRate = _addThousandsSeparators(rate.toInt().toString());
    return formattedRate;
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 