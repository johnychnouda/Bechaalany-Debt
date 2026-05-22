import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../providers/app_state.dart';
import '../utils/responsive_layout.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;
  final bool embeddedInShell;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onDeleted;

  const AddCustomerScreen({
    super.key,
    this.customer,
    this.embeddedInShell = false,
    this.onCancel,
    this.onComplete,
    this.onDeleted,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _formSubmitted = false;
  String? _idBorderError;
  String? _nameBorderError;
  String? _phoneBorderError;
  String? _emailBorderError;
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
  void _finish({bool saved = false, bool deleted = false}) {
    if (!mounted) return;
    if (widget.embeddedInShell) {
      if (deleted) {
        widget.onDeleted?.call();
      } else if (saved) {
        widget.onComplete?.call();
      } else {
        widget.onCancel?.call();
      }
      return;
    }
    _navigateBack(saved ? true : null);
  }

  void _navigateBack([dynamic result]) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Navigator.of(context).pop(result);
          } catch (e) {
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
  void _updateIdBorderError() {
    if (widget.customer != null) {
      _idBorderError = null;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final value = _idController.text.trim();
    if (value.isEmpty) {
      _idBorderError = _formSubmitted ? l10n.pleaseEnterCustomerId : null;
    } else if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      _idBorderError = l10n.customerIdInvalidChars;
    } else if (_isDuplicateId(value)) {
      _idBorderError = l10n.thisCustomerIdAlreadyExists;
    } else {
      _idBorderError = null;
    }
  }

  void _updateNameBorderError() {
    final l10n = AppLocalizations.of(context)!;
    final value = _nameController.text.trim();
    _nameBorderError = value.isEmpty && _formSubmitted ? l10n.pleaseEnterCustomerName : null;
  }

  void _updatePhoneBorderError() {
    final l10n = AppLocalizations.of(context)!;
    final value = _fullPhoneController.text.trim();
    if (value.isEmpty) {
      _phoneBorderError = _formSubmitted ? l10n.pleaseEnterPhoneNumber : null;
    } else if (!_isValidPhoneNumber(value)) {
      _phoneBorderError = l10n.validPhoneNumber;
    } else if (_isDuplicatePhone(value)) {
      _phoneBorderError = l10n.thisPhoneNumberAlreadyExists;
    } else {
      _phoneBorderError = null;
    }
  }

  void _updateEmailBorderError() {
    final l10n = AppLocalizations.of(context)!;
    final value = _emailController.text.trim();
    if (value.isEmpty) {
      _emailBorderError = null;
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      _emailBorderError = l10n.pleaseEnterValidEmail;
    } else if (!_isValidEmailDomain(value)) {
      _emailBorderError = l10n.validEmailDomain;
    } else if (_isDuplicateEmail(value)) {
      _emailBorderError = l10n.thisEmailAlreadyUsed;
    } else {
      _emailBorderError = null;
    }
  }

  void _updateAllBorderErrors() {
    _updateIdBorderError();
    _updateNameBorderError();
    _updatePhoneBorderError();
    _updateEmailBorderError();
  }

  bool _isBlockingPhoneError(AppLocalizations l10n) =>
      _phoneBorderError == l10n.pleaseEnterPhoneNumber ||
      _phoneBorderError == l10n.validPhoneNumber;

  bool _isBlockingEmailError(AppLocalizations l10n) =>
      _emailBorderError == l10n.pleaseEnterValidEmail ||
      _emailBorderError == l10n.validEmailDomain;

  bool _validateForm() {
    setState(() {
      _formSubmitted = true;
      _updateAllBorderErrors();
    });
    final l10n = AppLocalizations.of(context)!;
    if (_idBorderError != null || _nameBorderError != null) {
      return false;
    }
    if (_phoneBorderError != null && _isBlockingPhoneError(l10n)) {
      return false;
    }
    if (_emailBorderError != null && _isBlockingEmailError(l10n)) {
      return false;
    }
    return true;
  }

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

  Future<void> _confirmDeleteCustomer() async {
    if (widget.customer == null) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final customer = widget.customer!;
    final debts =
        appState.debts.where((d) => d.customerId == customer.id).toList();
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.deleteCustomer,
          style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
        ),
        content: Text(
          debts.isNotEmpty
              ? l10n.deleteCustomerConfirmWithDebts(debts.length.toString())
              : l10n.deleteCustomerConfirm,
          style: TextStyle(color: AppColors.dynamicTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.dynamicPrimary(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await appState.deleteCustomer(customer.id);
      if (mounted) {
        _finish(deleted: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCustomer() async {
    if (!_validateForm()) {
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
          _finish(saved: true);
        }
      } else {
        await appState.addCustomer(customer);
        if (mounted) {
          _finish(saved: true);
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

  Widget _buildPhoneInput({
    required String label,
    required String placeholder,
    required String? borderError,
    required void Function(String) onChanged,
  }) {
    final hasBorderError = borderError != null && borderError.isNotEmpty;

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
        Padding(
          padding: EdgeInsets.only(top: hasBorderError ? 8 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextFormField(
                controller: _fullPhoneController,
                keyboardType: TextInputType.phone,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(
                    color: AppColors.dynamicTextSecondary(context),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.dynamicSurface(context),
                  border: _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  enabledBorder:
                      _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  focusedBorder: _fieldOutlineBorder(
                    context,
                    hasBorderError: hasBorderError,
                    focused: true,
                  ),
                  errorBorder:
                      _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  focusedErrorBorder: _fieldOutlineBorder(
                    context,
                    hasBorderError: hasBorderError,
                    focused: true,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                style: TextStyle(
                  color: AppColors.dynamicTextPrimary(context),
                  fontSize: 16,
                ),
              ),
              if (hasBorderError)
                Positioned(
                  left: 12,
                  top: 0,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: AppColors.dynamicSurface(context),
                      child: Text(
                        borderError!,
                        style: TextStyle(
                          color: AppColors.dynamicError(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.customer != null;

    final formContent = Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          widget.embeddedInShell ? 20 : 16,
          widget.embeddedInShell ? 12 : 16,
          widget.embeddedInShell ? 20 : 16,
          24,
        ),
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
                      borderError: _idBorderError,
                      onChanged: (_) {
                        setState(_updateIdBorderError);
                      },
                    ),
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
                borderError: _nameBorderError,
                onChanged: (_) {
                  setState(_updateNameBorderError);
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildPhoneInput(
                label: AppLocalizations.of(context)!.phoneNumber,
                placeholder: AppLocalizations.of(context)!.enterPhoneNumber,
                borderError: _phoneBorderError,
                onChanged: (_) {
                  setState(_updatePhoneBorderError);
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildModernField(
                label: AppLocalizations.of(context)!.emailAddress,
                controller: _emailController,
                placeholder: AppLocalizations.of(context)!.enterEmailOptional,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                borderError: _emailBorderError,
                onChanged: (_) {
                  setState(_updateEmailBorderError);
                },
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

              if (isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dynamicPrimary(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.updateCustomer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _confirmDeleteCustomer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text(
                      l10n.deleteCustomer,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dynamicPrimary(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.addCustomer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              
              const SizedBox(height: 16),
            ],
          ),
    );

    final body = widget.embeddedInShell
        ? formContent
        : (ResponsiveLayout.isDesktopWeb(context)
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: formContent,
                ),
              )
            : formContent);

    return Scaffold(
      backgroundColor: widget.embeddedInShell
          ? AppColors.dynamicSurface(context)
          : AppColors.dynamicBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embeddedInShell,
        leading: widget.embeddedInShell
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.dynamicPrimary(context),
                ),
                onPressed: () => _finish(),
              )
            : null,
        title: Text(
          isEditing ? l10n.editCustomer : l10n.addCustomer,
          style: TextStyle(
            fontSize: widget.embeddedInShell ? 18 : 17,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.dynamicSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.dynamicPrimary(context)),
      ),
      body: body,
    );
  }
  
  OutlineInputBorder _fieldOutlineBorder(
    BuildContext context, {
    required bool hasBorderError,
    bool focused = false,
  }) {
    final errorColor = AppColors.dynamicError(context);
    final normalColor = AppColors.dynamicBorder(context);
    final color = hasBorderError
        ? errorColor
        : (focused ? AppColors.dynamicPrimary(context) : normalColor);
    final width = hasBorderError || focused ? 2.0 : 1.0;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
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
    String? borderError,
    void Function(String)? onChanged,
  }) {
    final hasBorderError = borderError != null && borderError.isNotEmpty;

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
        Padding(
          padding: EdgeInsets.only(top: hasBorderError ? 8 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextFormField(
                controller: controller,
                enabled: enabled,
                textCapitalization: textCapitalization ?? TextCapitalization.none,
                keyboardType: keyboardType,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: AppColors.dynamicTextSecondary(context)),
                  prefixIcon: Icon(
                    icon,
                    color: hasBorderError
                        ? AppColors.dynamicError(context)
                        : AppColors.dynamicTextSecondary(context),
                  ),
                  filled: true,
                  fillColor: AppColors.dynamicSurface(context),
                  border: _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  enabledBorder:
                      _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  focusedBorder: _fieldOutlineBorder(
                    context,
                    hasBorderError: hasBorderError,
                    focused: true,
                  ),
                  errorBorder:
                      _fieldOutlineBorder(context, hasBorderError: hasBorderError),
                  focusedErrorBorder: _fieldOutlineBorder(
                    context,
                    hasBorderError: hasBorderError,
                    focused: true,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                style: TextStyle(color: AppColors.dynamicTextPrimary(context)),
              ),
              if (hasBorderError)
                Positioned(
                  left: 12,
                  top: 0,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: AppColors.dynamicSurface(context),
                      child: Text(
                        borderError!,
                        style: TextStyle(
                          color: AppColors.dynamicError(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 