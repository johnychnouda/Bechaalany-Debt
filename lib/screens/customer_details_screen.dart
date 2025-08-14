import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';

import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';
import '../services/notification_service.dart';
import '../services/receipt_sharing_service.dart';
import 'add_debt_from_product_screen.dart';
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
  
  // Helper method to format dates
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final debtDate = DateTime(date.year, date.month, date.day);
    
    if (debtDate == today) {
      return 'Today';
    } else if (debtDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
    void _showReceiptSharingOptions(BuildContext context, AppState appState) {
    // Check available contact methods
    final hasPhone = _currentCustomer.phone.isNotEmpty;
    final hasEmail = _currentCustomer.email != null && _currentCustomer.email!.isNotEmpty;
    
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
                    'Choose how to send the receipt to ${_currentCustomer.name}',
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
                      _shareReceiptViaWhatsApp(appState);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                

                
                if (hasPhone) ...[
                  _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.arrow_down_circle,
                    title: 'Save to iPhone',
                    subtitle: 'Download to Files or Photos',
                    color: CupertinoColors.systemBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _saveReceiptToIPhone(appState);
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
                    builder: (context) => AddCustomerScreen(customer: _currentCustomer),
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
  
  Future<void> _shareReceiptViaWhatsApp(AppState appState) async {
    try {
      final success = await ReceiptSharingService.shareReceiptViaWhatsApp(
        _currentCustomer,
        appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
        appState.partialPayments.where((p) => 
          appState.debts.any((d) => d.id == p.debtId && d.customerId == _currentCustomer.id)
        ).toList(),
        appState.activities.where((a) => a.customerId == _currentCustomer.id).toList(),
        null, // No specific date filter
        null, // No specific debt filter
      );
      
      if (success) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'WhatsApp Opened',
          body: 'WhatsApp has been opened. Please attach the PDF receipt manually.',
        );
      } else {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'WhatsApp Error',
          body: 'Could not open WhatsApp. Please check if it\'s installed.',
        );
      }
    } catch (e) {
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'WhatsApp Error',
        body: 'Failed to open WhatsApp: $e',
      );
    }
  }
  
  Future<void> _shareReceiptViaEmail(AppState appState) async {
    try {
      final success = await ReceiptSharingService.shareReceiptViaEmail(
        _currentCustomer,
        appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
        appState.partialPayments.where((p) => 
          appState.debts.any((d) => d.id == p.debtId && d.customerId == _currentCustomer.id)
        ).toList(),
        appState.activities.where((a) => a.customerId == _currentCustomer.id).toList(),
        null, // No specific date filter
        null, // No specific debt filter
      );
      
      if (success) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Email App Opened',
          body: 'Your email app has been opened. Please attach the PDF receipt manually.',
        );
      } else {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Email Error',
          body: 'Could not open email app. Please check if you have an email app installed.',
        );
      }
    } catch (e) {
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Email Error',
        body: 'Failed to open email app: $e',
      );
    }
  }
  
  Future<void> _saveReceiptToIPhone(AppState appState) async {
    try {
      // Generate PDF receipt
      final pdfFile = await ReceiptSharingService.generateReceiptPDF(
        _currentCustomer,
        appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
        appState.partialPayments.where((p) => 
          appState.debts.any((d) => d.id == p.debtId && d.customerId == _currentCustomer.id)
        ).toList(),
        appState.activities.where((a) => a.customerId == _currentCustomer.id).toList(),
        null, // No specific date filter
        null, // No specific debt filter
      );
      
      if (pdfFile != null) {
        // Use the existing share functionality to save to iPhone
        await Share.shareXFiles([XFile(pdfFile.path)]);
        
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Receipt Saved',
          body: 'Receipt has been saved to your iPhone. You can now share it via any app.',
        );
      } else {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Save Error',
          body: 'Failed to generate receipt for saving.',
        );
      }
    } catch (e) {
      final notificationService = NotificationService();
      await notificationService.showErrorNotification(
        title: 'Save Error',
        body: 'Failed to save receipt: $e',
      );
    }
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

  Future<bool> _confirmClearPaidDebt(BuildContext context, Debt debt) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Paid Debt'),
          content: Text(
            'Are you sure you want to clear this paid debt?\n\n'
            'Debt: ${DebtDescriptionUtils.cleanDescription(debt.description)}\n'
            'Amount: ${CurrencyFormatter.formatAmount(context, debt.amount)}\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dynamicPrimary(context),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear Debt'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _deleteDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
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
        
        // Calculate total paid from payment activities (preserves payment history even when debts are cleared)
        final customerPaymentActivities = appState.activities.where((a) => 
          a.customerId == _currentCustomer.id && 
          a.type == ActivityType.payment
        ).toList();
        
        double totalPaid = customerPaymentActivities.fold(0.0, (sum, activity) => 
          sum + (activity.paymentAmount ?? 0)
        );
        
        // Get all customer debts and sort by date and time in descending order (newest first)
        final customerAllDebts = appState.debts
            .where((d) => d.customerId == _currentCustomer.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: AppColors.dynamicBackground(context),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDebtFromProductScreen(customer: _currentCustomer),
                ),
              );
              // Refresh the debt list if a debt was added
              if (result == true) {
                _loadCustomerDebts();
              }
            },
            backgroundColor: AppColors.dynamicPrimary(context),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            title: Text(
              _currentCustomer.name,
              style: AppTheme.getDynamicHeadline(context),
            ),
            backgroundColor: AppColors.dynamicSurface(context),
            elevation: 0,
            actions: [
              // Receipt sharing button
              IconButton(
                onPressed: () => _showReceiptSharingOptions(context, appState),
                icon: Icon(
                  Icons.receipt_long,
                  color: AppColors.dynamicPrimary(context),
                ),
                tooltip: 'Share Receipt',
              ),
              // Edit customer button
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
                      
                      // Debts List (shown first)
                      if (widget.showDebtsSection && customerAllDebts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'DEBTS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextPrimary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Debts List
                        ...customerAllDebts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final debt = entry.value;
                          final isLastDebt = index == customerAllDebts.length - 1;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Dismissible(
                              key: Key(debt.id),
                              direction: debt.isFullyPaid ? DismissDirection.endToStart : DismissDirection.none,
                              confirmDismiss: (direction) async {
                                if (debt.isFullyPaid) {
                                  return await _confirmClearPaidDebt(context, debt);
                                }
                                return false;
                              },
                              onDismissed: (direction) {
                                if (debt.isFullyPaid) {
                                  _deleteDebt(debt);
                                }
                              },
                              background: debt.isFullyPaid ? Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicPrimary(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_sweep,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ) : null,
                              child: Column(
                                children: [
                                  // Simple debt display without individual action buttons
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.dynamicSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.dynamicBorder(context),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.dynamicPrimary(context).withAlpha(26),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.attach_money,
                                            color: AppColors.dynamicPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${debt.description}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.dynamicTextPrimary(context),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Created: ${_formatDate(debt.createdAt)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.dynamicTextSecondary(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatAmount(context, debt.amount),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dynamicTextPrimary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Show consolidated action buttons only under the last debt
                                  if (isLastDebt && customerAllDebts.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    // Consolidated Action Buttons
                                    Row(
                                      children: [
                                        if (totalPendingDebt > 0) ...[
                                          // Make Payment button for all pending debts
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showConsolidatedPaymentDialog(context, customerAllDebts),
                                              icon: const Icon(Icons.payment, size: 16),
                                              label: const Text('Make Payment'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.dynamicPrimary(context),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        // Delete All button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showDeleteAllDebtsDialog(context, customerAllDebts),
                                            icon: const Icon(Icons.delete_forever, size: 16),
                                            label: const Text('Delete All'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.dynamicError(context),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                        }),
                        
                        const Divider(height: 32, thickness: 1),
                      ],
                      

                      
                      // Summary Totals (shown below debts)
                      // Total Pending Debt (only show if there are pending debts)
                      if (totalPendingDebt > 0) ...[
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
                      ],
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
                

                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Show consolidated payment dialog for all debts
  void _showConsolidatedPaymentDialog(BuildContext context, List<Debt> allDebts) {
    final pendingDebts = allDebts.where((d) => !d.isFullyPaid).toList();
    final totalRemaining = pendingDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Payment Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Remaining: ${CurrencyFormatter.formatAmount(context, totalRemaining)}'),
              const SizedBox(height: 16),
              const Text('Payment Options:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Pay Full Amount',
                subtitle: 'Mark all debts as fully paid',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _markAllDebtsAsPaid(pendingDebts);
                },
              ),
              const SizedBox(height: 8),
              _PaymentOption(
                title: 'Partial Payment',
                subtitle: 'Enter amount to pay across all debts',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showConsolidatedPartialPaymentDialog(context, pendingDebts);
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
  
  // Show consolidated partial payment dialog
  void _showConsolidatedPartialPaymentDialog(BuildContext context, List<Debt> pendingDebts) {
    final totalRemaining = pendingDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Partial Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Remaining: ${CurrencyFormatter.formatAmount(context, totalRemaining)}'),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                if (amount > 0 && amount <= totalRemaining) {
                  Navigator.of(dialogContext).pop();
                  _applyConsolidatedPartialPayment(amount, pendingDebts, context);
                }
              },
              child: const Text('Apply Payment'),
            ),
          ],
        );
      },
    );
  }
  
  // Apply consolidated partial payment across all pending debts
  void _applyConsolidatedPartialPayment(double paymentAmount, List<Debt> pendingDebts, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Use the existing method that handles payment across multiple debts
    final debtIds = pendingDebts.map((debt) => debt.id).toList();
    appState.applyPaymentAcrossDebts(debtIds, paymentAmount);
  }
  
  // Mark all debts as paid
  void _markAllDebtsAsPaid(List<Debt> pendingDebts) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    for (final debt in pendingDebts) {
      if (!debt.isFullyPaid) {
        appState.markDebtAsPaid(debt.id);
      }
    }
  }
  
  // Show delete all debts dialog
  void _showDeleteAllDebtsDialog(BuildContext context, List<Debt> allDebts) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete All Debts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete all debts for ${_currentCustomer.name}?'),
              const SizedBox(height: 16),
              Text('Total Debts: ${allDebts.length}'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone. All debt history will be permanently deleted.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAllDebts(allDebts);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
  
  // Delete all debts for the customer
  Future<void> _deleteAllDebts(List<Debt> allDebts) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      for (final debt in allDebts) {
        await appState.deleteDebt(debt.id);
      }
      _loadCustomerDebts(); // Re-load after deletion
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to delete some debts: $e',
        );
      }
    }
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