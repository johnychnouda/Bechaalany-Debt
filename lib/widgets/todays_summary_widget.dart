import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';

class TodaysSummaryWidget extends StatelessWidget {
  const TodaysSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final today = DateTime.now();
        final todayDebts = appState.debts.where((debt) {
          final dueDate = DateTime(debt.dueDate.year, debt.dueDate.month, debt.dueDate.day);
          final todayDate = DateTime(today.year, today.month, today.day);
          return dueDate.isAtSameMomentAs(todayDate) && debt.status != DebtStatus.paid;
        }).toList();

        final overdueDebts = appState.debts.where((debt) {
          final dueDate = DateTime(debt.dueDate.year, debt.dueDate.month, debt.dueDate.day);
          final todayDate = DateTime(today.year, today.month, today.day);
          return dueDate.isBefore(todayDate) && debt.status != DebtStatus.paid;
        }).toList();

        final totalDueToday = todayDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
        final totalOverdue = overdueDebts.fold<double>(0, (sum, debt) => sum + debt.amount);

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
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Today's Summary",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (todayDebts.isEmpty && overdueDebts.isEmpty)
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 32,
                          color: AppColors.success,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No payments due today!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      if (todayDebts.isNotEmpty) ...[
                        _SummaryRow(
                          title: 'Due Today',
                          amount: totalDueToday,
                          count: todayDebts.length,
                          color: AppColors.warning,
                          icon: Icons.schedule,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (overdueDebts.isNotEmpty) ...[
                        _SummaryRow(
                          title: 'Overdue',
                          amount: totalOverdue,
                          count: overdueDebts.length,
                          color: AppColors.error,
                          icon: Icons.warning,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryRow({
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'debt' : 'debts'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
} 