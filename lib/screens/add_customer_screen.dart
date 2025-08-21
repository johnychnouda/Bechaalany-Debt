import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
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
  bool _isEmailDuplicate = false;
  String _countryCode = '+961'; // Default country code for Lebanon
  final _fullPhoneController = TextEditingController(); // Controller for full phone number

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _idController.text = widget.customer!.id;
      _nameController.text = widget.customer!.name;
      _fullPhoneController.text = widget.customer!.phone;
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
    } else {
      _idController.text = '';
      // Set default country code for Lebanon (+961)
      _fullPhoneController.text = '+961';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _fullPhoneController.dispose();
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

  // Check for duplicate email address
  bool _isDuplicateEmail(String email) {
    if (widget.customer != null && email == widget.customer!.email) {
      return false; // Same customer, not a duplicate
    }
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.customers.any((customer) => customer.email == email && customer.email != null);
  }

  // Get customer with duplicate email
  Customer? _getCustomerWithEmail(String email) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.customers.firstWhere(
      (customer) => customer.email == email && customer.email != null,
      orElse: () => Customer(
        id: '',
        name: '',
        phone: '',
        createdAt: DateTime.now(),
      ),
    );
  }

  // Get customer with duplicate phone number
  Customer? _getCustomerWithPhone(String phone) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.customers.firstWhere(
      (customer) => customer.phone == phone,
      orElse: () => Customer(
        id: '',
        name: '',
        phone: '',
        createdAt: DateTime.now(),
      ),
    );
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid phone number (minimum 8 digits, maximum 15 digits)
    if (digitsOnly.length < 8 || digitsOnly.length > 15) {
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
          if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Check for duplicate email and show confirmation dialog
    final email = _emailController.text.trim();
    if (email.isNotEmpty && _isDuplicateEmail(email)) {
      final duplicateCustomer = _getCustomerWithEmail(email);
      if (duplicateCustomer != null && duplicateCustomer.id.isNotEmpty) {
        final shouldContinue = await _showDuplicateEmailDialog(duplicateCustomer, email);
        if (!shouldContinue) {
          return;
        }
      }
    }

    // Check for duplicate phone number and show confirmation dialog
    final phone = _fullPhoneController.text.trim();
    if (_isDuplicatePhone(phone)) {
      final duplicateCustomer = _getCustomerWithPhone(phone);
      if (duplicateCustomer != null && duplicateCustomer.id.isNotEmpty) {
        final shouldContinue = await _showDuplicatePhoneDialog(duplicateCustomer, phone);
        if (!shouldContinue) {
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        phone: _fullPhoneController.text.trim(),
        email: email.isEmpty ? null : email,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: widget.customer != null ? DateTime.now() : null,
      );

      final appState = Provider.of<AppState>(context, listen: false);
      
      if (widget.customer != null) {
        await appState.updateCustomer(customer);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate successful update
        }
      } else {
        await appState.addCustomer(customer);
        if (mounted) {
          Navigator.pop(context);
        }
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

  Future<bool> _showDuplicateEmailDialog(Customer existingCustomer, String email) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate Email'),
          content: Text(
            'The email address "$email" is already used by customer "${existingCustomer.name}" (ID: ${existingCustomer.id}).\n\nDo you want to continue with this email address?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showDuplicatePhoneDialog(Customer existingCustomer, String phone) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate Phone Number'),
          content: Text(
            'The phone number "$phone" is already used by customer "${existingCustomer.name}" (ID: ${existingCustomer.id}).\n\nDo you want to continue with this phone number?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Custom phone input widget with editable country code
  Widget _buildPhoneInput({
    required String label,
    required String placeholder,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dynamicBorder(context),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _fullPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground(context),
      appBar: AppBar(
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Add Customer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.dynamicPrimary(context)),
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
                  if (widget.customer != null) ...[
                    // Customer ID display styled like the customer field in Add Debt from Product
                    Text(
                      'Customer ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface(context).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dynamicBorder(context).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag,
                            color: AppColors.dynamicTextSecondary(context),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.customer!.id,
                            style: TextStyle(
                              color: AppColors.dynamicTextPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Editable field when adding new customer
                    _buildModernField(
                      label: 'Customer ID *',
                      controller: _idController,
                      placeholder: 'Enter customer ID',
                      icon: Icons.tag,
                      keyboardType: TextInputType.number,
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
                    const SizedBox(height: 16),
                  ],
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
                  _buildPhoneInput(
                    label: 'Phone Number *',
                    placeholder: 'Enter phone number',
                    onChanged: (value) {
                      setState(() {
                        _isPhoneDuplicate = _isDuplicatePhone(value.trim());
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      
                      // Check phone number format
                      if (!_isValidPhoneNumber(value.trim())) {
                        return 'Please enter a valid phone number (minimum 8 digits)';
                      }
                      
                      // Note: Duplicate phone number validation is handled in _saveCustomer with confirmation dialog
                      
                      return null;
                    },
                  ),
                  if (_isPhoneDuplicate && _phoneController.text.trim().isNotEmpty)
                    _buildDuplicateWarning('This phone number already exists'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    onChanged: (value) {
                      setState(() {
                        _isEmailDuplicate = _isDuplicateEmail(value.trim());
                      });
                    },
                  ),
                  if (_isEmailDuplicate && _emailController.text.trim().isNotEmpty)
                    _buildDuplicateWarning('This email is already used by another customer'),
                ],
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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dynamicError(context).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.dynamicError(context).withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.dynamicError(context),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.dynamicError(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
            prefixIcon: Icon(icon, color: AppColors.dynamicTextSecondary(context)),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dynamicError(context)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
        ),
      ],
    );
  }
} 