import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';

class SignupFormWidget extends StatefulWidget {
  final VoidCallback? onSignupPressed;

  const SignupFormWidget({super.key, this.onSignupPressed});

  @override
  State<SignupFormWidget> createState() => _SignupFormWidgetState();
}

class _SignupFormWidgetState extends State<SignupFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String _selectedCountryCode = '+961';
  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+961', 'country': 'LB', 'name': 'Lebanon'},
    {'code': '+1', 'country': 'US', 'name': 'United States'},
    {'code': '+44', 'country': 'UK', 'name': 'United Kingdom'},
    {'code': '+91', 'country': 'IN', 'name': 'India'},
    {'code': '+86', 'country': 'CN', 'name': 'China'},
    {'code': '+81', 'country': 'JP', 'name': 'Japan'},
    {'code': '+971', 'country': 'AE', 'name': 'UAE'},
    {'code': '+966', 'country': 'SA', 'name': 'Saudi Arabia'},
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[SIGNUP] 🔧 SignupFormWidget initialized');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFullNameField(),
          SizedBox(height: 2.h),
          _buildEmailField(),
          SizedBox(height: 2.h),
          _buildPhoneField(),
          SizedBox(height: 2.h),
          _buildPasswordField(),
          SizedBox(height: 2.h),
          _buildTermsCheckbox(),
          SizedBox(height: 4.h),
          _buildSignupButton(),
        ],
      ),
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _fullNameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) => _validateFullName(value),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3B3B3),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'person',
                size: 5.w,
                color: const Color(0xFFB3B3B3),
              ),
            ),
            errorText: _fullNameError,
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) => _validateEmail(value),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3B3B3),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'email',
                size: 5.w,
                color: const Color(0xFFB3B3B3),
              ),
            ),
            errorText: _emailError,
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Container(
              width: 28.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCountryCode,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 2.h,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                dropdownColor: AppTheme.lightTheme.colorScheme.surface,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
                items: _countryCodes.map((country) {
                  return DropdownMenuItem<String>(
                    value: country['code'],
                    child: Text(
                      '${country['code']} ${country['country']}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value!;
                    debugPrint(
                      '[SIGNUP] 📱 Country code changed to: $_selectedCountryCode',
                    );
                  });
                },
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                onChanged: (value) => _validatePhone(value),
                decoration: InputDecoration(
                  hintText: _selectedCountryCode == '+961'
                      ? '71234567'
                      : 'Phone number',
                  hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB3B3B3),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      size: 5.w,
                      color: const Color(0xFFB3B3B3),
                    ),
                  ),
                  errorText: _phoneError,
                  filled: true,
                  fillColor: AppTheme.lightTheme.colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) {
            debugPrint(
              '[SIGNUP] 🔐 Password input changed (length: ${value.length})',
            );
            _validatePassword(value);
          },
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3B3B3),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                size: 5.w,
                color: const Color(0xFFB3B3B3),
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
                debugPrint(
                  '[SIGNUP] 👁️ Password visibility toggled: $_isPasswordVisible',
                );
              },
              icon: CustomIconWidget(
                iconName: _isPasswordVisible ? 'visibility' : 'visibility_off',
                size: 5.w,
                color: const Color(0xFFB3B3B3),
              ),
            ),
            errorText: _passwordError,
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 1.5.h),
              child: RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid() && !_isLoading ? _handleSignup : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          backgroundColor: _isFormValid() && !_isLoading
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? SizedBox(
                height: 5.w,
                width: 5.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'Create Account',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _validateFullName(String value) {
    setState(() {
      if (value.isEmpty) {
        _fullNameError = 'Full name is required';
      } else if (value.trim().split(' ').length < 2) {
        _fullNameError = 'Please enter your full name';
      } else {
        _fullNameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      if (value.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (_selectedCountryCode == '+961' && value.length < 7) {
        _phoneError = 'Lebanon phone must be at least 7 digits';
      } else if (_selectedCountryCode != '+961' && value.length < 10) {
        _phoneError = 'Please enter a valid phone number';
      } else {
        _phoneError = null;
      }
      debugPrint(
        '[SIGNUP] 📱 Phone validation: code=$_selectedCountryCode number=$value error=$_phoneError',
      );
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (value.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
        _passwordError =
            'Password must contain uppercase, lowercase and number';
      } else {
        _passwordError = null;
      }
    });
  }

  bool _isFormValid() {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _acceptTerms &&
        _fullNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _emailError = 'Please accept the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _fullNameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fullPhone = '$_selectedCountryCode${_phoneController.text}';

    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: fullPhone,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      debugPrint('[SIGNUP] ✅ Signup successful');
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created! Please verify your email and phone.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        widget.onSignupPressed?.call();
      }
    } else {
      debugPrint('[SIGNUP] ❌ Signup failed');
      HapticFeedback.heavyImpact();

      final error = authProvider.errorMessage ?? 'Signup failed';

      if (error.toLowerCase().contains('email')) {
        setState(() {
          _emailError = error;
        });
      } else if (error.toLowerCase().contains('password')) {
        setState(() {
          _passwordError = error;
        });
      } else {
        setState(() {
          _emailError = error;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
