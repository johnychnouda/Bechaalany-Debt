import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../models/activity.dart';
import '../models/partial_payment.dart';

import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../utils/debt_description_utils.dart';
import '../services/notification_service.dart';
import '../services/receipt_sharing_service.dart';
import '../widgets/pdf_viewer_popup.dart';
import 'add_debt_from_product_screen.dart';
import 'add_customer_screen.dart';
import 'customer_debt_receipt_screen.dart';
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
  
  // Helper method to get all partial payments for the current customer
  // This ensures partial payments are shown even if debts were cleared or there are ID mismatches
  List<PartialPayment> _getCustomerPartialPayments(AppState appState) {
    return appState.partialPayments.where((p) {
      // First try to find the debt this payment was made for
      final linkedDebt = appState.debts.firstWhere(
        (d) => d.id == p.debtId,
        orElse: () => Debt(
          id: p.debtId,
          customerId: _currentCustomer.id,
          customerName: _currentCustomer.name,
          amount: 0,
          description: 'Unknown Product',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: p.paidAt,
          subcategoryId: null,
          subcategoryName: null,
          originalSellingPrice: null,
          originalCostPrice: null,
          categoryName: null,
          storedCurrency: 'USD',
        ),
      );
      
      // Include the payment if it's for this customer
      return linkedDebt.customerId == _currentCustomer.id;
    }).toList();
  }
  
  // Helper method to get all partial payments for a specific customer
  List<PartialPayment> _getCustomerPartialPaymentsById(AppState appState, String customerId, String customerName) {
    return appState.partialPayments.where((p) {
      // First try to find the debt this payment was made for
      final linkedDebt = appState.debts.firstWhere(
        (d) => d.id == p.debtId,
        orElse: () => Debt(
          id: p.debtId,
          customerId: customerId,
          customerName: customerName,
          amount: 0,
          description: 'Unknown Product',
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: p.paidAt,
          subcategoryId: null,
          subcategoryName: null,
          originalSellingPrice: null,
          originalCostPrice: null,
          categoryName: null,
          storedCurrency: 'USD',
        ),
      );
      
      // Include the payment if it's for this customer
      return linkedDebt.customerId == customerId;
    }).toList();
  }
  
  // Helper method to format dates
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final debtDate = DateTime(date.year, date.month, date.day);
    
    // Format time as HH:MM:SS AM/PM
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeString = '$displayHour:$minute:$second $period';
    
    if (debtDate == today) {
      return 'Today at $timeString';
    } else if (debtDate == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      // Format: DD/MM/YYYY at HH:MM:SS AM/PM
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      
      return 'Created on $day/$month/$year at $timeString';
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
                      color: CupertinoColors.label.resolveFrom(context), // Use system label color for proper dark/light mode support
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
  
  // Show PDF receipt popup for viewing and printing
  Future<void> _showPDFReceiptPopup(BuildContext context, AppState appState) async {
    try {
      print('=== _showPDFReceiptPopup called ===');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      // Get customer data
      final customerDebts = appState.debts.where((d) => d.customerId == _currentCustomer.id).toList();
      
      // Include ALL partial payments for this customer, not just those linked to existing debts
      // This ensures partial payments are shown even if debts were cleared or there are ID mismatches
      final customerPartialPayments = _getCustomerPartialPayments(appState);
      
      final customerActivities = appState.activities.where((a) => a.customerId == _currentCustomer.id).toList();
      
      print('Customer debts count: ${customerDebts.length}');
      print('Partial payments count: ${customerPartialPayments.length}');
      print('Activities count: ${customerActivities.length}');
      
      // Check if customer has pending debts OR has made any payments
      final hasPendingDebts = customerDebts.any((debt) => debt.remainingAmount > 0);
      final hasAnyPayments = customerPartialPayments.isNotEmpty || customerActivities.any((a) => a.type == ActivityType.payment);
      
      if (!hasPendingDebts && !hasAnyPayments) {
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showErrorNotification(
            title: 'No Receipt Data',
            body: 'Customer has no pending debts or payment history to generate receipt for.',
          );
        }
        return;
      }
      
      if (kIsWeb) {
        // Web-specific handling - navigate directly to receipt screen
        print('Web platform detected, navigating to receipt screen...');
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDebtReceiptScreen(
                customer: _currentCustomer,
                customerDebts: customerDebts,
                partialPayments: customerPartialPayments,
                activities: customerActivities,
                specificDate: null,
                specificDebtId: null,
              ),
            ),
          );
        }
      } else {
        // Mobile-specific handling - use PDF viewer popup
        print('Mobile platform detected, using PDF viewer...');
        
        // Generate PDF receipt
        final pdfFile = await ReceiptSharingService.generateReceiptPDF(
          customer: _currentCustomer,
          debts: appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
          partialPayments: customerPartialPayments,
          activities: appState.activities.where((a) => a.customerId == _currentCustomer.id).toList(),
          specificDate: null, // No specific date filter
          specificDebtId: null, // No specific debt filter
        );
        
        if (pdfFile != null) {
          if (mounted) {
            Navigator.of(context).push(
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (BuildContext context) => PDFViewerPopup(
                  pdfFile: pdfFile,
                  customerName: _currentCustomer.name,
                  customer: _currentCustomer, // Pass customer information
                  onClose: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            final notificationService = NotificationService();
            await notificationService.showErrorNotification(
              title: 'PDF Generation Error',
              body: 'Failed to generate receipt PDF. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      print('=== ERROR in _showPDFReceiptPopup ===');
      print('Error details: $e');
      print('Error type: ${e.runtimeType}');
      
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'PDF Error',
          body: 'Failed to generate receipt: $e',
        );
      }
    }
  }
  
  Future<void> _shareReceiptViaWhatsApp(AppState appState) async {
    try {
      // Include ALL partial payments for this customer, not just those linked to existing debts
      final customerPartialPayments = _getCustomerPartialPaymentsById(appState, widget.customer.id, widget.customer.name);
      
      final success = await ReceiptSharingService.shareReceiptViaWhatsApp(
        widget.customer,
        appState.debts.where((d) => d.customerId == widget.customer.id).toList(),
        customerPartialPayments,
        appState.activities.where((a) => a.customerId == widget.customer.id).toList(),
        null, // No specific date filter
        null, // No specific debt filter
      );

      if (success) {
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showSuccessNotification(
            title: 'WhatsApp Opened',
            body: 'WhatsApp has been opened. Please attach the PDF receipt manually.',
          );
        }
      } else {
        if (mounted) {
          final notificationService = NotificationService();
          await notificationService.showErrorNotification(
            title: 'WhatsApp Error',
            body: 'Could not open WhatsApp. Please check if it\'s installed.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'WhatsApp Error',
          body: 'Failed to open WhatsApp: $e',
        );
      }
    }
  }

  // Send WhatsApp payment reminder
  Future<void> _sendWhatsAppPaymentReminder(BuildContext context, AppState appState) async {
    try {
      await appState.sendWhatsAppPaymentReminder(widget.customer.id);

      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Payment Reminder Sent',
          body: 'WhatsApp payment reminder has been sent to ${widget.customer.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Payment Reminder Failed',
          body: 'Failed to send payment reminder: $e',
        );
      }
    }
  }

  // Send WhatsApp settlement notification
  Future<void> _sendWhatsAppSettlementNotification(BuildContext context, AppState appState) async {
    try {
      await appState.sendWhatsAppSettlementNotification(widget.customer.id);

      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Settlement Notification Sent',
          body: 'WhatsApp settlement notification has been sent to ${widget.customer.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Settlement Notification Failed',
          body: 'Failed to send settlement notification: $e',
        );
      }
    }
  }

  // Show personalized payment reminder dialog
  void _showPersonalizedPaymentReminderDialog(BuildContext context, AppState appState) {
    final messageController = TextEditingController(
      text: 'Hello ${widget.customer.name}, you have an outstanding balance. Please contact us to arrange payment.',
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Send Payment Reminder',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Customize your message for ${widget.customer.name}:',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: messageController,
              placeholder: 'Enter your custom message...',
              maxLines: 4,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dynamicBorder(context)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This message will be sent via WhatsApp to ${widget.customer.phone}',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              await _sendWhatsAppPaymentReminder(context, appState);
            },
            child: Text(
              'Send',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareReceiptViaEmail(AppState appState) async {
    try {
      // Include ALL partial payments for this customer, not just those linked to existing debts
      final customerPartialPayments = _getCustomerPartialPayments(appState);
      
      final success = await ReceiptSharingService.shareReceiptViaEmail(
        _currentCustomer,
        appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
        customerPartialPayments,
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
      // Include ALL partial payments for this customer, not just those linked to existing debts
      final customerPartialPayments = _getCustomerPartialPayments(appState);
      
      // Generate PDF receipt
      final pdfFile = await ReceiptSharingService.generateReceiptPDF(
        customer: _currentCustomer,
        debts: appState.debts.where((d) => d.customerId == _currentCustomer.id).toList(),
        partialPayments: customerPartialPayments,
        activities: appState.activities.where((a) => a.customerId == _currentCustomer.id).toList(),
        specificDate: null, // No specific date filter
        specificDebtId: null, // No specific debt filter
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
          content: Text('Are you sure you want to mark this debt as paid?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency)}'),
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
            'Amount: ${CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency)}\n\n'
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
          content: Text('Are you sure you want to delete this debt?\n\nAmount: ${CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency)}'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
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
        
        // Check if customer has ANY partial payments (this will hide all red X icons)
        // ANY partial payment (even $0.01) should disable delete functionality for ALL products
        final customerHasPartialPayments = allCustomerDebts.any((d) => d.paidAmount > 0);
        
        // Calculate total pending debt (current remaining amount)
        final totalPendingDebt = allCustomerDebts.where((d) => d.remainingAmount > 0).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        
        // Calculate total paid from payment activities (preserves payment history even when debts are cleared)
        final customerPaymentActivities = appState.activities.where((a) => 
          a.customerId == _currentCustomer.id && 
          a.type == ActivityType.payment
        ).toList();
        
        double totalPaid = customerPaymentActivities.fold(0.0, (sum, activity) => 
          sum + (activity.paymentAmount ?? 0)
        );
        
        // Use the comprehensive method that includes both activities and partial payments
        // This ensures consistency between Financial Summary and Activity History
        totalPaid = appState.getCustomerTotalHistoricalPayments(_currentCustomer.id);
        
        // Get all customer debts and sort by date and time in descending order (newest first)
        final customerAllDebts = appState.debts
            .where((d) => d.customerId == _currentCustomer.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Show only products that are NOT fully paid
        // This ensures fully paid products are hidden while pending products remain visible
        final customerActiveDebts = customerAllDebts.where((debt) {
          // Show the product if it's NOT fully paid
          // This is the most reliable way to ensure only pending products are visible
          return !debt.isFullyPaid;
        }).toList();

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
                
                // Financial Summary Section - Simple Style
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.dynamicBorder(context),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simple Header with Share Button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Financial Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dynamicTextPrimary(context),
                                ),
                              ),
                            ),
                            // PDF viewer button - Only show when customer has pending debts
                            if (totalPendingDebt > 0) ...[
                              IconButton(
                                onPressed: () => _showPDFReceiptPopup(context, appState),
                                icon: Icon(
                                  Icons.receipt_long,
                                  color: AppColors.dynamicPrimary(context),
                                  size: 20,
                                ),
                                tooltip: 'View Receipt',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],


                          ],
                        ),
                      ),
                      
                      // Product List - Show when there are products to display
                      if (widget.showDebtsSection) ...[
                        if (customerActiveDebts.isNotEmpty) ...[
                        // Section Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Text(
                                'Product Purchases',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dynamicTextSecondary(context),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicError(context).withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                                              child: Text(
                                '${customerActiveDebts.length} products',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dynamicPrimary(context),
                                ),
                              ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Simple Debts List - Show ALL products with payment status
                        ...customerActiveDebts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final debt = entry.value;
                          final isLastDebt = index == customerActiveDebts.length - 1;
                          
                                                      return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.dynamicPrimary(context).withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.dynamicPrimary(context).withAlpha(40),
                                    width: 1,
                                  ),
                                ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag,
                                    color: AppColors.dynamicPrimary(context),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              debt.description,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.dynamicTextPrimary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Created ${_formatDate(debt.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.dynamicTextSecondary(context),
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                                                                                          Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                                                  Text(
                                          CurrencyFormatter.formatAmount(context, debt.amount, storedCurrency: debt.storedCurrency),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dynamicTextPrimary(context),
                                          ),
                                        ),
                                          // BUSINESS RULE: Show red X delete icon for consistent behavior
                                          // Since partial payments apply to total pending amount, show red X on ALL products OR NONE
                                          // This ensures consistent UI behavior across all products
                                          if (debt.paidAmount == 0 && totalPendingDebt > 0) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _showDeleteDebtDialog(context, debt),
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
                                          ],
                                        ],
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        ],
                        
                        // Simple Action Buttons - Only show when there are pending debts
                        if (totalPendingDebt > 0) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showConsolidatedPaymentDialog(context, customerActiveDebts),
                                        icon: const Icon(Icons.payment, size: 20),
                                        label: const Text('Make Payment'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      
                      // Simple Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (totalPendingDebt > 0) ...[
                              Row(
                                children: [
                                  Text(
                                    'Total Pending:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.dynamicTextPrimary(context),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    CurrencyFormatter.formatAmount(context, totalPendingDebt),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dynamicError(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Text(
                                  'Total Paid:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dynamicTextPrimary(context),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyFormatter.formatAmount(context, totalPaid),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dynamicSuccess(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
              // Only show "Pay Full Amount" button when there's actually no remaining balance
              if (totalRemaining <= 0) ...[
                _PaymentOption(
                  title: 'All Debts Paid',
                  subtitle: 'Customer has no outstanding balance',
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    // No action needed - already fully paid
                  },
                ),
              ] else ...[
                _PaymentOption(
                  title: 'Pay Full Amount',
                  subtitle: 'Enter exact amount to complete all debts',
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showExactPaymentDialog(context, pendingDebts, totalRemaining);
                  },
                ),
              ],
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
    
    // Use the new even distribution method for better partial payment handling
    // This ensures payments are split evenly across all pending debts
    appState.applyPaymentEvenlyAcrossCustomerDebts(_currentCustomer.id, paymentAmount);
  }
  
  // Show exact payment dialog to complete all debts
  void _showExactPaymentDialog(BuildContext context, List<Debt> pendingDebts, double totalRemaining) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Complete All Debts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Remaining: ${CurrencyFormatter.formatAmount(context, totalRemaining)}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.dynamicBorder(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Amount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatAmount(context, totalRemaining),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will mark all remaining debts as fully paid.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _applyConsolidatedPartialPayment(totalRemaining, pendingDebts, context);
                  },
                  child: const Text('Complete Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  // Show delete all debts dialog
  void _showDeleteAllDebtsDialog(BuildContext context, List<Debt> allDebts) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Delete All Debts'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete all debts for ${_currentCustomer.name}?'),
              const SizedBox(height: 16),
              Text('Total Debts: ${allDebts.length}'),
              const SizedBox(height: 8),
              Text(
                '• Total amount: ${_calculateTotalAmountText(context, allDebts)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ This action will permanently delete all debts for this customer and cannot be undone.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.dynamicPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _deleteAllDebts(allDebts);
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
                    'Delete All',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Helper method to calculate total amount text for multiple debts
  /// Handles debts with different currencies by converting to USD for display
  String _calculateTotalAmountText(BuildContext context, List<Debt> allDebts) {
    if (allDebts.isEmpty) return '0.00\$';
    
    // Group debts by currency
    final Map<String, List<Debt>> debtsByCurrency = {};
    for (final debt in allDebts) {
      final currency = debt.storedCurrency ?? 'USD';
      debtsByCurrency.putIfAbsent(currency, () => []).add(debt);
    }
    
    // Calculate total in USD
    double totalUSD = 0.0;
    for (final entry in debtsByCurrency.entries) {
      final currency = entry.key;
      final debts = entry.value;
      
      if (currency == 'USD') {
        totalUSD += debts.fold(0.0, (sum, debt) => sum + debt.amount);
      } else if (currency == 'LBP') {
        // Convert LBP to USD using current exchange rate
        final appState = Provider.of<AppState>(context, listen: false);
        final settings = appState.currencySettings;
        if (settings?.exchangeRate != null) {
          final lbpTotal = debts.fold(0.0, (sum, debt) => sum + debt.amount);
          totalUSD += lbpTotal / settings!.exchangeRate!;
        } else {
          // If no exchange rate, just add the LBP amount as-is
          totalUSD += debts.fold(0.0, (sum, debt) => sum + debt.amount);
        }
      }
    }
    
    return '${totalUSD.toStringAsFixed(2)}\$';
  }
  
  // Show dialog to confirm deletion of a single debt
  void _showDeleteDebtDialog(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                  color: AppColors.dynamicTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dynamicBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt Details:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 16,
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            debt.description,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.dynamicTextPrimary(context),
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
                          color: AppColors.dynamicTextSecondary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Amount: $formattedAmount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dynamicTextPrimary(context),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.dynamicPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _deleteSingleDebt(debt);
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
            ),
          ],
        );
      },
    );
  }
  
  // Delete a single debt
  Future<void> _deleteSingleDebt(Debt debt) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      await appState.deleteDebt(debt.id);
      _loadCustomerDebts(); // Re-load after deletion
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to delete debt: $e',
        );
      }
    }
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