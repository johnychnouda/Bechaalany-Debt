import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/admin_contact.dart';

enum AccessDeniedReason {
  trialExpired,
  accessExpired,
  accessRevoked,
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
      case AccessDeniedReason.accessExpired:
        return 'Access Expired';
      case AccessDeniedReason.accessRevoked:
        return 'Access Revoked';
    }
  }
  
  String get _description {
    switch (reason) {
      case AccessDeniedReason.trialExpired:
        return 'We could not verify your trial status. The app is free to use, but there may be an issue with your account. Please contact the administrator so we can restore your access.';
      case AccessDeniedReason.accessExpired:
        return 'We could not verify your access status. The app is free to use for all signed-in users. Please contact the administrator so we can fix your account.';
      case AccessDeniedReason.accessRevoked:
        return 'There is an issue with your account. Please contact the administrator so we can review and restore your access if appropriate.';
    }
  }
  
  Color get _iconColor {
    switch (reason) {
      case AccessDeniedReason.trialExpired:
        return Colors.orange;
      case AccessDeniedReason.accessExpired:
        return Colors.red;
      case AccessDeniedReason.accessRevoked:
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
                        'After you contact the administrator, we will review and fix any technical issues with your account so you can continue using the app.',
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
                    'Bechaalany Connect',
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
                    'Bechaalany Connect',
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
