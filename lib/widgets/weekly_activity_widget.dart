import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';

class WeeklyActivityWidget extends StatelessWidget {
  const WeeklyActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        final weeklyDebts = appState.debts.where((debt) {
          final dueDate = DateTime(debt.dueDate.year, debt.dueDate.month, debt.dueDate.day);
          final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
          return dueDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                 dueDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 debt.status != DebtStatus.paid;
        }).toList();

        // Group by day
        final Map<int, List<Debt>> debtsByDay = {};
        for (int i = 0; i < 7; i++) {
          final day = startOfWeek.add(Duration(days: i));
          final dayKey = day.millisecondsSinceEpoch;
          debtsByDay[dayKey] = weeklyDebts.where((debt) {
            final dueDate = DateTime(debt.dueDate.year, debt.dueDate.month, debt.dueDate.day);
            final dayDate = DateTime(day.year, day.month, day.day);
            return dueDate.isAtSameMomentAs(dayDate);
          }).toList();
        }

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
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "This Week's Activity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (weeklyDebts.isEmpty)
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 32,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No payments this week',
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
                    children: debtsByDay.entries.map((entry) {
                      final day = DateTime.fromMillisecondsSinceEpoch(entry.key);
                      final debts = entry.value;
                      
                      if (debts.isEmpty) return const SizedBox.shrink();
                      
                      final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
                      final isToday = day.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
                      final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isToday 
                                    ? AppColors.primary 
                                    : isPast 
                                        ? AppColors.error.withOpacity(0.1)
                                        : AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isToday 
                                        ? Colors.white 
                                        : isPast 
                                            ? AppColors.error
                                            : AppColors.secondary,
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
                                    _getDayName(day),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isToday 
                                          ? AppColors.primary 
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${debts.length} ${debts.length == 1 ? 'payment' : 'payments'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isToday 
                                    ? AppColors.primary 
                                    : isPast 
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                              ),
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

  String _getDayName(DateTime day) {
    final now = DateTime.now();
    if (day.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
      return 'Today';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (day.isAtSameMomentAs(DateTime(yesterday.year, yesterday.month, yesterday.day))) {
      return 'Yesterday';
    }
    
    final tomorrow = now.add(const Duration(days: 1));
    if (day.isAtSameMomentAs(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
      return 'Tomorrow';
    }
    
    switch (day.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
} 