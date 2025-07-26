import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../utils/currency_formatter.dart';
import '../services/notification_service.dart';

class CustomerDebtReceiptScreen extends StatefulWidget {
  final Customer customer;
  final List<Debt> customerDebts;

  const CustomerDebtReceiptScreen({
    super.key,
    required this.customer,
    required this.customerDebts,
  });

  @override
  State<CustomerDebtReceiptScreen> createState() => _CustomerDebtReceiptScreenState();
}

class _CustomerDebtReceiptScreenState extends State<CustomerDebtReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final sortedDebts = List<Debt>.from(widget.customerDebts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
    final totalPaidAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.paidAmount);
    final totalRemainingAmount = sortedDebts.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Debt Receipt'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            onPressed: () => _printReceipt(),
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Receipt Header
            _buildReceiptHeader(),
            const SizedBox(height: 24),
            
            // Customer Information
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            
            // Summary Section
            _buildSummarySection(totalAmount, totalPaidAmount, totalRemainingAmount),
            const SizedBox(height: 24),
            
            // Debt Details
            _buildDebtDetails(sortedDebts),
            const SizedBox(height: 24),
            
            // Footer
            _buildReceiptFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/App Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'BECHAALANY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'DEBT RECEIPT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated on ${_formatDate(DateTime.now())}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER INFORMATION',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.person, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                                         if (widget.customer.phone.isNotEmpty) ...[
                       const SizedBox(height: 4),
                       Text(
                         widget.customer.phone,
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                  ],
                ),
              ),
            ],
          ),
                     if (widget.customer.address != null && widget.customer.address!.isNotEmpty) ...[
             const SizedBox(height: 12),
             Row(
               children: [
                 Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     widget.customer.address!,
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey[600],
                     ),
                   ),
                 ),
               ],
             ),
           ],
        ],
      ),
    );
  }

  Widget _buildSummarySection(double totalAmount, double totalPaidAmount, double totalRemainingAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Debt:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, totalPaidAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, totalRemainingAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalRemainingAmount > 0 ? Colors.orange[600] : Colors.green[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetails(List<Debt> sortedDebts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEBT DETAILS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedDebts.map((debt) => _buildDebtItem(debt)).toList(),
        ],
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final isFullyPaid = debt.isFullyPaid;
    final isPartiallyPaid = debt.isPartiallyPaid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getDebtStatusColor(isFullyPaid, isPartiallyPaid).withAlpha(26), // 0.1 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getDebtStatusColor(isFullyPaid, isPartiallyPaid).withAlpha(77), // 0.3 * 255
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(debt.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDebtStatusColor(isFullyPaid, isPartiallyPaid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDebtStatusText(isFullyPaid, isPartiallyPaid),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Product/Description
          Text(
            debt.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Amount details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, debt.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(context, debt.paidAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          if (debt.remainingAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(context, debt.remainingAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
                     ],
        ],
      ),
    );
  }

  Widget _buildReceiptFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Thank you for your business!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For any questions, please contact us.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Receipt ID: ${widget.customer.id}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDebtStatusColor(bool isFullyPaid, bool isPartiallyPaid) {
    if (isFullyPaid) {
      return Colors.green;
    } else if (isPartiallyPaid) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  String _getDebtStatusText(bool isFullyPaid, bool isPartiallyPaid) {
    if (isFullyPaid) {
      return 'PAID';
    } else if (isPartiallyPaid) {
      return 'PARTIAL';
    } else {
      return 'PENDING';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _printReceipt() async {
    // TODO: Implement print functionality
    final notificationService = NotificationService();
    await notificationService.showInfoNotification(
      title: 'Print Feature',
      body: 'Print functionality coming soon!',
    );
  }
} 