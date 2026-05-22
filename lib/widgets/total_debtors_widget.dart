import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/responsive_layout.dart';

class TotalDebtorsWidget extends StatelessWidget {
  const TotalDebtorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Get unique customers with pending debts
        final customersWithPendingDebts = appState.debts
            .where((debt) => !debt.isFullyPaid)
            .map((debt) => debt.customerId)
            .toSet()
            .length;

        final totalCustomers = appState.customers.length;

        final l10n = AppLocalizations.of(context)!;
        final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

        return _DashboardSectionCard(
          isDesktopWeb: isDesktopWeb,
          title: l10n.totalCustomersAndDebtors,
          icon: Icons.people_outline,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktopWeb) ...[
                _buildStatItem(
                  context,
                  l10n.customersWithDebts,
                  customersWithPendingDebts.toString(),
                  AppColors.warning,
                  Icons.account_balance_wallet,
                  compact: false,
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  context,
                  l10n.totalCustomers,
                  totalCustomers.toString(),
                  AppColors.primary,
                  Icons.people_outline,
                  compact: false,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        l10n.customersWithDebts,
                        customersWithPendingDebts.toString(),
                        AppColors.warning,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        l10n.totalCustomers,
                        totalCustomers.toString(),
                        AppColors.primary,
                        Icons.people_outline,
                      ),
                    ),
                  ],
                ),
                
              if (totalCustomers == 0) ...[
                const SizedBox(height: 12),
                _buildInsightBanner(
                  context,
                  AppColors.info,
                  l10n.noCustomersAddedYet,
                ),
              ] else if (customersWithPendingDebts > 0) ...[
                const SizedBox(height: 12),
                _buildInsightBanner(
                  context,
                  AppColors.warning,
                  l10n.percentCustomersPendingDebts(
                    ((customersWithPendingDebts / totalCustomers) * 100)
                        .toStringAsFixed(1),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightBanner(BuildContext context, Color color, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon, {
    bool compact = true,
  }) {
    if (!compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.title1.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTheme.subheadline.copyWith(
                color: AppColors.dynamicTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  final bool isDesktopWeb;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DashboardSectionCard({
    required this.isDesktopWeb,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicTextSecondary(context).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.title3.copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktopWeb ? 20 : 16),
          child,
        ],
      ),
    );
  }
} 