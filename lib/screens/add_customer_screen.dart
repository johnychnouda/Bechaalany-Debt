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
  bool _isIdDuplicate = false;
  bool _isPhoneDuplicate = false;

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

  // Check for duplicate customer ID
  bool _isDuplicateId(String id) {
    if (widget.customer != null && id == widget.customer!.id) {
      return false; // Same customer, not a duplicate
    }
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.customers.any((customer) => customer.id.toLowerCase() == id.toLowerCase());
  }

  // Check for duplicate phone number
  bool _isDuplicatePhone(String phone) {
    if (widget.customer != null && phone == widget.customer!.phone) {
      return false; // Same customer, not a duplicate
    }
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.customers.any((customer) => customer.phone == phone);
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid phone number (7-15 digits)
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return false;
    }
    
    // Check if it contains only digits and common phone characters
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    return phoneRegex.hasMatch(phone);
  }

  // Validate email domain
  bool _isValidEmailDomain(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return false;
      
      final domain = parts[1];
      
      // Check for common invalid domains
      final invalidDomains = [
        'test.com', 'example.com', 'invalid.com', 'fake.com',
        'temp.com', 'dummy.com', 'sample.com'
      ];
      
      if (invalidDomains.contains(domain.toLowerCase())) {
        return false;
      }
      
      // Check domain format
      final domainRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$');
      return domainRegex.hasMatch(domain);
    } catch (e) {
      return false;
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernField(
                    label: 'Customer ID *',
                    controller: _idController,
                    placeholder: 'Enter customer ID',
                    icon: Icons.tag,
                    enabled: true, // Allow editing in edit mode
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer ID';
                      }
                      
                      // Check for duplicate ID
                      if (_isDuplicateId(value.trim())) {
                        return 'Customer ID already exists';
                      }
                      
                      // Check for special characters
                      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
                        return 'Customer ID can only contain letters, numbers, underscore, and hyphen';
                      }
                      
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _isIdDuplicate = _isDuplicateId(value.trim());
                      });
                    },
                  ),
                  if (_isIdDuplicate && _idController.text.trim().isNotEmpty)
                    _buildDuplicateWarning('This Customer ID already exists'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Name
              _buildModernField(
                label: 'Full Name *',
                controller: _nameController,
                placeholder: 'Enter customer name',
                icon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      
                      // Check phone number format
                      if (!_isValidPhoneNumber(value.trim())) {
                        return 'Please enter a valid phone number (7-15 digits)';
                      }
                      
                      // Check for duplicate phone number
                      if (_isDuplicatePhone(value.trim())) {
                        return 'Phone number already exists';
                      }
                      
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _isPhoneDuplicate = _isDuplicatePhone(value.trim());
                      });
                    },
                  ),
                  if (_isPhoneDuplicate && _phoneController.text.trim().isNotEmpty)
                    _buildDuplicateWarning('This phone number already exists'),
                ],
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
                    
                    // Check email domain
                    if (!_isValidEmailDomain(value.trim())) {
                      return 'Please enter a valid email domain';
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
  
  Widget _buildDuplicateWarning(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
} 