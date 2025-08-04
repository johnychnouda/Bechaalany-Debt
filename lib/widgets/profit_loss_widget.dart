import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
// import '../models/debt.dart'; // Removed unused import
import '../models/activity.dart';

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
        // Calculate total revenue as profit from all paid amounts (full + partial payments)
        final totalRevenue = appState.debts.fold<double>(0.0, (sum, debt) {
          // Calculate revenue for any debt that has been paid (fully or partially)
          if (debt.paidAmount > 0) {
            // Handle case where originalSellingPrice might not be set for existing debts
            double? sellingPrice = debt.originalSellingPrice;
            if (sellingPrice == null && debt.subcategoryName != null) {
              // Try to find the subcategory and get its current selling price
              try {
                print('Looking for subcategory: ${debt.subcategoryName}');
                print('Available subcategories: ${appState.categories.expand((category) => category.subcategories).map((sub) => sub.name).toList()}');
                
                final subcategory = appState.categories
                    .expand((category) => category.subcategories)
                    .firstWhere((sub) => sub.name == debt.subcategoryName);
                sellingPrice = subcategory.sellingPrice;
                print('Found subcategory: ${subcategory.name} with selling price: ${subcategory.sellingPrice}');
              } catch (e) {
                // If subcategory not found, skip this debt
                print('Skipping debt ${debt.id}: subcategory ${debt.subcategoryName} not found');
                return sum;
              }
            } else if (sellingPrice == null) {
              // If no subcategory name, try to infer from description
              print('No subcategory name for debt ${debt.id}, trying to infer from description: ${debt.description}');
              if (debt.description.toLowerCase().contains('alfa')) {
                // Assume Alfa product with $15 selling price and $1 cost
                sellingPrice = 15.0;
                print('Inferred Alfa product with selling price: $sellingPrice');
              }
            }
            
            if (sellingPrice != null) {
              print('Processing debt: ${debt.id}');
              print('  - paidAmount: ${debt.paidAmount}');
              print('  - sellingPrice: $sellingPrice');
              print('  - subcategoryName: ${debt.subcategoryName}');
              
              // Find the subcategory to get cost price
              if (debt.subcategoryName != null) {
                try {
                  final subcategory = appState.categories
                      .expand((category) => category.subcategories)
                      .firstWhere((sub) => sub.name == debt.subcategoryName);
                  
                  print('  - found subcategory: ${subcategory.name}');
                  print('  - subcategory costPrice: ${subcategory.costPrice}');
                  
                  // Calculate profit ratio: (selling price - cost price) / selling price
                  final profitRatio = (sellingPrice! - subcategory.costPrice) / sellingPrice!;
                  print('  - profitRatio: $profitRatio');
                  
                  // Calculate actual profit from paid amount: paid amount * profit ratio
                  final profitFromPaidAmount = debt.paidAmount * profitRatio;
                  print('  - profitFromPaidAmount: $profitFromPaidAmount');
                  
                  return sum + profitFromPaidAmount;
                } catch (e) {
                  print('  - subcategory not found, using inferred cost price');
                  // If subcategory not found but we have a selling price, use inferred cost
                  double costPrice = 1.0; // Default cost for Alfa
                  if (debt.description.toLowerCase().contains('alfa')) {
                    costPrice = 1.0;
                  }
                  
                  final profitRatio = (sellingPrice! - costPrice) / sellingPrice!;
                  print('  - inferred costPrice: $costPrice');
                  print('  - profitRatio: $profitRatio');
                  
                  final profitFromPaidAmount = debt.paidAmount * profitRatio;
                  print('  - profitFromPaidAmount: $profitFromPaidAmount');
                  
                  return sum + profitFromPaidAmount;
                }
              } else {
                // No subcategory name, use inferred cost based on description
                print('  - no subcategory name, using inferred cost price');
                double costPrice = 1.0; // Default cost for Alfa
                if (debt.description.toLowerCase().contains('alfa')) {
                  costPrice = 1.0;
                }
                
                final profitRatio = (sellingPrice! - costPrice) / sellingPrice!;
                print('  - inferred costPrice: $costPrice');
                print('  - profitRatio: $profitRatio');
                
                final profitFromPaidAmount = debt.paidAmount * profitRatio;
                print('  - profitFromPaidAmount: $profitFromPaidAmount');
                
                return sum + profitFromPaidAmount;
              }
            } else {
              print('Skipping debt: ${debt.id} - paidAmount: ${debt.paidAmount}');
            }
          }
          return sum;
        });
        
        print('Total Revenue calculated: $totalRevenue');
        print('Total debts: ${appState.debts.length}');
        print('Debts with paidAmount > 0: ${appState.debts.where((d) => d.paidAmount > 0).length}');
        print('Debts with originalSellingPrice: ${appState.debts.where((d) => d.originalSellingPrice != null).length}');
        print('Debts with both paidAmount > 0 and originalSellingPrice: ${appState.debts.where((d) => d.paidAmount > 0 && d.originalSellingPrice != null).length}');
        
        // Debug: Print details of all debts with paid amounts
        for (final debt in appState.debts.where((d) => d.paidAmount > 0)) {
          print('Debt ${debt.id}:');
          print('  - paidAmount: ${debt.paidAmount}');
          print('  - originalSellingPrice: ${debt.originalSellingPrice}');
          print('  - subcategoryName: ${debt.subcategoryName}');
          print('  - description: ${debt.description}');
        }
        
        // Calculate total debts: sum of all debt amounts minus total partial payments
        final totalDebtAmount = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.amount);
        final totalPartialPayments = appState.debts.fold<double>(0.0, (sum, debt) => sum + debt.paidAmount);
        final totalDebts = totalDebtAmount - totalPartialPayments;


        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16), // Reduced from 20
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.dynamicSurface(context).withValues(alpha: 0.8),
                    AppColors.dynamicSurface(context).withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Revenue',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '/',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.dynamicTextPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: 'Debts',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' Analysis',
                              style: AppTheme.title3.copyWith(
                                color: AppColors.dynamicTextPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProfitLossCard(
                    'Total Revenue',
                    totalRevenue,
                    Icons.arrow_upward,
                    AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _buildProfitLossCard(
                    'Total Debts',
                    totalDebts,
                    Icons.arrow_downward,
                    AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfitLossCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context).withValues(alpha: 0.5), // 0.5 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1), // 0.1 * 255
        ),
      ),
      child: Row(
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
    );
  }

  // Removed _calculateTotalExpenses method as we now use totalDebt from AppState
} 