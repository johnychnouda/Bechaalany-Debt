import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import '../utils/admin_contact.dart';
import 'contact_owner_screen.dart';

class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  State<SubscriptionStatusScreen> createState() => _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscription = await _subscriptionService.getCurrentUserSubscription();
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Status card shows only: "Free Trial" | "Active Access" | "Expired" | "Cancelled"
  String _getStatusCardTitle() {
    final status = _subscription!.status;
    switch (status) {
      case SubscriptionStatus.trial:
        return 'Free Trial';
      case SubscriptionStatus.active:
        return 'Active Access';
      case SubscriptionStatus.expired:
        return 'Access Expired';
      case SubscriptionStatus.cancelled:
        return 'Access Cancelled';
    }
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
        return AppColors.primary;
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.expired:
        return AppColors.error;
      case SubscriptionStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  /// Text styles with explicit no-decoration to prevent spell-check/theme underlines.
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
          'Request Access',
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
                        if (_subscription != null) ...[
                          _buildStatusCard(context),
                          const SizedBox(height: 16),
                          if (_subscription!.status == SubscriptionStatus.trial)
                            _buildTrialSection(context),
                          if (_subscription!.status == SubscriptionStatus.active)
                            _buildActiveSection(context),
                          if (_subscription!.status == SubscriptionStatus.expired ||
                              _subscription!.status == SubscriptionStatus.cancelled)
                            _buildExpiredSection(context),
                          const SizedBox(height: 16),
                        ] else ...[
                          _buildNoDataSection(context),
                          const SizedBox(height: 16),
                        ],
                        _buildRequestAccessSection(context),
                        const SizedBox(height: 16),
                        _buildContactAdminSection(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _subscription!.status;
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
              status == SubscriptionStatus.active
                  ? CupertinoIcons.check_mark_circled_solid
                  : status == SubscriptionStatus.trial
                      ? CupertinoIcons.clock_fill
                      : CupertinoIcons.exclamationmark_circle_fill,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _getStatusCardTitle(),
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
            'Welcome to Bechaalany Connect',
            style: _textStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The app is completely free. Contact the administrator to request access and start managing your business.',
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
            'Trial details',
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
          title: 'Trial period',
          value: _subscription!.trialDaysRemaining != null
              ? '${_subscription!.trialDaysRemaining} days remaining'
              : 'Active',
          icon: CupertinoIcons.calendar,
        ),
        if (_subscription!.trialStartDate != null)
          _buildInfoCard(
            context,
            title: 'Trial started',
            value: _formatDate(_subscription!.trialStartDate!),
            icon: CupertinoIcons.time,
          ),
        if (_subscription!.trialEndDate != null)
          _buildInfoCard(
            context,
            title: 'Trial ends',
            value: _formatDate(_subscription!.trialEndDate!),
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
            'Access details',
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
          title: 'Access period',
          value: _subscription!.subscriptionDaysRemaining != null
              ? '${_subscription!.subscriptionDaysRemaining} days remaining'
              : 'Active',
          icon: CupertinoIcons.calendar,
        ),
        if (_subscription!.subscriptionStartDate != null)
          _buildInfoCard(
            context,
            title: 'Access started',
            value: _formatDate(_subscription!.subscriptionStartDate!),
            icon: CupertinoIcons.time,
          ),
        if (_subscription!.subscriptionEndDate != null)
          _buildInfoCard(
            context,
            title: 'Access ends',
            value: _formatDate(_subscription!.subscriptionEndDate!),
            icon: CupertinoIcons.calendar_today,
          ),
      ],
    );
  }

  Widget _buildExpiredSection(BuildContext context) {
    final isExpired = _subscription!.status == SubscriptionStatus.expired;

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
                ? 'Your access has expired'
                : 'Your access has been cancelled',
            style: _textStyle(
              context,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact the administrator to request continued access.',
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
            child: const Text('Contact Administrator'),
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
            'Request Access',
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
                      'Access is granted by the administrator',
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
                'After your free trial ends, contact the administrator to request continued access. Access is granted manually - no payment or subscription required.',
                style: _textStyle(
                  context,
                  fontSize: 13,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The app is completely free. No payment required.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
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
            'Contact Administrator',
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
                    'Request Access via WhatsApp',
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
                    'Request Access via Phone',
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
