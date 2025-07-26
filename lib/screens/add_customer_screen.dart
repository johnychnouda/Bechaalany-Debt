import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      final appState = Provider.of<AppState>(context, listen: false);
      
      if (widget.customer != null) {
        await appState.updateCustomer(customer);
      } else {
        await appState.addCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to save customer: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              _buildModernField(
                label: 'Customer ID *',
                controller: _idController,
                placeholder: 'Enter customer ID',
                icon: Icons.tag,
                enabled: widget.customer == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer ID';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Name
              _buildModernField(
                label: 'Full Name *',
                controller: _nameController,
                placeholder: 'Enter customer name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone
              _buildModernField(
                label: 'Phone Number *',
                controller: _phoneController,
                placeholder: 'Enter phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email
              _buildModernField(
                label: 'Email Address',
                controller: _emailController,
                placeholder: 'Enter email (optional)',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Address
              _buildModernField(
                label: 'Address',
                controller: _addressController,
                placeholder: 'Enter address (optional)',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.customer != null ? 'Update Customer' : 'Add Customer',
                          style: const TextStyle(fontSize: 16),
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
  
  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
} 