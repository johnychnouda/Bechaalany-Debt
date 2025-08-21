import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../models/customer.dart';
import '../services/notification_service.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  String _searchQuery = '';
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final appState = Provider.of<AppState>(context, listen: false);
    final customers = appState.customers;
    
    if (_searchQuery.isEmpty) {
      _filteredCustomers = customers;
    } else {
      _filteredCustomers = customers.where((customer) {
        return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.phone.contains(_searchQuery) ||
               (customer.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    setState(() {});
  }

  double _getCustomerTotalDebt(String customerId) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.debts
        .where((debt) => debt.customerId == customerId && !debt.isFullyPaid)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  bool _hasRemainingDebts(String customerId) {
    return _getCustomerTotalDebt(customerId) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final customersWithDebts = _filteredCustomers.where((customer) => _hasRemainingDebts(customer.id)).toList();
    
    return CupertinoPageScaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Payment Reminders',
          style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.dynamicPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search customers...',
                onChanged: (value) {
                  _searchQuery = value;
                  _filterCustomers();
                },
              ),
            ),
            
            // Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.money_dollar,
                      color: CupertinoColors.systemOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding Debts',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customersWithDebts.length} customers',
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
            
            // Customers List
            Expanded(
              child: customersWithDebts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.check_mark_circled,
                            size: 64,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No outstanding debts!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All customers have paid their debts.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customersWithDebts.length,
                      itemBuilder: (context, index) {
                        final customer = customersWithDebts[index];
                        final totalDebt = _getCustomerTotalDebt(customer.id);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSurface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.dynamicBorder(context),
                              width: 0.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.person_circle,
                                color: CupertinoColors.systemRed,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextPrimary(context),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  customer.phone,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.dynamicTextSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Outstanding: \$${totalDebt.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.systemRed,
                                  ),
                                ),
                              ],
                            ),
                            trailing: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: CupertinoColors.systemBlue,
                              borderRadius: BorderRadius.circular(8),
                              child: const Text(
                                'Send Reminder',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: () => _showPersonalizedReminderDialog(context, customer, totalDebt),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalizedReminderDialog(BuildContext context, Customer customer, double totalDebt) {
    final messageController = TextEditingController(
      text: 'Hello ${customer.name}, you have an outstanding balance of \$${totalDebt.toStringAsFixed(2)}. Please contact us to arrange payment.',
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
              'Customize your message for ${customer.name}:',
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
              'This message will be sent via WhatsApp to ${customer.phone}',
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
              await _sendWhatsAppReminder(context, customer, messageController.text.trim());
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

  Future<void> _sendWhatsAppReminder(BuildContext context, Customer customer, String message) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.sendWhatsAppPaymentReminder(customer.id, customMessage: message);

      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showSuccessNotification(
          title: 'Payment Reminder Sent',
          body: 'WhatsApp payment reminder has been sent to ${customer.name}',
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
}
