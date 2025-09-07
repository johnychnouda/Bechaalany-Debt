import '../models/debt.dart';
import '../models/partial_payment.dart';
import '../models/activity.dart';
import '../providers/app_state.dart';

/// Professional Revenue Calculation Service
/// Handles all revenue calculations with audit trail and precision
/// This service ensures revenue integrity and provides professional accounting standards
class RevenueCalculationService {
  static final RevenueCalculationService _instance = RevenueCalculationService._internal();
  factory RevenueCalculationService() => _instance;
  RevenueCalculationService._internal();

  /// Calculate total revenue from all debts
  /// This is the main revenue calculation method
  double calculateTotalRevenue(List<Debt> debts, List<PartialPayment> partialPayments, {List<Activity>? activities, AppState? appState}) {
    double totalRevenue = 0.0;
    
    // Calculate revenue as profit from payments received
    // Revenue = profit margin on the amount actually paid by customers
    for (final debt in debts) {
      if (debt.paidAmount > 0 && debt.originalCostPrice != null && debt.originalSellingPrice != null) {
        // Calculate profit margin on the paid amount
        final profitMargin = (debt.originalSellingPrice! - debt.originalCostPrice!) / debt.originalSellingPrice!;
        final profitFromPaidAmount = debt.paidAmount * profitMargin;
        totalRevenue += profitFromPaidAmount;
        
      }
    }
    
    // CRITICAL: Also calculate revenue from cleared/deleted debts via activities
    if (activities != null) {
      for (final activity in activities) {
        if (false) { // debtCleared activities removed
          // Try to extract revenue information from notes
          if (activity.notes != null && activity.notes!.contains('Revenue:')) {
            final revenueMatch = RegExp(r'Revenue: \$([\d.]+)').firstMatch(activity.notes!);
            if (revenueMatch != null) {
              final revenue = double.tryParse(revenueMatch.group(1) ?? '0') ?? 0.0;
              totalRevenue += revenue;
            }
          } else {
            // Fallback: estimate revenue based on payment amount and typical profit margins
            // This is a conservative estimate to maintain revenue integrity
            final estimatedRevenue = activity.paymentAmount! * 0.3; // Assume 30% profit margin
            totalRevenue += estimatedRevenue;
          }
        }
      }
    }
    
    return totalRevenue;
  }

  /// Calculate revenue for a specific customer
  /// Used in customer financial summary
  double calculateCustomerRevenue(String customerId, List<Debt> allDebts) {
    final customerDebts = allDebts.where((debt) => debt.customerId == customerId).toList();
    
    double totalRevenue = 0.0;
    
    for (final debt in customerDebts) {
      if (debt.isFullyPaid) {
        // For fully paid debts, count the full original revenue
        totalRevenue += debt.originalRevenue;
      } else if (debt.paidAmount > 0) {
        // For partially paid debts, count the proportional earned revenue
        totalRevenue += debt.earnedRevenue;
      }
    }
    
    return totalRevenue;
  }

  /// Calculate potential revenue for a customer (from unpaid amounts)
  double calculateCustomerPotentialRevenue(String customerId, List<Debt> allDebts) {
    final customerDebts = allDebts.where((debt) => debt.customerId == customerId).toList();
    
    double potentialRevenue = 0.0;
    for (final debt in customerDebts) {
      // Only include debts with remaining amounts > 0.01 (account for floating-point precision)
      if (debt.remainingAmount > 0.01) {
        potentialRevenue += debt.remainingRevenue;
      }
    }
    
    return potentialRevenue;
  }

  /// Calculate revenue from a specific payment amount
  /// This is the core method for proportional revenue calculation
  double calculateRevenueFromPayment(double paymentAmount, List<Debt> customerDebts) {
    if (customerDebts.isEmpty || paymentAmount <= 0) return 0.0;
    
    // Calculate total available revenue and total debt amount
    double totalAvailableRevenue = 0.0;
    double totalDebtAmount = 0.0;
    
    for (final debt in customerDebts) {
      if (debt.remainingAmount > 0.01) {
        totalAvailableRevenue += debt.remainingRevenue;
        totalDebtAmount += debt.remainingAmount;
      }
    }
    
    if (totalDebtAmount <= 0) return 0.0;
    
    // Calculate proportional revenue based on payment amount
    final revenueRatio = totalAvailableRevenue / totalDebtAmount;
    return paymentAmount * revenueRatio;
  }

  /// Calculate revenue from a specific payment amount for a customer
  /// This is the core method for proportional revenue calculation
  double calculateRevenueFromPaymentForCustomer(double paymentAmount, String customerId, List<Debt> allDebts, AppState appState) {
    final customerDebts = allDebts.where((debt) => debt.customerId == customerId).toList();
    
    if (customerDebts.isEmpty || paymentAmount <= 0) return 0.0;
    
    // Calculate total available revenue and total debt amount
    double totalAvailableRevenue = 0.0;
    double totalDebtAmount = 0.0;
    
    for (final debt in customerDebts) {
      if (debt.remainingAmount > 0.01) {
        totalAvailableRevenue += debt.remainingRevenue;
        totalDebtAmount += debt.remainingAmount;
      }
    }
    
    if (totalDebtAmount <= 0) return 0.0;
    
    // Calculate proportional revenue based on payment amount
    final revenueRatio = totalAvailableRevenue / totalDebtAmount;
    return paymentAmount * revenueRatio;
  }

  /// Get detailed revenue breakdown for a customer
  /// Used for financial reporting and auditing
  Map<String, dynamic> getCustomerRevenueBreakdown(String customerId, List<Debt> allDebts) {
    final customerDebts = allDebts.where((debt) => debt.customerId == customerId).toList();
    
    double totalRevenue = 0.0;
    double totalPotentialRevenue = 0.0;
    double totalPaidAmount = 0.0;
    double totalRemainingAmount = 0.0;
    
    List<Map<String, dynamic>> debtBreakdown = [];
    
    for (final debt in customerDebts) {
      final debtRevenue = debt.earnedRevenue;
      final debtPotentialRevenue = debt.remainingRevenue;
      
      totalRevenue += debtRevenue;
      totalPotentialRevenue += debtPotentialRevenue;
      totalPaidAmount += debt.paidAmount;
      totalRemainingAmount += debt.remainingAmount;
      
      debtBreakdown.add({
        'debtId': debt.id,
        'description': debt.description,
        'amount': debt.amount,
        'paidAmount': debt.paidAmount,
        'remainingAmount': debt.remainingAmount,
        'originalRevenue': debt.originalRevenue,
        'earnedRevenue': debtRevenue,
        'potentialRevenue': debtPotentialRevenue,
        'revenuePerDollar': debt.revenuePerDollar,
        'createdAt': debt.createdAt,
      });
    }
    
    return {
      'customerId': customerId,
      'totalRevenue': totalRevenue,
      'totalPotentialRevenue': totalPotentialRevenue,
      'totalPaidAmount': totalPaidAmount,
      'totalRemainingAmount': totalRemainingAmount,
      'debtBreakdown': debtBreakdown,
      'calculatedAt': DateTime.now(),
    };
  }

  /// Validate revenue calculation integrity
  /// This method ensures revenue calculations are mathematically sound
  bool validateRevenueIntegrity(List<Debt> debts) {
    for (final debt in debts) {
      // Check if revenue per dollar calculation is valid
      if (debt.amount > 0 && debt.originalRevenue >= 0) {
        final calculatedRevenuePerDollar = debt.originalRevenue / debt.amount;
        if ((calculatedRevenuePerDollar - debt.revenuePerDollar).abs() > 0.001) {
          return false; // Revenue calculation mismatch
        }
      }
      
      // Check if earned revenue calculation is valid
      if (debt.paidAmount > 0) {
        final calculatedEarnedRevenue = debt.revenuePerDollar * debt.paidAmount;
        if ((calculatedEarnedRevenue - debt.earnedRevenue).abs() > 0.001) {
          return false; // Earned revenue calculation mismatch
        }
      }
    }
    
    return true;
  }

  /// Get revenue summary for dashboard
  /// Provides aggregated revenue data for the main dashboard
  /// Now considers customer-level debt status for accurate revenue recognition
  Map<String, dynamic> getDashboardRevenueSummary(List<Debt> allDebts, {List<Activity>? activities, AppState? appState}) {
    double totalRevenue = 0.0;
    double totalPotentialRevenue = 0.0;
    double totalPaidAmount = 0.0;
    double totalDebtAmount = 0.0;
    
    int totalCustomers = 0;
    Set<String> customerIds = {};
    
    for (final debt in allDebts) {
      customerIds.add(debt.customerId);
      
      // NEW LOGIC: Revenue is only recognized when customer is fully settled
      // Individual debt status is determined by customer's overall debt status
      if (appState != null) {
        final customerId = debt.customerId;
        final isCustomerFullyPaid = appState.isCustomerFullyPaid(customerId);
        final isCustomerPartiallyPaid = appState.isCustomerPartiallyPaid(customerId);
        
        if (isCustomerFullyPaid) {
          // Customer has settled ALL debts - recognize full revenue for this debt
          totalRevenue += debt.originalRevenue;
        } else if (isCustomerPartiallyPaid && debt.paidAmount > 0) {
          // Customer has made some payments but not settled all debts - recognize proportional revenue
          totalRevenue += debt.earnedRevenue;
        }
        // If customer is pending, no revenue is recognized
      } else {
        // Fallback to old logic if AppState not provided
        if (debt.isFullyPaid) {
          totalRevenue += debt.originalRevenue;
        } else if (debt.paidAmount > 0) {
          totalRevenue += debt.earnedRevenue;
        }
      }
      
      // Calculate potential revenue from unpaid amounts
      // SIMPLIFIED LOGIC: Only process debts with remaining amounts > 0.01 (account for floating-point precision)
      if (debt.remainingAmount > 0.01) {
        if (debt.originalCostPrice != null && debt.originalSellingPrice != null) {
          // Use the proper remainingRevenue calculation which automatically reduces with payments
          final remainingRevenue = debt.remainingRevenue;
          totalPotentialRevenue += remainingRevenue;
          
        } else {
          // Fallback: use remaining debt amount as potential revenue when cost prices aren't set
          totalPotentialRevenue += debt.remainingAmount;
        }
      }
      
      totalPaidAmount += debt.paidAmount;
      totalDebtAmount += debt.remainingAmount; // Use remaining amount for total debts
    }
    


    

    
    // CRITICAL: Also include revenue from cleared/deleted debts via activities
    if (activities != null) {
      for (final activity in activities) {
        if (false) { // debtCleared activities removed
          // Try to extract revenue information from notes
          if (activity.notes != null && activity.notes!.contains('Revenue:')) {
            final revenueMatch = RegExp(r'Revenue: \$([\d.]+)').firstMatch(activity.notes!);
            if (revenueMatch != null) {
              final revenue = double.tryParse(revenueMatch.group(1) ?? '0') ?? 0.0;
              totalRevenue += revenue;
            }
          } else {
            // Fallback: estimate revenue based on payment amount and typical profit margins
            final estimatedRevenue = activity.paymentAmount! * 0.3; // Assume 30% profit margin
            totalRevenue += estimatedRevenue;
          }
        }
      }
    }
    
    totalCustomers = customerIds.length;
    
    // CRITICAL: Round all financial values to exactly 2 decimal places to avoid floating-point precision errors
    totalRevenue = (totalRevenue * 100).round() / 100;
    totalPotentialRevenue = (totalPotentialRevenue * 100).round() / 100;
    totalPaidAmount = (totalPaidAmount * 100).round() / 100;
    totalDebtAmount = (totalDebtAmount * 100).round() / 100;
    
    return {
      'totalRevenue': totalRevenue,
      'totalPotentialRevenue': totalPotentialRevenue,
      'totalPaidAmount': totalPaidAmount,
      'totalDebtAmount': totalDebtAmount,
      'totalCustomers': totalCustomers,
      'averageRevenuePerCustomer': totalCustomers > 0 ? (totalRevenue / totalCustomers * 100).round() / 100 : 0.0,
      'revenueToDebtRatio': totalDebtAmount > 0 ? (totalRevenue / totalDebtAmount * 100).round() / 100 : 0.0,
      'calculatedAt': DateTime.now(),
    };
  }
}
