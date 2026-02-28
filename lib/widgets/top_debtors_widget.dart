import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';

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

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26), // 0.1 * 255
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.topDebtors,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (topDebtors.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 32,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.noOutstandingDebts,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: topDebtors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final customer = entry.value;
                      final totalDebt = customerDebts[customer.id] ?? 0.0;
                      final customerDebtsList = debts.where((debt) => 
                        debt.customerId == customer.id
                      ).toList();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getRankColor(index).withAlpha(26), // 0.1 * 255
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getRankColor(index),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
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

  String _getRankLabel(int index) {
    switch (index) {
      case 0: return '1st';
      case 1: return '2nd';
      case 2: return '3rd';
      default: return '${index + 1}th';
    }
  }
} 