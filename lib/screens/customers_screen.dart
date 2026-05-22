import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';

import '../utils/currency_formatter.dart';
import '../utils/responsive_layout.dart';
import 'add_customer_screen.dart';
import 'add_debt_from_product_screen.dart';
import 'customer_details_screen.dart';

enum _DesktopDetailPanel { customer, addDebt, editCustomer }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with WidgetsBindingObserver {
  List<Customer> _filteredCustomers = [];
  Customer? _selectedCustomer;
  _DesktopDetailPanel _detailPanel = _DesktopDetailPanel.customer;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_filterCustomers);
    
    // Listen to AppState changes to refresh customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onAppStateChanged);
      
      // CRITICAL FIX: Initialize filtered customers immediately after adding listener
      if (appState.customers.isNotEmpty) {
        _filterCustomers();
      }
    });
  }
  
  void _onAppStateChanged() {
    if (!mounted) return;
    
    // Ensure filtered customers are always in sync with app state
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Always refresh filtered customers when app state changes
    // This ensures we have the latest data from Firebase streams
    if (appState.customers.isNotEmpty) {
      _filteredCustomers = List.from(appState.customers);
    } else if (appState.customers.isEmpty) {
      _filteredCustomers = [];
    }

    if (_selectedCustomer != null &&
        !appState.customers.any((c) => c.id == _selectedCustomer!.id)) {
      _selectedCustomer = null;
    }
    
    _filterCustomers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    
    // Remove AppState listener
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.removeListener(_onAppStateChanged);
    } catch (e) {
      // Context might be disposed already
    }
    
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
      if (customers.isEmpty) {
        _filteredCustomers = [];
        return;
      }
      
      if (query.isEmpty) {
        _filteredCustomers = List.from(customers); // Create a new list to avoid reference issues
      } else {
        _filteredCustomers = customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.id.toLowerCase().contains(query);
        }).toList();
      }

      if (_selectedCustomer != null) {
        final stillVisible = _filteredCustomers.any(
          (c) => c.id == _selectedCustomer!.id,
        );
        if (!stillVisible) {
          _selectedCustomer = null;
        }
      }
    });
  }

  Customer? _resolveSelectedCustomer(AppState appState) {
    if (_selectedCustomer == null) return null;
    for (final customer in appState.customers) {
      if (customer.id == _selectedCustomer!.id) {
        return customer;
      }
    }
    return null;
  }

  Map<String, List<Customer>> _groupCustomersByFirstLetter() {
    try {
      final grouped = <String, List<Customer>>{};
      
      // Safety check: return empty map if no customers
      if (_filteredCustomers.isEmpty) {
        return grouped;
      }
      
      for (final customer in _filteredCustomers) {
        try {
          final firstLetter = customer.name.isNotEmpty 
              ? customer.name[0].toUpperCase() 
              : '#';
          
          if (!grouped.containsKey(firstLetter)) {
            grouped[firstLetter] = [];
          }
          grouped[firstLetter]!.add(customer);
        } catch (e) {
          // Skip invalid customers
          continue;
        }
      }
      
      // Sort the groups alphabetically
      final sortedKeys = grouped.keys.toList()..sort();
      final sortedMap = <String, List<Customer>>{};
      
      for (final key in sortedKeys) {
        try {
          final customers = grouped[key];
          if (customers != null && customers.isNotEmpty) {
            sortedMap[key] = List.from(customers)..sort((a, b) => a.name.compareTo(b.name));
          }
        } catch (e) {
          // Skip invalid groups
          continue;
        }
      }
      
      return sortedMap;
    } catch (e) {
      // Return empty map if any error occurs
      return <String, List<Customer>>{};
    }
  }

  List<Customer> get _sortedFilteredCustomers {
    final sorted = List<Customer>.from(_filteredCustomers);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  Future<void> _openAddCustomer() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerScreen(),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, {double? maxWidth}) {
    final l10n = AppLocalizations.of(context)!;
    final field = Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dynamicBorder(context).withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchByNameOrId,
          hintStyle: TextStyle(
            color: AppColors.dynamicTextSecondary(context),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.dynamicTextSecondary(context),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(
          color: AppColors.dynamicTextPrimary(context),
          fontSize: 15,
        ),
      ),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: field,
      );
    }
    return field;
  }

  Widget _buildEmptyCustomersState(BuildContext context, {required bool hasCustomers}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: AppColors.dynamicTextSecondary(context),
          ),
          const SizedBox(height: 16),
          Text(
            hasCustomers ? l10n.noCustomersFound : l10n.noCustomersYet,
            style: AppTheme.title3.copyWith(
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasCustomers
                ? l10n.tryAdjustingSearchCriteria
                : l10n.startByAddingFirstCustomer,
            style: AppTheme.body.copyWith(
              color: AppColors.dynamicTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCustomerListPanel(
    BuildContext context, {
    required List<Customer> customers,
    required bool hasCustomers,
    required bool compact,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: customers.isEmpty
          ? _buildEmptyCustomersState(context, hasCustomers: hasCustomers)
          : Column(
              children: [
                if (compact)
                  _DesktopCustomersCompactHeader()
                else ...[
                  const _DesktopCustomersTableHeader(),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.dynamicBorder(context)
                          .withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      if (compact) {
                        return _DesktopCompactCustomerRow(
                          customer: customer,
                          isSelected: _selectedCustomer?.id == customer.id,
                          onView: () => _viewCustomerDetails(customer),
                        );
                      }
                      return _DesktopCustomerRow(
                        customer: customer,
                        isSelected: _selectedCustomer?.id == customer.id,
                        onView: () => _viewCustomerDetails(customer),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDesktopCustomers(BuildContext context, {required AppState appState}) {
    final l10n = AppLocalizations.of(context)!;
    final customers = _sortedFilteredCustomers;
    final hasCustomers = appState.customers.isNotEmpty;
    final selectedCustomer = _resolveSelectedCustomer(appState);
    final showDetailPanel = selectedCustomer != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(context, maxWidth: 420)),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _openAddCustomer,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: Text(l10n.addCustomer),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dynamicPrimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDetailPanel)
                  Expanded(
                    flex: 2,
                    child: _buildDesktopCustomerListPanel(
                      context,
                      customers: customers,
                      hasCustomers: hasCustomers,
                      compact: true,
                    ),
                  )
                else
                  Expanded(
                    child: _buildDesktopCustomerListPanel(
                      context,
                      customers: customers,
                      hasCustomers: hasCustomers,
                      compact: false,
                    ),
                  ),
                if (showDetailPanel) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.dynamicBorder(context)
                                .withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: switch (_detailPanel) {
                          _DesktopDetailPanel.addDebt =>
                            AddDebtFromProductScreen(
                              key: ValueKey('add-debt-${selectedCustomer.id}'),
                              customer: selectedCustomer,
                              embeddedInShell: true,
                              onCancel: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.customer,
                              ),
                              onComplete: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.customer,
                              ),
                            ),
                          _DesktopDetailPanel.editCustomer =>
                            AddCustomerScreen(
                              key: ValueKey('edit-${selectedCustomer.id}'),
                              customer: selectedCustomer,
                              embeddedInShell: true,
                              onCancel: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.customer,
                              ),
                              onComplete: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.customer,
                              ),
                              onDeleted: () => setState(() {
                                _selectedCustomer = null;
                                _detailPanel = _DesktopDetailPanel.customer;
                              }),
                            ),
                          _ => CustomerDetailsScreen(
                              key: ValueKey(selectedCustomer.id),
                              customer: selectedCustomer,
                              showDebtsSection: true,
                              embeddedInShell: true,
                              onClose: () => setState(() {
                                _selectedCustomer = null;
                                _detailPanel = _DesktopDetailPanel.customer;
                              }),
                              onAddDebt: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.addDebt,
                              ),
                              onEdit: () => setState(
                                () => _detailPanel = _DesktopDetailPanel.editCustomer,
                              ),
                            ),
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomersList(
    BuildContext context, {
    required AppState appState,
    required Map<String, List<Customer>> groupedCustomers,
  }) {
    if (_filteredCustomers.isEmpty || groupedCustomers.isEmpty) {
      return _buildEmptyCustomersState(
        context,
        hasCustomers: appState.customers.isNotEmpty,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groupedCustomers.length,
      itemBuilder: (context, index) {
        try {
          if (groupedCustomers.isEmpty ||
              index < 0 ||
              index >= groupedCustomers.length) {
            return const SizedBox.shrink();
          }

          final keys = groupedCustomers.keys.toList();
          if (index >= keys.length) {
            return const SizedBox.shrink();
          }

          final letter = keys[index];
          final customers = groupedCustomers[letter];

          if (customers == null || customers.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: AppColors.dynamicPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...customers.map(
                (customer) => _CustomerListTile(
                  customer: customer,
                  onDelete: () => _deleteCustomer(customer),
                  onView: () => _viewCustomerDetails(customer),
                ),
              ),
            ],
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final debts = appState.debts.where((d) => d.customerId == customer.id).toList();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteCustomer, style: TextStyle(color: AppColors.dynamicTextPrimary(context))),
          content: debts.isNotEmpty
              ? Text(l10n.deleteCustomerConfirmWithDebts(debts.length.toString()), style: TextStyle(color: AppColors.dynamicTextSecondary(context)))
              : Text(l10n.deleteCustomerConfirm, style: TextStyle(color: AppColors.dynamicTextSecondary(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: AppColors.dynamicPrimary(context))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await appState.deleteCustomer(customer.id);
                if (_selectedCustomer?.id == customer.id) {
                  _selectedCustomer = null;
                }
                _filterCustomers();
              },
              child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = ResponsiveLayout.isDesktopWeb(context);

    Widget body = Consumer<AppState>(
          builder: (context, appState, child) {
            // Show loading state while data is being loaded
            if (appState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            final groupedCustomers = _groupCustomersByFirstLetter();
            final totalCustomers = appState.customers.length;

            
            if (isDesktopWeb) {
              return _buildDesktopCustomers(
                context,
                appState: appState,
              );
            }

            final l10n = AppLocalizations.of(context)!;
            final content = Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customersTitle,
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(context),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalCustomers == 1
                            ? l10n.customerCountOne
                            : l10n.customersCount(totalCustomers.toString()),
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildSearchField(context),
                ),
                Expanded(
                  child: _buildMobileCustomersList(
                    context,
                    appState: appState,
                    groupedCustomers: groupedCustomers,
                  ),
                ),
              ],
            );
            return content;
          },
        );

    if (!isDesktopWeb) {
      body = SafeArea(child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      body: body,
      floatingActionButton: isDesktopWeb
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dynamicPrimary(context).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'customers_fab_hero',
                onPressed: _openAddCustomer,
                backgroundColor: AppColors.dynamicPrimary(context),
                elevation: 0,
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
    );
  }

  void _viewCustomerDetails(Customer customer) {
    if (ResponsiveLayout.isDesktopWeb(context)) {
      setState(() {
        _selectedCustomer = customer;
        _detailPanel = _DesktopDetailPanel.customer;
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(
          customer: customer,
          showDebtsSection: true,
        ),
      ),
    );
  }
}

/// Fixed column widths so phone, ID, and debt stay aligned in the full table.
class _DesktopCustomerTableColumns {
  _DesktopCustomerTableColumns._();

  static const double avatarWidth = 44;
  static const double avatarGap = 12;
  static const double phoneWidth = 150;
  static const double idWidth = 64;
  static const double debtWidth = 100;
  static const double horizontalPadding = 20;
}

class _DesktopCustomersCompactHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Text(
        l10n.customersTitle,
        style: AppTheme.caption1.copyWith(
          color: AppColors.dynamicTextSecondary(context),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DesktopCustomersTableHeader extends StatelessWidget {
  const _DesktopCustomersTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = AppTheme.caption1.copyWith(
      color: AppColors.dynamicTextSecondary(context),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _DesktopCustomerTableColumns.horizontalPadding,
        vertical: 14,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: _DesktopCustomerTableColumns.avatarWidth +
                _DesktopCustomerTableColumns.avatarGap,
          ),
          Expanded(
            child: Text(
              l10n.fullName.replaceAll(' *', ''),
              style: labelStyle,
            ),
          ),
          SizedBox(
            width: _DesktopCustomerTableColumns.phoneWidth,
            child: Text(l10n.phone, style: labelStyle),
          ),
          SizedBox(
            width: _DesktopCustomerTableColumns.idWidth,
            child: Text(l10n.idLabel, style: labelStyle),
          ),
          SizedBox(
            width: _DesktopCustomerTableColumns.debtWidth,
            child: Text(
              l10n.outstandingDebt,
              style: labelStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopCompactCustomerRow extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onView;

  const _DesktopCompactCustomerRow({
    required this.customer,
    required this.isSelected,
    required this.onView,
  });

  String _initials(String name) {
    final parts = name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]);
    final initials = parts.join();
    if (initials.isEmpty) return '?';
    if (initials.length == 1) return '$initials$initials';
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customerDebts =
            appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts
            .where((d) => !d.isFullyPaid)
            .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        final roundedDebt =
            ((totalRemainingDebt * 100).round() / 100).toDouble();

        return Material(
          color: isSelected
              ? AppColors.dynamicPrimary(context).withValues(alpha: 0.1)
              : Colors.transparent,
          child: InkWell(
            onTap: onView,
            hoverColor: AppColors.dynamicPrimary(context).withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                    child: Text(
                      _initials(customer.name),
                      style: TextStyle(
                        color: AppColors.dynamicPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTheme.body.copyWith(
                            color: AppColors.dynamicTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone,
                          style: AppTheme.caption1.copyWith(
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      roundedDebt > 0
                          ? CurrencyFormatter.formatAmount(context, roundedDebt)
                          : '—',
                      style: AppTheme.caption1.copyWith(
                        color: roundedDebt > 0
                            ? AppColors.error
                            : AppColors.dynamicTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopCustomerRow extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onView;

  const _DesktopCustomerRow({
    required this.customer,
    this.isSelected = false,
    required this.onView,
  });

  String _initials(String name) {
    final parts = name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]);
    final initials = parts.join();
    if (initials.isEmpty) return '?';
    if (initials.length == 1) return '$initials$initials';
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final customerDebts =
            appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts
            .where((d) => !d.isFullyPaid)
            .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        final roundedDebt =
            ((totalRemainingDebt * 100).round() / 100).toDouble();

        return Material(
          color: isSelected
              ? AppColors.dynamicPrimary(context).withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: onView,
            hoverColor: AppColors.dynamicPrimary(context).withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _DesktopCustomerTableColumns.horizontalPadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.dynamicPrimary(context).withValues(alpha: 0.1),
                    child: Text(
                      _initials(customer.name),
                      style: TextStyle(
                        color: AppColors.dynamicPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: _DesktopCustomerTableColumns.avatarGap),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: AppTheme.headline.copyWith(
                        color: AppColors.dynamicTextPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: _DesktopCustomerTableColumns.phoneWidth,
                    child: Text(
                      customer.phone,
                      style: AppTheme.body.copyWith(
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: _DesktopCustomerTableColumns.idWidth,
                    child: Text(
                      customer.id,
                      style: AppTheme.body.copyWith(
                        color: AppColors.dynamicTextSecondary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: _DesktopCustomerTableColumns.debtWidth,
                    child: Text(
                      roundedDebt > 0
                          ? CurrencyFormatter.formatAmount(context, roundedDebt)
                          : '—',
                      style: AppTheme.body.copyWith(
                        color: roundedDebt > 0
                            ? AppColors.error
                            : AppColors.dynamicTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _CustomerListTile({
    required this.customer,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Simple calculation: Sum up remaining amounts from debt records
        final customerDebts = appState.debts.where((d) => d.customerId == customer.id).toList();
        final totalRemainingDebt = customerDebts.where((d) => !d.isFullyPaid).fold(0.0, (sum, debt) => sum + debt.remainingAmount);
        // Fix floating-point precision issues by rounding to 2 decimal places
        final roundedTotalRemainingDebt = ((totalRemainingDebt * 100).round() / 100);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showCustomerActionSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
              contentPadding: const EdgeInsets.only(left: 8, right: 16, top: 0, bottom: 0),
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.dynamicPrimary(context).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    () {
                      final initials = customer.name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join('');
                      // Ensure we always show at least 2 characters, pad with first letter if needed
                      if (initials.isEmpty) return '?';
                      if (initials.length == 1) return initials + initials;
                      return initials.length > 2 ? initials.substring(0, 2) : initials;
                    }(),
                    style: TextStyle(
                      color: AppColors.dynamicPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.dynamicTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 8,
                              color: AppColors.dynamicTextSecondary(context),
                            ),
                            const SizedBox(width: 1),
                            Text(
                              customer.phone,
                              style: TextStyle(
                                color: AppColors.dynamicTextSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 8,
                            color: AppColors.dynamicTextSecondary(context),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            'ID: ${customer.id}',
                            style: TextStyle(
                              color: AppColors.dynamicTextSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (roundedTotalRemainingDebt > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 8,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              CurrencyFormatter.formatAmount(context, roundedTotalRemainingDebt),
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
  
  void _showCustomerActionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          customer.name,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onView();
            },
            child: Text(l10n.viewDetails),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await _showDeleteConfirmation(context);
              if (confirmed) {
                onDelete();
              }
            },
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(l10n.deleteCustomer),
        content: Text(l10n.deleteCustomerConfirmWithName(customer.name)),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ) ?? false;
  }
}