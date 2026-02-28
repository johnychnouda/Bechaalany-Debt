import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../models/customer.dart';
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
  Set<String> _selectedCustomerIds = {};
  bool _isSelectionMode = false;

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
                 customer.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _toggleCustomerSelection(String customerId) {
    setState(() {
      if (_selectedCustomerIds.contains(customerId)) {
        _selectedCustomerIds.remove(customerId);
      } else {
        _selectedCustomerIds.add(customerId);
      }
      _isSelectionMode = _selectedCustomerIds.isNotEmpty;
    });
  }

  void _selectAllCustomers() {
    final customersWithDebts = _filteredCustomers.where((customer) => _hasRemainingDebts(customer.id)).toList();
    setState(() {
      _selectedCustomerIds = customersWithDebts.map((c) => c.id).toSet();
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCustomerIds.clear();
      _isSelectionMode = false;
    });
  }

  double _getCustomerTotalDebt(String customerId) {
    final appState = Provider.of<AppState>(context, listen: false);
    final customerDebts = appState.debts
        .where((debt) => debt.customerId == customerId && !debt.isFullyPaid)
        .toList();
    
    double totalUSD = 0.0;
    for (final debt in customerDebts) {
      // Convert each debt amount to USD equivalent
      final usdAmount = CurrencyFormatter.getCurrentUSDEquivalent(context, debt.remainingAmount, storedCurrency: debt.storedCurrency);
      totalUSD += usdAmount;
    }
    
    return totalUSD;
  }

  bool _hasRemainingDebts(String customerId) {
    return _getCustomerTotalDebt(customerId) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customersWithDebts = _filteredCustomers.where((customer) => _hasRemainingDebts(customer.id)).toList();
        
        return Scaffold(
          backgroundColor: AppColors.dynamicBackground(context),
          body: SafeArea(
            child: Column(
              children: [
                // iOS 18.6 Style Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button and Title Row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: AppColors.dynamicTextPrimary(context),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.paymentRemindersTitle,
                              style: TextStyle(
                                color: AppColors.dynamicTextPrimary(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (_isSelectionMode)
                            TextButton(
                              onPressed: _clearSelection,
                              child: Text(
                                AppLocalizations.of(context)!.clearSelection,
                                style: TextStyle(
                                  color: AppColors.dynamicPrimary(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: _selectAllCustomers,
                              child: Text(
                                AppLocalizations.of(context)!.selectAll,
                                style: TextStyle(
                                  color: AppColors.dynamicPrimary(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customersWithDebts.length == 1
                            ? AppLocalizations.of(context)!.paymentRemindersCustomerCountOne
                            : AppLocalizations.of(context)!.paymentRemindersCustomerCountOther(customersWithDebts.length.toString()),
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // iOS 18.6 Style Search Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
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
                        hintText: AppLocalizations.of(context)!.searchByNameOrId,
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
                ),
                
                // Selection Summary
                if (_isSelectionMode) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.dynamicPrimary(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.dynamicPrimary(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCustomerIds.length == 1
                                ? AppLocalizations.of(context)!.paymentRemindersSelectedOne
                                : AppLocalizations.of(context)!.paymentRemindersSelectedOther(_selectedCustomerIds.length.toString()),
                            style: TextStyle(
                              color: AppColors.dynamicPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selectedCustomerIds.isNotEmpty ? () => _showBatchReminderDialog(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dynamicPrimary(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.sendReminders,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
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
                                AppLocalizations.of(context)!.allClear,
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.noCustomersOutstandingDebts,
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
                            final isSelected = _selectedCustomerIds.contains(customer.id);
                            
                            return _CustomerReminderTile(
                              customer: customer,
                              totalDebt: totalDebt,
                              isSelected: isSelected,
                              onTap: () => _toggleCustomerSelection(customer.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBatchReminderDialog(BuildContext context) {
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.dynamicSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.dynamicTextSecondary(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                AppLocalizations.of(context)!.sendPaymentReminderDialogTitle,
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                AppLocalizations.of(context)!.batchReminderSubtitle,
                style: TextStyle(
                  color: AppColors.dynamicTextSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              
              // Text input field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.dynamicBorder(context),
                    width: 1,
                  ),
                ),
                child: CupertinoTextField(
                  controller: messageController,
                  placeholder: AppLocalizations.of(context)!.enterCustomMessage,
                  placeholderStyle: TextStyle(
                    color: AppColors.dynamicTextSecondary(context).withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  style: TextStyle(
                    color: AppColors.dynamicTextPrimary(context),
                    fontSize: 16,
                  ),
                  maxLines: 4,
                  minLines: 3,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.dynamicBorder(context),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
                              color: AppColors.dynamicTextPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _sendBatchWhatsAppReminders(context, messageController.text.trim());
                      },
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.sendToCount(_selectedCustomerIds.length.toString()),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendBatchWhatsAppReminders(BuildContext context, String message) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      int successCount = 0;
      int totalCount = _selectedCustomerIds.length;
      
      // Send reminders to all selected customers
      for (final customerId in _selectedCustomerIds) {
        try {
          await appState.sendWhatsAppPaymentReminder(customerId, customMessage: message);
          successCount++;
          
          // Add delay between customers to allow user to send message
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          // Continue with other customers even if one fails
        }
      }

      // Show success feedback
      if (mounted && context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (successCount == totalCount) {
          _showSuccessDialog(context, l10n.allRemindersSentSuccess);
        } else {
          _showWarningDialog(context, l10n.sentToCountOfTotal(successCount.toString(), totalCount.toString()));
        }
        
        // Clear selection after sending
        setState(() {
          _selectedCustomerIds.clear();
          _isSelectionMode = false;
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        _showErrorDialog(context, AppLocalizations.of(context)!.batchRemindersFailed(e.toString()));
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.success),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.warning),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

}

class _CustomerReminderTile extends StatelessWidget {
  final Customer customer;
  final double totalDebt;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerReminderTile({
    required this.customer,
    required this.totalDebt,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context).withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.dynamicPrimary(context).withValues(alpha: 0.1) : AppColors.dynamicSurface(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.dynamicPrimary(context) : AppColors.dynamicBorder(context).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.dynamicPrimary(context),
                              size: 18,
                            )
                          : null,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Customer Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          customer.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                          style: TextStyle(
                            color: AppColors.dynamicPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.dynamicTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppLocalizations.of(context)!.idLabel}: ${customer.id}',
                            style: TextStyle(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: AppColors.dynamicTextSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  color: AppColors.dynamicTextSecondary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Amount on the right side
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        CurrencyFormatter.formatAmount(context, totalDebt),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

