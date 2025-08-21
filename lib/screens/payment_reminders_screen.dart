import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../models/customer.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> with WidgetsBindingObserver {
  String _searchQuery = '';
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_filterCustomers);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterCustomers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _filterCustomers();
    }
  }

  void _filterCustomers() {
    final appState = Provider.of<AppState>(context, listen: false);
    final customers = appState.customers;
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(customers);
      } else {
        _filteredCustomers = customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.phone.contains(query) ||
                 (customer.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
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

  double _getTotalOutstandingAmount() {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.debts
        .where((debt) => !debt.isFullyPaid)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customersWithDebts = _filteredCustomers.where((customer) => _hasRemainingDebts(customer.id)).toList();
        final totalOutstanding = _getTotalOutstandingAmount();
        
        return Scaffold(
          backgroundColor: AppColors.dynamicBackground(context),
          appBar: AppBar(
            backgroundColor: AppColors.dynamicBackground(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
            title: Text(
              'Payment Reminders',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.dynamicPrimary(context),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Modern Search Bar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    hintStyle: TextStyle(
                      color: AppColors.dynamicTextSecondary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.dynamicTextSecondary(context),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(
                    color: AppColors.dynamicTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              // Beautiful Summary Cards
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Outstanding Customers Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_outline_rounded,
                                color: Colors.orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Outstanding',
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${customersWithDebts.length}',
                              style: TextStyle(
                                color: AppColors.dynamicTextPrimary(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              customersWithDebts.length == 1 ? 'customer' : 'customers',
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Total Amount Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.attach_money_rounded,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total Owed',
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatAmountWithCurrency(context, totalOutstanding),
                              style: TextStyle(
                                color: AppColors.dynamicTextPrimary(context),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Customers List
              Expanded(
                child: customersWithDebts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.dynamicSurface(context),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 36,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'All clear!',
                              style: TextStyle(
                                color: AppColors.dynamicTextPrimary(context),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No customers have outstanding debts',
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: customersWithDebts.length,
                        itemBuilder: (context, index) {
                          final customer = customersWithDebts[index];
                          final totalDebt = _getCustomerTotalDebt(customer.id);
                          
                          return _CustomerReminderTile(
                            customer: customer,
                            totalDebt: totalDebt,
                            onSendReminder: () => _showPersonalizedReminderDialog(context, customer, totalDebt),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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

class _CustomerReminderTile extends StatelessWidget {
  final Customer customer;
  final double totalDebt;
  final VoidCallback onSendReminder;

  const _CustomerReminderTile({
    required this.customer,
    required this.totalDebt,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customerDebts = appState.debts.where((d) => d.customerId == customer.id && !d.isFullyPaid).toList();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSendReminder,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Customer Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          customer.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                          style: TextStyle(
                            color: AppColors.dynamicPrimary(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  CurrencyFormatter.formatAmountWithCurrency(context, totalDebt),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'owed',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Action Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onSendReminder,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Remind',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
