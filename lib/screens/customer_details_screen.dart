import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';
import '../services/notification_service.dart';
import 'add_debt_screen.dart';
import 'add_customer_screen.dart';
import '../constants/app_colors.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  final bool showDebtsSection;

  const CustomerDetailsScreen({
    super.key, 
    required this.customer,
    this.showDebtsSection = true,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with WidgetsBindingObserver {
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentCustomer = widget.customer;
    _loadCustomerDebts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentCustomer = widget.customer;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCustomerDebts();
    }
  }

  void _loadCustomerDebts() {
    // Customer debts are loaded in build method
  }

  Future<void> _markAsPaid(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Paid'),
          content: Text('Are you sure you want to mark this debt as paid?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await appState.markDebtAsPaid(debt.id);
                  _loadCustomerDebts(); // Re-load after status change

                } catch (e) {
                  if (mounted) {
                    // Show error notification
                    final notificationService = NotificationService();
                    await notificationService.showErrorNotification(
                      title: 'Error',
                      body: 'Failed to mark debt as paid: $e',
                    );
                  }
                }
              },
              child: const Text('Mark as Paid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Don't allow deletion of fully paid debts
    if (debt.isFullyPaid) {
      return;
    }
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Debt'),
          content: Text('Are you sure you want to delete this debt?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await appState.deleteDebt(debt.id);
                  _loadCustomerDebts(); // Re-load after deletion

                } catch (e) {
                  if (mounted) {
                    // Show error notification
                    final notificationService = NotificationService();
                    await notificationService.showErrorNotification(
                      title: 'Error',
                      body: 'Failed to delete debt: $e',
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Refresh customer data and debts when AppState changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadCustomerDebts();
          }
        });
        
        // Calculate totals from all customer debts (including paid ones)
        final allCustomerDebts = appState.debts.where((d) => d.customerId == _currentCustomer.id).toList();
        
        // Calculate total pending debt (current remaining amount)
        final totalPendingDebt = allCustomerDebts.where((d) => !d.isFullyPaid).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
        // Calculate total paid (cumulative sum of all payments made)
        // This includes payments for active debts and cleared/deleted debts
        double totalPaid = 0.0;
        
        // Add payments from active debts
        for (final debt in allCustomerDebts) {
          totalPaid += debt.paidAmount;
        }
        
        // Add payments from cleared/deleted debts (debts that no longer exist but have payment activities)
        final activeDebtIds = allCustomerDebts.map((d) => d.id).toSet();
        final paymentActivitiesForClearedDebts = appState.activities.where((a) => 
          a.customerId == _currentCustomer.id && 
          a.type == ActivityType.payment &&
          a.debtId != null &&
          !activeDebtIds.contains(a.debtId)
        ).toList();
        
        for (final activity in paymentActivitiesForClearedDebts) {
          totalPaid += activity.paymentAmount ?? 0;
        }
        
        // Also add cross-debt payments (activities without specific debt ID)
        final crossDebtPayments = appState.activities.where((a) => 
          a.customerId == _currentCustomer.id && 
          a.type == ActivityType.payment &&
          a.debtId == null
        ).toList();
        
        for (final activity in crossDebtPayments) {
          totalPaid += activity.paymentAmount ?? 0;
        }
        
        // Get all customer debts and sort by date and time in descending order (newest first)
        final customerAllDebts = appState.debts
            .where((d) => d.customerId == _currentCustomer.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: AppColors.dynamicBackground(context),
          appBar: AppBar(
            title: Text(
              _currentCustomer.name,
              style: AppTheme.getDynamicHeadline(context),
            ),
            backgroundColor: AppColors.dynamicSurface(context),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCustomerScreen(customer: _currentCustomer),
                    ),
                  );
                  // Refresh the screen after editing
                  if (result == true) {
                    setState(() {
                      // Refresh customer data from AppState
                      final appState = Provider.of<AppState>(context, listen: false);
                      final updatedCustomer = appState.customers.firstWhere(
                        (c) => c.id == _currentCustomer.id,
                        orElse: () => _currentCustomer,
                      );
                      _currentCustomer = updatedCustomer;
                    });
                    // Refresh customer debts
                    _loadCustomerDebts();
                  }
                },
                icon: Icon(
                  Icons.edit,
                  color: AppColors.dynamicPrimary(context),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer Information Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 * 255
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'CUSTOMER INFORMATION',
                          style: AppTheme.getDynamicSubheadline(context).copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Customer ID
                      ListTile(
                        leading: Icon(
                          Icons.tag,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        title: Text(
                          'Customer ID',
                          style: AppTheme.getDynamicBody(context).copyWith(
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.id,
                          style: AppTheme.getDynamicCallout(context).copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                      // Name
                      ListTile(
                        leading: Icon(
                          Icons.person,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        title: Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.name,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                      // Phone
                      ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        title: Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          _currentCustomer.phone,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                      ),
                      // Email (if available)
                      if (_currentCustomer.email != null)
                        ListTile(
                          leading: Icon(
                            Icons.email,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          title: Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          subtitle: Text(
                            _currentCustomer.email!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                        ),
                      // Address (if available)
                      if (_currentCustomer.address != null)
                        ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          title: Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          subtitle: Text(
                            _currentCustomer.address!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Financial Summary Section
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 * 255
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'FINANCIAL SUMMARY',
                          style: AppTheme.getDynamicSubheadline(context).copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Total Debt
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicError(context).withAlpha(26), // 0.1 * 255
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: AppColors.dynamicError(context),
                            size: 16,
                          ),
                        ),
                        title: Text(
                          'Total Pending Debt',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatAmount(context, totalPendingDebt),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.dynamicError(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Total Paid
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSuccess(context).withAlpha(26), // 0.1 * 255
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.dynamicSuccess(context),
                            size: 16,
                          ),
                        ),
                        title: Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatAmount(context, totalPaid),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.dynamicSuccess(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Debts Section (only show if showDebtsSection is true)
                if (widget.showDebtsSection) ...[
                  // Debts Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DEBTS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDebtScreen(customer: _currentCustomer),
                              ),
                            );
                            
                            // Refresh the debt list if a debt was added
                            if (result == true) {
                              _loadCustomerDebts();
                            }
                          },
                          child: Text(
                            'Add Debt',
                            style: TextStyle(
                              color: AppColors.dynamicPrimary(context),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Debts List
                  customerAllDebts.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 64,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No debts found',
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a new debt to get started',
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: customerAllDebts.length,
                          itemBuilder: (context, index) {
                            final debt = customerAllDebts[index];
                            return _DebtCard(
                              debt: debt,
                              onMarkAsPaid: () => _markAsPaid(debt),
                              onDelete: () => _deleteDebt(debt),
                            );
                          },
                        ),
                ],
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.onMarkAsPaid,
    required this.onDelete,
  });

  Color _getStatusColor() {
    if (debt.isFullyPaid) {
      return Colors.green;
    } else if (debt.isPartiallyPaid) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  String _getStatusText() {
    if (debt.isFullyPaid) {
      return 'Paid';
    } else if (debt.isPartiallyPaid) {
      return 'Partially Paid';
    } else {
      return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context),
          width: 1,
        ),
      ),
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
                    color: _getStatusColor().withAlpha(26), // 0.1 * 255
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    debt.isFullyPaid 
                        ? Icons.check_circle 
                        : debt.isPartiallyPaid 
                            ? Icons.payment 
                            : Icons.attach_money,
                    color: _getStatusColor(),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DebtDescriptionUtils.cleanDescription(debt.description),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        debt.status == DebtStatus.paid 
                            ? 'Paid: ${_formatDate(debt.paidAt ?? debt.createdAt)}'
                            : 'Created: ${_formatDate(debt.createdAt)}',
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      debt.status == DebtStatus.paid 
                          ? CurrencyFormatter.formatAmount(context, debt.amount)
                          : CurrencyFormatter.formatAmount(context, debt.remainingAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (debt.status == DebtStatus.pending && debt.paidAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Paid: ${CurrencyFormatter.formatAmount(context, debt.paidAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicSuccess(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withAlpha(26), // 0.1 * 255
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!debt.isFullyPaid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicSuccess(context),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showPaymentOptions(context),
                      child: const Text(
                        'Make Payment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dynamicError(context),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onDelete,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${difference.abs()} days ago';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return 'in $difference days';
    }
  }

  void _showPaymentOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Payment Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Debt: ${DebtDescriptionUtils.cleanDescription(debt.description)}'),
              Text('Amount: ${CurrencyFormatter.formatAmount(context, debt.amount)}'),
              Text('Remaining: ${CurrencyFormatter.formatAmount(context, debt.remainingAmount)}'),
              const SizedBox(height: 16),
              const Text('Payment Options:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Pay Full Amount',
                subtitle: 'Mark this debt as fully paid',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  onMarkAsPaid();
                },
              ),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Partial Payment',
                subtitle: 'Enter amount to pay',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showPartialPaymentDialog(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showPartialPaymentDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Partial Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Remaining Amount: ${CurrencyFormatter.formatAmount(context, debt.remainingAmount)}'),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
                if (amount > 0 && amount <= debt.remainingAmount) {
                  Navigator.of(dialogContext).pop();
                  _applyPartialPayment(amount, context);
                }
              },
              child: const Text('Apply Payment'),
            ),
          ],
        );
      },
    );
  }

  void _applyPartialPayment(double paymentAmount, BuildContext context) {
    // Use the new partial payment method
    final appState = Provider.of<AppState>(context, listen: false);
    appState.applyPartialPayment(debt.id, paymentAmount);
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dynamicBorder(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.dynamicTextSecondary(context)),
          ],
        ),
      ),
    );
  }
} 