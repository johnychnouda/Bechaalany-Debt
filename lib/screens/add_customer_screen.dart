import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _idController.text = widget.customer!.id;
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
    } else {
      _idController.text = '';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    final l10n = AppLocalizations.of(context);
    
    String customerId = _idController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String address = _addressController.text.trim();
    
    if (customerId.isEmpty) {
      _showErrorSnackBar(l10n.pleaseEnterCustomerId);
      return;
    }
    
    if (name.isEmpty) {
      _showErrorSnackBar(l10n.pleaseEnterName);
      return;
    }
    
    if (phone.isEmpty) {
      _showErrorSnackBar(l10n.pleaseEnterPhone);
      return;
    }
    
    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorSnackBar(l10n.pleaseEnterValidEmail);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      Customer customer;
      
      if (widget.customer != null) {
        customer = widget.customer!.copyWith(
          id: customerId,
          name: name,
          phone: phone,
          email: email.isEmpty ? null : email,
          address: address.isEmpty ? null : address,
          updatedAt: DateTime.now(),
        );
        await appState.updateCustomer(customer);
      } else {
        customer = Customer(
          id: customerId,
          name: name,
          phone: phone,
          email: email.isEmpty ? null : email,
          address: address.isEmpty ? null : address,
          createdAt: DateTime.now(),
        );
        await appState.addCustomer(customer);
      }

      setState(() {
        _isLoading = false;
      });
      
      _showSuccessSnackBar(widget.customer != null 
          ? 'Customer updated successfully!' 
          : 'Customer added successfully!');
      
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar(widget.customer != null 
          ? 'Failed to update customer: $e'
          : 'Failed to add customer: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
                            backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
                            backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.customer != null ? l10n.editCustomer : l10n.addCustomer,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer ID
              _buildField(
                label: 'Customer ID',
                controller: _idController,
                placeholder: 'Enter customer ID',
                enabled: widget.customer == null,
                isRequired: true,
              ),
              
              const SizedBox(height: 16),
              
              // Name
              _buildField(
                label: 'Full Name',
                controller: _nameController,
                placeholder: 'Enter customer name',
                isRequired: true,
              ),
              
              const SizedBox(height: 16),
              
              // Phone
              _buildField(
                label: 'Phone Number',
                controller: _phoneController,
                placeholder: 'Enter phone number',
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              
              const SizedBox(height: 16),
              
              // Email
              _buildField(
                label: 'Email Address',
                controller: _emailController,
                placeholder: 'Enter email (optional)',
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              
              // Address
              _buildField(
                label: 'Address',
                controller: _addressController,
                placeholder: 'Enter address (optional)',
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.customer != null ? 'Update Customer' : 'Add Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
                          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
                TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
} 