import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/access.dart';
import '../services/access_service.dart';
import '../utils/admin_contact.dart';
import 'contact_owner_screen.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final AccessService _accessService = AccessService();
  Access? _access;
  bool _isLoading = true;

  static const String _arabicIndicNumerals = '٠١٢٣٤٥٦٧٨٩';
  static String _toArabicNumerals(String s) {
    return s.replaceAllMapped(
        RegExp(r'\d'), (m) => _arabicIndicNumerals[int.parse(m.group(0)!)]);
  }

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final access = await _accessService.getCurrentUserAccess();
      setState(() {
        _access = access;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusCardTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _access!.status;
    switch (status) {
      case AccessStatus.trial:
        return l10n.freeTrial;
      case AccessStatus.active:
        return l10n.activeAccess;
      case AccessStatus.expired:
        return l10n.accessExpired;
      case AccessStatus.cancelled:
        return l10n.accessCancelled;
    }
  }

  Color _getStatusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.trial:
        return AppColors.primary;
      case AccessStatus.active:
        return AppColors.success;
      case AccessStatus.expired:
        return AppColors.error;
      case AccessStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  TextStyle _textStyle(
    BuildContext context, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.dynamicTextPrimary(context),
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppLocalizations.of(context)!.requestAccess,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    if (_access != null) ...[
                      _buildStatusCard(context),
                      const SizedBox(height: 16),
                      if (_access!.status == AccessStatus.trial)
                        _buildTrialSection(context),
                      if (_access!.status == AccessStatus.active)
                        _buildActiveSection(context),
                      if (_access!.status == AccessStatus.expired ||
                          _access!.status == AccessStatus.cancelled)
                        _buildExpiredSection(context),
                      const SizedBox(height: 16),
                    ] else ...[
                      _buildNoDataSection(context),
                      const SizedBox(height: 16),
                    ],
                    if (_access != null && _access!.status == AccessStatus.trial) ...[
                      _buildRequestAccessSection(context),
                      const SizedBox(height: 16),
                    ],
                    _buildContactAdminSection(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _access!.status;
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == AccessStatus.active
                  ? CupertinoIcons.check_mark_circled_solid
                  : status == AccessStatus.trial
                      ? CupertinoIcons.clock_fill
                      : CupertinoIcons.exclamationmark_circle_fill,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _getStatusCardTitle(context),
              style: _textStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.person_circle,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.welcomeToBechaalany,
            style: _textStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.welcomeNoDataMessage,
            style: _textStyle(
              context,
              fontSize: 14,
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrialSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.trialDetails,
            style: _textStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        _buildInfoCard(
          context,
          title: AppLocalizations.of(context)!.trialPeriod,
          value: _access!.trialDaysRemaining != null
              ? AppLocalizations.of(context)!.daysRemaining(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? _toArabicNumerals(_access!.trialDaysRemaining.toString())
                      : _access!.trialDaysRemaining.toString())
              : AppLocalizations.of(context)!.active,
          icon: CupertinoIcons.calendar,
        ),
        if (_access!.trialStartDate != null)
          _buildInfoCard(
            context,
            title: AppLocalizations.of(context)!.trialStarted,
            value: _formatDate(_access!.trialStartDate!),
            icon: CupertinoIcons.time,
          ),
        if (_access!.trialEndDate != null)
          _buildInfoCard(
            context,
            title: AppLocalizations.of(context)!.trialEnds,
            value: _formatDate(_access!.trialEndDate!),
            icon: CupertinoIcons.calendar_today,
          ),
      ],
    );
  }

  Widget _buildActiveSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.accessDetails,
            style: _textStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        _buildInfoCard(
          context,
          title: AppLocalizations.of(context)!.accessPeriod,
          value: _access!.accessDaysRemaining != null
              ? AppLocalizations.of(context)!.daysRemaining(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? _toArabicNumerals(_access!.accessDaysRemaining.toString())
                      : _access!.accessDaysRemaining.toString())
              : AppLocalizations.of(context)!.active,
          icon: CupertinoIcons.calendar,
        ),
        if (_access!.accessStartDate != null)
          _buildInfoCard(
            context,
            title: AppLocalizations.of(context)!.accessStarted,
            value: _formatDate(_access!.accessStartDate!),
            icon: CupertinoIcons.time,
          ),
        if (_access!.accessEndDate != null)
          _buildInfoCard(
            context,
            title: AppLocalizations.of(context)!.accessEnds,
            value: _formatDate(_access!.accessEndDate!),
            icon: CupertinoIcons.calendar_today,
          ),
      ],
    );
  }

  Widget _buildExpiredSection(BuildContext context) {
    final isExpired = _access!.status == AccessStatus.expired;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: AppColors.error,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            isExpired
                ? AppLocalizations.of(context)!.yourAccessExpired
                : AppLocalizations.of(context)!.yourAccessCancelled,
            style: _textStyle(
              context,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.expiredContactMessage,
            style: _textStyle(
              context,
              fontSize: 14,
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ContactOwnerScreen(),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.contactAdministrator),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.requestAccess,
            style: _textStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: AppColors.dynamicPrimary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.accessStatusAndRenewals,
                      style: _textStyle(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.requestAccessInfoMessage,
                style: _textStyle(
                  context,
                  fontSize: 13,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const Color _whatsappGreen = Color(0xFF25D366);

  Widget _buildContactAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.contactAdministrator,
            style: _textStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        _buildWhatsAppCard(context),
        const SizedBox(height: 8),
        _buildCallAdminCard(context),
      ],
    );
  }

  Widget _buildWhatsAppCard(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => AdminContact.openWhatsApp(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _whatsappGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _whatsappGreen.withValues(alpha: 0.3),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _whatsappGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                'assets/images/whatsapp_logo.svg',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.whatsApp,
                    style: _textStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AdminContact.whatsApp,
                    style: _textStyle(
                      context,
                      fontSize: 13,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: _whatsappGreen,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallAdminCard(BuildContext context) {
    final primary = AppColors.dynamicPrimary(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => AdminContact.call(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dynamicSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dynamicBorder(context)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CupertinoIcons.phone_fill, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.phone,
                    style: _textStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AdminContact.phone,
                    style: _textStyle(
                      context,
                      fontSize: 13,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.dynamicTextSecondary(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.dynamicPrimary(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _textStyle(
                    context,
                    fontSize: 13,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: _textStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
