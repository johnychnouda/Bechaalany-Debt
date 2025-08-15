import '../models/debt.dart';
import '../models/partial_payment.dart';
import '../models/activity.dart';

/// Professional Revenue Calculation Service
/// Handles all revenue calculations with audit trail and precision
/// This service ensures revenue integrity and provides professional accounting standards
class RevenueCalculationService {
  static final RevenueCalculationService _instance = RevenueCalculationService._internal();
  factory RevenueCalculationService() => _instance;
  RevenueCalculationService._internal();

  /// Calculate total revenue from all customer payments
  /// This is the main method used in the dashboard
  double calculateTotalRevenue(List<Debt> debts, List<PartialPayment> partialPayments, {List<Activity>? activities}) {
    double totalRevenue = 0.0;
    
    print('=== REVENUE CALCULATION DEBUG ===');
    print('Total debts: ${debts.length}');
    print('Total activities: ${activities?.length ?? 0}');
    
    // Calculate revenue from all debts based on their payment status
    for (final debt in debts) {
      print('Debt: ${debt.description}');
      print('  - Amount: \$${debt.amount}');
      print('  - Paid: \$${debt.paidAmount}');
      print('  - Cost Price: \$${debt.originalCostPrice}');
      print('  - Selling Price: \$${debt.originalSellingPrice}');
      print('  - Original Revenue: \$${debt.originalRevenue}');
      print('  - Earned Revenue: \$${debt.earnedRevenue}');
      print('  - Is Fully Paid: ${debt.isFullyPaid}');
      
      if (debt.isFullyPaid) {
        // For fully paid debts, count the full original revenue
        totalRevenue += debt.originalRevenue;
        print('  - FULLY PAID: Adding full revenue \$${debt.originalRevenue}');
      } else if (debt.paidAmount > 0) {
        // For partially paid debts, count the proportional earned revenue
        totalRevenue += debt.earnedRevenue;
        print('  - PARTIALLY PAID: Adding earned revenue \$${debt.earnedRevenue}');
      } else {
        print('  - PENDING: No revenue yet');
      }
    }
    
    // CRITICAL: Also calculate revenue from cleared/deleted debts via activities
    if (activities != null) {
      print('\n=== CHECKING ACTIVITIES FOR CLEARED DEBTS ===');
      for (final activity in activities) {
        if (activity.type == ActivityType.debtCleared && activity.paymentAmount != null && activity.paymentAmount! > 0) {
          print('Activity: ${activity.description}');
          print('  - Type: ${activity.type}');
          print('  - Payment Amount: \$${activity.paymentAmount}');
          print('  - Notes: ${activity.notes}');
          
          // Try to extract revenue information from notes
          if (activity.notes != null && activity.notes!.contains('Revenue:')) {
            final revenueMatch = RegExp(r'Revenue: \$([\d.]+)').firstMatch(activity.notes!);
            if (revenueMatch != null) {
              final revenue = double.tryParse(revenueMatch.group(1) ?? '0') ?? 0.0;
              totalRevenue += revenue;
              print('  - EXTRACTED REVENUE: \$${revenue}');
              print('  - ADDING to total: \$${revenue}');
            }
          } else {
            // Fallback: estimate revenue based on payment amount and typical profit margins
            // This is a conservative estimate to maintain revenue integrity
            final estimatedRevenue = activity.paymentAmount! * 0.3; // Assume 30% profit margin
            totalRevenue += estimatedRevenue;
            print('  - ESTIMATED REVENUE: \$${estimatedRevenue} (30% of payment)');
            print('  - ADDING to total: \$${estimatedRevenue}');
          }
        }
      }
    }
    
    print('=== FINAL TOTAL REVENUE: \$$totalRevenue ===');
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
      if (!debt.isFullyPaid) {
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
      if (!debt.isFullyPaid) {
        totalAvailableRevenue += debt.remainingRevenue;
        totalDebtAmount += debt.remainingAmount;
      }
    }
    
    if (totalDebtAmount <= 0) return 0.0;
    
    // Calculate proportional revenue
    double revenueRatio = totalAvailableRevenue / totalDebtAmount;
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
  Map<String, dynamic> getDashboardRevenueSummary(List<Debt> allDebts, {List<Activity>? activities}) {
    double totalRevenue = 0.0;
    double totalPotentialRevenue = 0.0;
    double totalPaidAmount = 0.0;
    double totalDebtAmount = 0.0;
    
    int totalCustomers = 0;
    Set<String> customerIds = {};
    
    for (final debt in allDebts) {
      customerIds.add(debt.customerId);
      
      // Calculate revenue based on payment status
      if (debt.isFullyPaid) {
        // For fully paid debts, count the full original revenue
        totalRevenue += debt.originalRevenue;
      } else if (debt.paidAmount > 0) {
        // For partially paid debts, count the proportional earned revenue
        totalRevenue += debt.earnedRevenue;
      }
      
      totalPotentialRevenue += debt.remainingRevenue;
      totalPaidAmount += debt.paidAmount;
      totalDebtAmount += debt.amount;
    }
    
    // CRITICAL: Also include revenue from cleared/deleted debts via activities
    if (activities != null) {
      for (final activity in activities) {
        if (activity.type == ActivityType.debtCleared && activity.paymentAmount != null && activity.paymentAmount! > 0) {
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
    
    return {
      'totalRevenue': totalRevenue,
      'totalPotentialRevenue': totalPotentialRevenue,
      'totalPaidAmount': totalPaidAmount,
      'totalDebtAmount': totalDebtAmount,
      'totalCustomers': totalCustomers,
      'averageRevenuePerCustomer': totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0,
      'revenueToDebtRatio': totalDebtAmount > 0 ? totalRevenue / totalDebtAmount : 0.0,
      'calculatedAt': DateTime.now(),
    };
  }
}
