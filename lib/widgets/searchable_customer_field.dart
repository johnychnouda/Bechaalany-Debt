import 'package:flutter/material.dart';
import '../models/customer.dart';

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
    this.placeholder = 'Search by name or ID...',
  });

  @override
  State<SearchableCustomerField> createState() => _SearchableCustomerFieldState();
}

class _SearchableCustomerFieldState extends State<SearchableCustomerField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Customer> _filteredCustomers = [];

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

  void _filterCustomers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = [];
      });
      return;
    }

    setState(() {
      _filteredCustomers = widget.customers.where((customer) {
        final nameMatch = customer.name.toLowerCase().contains(query.toLowerCase());
        final idMatch = customer.id.toLowerCase().contains(query.toLowerCase());
        return nameMatch || idMatch;
      }).toList();
    });
  }

  void _selectCustomer(Customer customer) {
    widget.onCustomerSelected(customer);
    _searchController.text = customer.name;
    _searchFocusNode.unfocus();
    setState(() {
      _filteredCustomers = [];
    });
  }

  void _updateSelectedCustomer() {
    if (widget.selectedCustomer != null) {
      _searchController.text = widget.selectedCustomer!.name;
      setState(() {
        _filteredCustomers = [];
      });
    }
  }

  void _clearSelection() {
    widget.onCustomerSelected(null);
    _searchController.clear();
    setState(() {
      _filteredCustomers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Search Text Field Container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: _searchController.text.isNotEmpty && _filteredCustomers.isNotEmpty 
                  ? Radius.zero 
                  : const Radius.circular(12),
              bottomRight: _searchController.text.isNotEmpty && _filteredCustomers.isNotEmpty 
                  ? Radius.zero 
                  : const Radius.circular(12),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.selectedCustomer != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSelection,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _filterCustomers,
            onTap: () {
              // Don't show suggestions until user starts typing
            },
          ),
        ),
        

        
        // Search Results Dropdown
        if (_searchController.text.isNotEmpty && _filteredCustomers.isNotEmpty && widget.selectedCustomer == null)
          Container(
            constraints: BoxConstraints(
              maxHeight: _filteredCustomers.length == 1 ? 48.0 : (_filteredCustomers.length * 48.0).clamp(48.0, 200.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return Container(
                  decoration: BoxDecoration(
                    border: index < _filteredCustomers.length - 1 
                        ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                        : null,
                  ),
                  child: GestureDetector(
                    onTap: () => _selectCustomer(customer),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ID: ${customer.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
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
              },
            ),
          ),
        
        // No Results Message
        if (_searchController.text.isNotEmpty && _filteredCustomers.isEmpty && widget.selectedCustomer == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'No customers found matching "${_searchController.text}"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
} 