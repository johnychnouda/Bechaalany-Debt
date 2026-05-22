import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_layout.dart';


class ProfitLossWidget extends StatefulWidget {
  const ProfitLossWidget({super.key});

  @override
  State<ProfitLossWidget> createState() => _ProfitLossWidgetState();
}

class _ProfitLossWidgetState extends State<ProfitLossWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use professional revenue calculation based on product profit margins
        final totalRevenue = appState.totalHistoricalRevenue;
        
        // Get comprehensive revenue summary for dashboard
        final revenueSummary = appState.getDashboardRevenueSummary();
        
        // Use the proper getters from AppState for accurate calculations
        // Note: totalDebt and totalPaid are already in USD, no conversion needed
        final totalDebts = appState.totalDebt;
        final totalPayments = appState.totalPaid;



        final l10n = AppLocalizations.of(context)!;
        final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);
        final metrics = [
          (
            'total_revenue',
            l10n.totalRevenue,
            totalRevenue,
            Icons.arrow_upward,
            AppColors.success,
            l10n.fromProductProfitMargins,
          ),
          (
            'potential_revenue',
            l10n.potentialRevenue,
            (revenueSummary['totalPotentialRevenue'] as num?)?.toDouble() ?? 0.0,
            Icons.trending_up,
            AppColors.warning,
            l10n.fromUnpaidAmounts,
          ),
          (
            'total_debts',
            l10n.totalDebts,
            totalDebts,
            Icons.arrow_downward,
            AppColors.error,
            l10n.outstandingAmounts,
          ),
          (
            'total_payments',
            l10n.totalPayments,
            totalPayments,
            Icons.payment,
            AppColors.info,
            l10n.fromCustomerPayments,
          ),
        ];

        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildDashboardShell(
              context,
              isDesktopWeb: isDesktopWeb,
              title: l10n.financialAnalysis,
              icon: Icons.analytics_outlined,
              iconColor: AppColors.primary,
              child: isDesktopWeb
                  ? _buildDesktopMetricsGrid(context, metrics)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _buildProfitLossCard(
                            context,
                            metrics[i].$1,
                            metrics[i].$2,
                            metrics[i].$3,
                            metrics[i].$4,
                            metrics[i].$5,
                            subtitle: metrics[i].$6,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardShell(
    BuildContext context, {
    required bool isDesktopWeb,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
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
              Text(
                title,
                style: AppTheme.title3.copyWith(
                  color: AppColors.dynamicTextPrimary(context),
                  fontWeight: FontWeight.w600,
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

  Widget _buildDesktopMetricsGrid(
    BuildContext context,
    List<(String, String, double, IconData, Color, String)> metrics,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 16.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: tileWidth,
                child: _buildDesktopKpiCard(
                  context,
                  metric.$1,
                  metric.$2,
                  metric.$3,
                  metric.$4,
                  metric.$5,
                  subtitle: metric.$6,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopKpiCard(
    BuildContext context,
    String cardKey,
    String title,
    double amount,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final backgroundColor = _metricBackgroundColor(context, cardKey, color);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.subheadline.copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatAmount(context, amount),
            style: AppTheme.title1.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTheme.caption1.copyWith(
                color: AppColors.dynamicTextSecondary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _metricBackgroundColor(BuildContext context, String cardKey, Color fallback) {
    switch (cardKey) {
      case 'total_revenue':
        return AppColors.success.withValues(alpha: 0.08);
      case 'potential_revenue':
        return AppColors.warning.withValues(alpha: 0.08);
      case 'total_debts':
        return AppColors.error.withValues(alpha: 0.08);
      case 'total_payments':
        return AppColors.info.withValues(alpha: 0.08);
      default:
        return AppColors.dynamicSurface(context).withValues(alpha: 0.5);
    }
  }

  Widget _buildProfitLossCard(
    BuildContext context,
    String cardKey,
    String title,
    double amount,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final backgroundColor = _metricBackgroundColor(context, cardKey, color);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1), // 0.1 * 255
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.footnote.copyWith(
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, amount),
                style: AppTheme.title3.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                                 subtitle,
                 style: AppTheme.caption1.copyWith(
                   color: AppColors.dynamicTextSecondary(context),
                 ),
              ),
            ),
        ],
      ),
    );
  }




} 