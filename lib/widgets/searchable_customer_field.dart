import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../constants/app_colors.dart';

class SearchableCustomerField extends StatefulWidget {
  final Customer? selectedCustomer;
  final List<Customer> customers;
  final Function(Customer?) onCustomerSelected;
  final String label;
  final String placeholder;

  const SearchableCustomerField({
    super.key,
    required this.selectedCustomer,
    required this.customers,
    required this.onCustomerSelected,
    this.label = 'Customer',
    this.placeholder = 'Search by name or ID',
  });

  @override
  State<SearchableCustomerField> createState() => _SearchableCustomerFieldState();
}

class _SearchableCustomerFieldState extends State<SearchableCustomerField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Customer> _filteredCustomers = [];
  // String _searchQuery = ''; // Removed unused field
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredCustomers = [];
    if (widget.selectedCustomer != null) {
      _searchController.text = widget.selectedCustomer!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableCustomerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomer != oldWidget.selectedCustomer) {
      _updateSelectedCustomer();
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = widget.customers;
      } else {
        _filteredCustomers = widget.customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // void _selectCustomer(Customer customer) { // Removed unused method
  //   widget.onCustomerSelected(customer);
  //   _searchController.clear();
  //   _searchFocusNode.unfocus();
  //   setState(() {
  //     _filteredCustomers = [];
  //   });
  // }

  void _updateSelectedCustomer() {
    if (widget.selectedCustomer != null) {
      _searchController.clear();
      setState(() {
        _filteredCustomers = [];
      });
    }
  }

  // void _clearSelection() { // Removed unused method
  //   widget.onCustomerSelected(null);
  //   _searchController.clear();
  //   setState(() {
  //     _filteredCustomers = [];
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
            prefixIcon: Icon(Icons.search, color: AppColors.dynamicTextSecondary(context)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _filterCustomers();
                    },
                    icon: Icon(Icons.clear, color: AppColors.dynamicTextSecondary(context)),
                  )
                : null,
            filled: true,
            fillColor: AppColors.dynamicSurface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dynamicBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dynamicPrimary(context), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
          onChanged: (value) {
            _filterCustomers();
            setState(() {
              _showDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showDropdown = _searchController.text.isNotEmpty;
            });
          },
        ),
        if (_showDropdown && _filteredCustomers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dynamicBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _filteredCustomers.map((customer) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      widget.onCustomerSelected(customer);
                      _searchController.text = customer.name;
                      setState(() {
                        _showDropdown = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.dynamicPrimary(context).withAlpha(26),
                            child: Text(
                              customer.name.split(' ').map((e) => e[0]).join(''),
                              style: TextStyle(
                                color: AppColors.dynamicPrimary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  customer.name,
                                  style: TextStyle(
                                    color: AppColors.dynamicTextPrimary(context),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'ID: ${customer.id}',
                                  style: TextStyle(
                                    color: AppColors.dynamicTextSecondary(context),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (widget.selectedCustomer != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dynamicPrimary(context).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.dynamicPrimary(context).withAlpha(51),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.dynamicPrimary(context),
                  child: Text(
                    widget.selectedCustomer!.name.split(' ').map((e) => e[0]).join(''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedCustomer!.name,
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${widget.selectedCustomer!.id}',
                        style: TextStyle(
                          color: AppColors.dynamicTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    widget.onCustomerSelected(null);
                  },
                  icon: Icon(
                    Icons.close,
                    color: AppColors.dynamicTextSecondary(context),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 