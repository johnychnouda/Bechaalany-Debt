import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/logo_utils.dart';
import '../models/currency_settings.dart';
import '../providers/app_state.dart';
import '../services/business_name_service.dart';
import '../services/data_service.dart';
import '../services/admin_service.dart';
import 'currency_settings_screen.dart' show ThousandsSeparatorInputFormatter;

/// Shown when the user has access but has not yet set shop name and/or exchange rate.
/// User must complete both before using the app.
class RequiredSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const RequiredSetupScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<RequiredSetupScreen> createState() => _RequiredSetupScreenState();
}

class _RequiredSetupScreenState extends State<RequiredSetupScreen> {
  final BusinessNameService _businessNameService = BusinessNameService();
  final DataService _dataService = DataService();
  final AdminService _adminService = AdminService();

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();

  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    try {
      final isAdmin = await _adminService.isAdmin();
      if (isAdmin) {
        _shopNameController.text = BusinessNameService.adminBusinessName;
      } else {
        final name = await _businessNameService.getBusinessName();
        if (name.isNotEmpty) _shopNameController.text = name;
      }
      final settings = await _dataService.getCurrencySettings();
      if (settings?.exchangeRate != null) {
        _exchangeRateController.text =
            NumberFormat('#,###').format(settings!.exchangeRate!.toInt());
      }
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.couldNotLoadValues;
        });
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final shopName = _shopNameController.text.trim();
    final rateText = _exchangeRateController.text.replaceAll(',', '').trim();
    final exchangeRate = double.tryParse(rateText);

    setState(() {
      _errorMessage = null;
    });

    if (!_isAdmin && shopName.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.addShopNameToContinue);
      return;
    }
    if (rateText.isEmpty || exchangeRate == null || exchangeRate <= 0) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterRateToContinue);
      return;
    }

    setState(() => _isSaving = true);

    // Resolve AppState before any await to avoid using context after async gap.
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (!_isAdmin) {
        await _businessNameService.setBusinessName(shopName);
      }
      final settings = CurrencySettings(
        baseCurrency: 'USD',
        targetCurrency: 'LBP',
        exchangeRate: exchangeRate,
        lastUpdated: DateTime.now(),
        notes: null,
      );
      await appState.updateCurrencySettings(settings);

      if (mounted) {
        widget.onComplete();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('RequiredSetupScreen save error: $e');
        debugPrint('$stackTrace');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = AppLocalizations.of(context)!.saveFailedTryAgain;
        });
      }
    }
  }

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.dynamicBackground(context),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.dynamicBackground(context),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
            const SizedBox(height: 36),
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputCard(
                        context: context,
                        icon: Icons.store_rounded,
                        title: AppLocalizations.of(context)!.shopNameLabel,
                        hint: AppLocalizations.of(context)!.shopNameHint,
                        child: CupertinoTextField(
                          controller: _shopNameController,
                          placeholder: AppLocalizations.of(context)!.shopNamePlaceholder,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? AppColors.dynamicSurface(context)
                                : AppColors.systemGray6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 16,
                          ),
                          placeholderStyle: TextStyle(
                            color: AppColors.dynamicTextSecondary(context),
                            fontSize: 16,
                          ),
                          readOnly: _isAdmin,
                          enabled: !_isAdmin,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInputCard(
                        context: context,
                        icon: Icons.currency_exchange_rounded,
                        title: AppLocalizations.of(context)!.exchangeRateLabel,
                        hint: AppLocalizations.of(context)!.exchangeRateHint,
                        child: CupertinoTextField(
                          controller: _exchangeRateController,
                          placeholder: AppLocalizations.of(context)!.exchangeRatePlaceholder,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          decoration: BoxDecoration(
                            color: _isDark
                                ? AppColors.dynamicSurface(context)
                                : AppColors.systemGray6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 16,
                          ),
                          placeholderStyle: TextStyle(
                            color: AppColors.dynamicTextSecondary(context),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.settingsHint,
                        style: AppTheme.getDynamicBody(context).copyWith(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: _buildPrimaryButton(context),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        children: [
          LogoUtils.buildLogo(
            context: context,
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.requiredSetupHeaderTitle,
            style: AppTheme.getDynamicTitle2(context).copyWith(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.requiredSetupHeaderSubtitle,
            style: AppTheme.getDynamicBody(context).copyWith(
              color: AppColors.dynamicTextSecondary(context),
              height: 1.35,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildLanguageSelector(context),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _languageChip(
          context: context,
          label: l10n.languageEnglish,
          localeCode: 'en',
          isSelected: appState.localeCode == 'en',
          onTap: () => appState.setLocale('en'),
        ),
        const SizedBox(width: 12),
        _languageChip(
          context: context,
          label: l10n.languageArabic,
          localeCode: 'ar',
          isSelected: appState.localeCode == 'ar',
          onTap: () => appState.setLocale('ar'),
        ),
      ],
    );
  }

  Widget _languageChip({
    required BuildContext context,
    required String label,
    required String localeCode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      onPressed: onTap,
      borderRadius: BorderRadius.circular(22),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.dynamicSurface(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          Text(
            label,
            style: AppTheme.getDynamicBody(context).copyWith(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.dynamicTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? hint,
    required Widget child,
  }) {
    final surface = AppColors.dynamicSurface(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: _isDark
            ? Border.all(
                color: AppColors.dynamicBorder(context),
                width: 0.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.getDynamicBody(context).copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                hint,
                style: AppTheme.getDynamicBody(context).copyWith(
                  color: AppColors.dynamicTextSecondary(context),
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(26),
        color: AppColors.primary,
        onPressed: _isSaving ? null : _onContinue,
        child: _isSaving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CupertinoActivityIndicator(color: Colors.white),
              )
            : Text(
                AppLocalizations.of(context)!.getStarted,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
