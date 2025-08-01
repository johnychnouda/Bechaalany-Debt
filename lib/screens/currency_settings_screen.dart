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
  final TextEditingController _notesController = TextEditingController();
  
  // Available currencies
  final List<String> _currencies = ['USD', 'LBP', 'EUR', 'GBP', 'CAD', 'AUD'];
  
  String _selectedBaseCurrency = 'USD';
  String _selectedTargetCurrency = 'LBP';

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings();
  }

  @override
  void dispose() {
    _exchangeRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentSettings = _dataService.currencySettings;
      
      if (_currentSettings != null) {
        _selectedBaseCurrency = _currentSettings!.baseCurrency;
        _selectedTargetCurrency = _currentSettings!.targetCurrency;
        _exchangeRateController.text = _currentSettings!.exchangeRate.toString();
        _notesController.text = _currentSettings!.notes ?? '';
      } else {
        // Set default values
        _selectedBaseCurrency = 'USD';
        _selectedTargetCurrency = 'LBP';
        _exchangeRateController.text = '89500.0';
        _notesController.text = '';
      }
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
      final exchangeRate = double.tryParse(_exchangeRateController.text) ?? 89500.0;
      
      final settings = CurrencySettings(
        baseCurrency: _selectedBaseCurrency,
        targetCurrency: _selectedTargetCurrency,
        exchangeRate: exchangeRate,
        lastUpdated: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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

  void _showCurrencyPicker(BuildContext context, bool isBaseCurrency) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    isBaseCurrency ? 'Base Currency' : 'Target Currency',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      if (isBaseCurrency) {
                        _selectedBaseCurrency = _currencies[index];
                      } else {
                        _selectedTargetCurrency = _currencies[index];
                      }
                    });
                  },
                  children: _currencies.map((currency) {
                    return Center(
                      child: Text(
                        currency,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyRow(String title, String value, VoidCallback onTap) {
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
                    value,
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
                            _currentSettings!.formattedRate,
                            CupertinoIcons.money_dollar,
                          ),
                          _buildInfoRow(
                            'Last Updated',
                            _formatDate(_currentSettings!.lastUpdated),
                            CupertinoIcons.time,
                          ),
                          if (_currentSettings!.notes != null) ...[
                            _buildInfoRow(
                              'Notes',
                              _currentSettings!.notes!,
                              CupertinoIcons.doc_text,
                            ),
                          ],
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
                        _buildCurrencyRow(
                          'Base Currency',
                          _selectedBaseCurrency,
                          () => _showCurrencyPicker(context, true),
                        ),
                        _buildCurrencyRow(
                          'Target Currency',
                          _selectedTargetCurrency,
                          () => _showCurrencyPicker(context, false),
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
                                  placeholder: 'Enter exchange rate (e.g., 89500.0)',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                const SizedBox(height: 4),
                                Text(
                                  '1 $_selectedBaseCurrency = ${_exchangeRateController.text.isEmpty ? "0" : _exchangeRateController.text} $_selectedTargetCurrency',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                  'Notes (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CupertinoTextField(
                                  controller: _notesController,
                                  placeholder: 'Add notes about this exchange rate',
                                  maxLines: 3,
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
                    
                    const SizedBox(height: 20),
                    
                    // Quick Actions Section
                    _buildSection(
                      'Quick Actions',
                      [
                        _buildActionRow(
                          'Set Default Rate (USD to LBP)',
                          'Set 1 USD = 89,500 LBP',
                          CupertinoIcons.arrow_clockwise,
                          () {
                            setState(() {
                              _selectedBaseCurrency = 'USD';
                              _selectedTargetCurrency = 'LBP';
                              _exchangeRateController.text = '89500.0';
                            });
                          },
                        ),
                        _buildActionRow(
                          'Reset to Current Settings',
                          'Restore saved settings',
                          CupertinoIcons.refresh,
                          _loadCurrencySettings,
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 