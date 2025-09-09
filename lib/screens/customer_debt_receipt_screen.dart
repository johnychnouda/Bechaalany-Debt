import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Conditional imports for web compatibility
import 'package:share_plus/share_plus.dart';

// These imports are only used in mobile-specific code
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/partial_payment.dart';
import '../models/activity.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/pdf_font_utils.dart';
import '../utils/logo_utils.dart';
import '../utils/debt_description_utils.dart';
import '../services/receipt_sharing_service.dart';
import '../providers/app_state.dart';
import 'add_customer_screen.dart';

class CustomerDebtReceiptScreen extends StatefulWidget {
  final Customer customer;
  final List<Debt> customerDebts;
  final List<PartialPayment> partialPayments;
  final List<Activity> activities;
  final DateTime? specificDate; // Optional date to filter debts
  final String? specificDebtId; // Optional specific debt ID to show only that debt

  const CustomerDebtReceiptScreen({
    super.key,
    required this.customer,
    required this.customerDebts,
    required this.partialPayments,
    required this.activities,
    this.specificDate,
    this.specificDebtId,
  });

  @override
  State<CustomerDebtReceiptScreen> createState() => _CustomerDebtReceiptScreenState();
}

class _CustomerDebtReceiptScreenState extends State<CustomerDebtReceiptScreen> {
  
  List<Debt> _getRelevantDebts(List<Debt> allCustomerDebts) {
    // If a specific debt ID is provided, show all debts until partial payment
    if (widget.specificDebtId != null) {
      // Check if any partial payments have been made
      final hasPartialPayments = allCustomerDebts.any((debt) => debt.paidAmount > 0);
      
      if (hasPartialPayments) {
        // If partial payments exist, show only the specific debt
        return allCustomerDebts.where((debt) {
          return debt.id == widget.specificDebtId;
        }).toList();
      } else {
        // If no partial payments, show all debts (accumulate all new debts)
        return allCustomerDebts.where((debt) => debt.paidAmount == 0).toList();
      }
    }
    
    // If a specific date is provided, filter debts to only include those relevant to that date
    if (widget.specificDate != null) {
      final targetDate = widget.specificDate!;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return allCustomerDebts.where((debt) {
        // Include debts created within 1 hour of the specific debt time
        return debt.createdAt.isAfter(startTime) && debt.createdAt.isBefore(endTime);
      }).toList();
    }
    
    // If no specific date or debt ID, show only active debts (not fully paid)
    // This excludes old debts that were already paid off
    return allCustomerDebts.where((debt) => !debt.isFullyPaid).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    // Add debugging for web
    if (kIsWeb) {

    }
    
    // Filter debts to only include those relevant to the payment being viewed
    // This excludes new debts that were created after the payment was completed
    final relevantDebts = _getRelevantDebts(widget.customerDebts);
    
    // Check if customer has ANY partial payments (this will hide all red X icons)
    final customerHasPartialPayments = widget.customerDebts.any((d) => d.paidAmount > 0);
    
    final sortedDebts = List<Debt>.from(relevantDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    // Get relevant partial payments and activities for accurate total calculation
    final relevantPartialPayments = _getRelevantPartialPayments(widget.partialPayments, sortedDebts);
    final relevantPaymentActivities = _getRelevantPaymentActivities(widget.activities, sortedDebts);
    
    // Calculate total paid amount from relevant partial payments
    final totalPaidFromPartialPayments = relevantPartialPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
    
    // Calculate total paid amount from relevant payment activities
    final totalPaidFromActivities = relevantPaymentActivities.fold<double>(0, (sum, activity) => sum + (activity.paymentAmount ?? 0));
    
    // Use the higher of the two values to ensure we don't miss any payments
    final totalPaidAmount = totalPaidFromActivities > totalPaidFromPartialPayments ? totalPaidFromActivities : totalPaidFromPartialPayments;
    
    // Calculate total original amount
    final totalOriginalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    


    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        title: Text(
          'Receipt',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.dynamicTextPrimary(context),
          ),
          onPressed: () {
            // Web-compatible navigation
            if (kIsWeb) {
              // For web, just pop once and let the browser handle navigation
              Navigator.of(context).pop();
            } else {
              // For mobile, pop multiple times to get back to customer details
              Navigator.of(context).pop(); // Pop receipt
              Navigator.of(context).pop(); // Pop debt history
              Navigator.of(context).pop(); // Pop any other screen
            }
          },
        ),
        iconTheme: IconThemeData(
          color: AppColors.dynamicTextPrimary(context),
        ),
        actions: [
          // Contact sharing button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showContactSharingOptions(),
            child: Icon(
              CupertinoIcons.person_crop_circle_badge_plus,
              color: AppColors.primary,
            ),
          ),
          // Regular share button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _shareReceipt(),
            child: Icon(
              CupertinoIcons.share,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptHeader(),
            const SizedBox(height: 24),
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            _buildDebtDetails(sortedDebts, customerHasPartialPayments),
            const SizedBox(height: 24),
            _buildTotalAmount(remainingAmount, totalPaidAmount, totalOriginalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          LogoUtils.buildLogo(
            context: context,
            width: 32,
            height: 32,
            placeholder: Icon(
              Icons.account_balance_wallet,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Bechaalany Connect',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextPrimary(context),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.dynamicTextSecondary(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.dynamicTextSecondary(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.customer.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          if (widget.customer.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.dynamicTextSecondary(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.customer.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.dynamicTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tag, size: 16, color: AppColors.dynamicTextSecondary(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${widget.customer.id}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetails(List<Debt> sortedDebts, bool customerHasPartialPayments) {
    List<Map<String, dynamic>> allItems = [];
    
    for (Debt debt in sortedDebts) {
      final cleanedDescription = DebtDescriptionUtils.cleanDescription(debt.description);
      
      // Always show the debt/product
      allItems.add({
        'type': 'debt',
        'description': cleanedDescription,
        'amount': debt.amount,
        'date': debt.createdAt,
        'debt': debt,
      });
    }
    
    // Filter partial payments to only include those relevant to the debts being shown
    final relevantPartialPayments = _getRelevantPartialPayments(widget.partialPayments, sortedDebts);
    
    // Add relevant partial payments
    for (PartialPayment payment in relevantPartialPayments) {
      allItems.add({
        'type': 'partial_payment',
        'description': 'Partial Payment',
        'amount': payment.amount,
        'date': payment.paidAt,
        'payment': payment,
      });
    }
    
    // Filter payment activities to only include those relevant to the debts being shown
    final relevantPaymentActivities = _getRelevantPaymentActivities(widget.activities, sortedDebts);
    
    // Add relevant payment activities (these are the actual partial payments shown in Activity History)
    for (Activity activity in relevantPaymentActivities) {
      // Only add payment activities that have a payment amount
      if (activity.paymentAmount != null && activity.paymentAmount! > 0) {
        allItems.add({
          'type': 'payment_activity',
          'description': 'Partial Payment',
          'amount': activity.paymentAmount!,
          'date': activity.date,
          'activity': activity,
        });
      }
    }
    
    allItems.sort((a, b) => b['date'].compareTo(a['date']));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DEBT DETAILS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextPrimary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...allItems.map((item) {
            if (item['type'] == 'debt') {
              return _buildDebtItem(item['debt'] as Debt, customerHasPartialPayments);
            } else if (item['type'] == 'payment_activity') {
              return _buildPaymentActivityItem(item['activity'] as Activity);
            } else if (item['type'] == 'partial_payment') {
              return _buildPartialPaymentItem(item['payment'] as PartialPayment);
            } else {
              return const SizedBox.shrink();
            }
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDebtItem(Debt debt, bool customerHasPartialPayments) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DebtDescriptionUtils.cleanDescription(debt.description),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              // Delete button for debt management - Only show when customer has NO partial payments at all
              if (!customerHasPartialPayments) ...[
                GestureDetector(
                  onTap: () => _showDeleteDebtDialog(debt),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ] else ...[
                // Show info icon when delete is not available (customer has partial payments)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicTextSecondary(context).withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          Text(
            _formatDateTime(debt.createdAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  List<PartialPayment> _getPartialPaymentsForDebt(String debtId) {
    final payments = widget.partialPayments
        .where((payment) => payment.debtId == debtId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return payments;
  }

  Widget _buildPaymentActivityItem(Activity activity) {
    final isFullPayment = activity.isPaymentCompleted;
    final paymentColor = isFullPayment ? AppColors.dynamicSuccess(context) : AppColors.dynamicWarning(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: paymentColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFullPayment ? Icons.check_circle : Icons.payment,
                  size: 14,
                  color: paymentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.paymentAmount == activity.amount ? 'Payment completed' : 'Partial payment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, activity.paymentAmount ?? 0),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: paymentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(activity.date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: paymentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialPaymentItem(PartialPayment payment) {
    final paymentColor = AppColors.dynamicSuccess(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dynamicBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: paymentColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  size: 14,
                  color: paymentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Partial Payment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.formatAmount(context, payment.amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: paymentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(payment.paidAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: paymentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount(double remainingAmount, double totalPaidAmount, double totalOriginalAmount) {
    // Determine the payment status for the relevant debts
    final hasPartialPayments = totalPaidAmount > 0;
    final allDebtsFullyPaid = remainingAmount == 0 && widget.customerDebts.isNotEmpty;
    final hasNewDebts = widget.customerDebts.any((debt) => debt.paidAmount == 0 && !debt.isFullyPaid);
    
    DateTime? latestPaymentDate;
    if (allDebtsFullyPaid) {
      latestPaymentDate = widget.customerDebts
          .where((debt) => debt.paidAt != null)
          .map((debt) => debt.paidAt!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Summary Section - Show all three totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL ORIGINAL AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, totalOriginalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicTextPrimary(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Total Paid Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL PAID AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicSuccess(context),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, totalPaidAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicSuccess(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Total Remaining Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL REMAINING AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicError(context),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, remainingAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dynamicError(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Case 1: New debt (no payments) - show only remaining amount
          if (hasNewDebts && !hasPartialPayments && !allDebtsFullyPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(context, remainingAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicError(context),
                  ),
                ),
              ],
            ),
          ],
          
          // Case 2: Partial payments made - show partially paid amount and remaining amount
          if (hasPartialPayments && !allDebtsFullyPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partially Paid Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(context, totalPaidAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicSuccess(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicTextSecondary(context),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(context, remainingAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicError(context),
                  ),
                ),
              ],
            ),
          ],
          
          // Case 3: Fully paid - show full paid amount status
          if (allDebtsFullyPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Debts Fully Paid',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dynamicSuccess(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(context, totalOriginalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dynamicSuccess(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: AppColors.dynamicSuccess(context),
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
            if (latestPaymentDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Paid on ${_formatDateTime(latestPaymentDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }



  String _formatDateTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at $displayHour:$displayMinute $period';
  }
  
  /// Get relevant partial payments based on the debts being shown
  List<PartialPayment> _getRelevantPartialPayments(
    List<PartialPayment> allPartialPayments,
    List<Debt> relevantDebts,
  ) {
    // If a specific debt ID is provided, only include payments for that debt
    if (widget.specificDebtId != null) {
      return allPartialPayments.where((payment) => payment.debtId == widget.specificDebtId).toList();
    }
    
    // If a specific date is provided, only include payments made within 1 hour of that date
    if (widget.specificDate != null) {
      final targetDate = widget.specificDate!;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return allPartialPayments.where((payment) {
        return payment.paidAt.isAfter(startTime) && payment.paidAt.isBefore(endTime);
      }).toList();
    }
    
    // If no specific filters, include only partial payments for the active debts being shown
    // This excludes payments for old debts that were already paid off
    final relevantDebtIds = relevantDebts.map((debt) => debt.id).toSet();
    return allPartialPayments.where((payment) => relevantDebtIds.contains(payment.debtId)).toList();
  }
  
  /// Get relevant payment activities based on the debts being shown
  List<Activity> _getRelevantPaymentActivities(
    List<Activity> allActivities,
    List<Debt> relevantDebts,
  ) {
    // Filter to only payment activities for this customer
    final customerPaymentActivities = allActivities
        .where((activity) => 
            activity.type == ActivityType.payment && 
            activity.customerId == widget.customer.id)
        .toList();
    
    // If a specific debt ID is provided, only include activities for that debt
    if (widget.specificDebtId != null) {
      return customerPaymentActivities.where((activity) => activity.debtId == widget.specificDebtId).toList();
    }
    
    // If a specific date is provided, only include activities within 1 hour of that date
    if (widget.specificDate != null) {
      final targetDate = widget.specificDate!;
      final startTime = targetDate.subtract(const Duration(hours: 1));
      final endTime = targetDate.add(const Duration(hours: 1));
      
      return customerPaymentActivities.where((activity) {
        return activity.date.isAfter(startTime) && activity.date.isBefore(endTime);
      }).toList();
    }
    
    // If no specific filters, include only payment activities for the active debts being shown
    // This excludes payments for old debts that were already paid off
    final relevantDebtIds = relevantDebts.map((debt) => debt.id).toSet();
    return customerPaymentActivities.where((activity) {
      // If activity has a specific debt ID, check if it matches
      if (activity.debtId != null) {
        return relevantDebtIds.contains(activity.debtId);
      }
      // If activity doesn't have a specific debt ID (cross-debt payment),
      // check if the activity date is after any of the relevant debts
      return relevantDebts.any((debt) => activity.date.isAfter(debt.createdAt));
    }).toList();
  }

  void _shareReceipt() async {
    try {
      await _exportAsPDF();
    } catch (e) {
      final notificationService = NotificationService();
    }
  }
  
  void _showContactSharingOptions() {
    // Check available contact methods
    final hasPhone = widget.customer.phone.isNotEmpty;
    final hasEmail = widget.customer.email != null && widget.customer.email!.isNotEmpty;
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Send Receipt',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Choose how to send the receipt to ${widget.customer.name}',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                if (hasPhone) ...[
                  _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.chat_bubble_2,
                    title: 'Send via WhatsApp',
                    subtitle: 'Share directly to customer',
                    color: CupertinoColors.systemGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _shareReceiptViaWhatsApp();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                

                
                if (hasPhone) ...[
                  _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.arrow_down_circle,
                    title: kIsWeb ? 'Download PDF' : 'Save to iPhone',
                    subtitle: kIsWeb ? 'Download receipt as PDF file' : 'Download to Files or Photos',
                    color: CupertinoColors.systemBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _saveReceiptToIPhone();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (!hasPhone && !hasEmail) ...[
                  _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.person_add,
                    title: 'Add Contact Information',
                    subtitle: 'Add phone or email to share receipts',
                    color: CupertinoColors.systemBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddContactInfoDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                const SizedBox(height: 16),
                
                // Cancel button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                                         Text(
                       subtitle,
                       style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                         fontSize: 14,
                         color: CupertinoColors.systemGrey.resolveFrom(context),
                       ),
                     ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3.resolveFrom(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Contact Information',
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          content: Text(
            'To send receipts, customers need either a phone number or email address. You can add this information by editing the customer profile.',
            style: TextStyle(
              color: AppColors.dynamicTextSecondary(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to edit customer screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCustomerScreen(customer: widget.customer),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary(context),
              ),
              child: Text(
                'Edit Customer',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _shareReceiptViaWhatsApp() async {
    try {
      final success = await ReceiptSharingService.shareReceiptViaWhatsApp(
        widget.customer,
        widget.customerDebts,
        widget.partialPayments,
        widget.activities,
        widget.specificDate,
        widget.specificDebtId,
      );
      
      if (success) {
        final notificationService = NotificationService();
      } else {
        final notificationService = NotificationService();
      }
    } catch (e) {
      final notificationService = NotificationService();
    }
  }
  
  Future<void> _shareReceiptViaEmail() async {
    try {
      final success = await ReceiptSharingService.shareReceiptViaEmail(
        widget.customer,
        widget.customerDebts,
        widget.partialPayments,
        widget.activities,
        widget.specificDate,
        widget.specificDebtId,
      );
      
      if (success) {
        final notificationService = NotificationService();
      } else {
        final notificationService = NotificationService();
      }
    } catch (e) {
      final notificationService = NotificationService();
    }
  }
  
  Future<void> _saveReceiptToIPhone() async {
    try {
      if (kIsWeb) {
        // For web, just export as PDF (download)
        await _exportAsPDF();
      } else {
        // Generate PDF receipt for iOS/Android
        final pdfFile = await ReceiptSharingService.generateReceiptPDF(
          customer: widget.customer,
          debts: widget.customerDebts,
          partialPayments: widget.partialPayments,
          activities: widget.activities,
          specificDate: widget.specificDate,
          specificDebtId: widget.specificDebtId,
        );
        
        if (pdfFile != null) {
          // Use the existing share functionality to save to iPhone
          await Share.shareXFiles([XFile(pdfFile.path)]);
          
          if (mounted) {
            final notificationService = NotificationService();
            await notificationService.showSuccessNotification(
              title: 'Receipt Saved',
              body: 'Receipt has been saved to your device',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Save Error',
          body: 'Failed to save receipt: $e',
        );
      }
    }
  }
  
  Future<void> _exportAsPDF() async {
    try {
      final pdf = PdfFontUtils.createDocumentWithFonts();
      await _buildMultiPagePDF(pdf);
      
      if (kIsWeb) {
        // Web-specific PDF handling - use share_plus for web compatibility
        try {
          // For web, use share_plus which handles web platforms better
          await Share.share(
            'Receipt for ${widget.customer.name}',
            subject: 'Debt Receipt - ${widget.customer.name}',
          );
          
          if (mounted) {
            final notificationService = NotificationService();
            await notificationService.showSuccessNotification(
              title: 'PDF Exported',
              body: 'Receipt has been exported successfully',
            );
          }
        } catch (e) {
          if (mounted) {
            final notificationService = NotificationService();
            await notificationService.showErrorNotification(
              title: 'Export Error',
              body: 'Failed to export PDF: $e',
            );
          }
        }
      } else {
        // Mobile PDF handling - only if not on web
        if (!kIsWeb) {
          final pdfBytes = await pdf.save();
          final now = DateTime.now();
          final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month}-${now.year}';
          final fileName = '${widget.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')}_${dateStr}_ID${widget.customer.id}.pdf';
          
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          
          await Share.shareXFiles([XFile(file.path)]);
          
          if (mounted) {
            final notificationService = NotificationService();
            await notificationService.showSuccessNotification(
              title: 'PDF Exported',
              body: 'Receipt has been exported successfully',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Export Error',
          body: 'Failed to export PDF: $e',
        );
      }
    }
  }

  Future<void> _buildMultiPagePDF(pw.Document pdf) async {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final remainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    
    final sanitizedCustomerName = PdfFontUtils.sanitizeText(widget.customer.name);
    final sanitizedCustomerPhone = PdfFontUtils.sanitizeText(widget.customer.phone);
    final sanitizedCustomerId = PdfFontUtils.sanitizeText(widget.customer.id);
    
    List<Map<String, dynamic>> allItems = [];
    
    for (Debt debt in sortedDebts) {
      final cleanedDescription = DebtDescriptionUtils.cleanDescription(debt.description);
      
      allItems.add({
        'type': 'debt',
        'description': cleanedDescription,
        'amount': debt.amount,
        'date': debt.createdAt,
        'debt': debt,
      });
      
      // Add partial payments for this debt, excluding the final payment
      final partialPayments = _getPartialPaymentsForDebt(debt.id);
      if (partialPayments.isNotEmpty && debt.isFullyPaid) {
        // For fully paid debts, exclude the most recent payment (the final payment)
        for (int i = 0; i < partialPayments.length; i++) {
          final payment = partialPayments[i];
          // Skip the most recent payment if the debt is fully paid
          if (!(i == 0 && debt.isFullyPaid)) {
            allItems.add({
              'type': 'partial_payment',
              'description': 'Partial Payment',
              'amount': payment.amount,
              'date': payment.paidAt,
            });
          }
        }
      } else {
        // For debts that are not fully paid, show all partial payments
        for (PartialPayment payment in partialPayments) {
          allItems.add({
            'type': 'partial_payment',
            'description': 'Partial Payment',
            'amount': payment.amount,
            'date': payment.paidAt,
          });
        }
      }
    }
    
    allItems.sort((a, b) => b['date'].compareTo(a['date']));
    
    const int itemsPerPage = 6;
    const int firstPageItemCount = 12;
    
    if (allItems.length <= firstPageItemCount) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return _buildPDFPage(
              pageItems: allItems,
              allItems: allItems,
              remainingAmount: remainingAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              pageIndex: 0,
              totalPages: 1,
              isFirstPage: true,
              isLastPage: true,
            );
          },
        ),
      );
    } else {
      int currentIndex = 0;
      int pageIndex = 0;
      
      final remainingItemsAfterFirstPage = allItems.length - firstPageItemCount;
      final additionalPagesNeeded = (remainingItemsAfterFirstPage / itemsPerPage).ceil();
      final totalPages = 1 + additionalPagesNeeded;
      
      final firstPageItems = allItems.take(firstPageItemCount).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return _buildPDFPage(
              pageItems: firstPageItems,
              allItems: allItems,
              remainingAmount: remainingAmount,
              sanitizedCustomerName: sanitizedCustomerName,
              sanitizedCustomerPhone: sanitizedCustomerPhone,
              sanitizedCustomerId: sanitizedCustomerId,
              pageIndex: pageIndex,
              totalPages: totalPages,
              isFirstPage: true,
              isLastPage: totalPages == 1,
            );
          },
        ),
      );
      
      currentIndex = firstPageItemCount;
      pageIndex++;
      
      while (currentIndex < allItems.length) {
        final pageItems = allItems.skip(currentIndex).take(itemsPerPage).toList();
        final isLastPage = pageIndex == totalPages - 1;
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(8),
            build: (pw.Context context) {
              return _buildPDFPage(
                pageItems: pageItems,
                allItems: allItems,
                remainingAmount: remainingAmount,
                sanitizedCustomerName: sanitizedCustomerName,
                sanitizedCustomerPhone: sanitizedCustomerPhone,
                sanitizedCustomerId: sanitizedCustomerId,
                pageIndex: pageIndex,
                totalPages: totalPages,
                isFirstPage: false,
                isLastPage: isLastPage,
              );
            },
          ),
        );
        
        currentIndex += itemsPerPage;
        pageIndex++;
      }
    }
  }

  pw.Widget _buildPDFPage({
    required List<Map<String, dynamic>> pageItems,
    required List<Map<String, dynamic>> allItems,
    required double remainingAmount,
    required String sanitizedCustomerName,
    required String sanitizedCustomerPhone,
    required String sanitizedCustomerId,
    required int pageIndex,
    required int totalPages,
    required bool isFirstPage,
    required bool isLastPage,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (isFirstPage) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    'Bechaalany Connect',
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: PdfFontUtils.createGracefulText(
                    _formatDateTime(DateTime.now()),
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'CUSTOMER INFORMATION',
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 4),
                PdfFontUtils.createGracefulText(
                  sanitizedCustomerName,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                if (sanitizedCustomerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  PdfFontUtils.createGracefulText(
                    sanitizedCustomerPhone,
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF424242),
                  ),
                ],
                pw.SizedBox(height: 2),
                PdfFontUtils.createGracefulText(
                  'ID: $sanitizedCustomerId',
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          
          PdfFontUtils.createGracefulText(
            'DEBT DETAILS',
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF424242),
          ),
          pw.SizedBox(height: 6),
        ],
        
        ...pageItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLastItem = index == pageItems.length - 1;
          
          return pw.Container(
            margin: pw.EdgeInsets.only(
              bottom: isLastItem ? 0 : 4,
            ),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfFontUtils.createGracefulText(
                        item['description'],
                        fontSize: 11,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    PdfFontUtils.createGracefulText(
                      _formatCurrency(item['amount']),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: item['type'] == 'partial_payment' 
                          ? PdfColor.fromInt(0xFF4CAF50)
                          : PdfColor.fromInt(0xFF0175C2),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                PdfFontUtils.createGracefulText(
                  _formatDateTime(item['date']),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.normal,
                  color: item['type'] == 'partial_payment' 
                      ? PdfColor.fromInt(0xFF4CAF50)
                      : PdfColor.fromInt(0xFF1976D2),
                ),
              ],
            ),
          );
        }).toList(),
        
        if (isLastPage) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty
                  ? PdfColor.fromInt(0xFFE8F5E8) // Light green background for fully paid
                  : PdfColor.fromInt(0xFFFFEBEE), // Light red background for not fully paid
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfFontUtils.createGracefulText(
                  'SUMMARY',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF424242),
                ),
                pw.SizedBox(height: 6),
                
                if (remainingAmount == 0 && allItems.where((item) => item['type'] == 'debt').isNotEmpty) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Debts Fully Paid',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(allItems
                            .where((item) => item['type'] == 'debt')
                            .fold<double>(0, (sum, item) => sum + item['amount'])),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F), // Red color for amount
                      ),
                    ],
                  ),
                ] else ...[
                  // Calculate partially paid amount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Partially Paid Amount:',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(allItems
                            .where((item) => item['type'] == 'partial_payment')
                            .fold<double>(0, (sum, item) => sum + item['amount'])),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50), // Green color for partially paid
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfFontUtils.createGracefulText(
                        'Remaining Amount:',
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF424242),
                      ),
                      PdfFontUtils.createGracefulText(
                        _formatCurrency(remainingAmount),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFD32F2F), // Red color for remaining amount
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(
              child: PdfFontUtils.createGracefulText(
                'Page ${pageIndex + 1} of $totalPages',
                fontSize: 7,
                color: PdfColor.fromInt(0xFF999999),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} USD';
  }

  /// Show delete debt confirmation dialog
  void _showDeleteDebtDialog(Debt debt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Format the amount properly using stored currency
        final formattedAmount = CurrencyFormatter.formatAmount(
          context, 
          debt.amount, 
          storedCurrency: debt.storedCurrency
        );
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Delete Debt'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this debt?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt Details:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            debt.description,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Amount: $formattedAmount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteDebt(debt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete debt and refresh the screen
  Future<void> _deleteDebt(Debt debt) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.deleteDebt(debt.id);
      
      if (mounted) {
        // Refresh the screen data
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Delete Error',
          body: 'Failed to delete debt: $e',
        );
      }
    }
  }
} 