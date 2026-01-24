import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/subscription_pricing.dart';
import '../../services/subscription_pricing_service.dart';

/// Input formatter for currency values (USD) - allows decimals and formats with $ prefix
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters except decimal point
    String text = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Prevent multiple decimal points
    if ('.'.allMatches(text).length > 1) {
      text = text.substring(0, text.lastIndexOf('.')) + 
             text.substring(text.lastIndexOf('.') + 1);
      // Re-add the last decimal point
      if (newValue.text.contains('.')) {
        final parts = newValue.text.split('.');
        if (parts.length > 1) {
          text = parts[0].replaceAll(RegExp(r'[^\d]'), '') + '.' + 
                 parts[1].replaceAll(RegExp(r'[^\d]'), '');
        }
      }
    }
    
    // Limit to 2 decimal places
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 1 && parts[1].length > 2) {
        text = parts[0] + '.' + parts[1].substring(0, 2);
      }
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class SubscriptionPricingScreen extends StatefulWidget {
  const SubscriptionPricingScreen({super.key});

  @override
  State<SubscriptionPricingScreen> createState() =>
      _SubscriptionPricingScreenState();
}

class _SubscriptionPricingScreenState extends State<SubscriptionPricingScreen> {
  final SubscriptionPricingService _pricingService = SubscriptionPricingService();
  final TextEditingController _monthlyController = TextEditingController();
  final TextEditingController _yearlyController = TextEditingController();
  bool _isSaving = false;
  String? _error;
  String? _success;
  bool _initialized = false;
  String? _monthlyError;
  String? _yearlyError;

  @override
  void initState() {
    super.initState();
    // Add listeners for live preview and validation
    _monthlyController.addListener(_onMonthlyChanged);
    _yearlyController.addListener(_onYearlyChanged);
  }

  @override
  void dispose() {
    _monthlyController.removeListener(_onMonthlyChanged);
    _yearlyController.removeListener(_onYearlyChanged);
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  void _onMonthlyChanged() {
    _validateMonthly();
    setState(() {}); // Trigger rebuild for live preview
  }

  void _onYearlyChanged() {
    _validateYearly();
    setState(() {}); // Trigger rebuild for live preview
  }

  void _validateMonthly() {
    final text = _monthlyController.text.trim();
    if (text.isEmpty) {
      _monthlyError = null;
      return;
    }
    final value = double.tryParse(text);
    if (value == null) {
      _monthlyError = 'Please enter a valid number';
    } else if (value < 0) {
      _monthlyError = 'Price cannot be negative';
    } else if (value > 9999.99) {
      _monthlyError = 'Price is too high (max: \$9,999.99)';
    } else {
      _monthlyError = null;
    }
  }

  void _validateYearly() {
    final text = _yearlyController.text.trim();
    if (text.isEmpty) {
      _yearlyError = null;
      return;
    }
    final value = double.tryParse(text);
    if (value == null) {
      _yearlyError = 'Please enter a valid number';
    } else if (value < 0) {
      _yearlyError = 'Price cannot be negative';
    } else if (value > 99999.99) {
      _yearlyError = 'Price is too high (max: \$99,999.99)';
    } else {
      _yearlyError = null;
    }
  }

  /// Calculate savings percentage when choosing yearly over monthly
  double? _calculateSavings() {
    final monthly = double.tryParse(_monthlyController.text.trim());
    final yearly = double.tryParse(_yearlyController.text.trim());
    
    if (monthly == null || yearly == null || monthly <= 0) {
      return null;
    }
    
    final monthlyYearlyTotal = monthly * 12;
    if (monthlyYearlyTotal <= 0) return null;
    
    final savings = ((monthlyYearlyTotal - yearly) / monthlyYearlyTotal) * 100;
    return savings > 0 ? savings : null;
  }

  void _applyPricing(SubscriptionPricing p) {
    if (_initialized) return;
    _monthlyController.text = p.monthlyPrice.toStringAsFixed(2);
    _yearlyController.text = p.yearlyPrice.toStringAsFixed(2);
    _initialized = true;
  }

  // Get current preview pricing from input fields (always USD)
  SubscriptionPricing _getCurrentPreviewPricing() {
    final monthly = double.tryParse(_monthlyController.text.trim()) ?? 0.0;
    final yearly = double.tryParse(_yearlyController.text.trim()) ?? 0.0;
    return SubscriptionPricing(
      monthlyPrice: monthly,
      yearlyPrice: yearly,
      currency: 'USD',
    );
  }

  Future<void> _save() async {
    // Validate all fields
    _validateMonthly();
    _validateYearly();

    if (_monthlyError != null || _yearlyError != null) {
      setState(() {
        _error = 'Please fix the errors above before saving.';
      });
      return;
    }

    setState(() {
      _error = null;
      _success = null;
      _isSaving = true;
    });

    try {
      final monthly = double.tryParse(_monthlyController.text.trim());
      final yearly = double.tryParse(_yearlyController.text.trim());

      if (monthly == null || monthly < 0) {
        setState(() {
          _error = 'Enter a valid monthly price (≥ 0)';
          _isSaving = false;
        });
        return;
      }
      if (yearly == null || yearly < 0) {
        setState(() {
          _error = 'Enter a valid yearly price (≥ 0)';
          _isSaving = false;
        });
        return;
      }

      await _pricingService.updatePricing(
        monthlyPrice: monthly,
        yearlyPrice: yearly,
        currency: 'USD',
      );

      setState(() {
        _isSaving = false;
        _success = 'Pricing updated successfully!';
      });

      // Show snackbar for better visibility
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pricing updated successfully!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Auto-dismiss success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Subscription Pricing'),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: StreamBuilder<SubscriptionPricing>(
          stream: _pricingService.getPricingStream(),
          builder: (context, snapshot) {
            final pricing = snapshot.data ?? SubscriptionPricing.defaults;
            if (snapshot.hasData && !_initialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _applyPricing(pricing);
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary(context).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          size: 18,
                          color: AppColors.dynamicPrimary(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Users see these prices on the subscription and contact owner screens. Only you (admin) can edit them.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildPriceTextField(
                    controller: _monthlyController,
                    label: 'Monthly price',
                    hint: '0.00',
                    error: _monthlyError,
                    helperText: 'Price users pay per month',
                  ),
                  const SizedBox(height: 20),
                  _buildPriceTextField(
                    controller: _yearlyController,
                    label: 'Yearly price',
                    hint: '0.00',
                    error: _yearlyError,
                    helperText: 'Price users pay per year (12 months)',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _success!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: CupertinoButton.filled(
                      onPressed: _isSaving ? null : _save,
                      borderRadius: BorderRadius.circular(12),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Save pricing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPreview(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? error,
    String? helperText,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dynamicTextPrimary(context),
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: helperText,
                child: Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        StatefulBuilder(
          builder: (context, setFieldState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.dynamicSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError 
                      ? AppColors.error 
                      : AppColors.dynamicBorder(context),
                  width: hasError ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: controller,
                      placeholder: hint,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: [
                        CurrencyInputFormatter(),
                      ],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                      onChanged: (_) {
                        setFieldState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () {
                          controller.clear();
                          setFieldState(() {});
                          setState(() {});
                        },
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 20,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    // Use live preview from input fields
    final previewPricing = _getCurrentPreviewPricing();
    final hasInput = _monthlyController.text.trim().isNotEmpty || 
                     _yearlyController.text.trim().isNotEmpty;
    final savings = _calculateSavings();
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasInput 
              ? AppColors.dynamicPrimary(context).withValues(alpha: 0.3)
              : AppColors.dynamicBorder(context),
          width: hasInput ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.eye,
                size: 18,
                color: AppColors.dynamicTextSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Live preview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextPrimary(context),
                ),
              ),
              if (hasInput) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicPrimary(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicPrimary(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _previewChip(
                  context,
                  'Monthly',
                  previewPricing.formatMonthly(),
                  subtitle: 'per month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _previewChip(
                  context,
                  'Yearly',
                  previewPricing.formatYearly(),
                  subtitle: 'per year',
                  savings: savings,
                ),
              ),
            ],
          ),
          if (savings != null && savings > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Users save ${savings.toStringAsFixed(1)}% with yearly plan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!hasInput) ...[
            const SizedBox(height: 12),
            Text(
              'Start typing to see live preview',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.dynamicTextSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewChip(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    double? savings,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.dynamicPrimary(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: savings != null && savings > 0
            ? Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
              if (savings != null && savings > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Best Value',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
