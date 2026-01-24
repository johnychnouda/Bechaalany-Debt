import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/subscription_pricing_service.dart';
import '../models/subscription_pricing.dart';
import '../utils/admin_contact.dart';

enum AccessDeniedReason {
  trialExpired,
  subscriptionExpired,
  subscriptionCancelled,
}

class ContactOwnerScreen extends StatelessWidget {
  final AccessDeniedReason reason;
  
  const ContactOwnerScreen({
    super.key,
    this.reason = AccessDeniedReason.trialExpired,
  });

  static const Color _whatsappGreen = Color(0xFF25D366);
  
  String get _title {
    switch (reason) {
      case AccessDeniedReason.trialExpired:
        return 'Trial Expired';
      case AccessDeniedReason.subscriptionExpired:
        return 'Subscription Expired';
      case AccessDeniedReason.subscriptionCancelled:
        return 'Subscription Revoked';
    }
  }
  
  String get _description {
    switch (reason) {
      case AccessDeniedReason.trialExpired:
        return 'Your free trial has ended. To continue using the app, please contact the app owner to subscribe.';
      case AccessDeniedReason.subscriptionExpired:
        return 'Your subscription has expired. To continue using the app, please contact the app owner to renew your subscription.';
      case AccessDeniedReason.subscriptionCancelled:
        return 'Your subscription has been revoked. To continue using the app, please contact the app owner to reactivate your subscription.';
    }
  }
  
  Color get _iconColor {
    switch (reason) {
      case AccessDeniedReason.trialExpired:
        return Colors.orange;
      case AccessDeniedReason.subscriptionExpired:
        return Colors.red;
      case AccessDeniedReason.subscriptionCancelled:
        return Colors.red;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Contact Owner'),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _signOut(context),
          child: const Text('Sign out'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 60,
                  color: _iconColor,
                ),
              ),
              const SizedBox(height: 30),
              // Title
              Text(
                _title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextPrimary(context),
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                _description,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.dynamicTextSecondary(context),
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 40),
              // Subscription pricing
              _buildPricingSection(context),
              const SizedBox(height: 24),
              // WhatsApp
              _buildWhatsAppCard(context),
              const SizedBox(height: 16),
              // Call
              _buildCallCard(context),
              const SizedBox(height: 40),
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.dynamicBorder(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: AppColors.dynamicPrimary(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'After contacting the owner, your subscription will be activated and you\'ll be able to use the app again.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.dynamicTextSecondary(context),
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return StreamBuilder<SubscriptionPricing>(
      stream: SubscriptionPricingService().getPricingStream(),
      builder: (context, snapshot) {
        final pricing = snapshot.data ?? SubscriptionPricing.defaults;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription plans',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextPrimary(context),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.dynamicTextSecondary(context),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pricing.formatMonthly(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary(context),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppColors.dynamicBorder(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yearly',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.dynamicTextSecondary(context),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pricing.formatYearly(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary(context),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhatsAppCard(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => AdminContact.openWhatsApp(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _whatsappGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _whatsappGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _whatsappGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                'assets/images/whatsapp_logo.svg',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Message on WhatsApp',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AdminContact.whatsApp,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextSecondary(context),
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: _whatsappGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallCard(BuildContext context) {
    final primary = AppColors.dynamicPrimary(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => AdminContact.call(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.dynamicSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dynamicBorder(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(CupertinoIcons.phone_fill, color: primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Call owner',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary(context),
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AdminContact.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.dynamicTextSecondary(context),
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.dynamicTextSecondary(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
