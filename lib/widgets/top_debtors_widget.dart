import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_layout.dart';

class TopDebtorsWidget extends StatelessWidget {
  const TopDebtorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customers = appState.customers;
        final debts = appState.debts;
        
        // Calculate total debt for each customer (same as debts page)
        final Map<String, double> customerDebts = {};
        for (final customer in customers) {
          final customerDebtsList = debts.where((debt) => 
            debt.customerId == customer.id
          ).toList();
          
          // Calculate total remaining amount (same logic as debts page)
          final totalRemainingAmount = customerDebtsList.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
          
          if (totalRemainingAmount > 0) {
            customerDebts[customer.id] = totalRemainingAmount;
          }
        }
        
        // Sort customers by debt amount (descending)
        final sortedCustomers = customers.where((customer) => 
          customerDebts.containsKey(customer.id)
        ).toList()
          ..sort((a, b) {
            final debtA = customerDebts[a.id];
            final debtB = customerDebts[b.id];
            if (debtA == null || debtB == null) return 0;
            return debtB.compareTo(debtA);
          });
        
        // Take top 3
        final topDebtors = sortedCustomers.take(3).toList();

        final l10n = AppLocalizations.of(context)!;
        final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.leaderboard_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.topDebtors,
                    style: AppTheme.title3.copyWith(
                      color: AppColors.dynamicTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktopWeb ? 20 : 16),
              if (topDebtors.isEmpty)
                _buildEmptyState(context, l10n.noOutstandingDebts, isDesktopWeb)
              else if (isDesktopWeb)
                ...topDebtors.asMap().entries.map(
                  (entry) => _buildDesktopDebtorRow(
                    context,
                    rank: entry.key,
                    customerName: entry.value.name,
                    amount: customerDebts[entry.value.id] ?? 0.0,
                    isLast: entry.key == topDebtors.length - 1,
                  ),
                )
              else
                ...topDebtors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final customer = entry.value;
                  final totalDebt = customerDebts[customer.id] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _buildRankBadge(index),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(context, totalDebt),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(index),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, bool isDesktopWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktopWeb ? 32 : 24,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.dynamicBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicTextSecondary(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: isDesktopWeb ? 40 : 32,
            color: AppColors.dynamicTextSecondary(context),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTheme.subheadline.copyWith(
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDebtorRow(
    BuildContext context, {
    required int rank,
    required String customerName,
    required double amount,
    required bool isLast,
  }) {
    final color = _getRankColor(rank);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              _buildRankBadge(rank),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  customerName,
                  style: AppTheme.headline.copyWith(
                    color: AppColors.dynamicTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, amount),
                style: AppTheme.title3.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRankBadge(int index) {
    final color = _getRankColor(index);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return Colors.amber[700]!;
      case 1: return Colors.grey[600]!;
      case 2: return Colors.brown[600]!;
      default: return AppColors.textSecondary;
    }
  }

} 