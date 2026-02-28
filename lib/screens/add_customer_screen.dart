import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
// Notification service import removed

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

  // Direct navigation method
  void _navigateBack([dynamic result]) {
    if (mounted) {

      // Use a post-frame callback to ensure the UI is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Navigator.of(context).pop(result);

          } catch (e) {

            // Try alternative method
            try {
              Navigator.of(context).maybePop();
            } catch (e2) {
              // Ignore navigation errors
            }
          }
        }
      });
    }
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
        updatedAt: DateTime.now(), // Always set updatedAt to current time
      );

      // Validate that ID is not changed when updating
      if (widget.customer != null && customer.id != widget.customer!.id) {
        throw Exception('Customer ID cannot be changed during update');
      }

      final appState = Provider.of<AppState>(context, listen: false);
      
      if (widget.customer != null) {
        // Ensure we're updating with the latest data and preserve the original ID
        final updatedCustomer = customer.copyWith(
          id: widget.customer!.id, // Always preserve the original ID
          updatedAt: DateTime.now(), // Force update timestamp
        );
        

        
        await appState.updateCustomer(updatedCustomer);
        
        // Show success message and navigate back immediately
        if (mounted) {
          // Customer updated successfully
          
          // Try direct navigation first
          try {

            Navigator.of(context).pop(true);

          } catch (e) {

            // Fallback to our method
            _navigateBack(true);
          }
        }
      } else {
        await appState.addCustomer(customer);

        
        // Show success message and navigate back immediately
        if (mounted) {

          // Customer added successfully
          
          // Try direct navigation first
          try {

            Navigator.of(context).pop();

          } catch (e) {

            // Fallback to our method
            _navigateBack();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Error occurred
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
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.duplicatePhoneNumber),
          content: Text(
            l10n.duplicatePhoneMessage(phone, existingCustomer.name, existingCustomer.id),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.continueButton),
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
        DecoratedBox(
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
          widget.customer != null
              ? AppLocalizations.of(context)!.editCustomer
              : AppLocalizations.of(context)!.addCustomer,
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
                      AppLocalizations.of(context)!.customerId,
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
                        color: AppColors.dynamicSurface(context).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dynamicBorder(context).withValues(alpha: 0.5),
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
                      label: AppLocalizations.of(context)!.customerIdRequired,
                      controller: _idController,
                      placeholder: AppLocalizations.of(context)!.enterCustomerId,
                      icon: Icons.tag,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final l10n = AppLocalizations.of(context)!;
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterCustomerId;
                        }
                        
                        // Check for duplicate ID
                        if (_isDuplicateId(value.trim())) {
                          return l10n.customerIdAlreadyExists;
                        }
                        
                        // Check for special characters
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
                          return l10n.customerIdInvalidChars;
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
                      _buildDuplicateWarning(AppLocalizations.of(context)!.thisCustomerIdAlreadyExists),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Name
              _buildModernField(
                label: AppLocalizations.of(context)!.fullName,
                controller: _nameController,
                placeholder: AppLocalizations.of(context)!.enterCustomerName,
                icon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterCustomerName;
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
                    label: AppLocalizations.of(context)!.phoneNumber,
                    placeholder: AppLocalizations.of(context)!.enterPhoneNumber,
                    onChanged: (value) {
                      setState(() {
                        _isPhoneDuplicate = _isDuplicatePhone(value.trim());
                      });
                    },
                    validator: (value) {
                      final l10n = AppLocalizations.of(context)!;
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterPhoneNumber;
                      }
                      
                      // Check phone number format
                      if (!_isValidPhoneNumber(value.trim())) {
                        return l10n.validPhoneNumber;
                      }
                      
                      // Note: Duplicate phone number validation is handled in _saveCustomer with confirmation dialog
                      
                      return null;
                    },
                  ),
                  if (_isPhoneDuplicate && _phoneController.text.trim().isNotEmpty)
                    _buildDuplicateWarning(AppLocalizations.of(context)!.thisPhoneNumberAlreadyExists),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernField(
                    label: AppLocalizations.of(context)!.emailAddress,
                    controller: _emailController,
                    placeholder: AppLocalizations.of(context)!.enterEmailOptional,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final l10n = AppLocalizations.of(context)!;
                      if (value != null && value.trim().isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return l10n.pleaseEnterValidEmail;
                        }
                        
                        // Check email domain
                        if (!_isValidEmailDomain(value.trim())) {
                          return l10n.validEmailDomain;
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
                    _buildDuplicateWarning(AppLocalizations.of(context)!.thisEmailAlreadyUsed),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Address
              _buildModernField(
                label: AppLocalizations.of(context)!.address,
                controller: _addressController,
                placeholder: AppLocalizations.of(context)!.enterAddressOptional,
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
                          widget.customer != null
                              ? AppLocalizations.of(context)!.updateCustomer
                              : AppLocalizations.of(context)!.addCustomer,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              

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