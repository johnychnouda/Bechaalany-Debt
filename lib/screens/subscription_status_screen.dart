import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';
import '../services/subscription_pricing_service.dart';
import '../models/subscription.dart';
import '../models/subscription_pricing.dart';
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

  /// Status card shows only: "Free Trial" | "Monthly Plan" | "Yearly Plan" | "Expired" | "Cancelled"
  String _getStatusCardTitle() {
    final status = _subscription!.status;
    final type = _subscription!.type;
    switch (status) {
      case SubscriptionStatus.trial:
        return 'Free Trial';
      case SubscriptionStatus.active:
        if (type == SubscriptionType.yearly) return 'Yearly Plan';
        if (type == SubscriptionType.monthly) return 'Monthly Plan';
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
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
          'Subscription',
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
            : _subscription == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No subscription data found',
                        style: _textStyle(
                          context,
                          fontSize: 16,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
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
                        _buildPricingSection(context),
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
            'Subscription details',
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
          title: 'Subscription period',
          value: _subscription!.subscriptionDaysRemaining != null
              ? '${_subscription!.subscriptionDaysRemaining} days remaining'
              : 'Active',
          icon: CupertinoIcons.calendar,
        ),
        if (_subscription!.subscriptionStartDate != null)
          _buildInfoCard(
            context,
            title: 'Subscription started',
            value: _formatDate(_subscription!.subscriptionStartDate!),
            icon: CupertinoIcons.time,
          ),
        if (_subscription!.subscriptionEndDate != null)
          _buildInfoCard(
            context,
            title: 'Subscription ends',
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
                ? 'Your subscription has expired'
                : 'Your subscription has been cancelled',
            style: _textStyle(
              context,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact the owner to renew and restore access.',
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
            child: const Text('Contact owner'),
          ),
        ],
      ),
    );
  }

  /// Calculate savings percentage when choosing yearly over monthly
  double? _calculateSavings(SubscriptionPricing pricing) {
    final monthly = pricing.monthlyPrice;
    final yearly = pricing.yearlyPrice;
    
    if (monthly <= 0) {
      return null;
    }
    
    final monthlyYearlyTotal = monthly * 12;
    if (monthlyYearlyTotal <= 0) return null;
    
    final savings = ((monthlyYearlyTotal - yearly) / monthlyYearlyTotal) * 100;
    return savings > 0 ? savings : null;
  }

  Widget _buildPricingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Plans & pricing',
            style: _textStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
        ),
        StreamBuilder<SubscriptionPricing>(
          stream: SubscriptionPricingService().getPricingStream(),
          builder: (context, snapshot) {
            final pricing = snapshot.data ?? SubscriptionPricing.defaults;
            final savings = _calculateSavings(pricing);
            
            return Container(
              padding: const EdgeInsets.all(14),
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
                      Expanded(
                        child: _buildPricingCard(
                          context,
                          'Monthly',
                          pricing.formatMonthly(),
                          subtitle: 'per month',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPricingCard(
                          context,
                          'Yearly',
                          pricing.formatYearly(),
                          subtitle: 'per year',
                          savings: savings,
                        ),
                      ),
                    ],
                  ),
                  if (savings != null && savings > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Users save ${savings.toStringAsFixed(1)}% with yearly plan',
                              style: TextStyle(
                                fontSize: 11,
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
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    double? savings,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: _textStyle(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ),
              if (savings != null && savings > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Best Value',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: _textStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: _textStyle(
                context,
                fontSize: 10,
                color: AppColors.dynamicTextSecondary(context),
              ),
            ),
          ],
        ],
      ),
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
            'Contact admin',
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
                    'Message on WhatsApp',
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
                    'Call admin',
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
