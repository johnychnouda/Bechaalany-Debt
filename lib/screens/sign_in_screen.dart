import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/logo_utils.dart';
import '../widgets/email_verification_modal.dart';
import 'main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;
  bool _isPhoneAuth = false;
  bool _obscurePassword = true;
  String _countryCode = '+961'; // Default to Lebanon
  String _selectedCountry = 'Lebanon';
  String _selectedFlag = '🇱🇧';
  String _phoneValidationMessage = '';
  
  // Common countries for dropdown
  final List<Map<String, String>> _countries = [
    {'name': 'Lebanon', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'China', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Russia', 'code': '+7', 'flag': '🇷🇺'},
    {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'Egypt', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'Jordan', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'Syria', 'code': '+963', 'flag': '🇸🇾'},
  ];

  // Phone format validation for different countries
  Map<String, Map<String, dynamic>> _phoneFormats = {
    '+961': { // Lebanon
      'pattern': r'^[0-9]{8}$',
      'example': '70123456',
      'description': '8 digits (e.g., 70123456)',
    },
    '+1': { // US/Canada
      'pattern': r'^[0-9]{10}$',
      'example': '5551234567',
      'description': '10 digits (e.g., 5551234567)',
    },
    '+44': { // UK
      'pattern': r'^[0-9]{10,11}$',
      'example': '7700123456',
      'description': '10-11 digits (e.g., 7700123456)',
    },
    '+33': { // France
      'pattern': r'^[0-9]{9}$',
      'example': '123456789',
      'description': '9 digits (e.g., 123456789)',
    },
    '+49': { // Germany
      'pattern': r'^[0-9]{10,11}$',
      'example': '15123456789',
      'description': '10-11 digits (e.g., 15123456789)',
    },
    '+39': { // Italy
      'pattern': r'^[0-9]{10}$',
      'example': '3123456789',
      'description': '10 digits (e.g., 3123456789)',
    },
    '+34': { // Spain
      'pattern': r'^[0-9]{9}$',
      'example': '612345678',
      'description': '9 digits (e.g., 612345678)',
    },
    '+61': { // Australia
      'pattern': r'^[0-9]{9}$',
      'example': '412345678',
      'description': '9 digits (e.g., 412345678)',
    },
    '+81': { // Japan
      'pattern': r'^[0-9]{10,11}$',
      'example': '9012345678',
      'description': '10-11 digits (e.g., 9012345678)',
    },
    '+86': { // China
      'pattern': r'^[0-9]{11}$',
      'example': '13812345678',
      'description': '11 digits (e.g., 13812345678)',
    },
    '+91': { // India
      'pattern': r'^[0-9]{10}$',
      'example': '9876543210',
      'description': '10 digits (e.g., 9876543210)',
    },
    '+55': { // Brazil
      'pattern': r'^[0-9]{10,11}$',
      'example': '11987654321',
      'description': '10-11 digits (e.g., 11987654321)',
    },
    '+7': { // Russia
      'pattern': r'^[0-9]{10}$',
      'example': '9123456789',
      'description': '10 digits (e.g., 9123456789)',
    },
    '+90': { // Turkey
      'pattern': r'^[0-9]{10}$',
      'example': '5321234567',
      'description': '10 digits (e.g., 5321234567)',
    },
    '+20': { // Egypt
      'pattern': r'^[0-9]{10}$',
      'example': '1012345678',
      'description': '10 digits (e.g., 1012345678)',
    },
    '+966': { // Saudi Arabia
      'pattern': r'^[0-9]{9}$',
      'example': '501234567',
      'description': '9 digits (e.g., 501234567)',
    },
    '+971': { // UAE
      'pattern': r'^[0-9]{9}$',
      'example': '501234567',
      'description': '9 digits (e.g., 501234567)',
    },
    '+962': { // Jordan
      'pattern': r'^[0-9]{9}$',
      'example': '791234567',
      'description': '9 digits (e.g., 791234567)',
    },
    '+963': { // Syria
      'pattern': r'^[0-9]{9}$',
      'example': '941234567',
      'description': '9 digits (e.g., 941234567)',
    },
  };
  
  late TabController _tabController;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update segmented control
    });
    _checkAuthState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _checkAuthState() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null && mounted) {
        _navigateToMainScreen();
      }
    });
  }

  // Authentication methods will be added in the next part
  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAccountWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Show verification modal after successful account creation
      if (mounted) {
        _showEmailVerificationModal();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show email verification modal
  void _showEmailVerificationModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => EmailVerificationModal(
        onVerified: () {
          // Navigate to main screen when verified
          Navigator.of(context).pop(); // Close modal
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (context) => const MainScreen()),
          );
        },
        onDismiss: () {
          // Navigate to main screen even if user dismisses
          Navigator.of(context).pop(); // Close modal
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (context) => const MainScreen()),
          );
        },
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        _showPasswordResetSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show password reset success dialog with better instructions
  void _showPasswordResetSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            const Text('Check Your Email'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ve sent a password reset link to:',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emailController.text.trim(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your inbox and follow the instructions to reset your password.',
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Didn\'t receive the email? Check your spam folder or try again.',
              style: TextStyle(
                color: AppColors.dynamicTextSecondary(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPhoneVerification() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: '$_countryCode${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = e.message ?? 'Phone verification failed.';
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isPhoneAuth = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhoneCode() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code.';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'No verification ID found. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _verificationCodeController.text.trim(),
      );
      await _signInWithPhoneCredential(credential);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await _authService.signInWithPhoneCredential(credential);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  // Real-time phone number validation
  void _validatePhoneFormat(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneValidationMessage = '';
      });
      return;
    }

    final format = _phoneFormats[_countryCode];
    if (format == null) {
      setState(() {
        _phoneValidationMessage = 'Unknown country format';
      });
      return;
    }

    final pattern = RegExp(format['pattern']);
    final isValid = pattern.hasMatch(phoneNumber);
    
    if (isValid) {
      setState(() {
        _phoneValidationMessage = '✓ Valid format';
      });
    } else {
      setState(() {
        _phoneValidationMessage = 'Format: ${format['description']}';
      });
    }
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Country',
                  style: AppTheme.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextPrimary(context),
                  ),
                ),
              ),
              // Countries list
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final isSelected = country['name'] == _selectedCountry;
                    
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        country['name']!,
                        style: AppTheme.callout.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        country['code']!,
                        style: AppTheme.callout.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.dynamicTextSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country['name']!;
                          _countryCode = country['code']!;
                          _selectedFlag = country['flag']!;
                        });
                        // Re-validate phone number with new country format
                        _validatePhoneFormat(_phoneController.text);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the verification code';
    }
    if (value.length < 6) {
      return 'Please enter the complete verification code';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;
    final isLargeScreen = MediaQuery.of(context).size.width > 450;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF),
              const Color(0xFFF8F9FA),
              const Color(0xFFF2F2F7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing24,
              vertical: AppTheme.spacing16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Design
                LogoUtils.buildLogo(
                  context: context,
                  width: isSmallScreen ? 120 : isLargeScreen ? 160 : 140,
                  height: isSmallScreen ? 120 : isLargeScreen ? 160 : 140,
                  placeholder: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: isSmallScreen ? 50 : isLargeScreen ? 70 : 60,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing16 : AppTheme.spacing20),
                
                // App Title with Elegant Styling
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bechaalany ',
                        style: AppTheme.title1.copyWith(
                          color: Colors.black,
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Connect',
                        style: AppTheme.title1.copyWith(
                          color: const Color(0xFFFF3B30),
                          fontSize: isSmallScreen ? 28 : isLargeScreen ? 32 : 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacing16),
                
                // Subtitle with Elegant Styling
                Text(
                  'Sign in to manage your debt records',
                  style: AppTheme.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing16 : AppTheme.spacing20),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.callout.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) SizedBox(height: AppTheme.spacing24),
                
                // Modern iOS 18.6 Segmented Control
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Option B: Gradient Pills (Selected)
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: Row(
                          children: [
                            // Email/Password Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(0);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
                                    horizontal: isSmallScreen ? 8 : isLargeScreen ? 24 : 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _tabController.index == 0 
                                        ? LinearGradient(
                                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: _tabController.index == 0 
                                        ? null 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 20 : isLargeScreen ? 30 : 25),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: isSmallScreen ? 1.0 : 1.5,
                                    ),
                                    boxShadow: _tabController.index == 0 
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: isSmallScreen ? 6 : 8,
                                              offset: Offset(0, isSmallScreen ? 2 : 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.mail,
                                        size: isSmallScreen ? 14 : isLargeScreen ? 20 : 18,
                                        color: _tabController.index == 0 
                                            ? Colors.white 
                                            : AppColors.primary,
                                      ),
                                      SizedBox(width: isSmallScreen ? 4 : isLargeScreen ? 10 : 8),
                                      Text(
                                        'Email',
                                        style: AppTheme.headline.copyWith(
                                          color: _tabController.index == 0 
                                              ? Colors.white 
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 12 : isLargeScreen ? 18 : 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 6 : isLargeScreen ? 16 : 12),
                            // Phone Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(1);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
                                    horizontal: isSmallScreen ? 8 : isLargeScreen ? 24 : 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _tabController.index == 1 
                                        ? LinearGradient(
                                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: _tabController.index == 1 
                                        ? null 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 20 : isLargeScreen ? 30 : 25),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: isSmallScreen ? 1.0 : 1.5,
                                    ),
                                    boxShadow: _tabController.index == 1 
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: isSmallScreen ? 6 : 8,
                                              offset: Offset(0, isSmallScreen ? 2 : 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.phone,
                                        size: isSmallScreen ? 14 : isLargeScreen ? 20 : 18,
                                        color: _tabController.index == 1 
                                            ? Colors.white 
                                            : AppColors.primary,
                                      ),
                                      SizedBox(width: isSmallScreen ? 4 : isLargeScreen ? 10 : 8),
                                      Text(
                                        'Phone',
                                        style: AppTheme.headline.copyWith(
                                          color: _tabController.index == 1 
                                              ? Colors.white 
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 12 : isLargeScreen ? 18 : 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Content with Divider
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFFE5E5EA),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing24),
                        child: _tabController.index == 0 
                            ? _buildEmailPasswordForm(isSmallScreen, isLargeScreen)
                            : _buildPhoneForm(isSmallScreen, isLargeScreen),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? AppTheme.spacing8 : AppTheme.spacing16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Form widgets will be added in the next part
  Widget _buildEmailPasswordForm(bool isSmallScreen, bool isLargeScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          // Forgot Password - iOS 18.6 Native Style
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              onPressed: _sendPasswordResetEmail,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 8 : isLargeScreen ? 12 : 10,
                horizontal: isSmallScreen ? 8 : isLargeScreen ? 12 : 10,
              ),
              child: Text(
                'Forgot Password?',
                style: AppTheme.callout.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : isLargeScreen ? 18 : 16,
                ),
              ),
            ),
          ),
          
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Sign In Button - iOS 18.6 Native Style
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _signInWithEmailAndPassword,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
              horizontal: isSmallScreen ? 16 : isLargeScreen ? 28 : 24,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : isLargeScreen ? 14 : 12),
            child: _isLoading
                ? CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: isSmallScreen ? 8 : isLargeScreen ? 12 : 10,
                  )
                : Text(
                    'Sign In',
                    style: AppTheme.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : isLargeScreen ? 19 : 17,
                    ),
                  ),
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Option 4: Simple Text Link Approach
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Don\'t have an account? ',
                style: AppTheme.callout.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              CupertinoButton(
                onPressed: _isLoading ? null : _createAccountWithEmailAndPassword,
                padding: EdgeInsets.zero,
                child: Text(
                  'Sign up here',
                  style: AppTheme.callout.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(bool isSmallScreen, bool isLargeScreen) {
    if (_isPhoneAuth) {
      return _buildVerificationForm(isSmallScreen, isLargeScreen);
    }
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone Field with Integrated Country Code Selector
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: _validatePhone,
            onChanged: _validatePhoneFormat,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: GestureDetector(
                onTap: () => _showCountryPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFlag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _countryCode,
                        style: AppTheme.callout.copyWith(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.dynamicTextSecondary(context),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          
          // Real-time validation message
          if (_phoneValidationMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _phoneValidationMessage.startsWith('✓') 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _phoneValidationMessage.startsWith('✓')
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _phoneValidationMessage.startsWith('✓')
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: _phoneValidationMessage.startsWith('✓')
                        ? AppColors.success
                        : AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _phoneValidationMessage,
                      style: AppTheme.callout.copyWith(
                        color: _phoneValidationMessage.startsWith('✓')
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Info Text
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'We\'ll send you a verification code via SMS to $_countryCode',
                    style: AppTheme.callout.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Send Code Button - iOS 18.6 Native Style
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _sendPhoneVerification,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
              horizontal: isSmallScreen ? 16 : isLargeScreen ? 28 : 24,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : isLargeScreen ? 14 : 12),
            child: _isLoading
                ? CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: isSmallScreen ? 8 : isLargeScreen ? 12 : 10,
                  )
                : Text(
                    'Send Verification Code',
                    style: AppTheme.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : isLargeScreen ? 19 : 17,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(bool isSmallScreen, bool isLargeScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verification Code Field
          TextFormField(
            controller: _verificationCodeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: _validateVerificationCode,
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter the 6-digit code',
              prefixIcon: const Icon(Icons.security_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Info Text
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Code sent to $_countryCode${_phoneController.text}',
                    style: AppTheme.callout.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Verify Button - iOS 18.6 Native Style
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _verifyPhoneCode,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
              horizontal: isSmallScreen ? 16 : isLargeScreen ? 28 : 24,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : isLargeScreen ? 14 : 12),
            child: _isLoading
                ? CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: isSmallScreen ? 8 : isLargeScreen ? 12 : 10,
                  )
                : Text(
                    'Verify Code',
                    style: AppTheme.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : isLargeScreen ? 19 : 17,
                    ),
                  ),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Back Button - iOS 18.6 Native Style
          CupertinoButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _isPhoneAuth = false;
                _verificationCodeController.clear();
                _verificationId = null;
                _resendToken = null;
              });
            },
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
              horizontal: isSmallScreen ? 16 : isLargeScreen ? 28 : 24,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : isLargeScreen ? 14 : 12),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.textSecondary,
                  width: isSmallScreen ? 1.0 : 1.5,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : isLargeScreen ? 14 : 12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : isLargeScreen ? 20 : 16, 
                horizontal: isSmallScreen ? 16 : isLargeScreen ? 28 : 24,
              ),
              child: Text(
                'Back to Phone Number',
                style: AppTheme.headline.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : isLargeScreen ? 19 : 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
