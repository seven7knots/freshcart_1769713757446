// ============================================================
// FILE: lib/presentation/authentication_screen/widgets/signup_form_widget.dart
// ============================================================
// UPDATED: White text on glass background, matching login style.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _glassInput({required String hint, required IconData icon, Widget? suffix, String? error}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13.sp),
      prefixIcon: Padding(padding: EdgeInsets.all(3.w), child: Icon(icon, size: 5.w, color: Colors.white.withOpacity(0.5))),
      suffixIcon: suffix,
      errorText: error,
      errorStyle: TextStyle(color: Colors.redAccent.shade100, fontSize: 11.sp),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent.shade100)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5)),
    );
  }

  TextStyle get _labelStyle => TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.sp);
  TextStyle get _inputStyle => TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          Text('Full Name', style: _labelStyle),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validateFullName,
            decoration: _glassInput(hint: 'Enter your full name', icon: Icons.person_outline, error: _fullNameError),
          ),
          SizedBox(height: 2.h),

          // Email
          Text('Email', style: _labelStyle),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validateEmail,
            decoration: _glassInput(hint: 'Enter your email', icon: Icons.email_outlined, error: _emailError),
          ),
          SizedBox(height: 2.h),

          // Phone
          Text('Phone Number', style: _labelStyle),
          SizedBox(height: 1.h),
          Row(
            children: [
              // Country code dropdown
              Container(
                width: 28.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountryCode,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13.sp),
                  iconEnabledColor: Colors.white.withOpacity(0.5),
                  items: _countryCodes.map((c) => DropdownMenuItem<String>(
                    value: c['code'],
                    child: Text('${c['code']} ${c['country']}', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCountryCode = v!),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  cursorColor: Colors.white,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                  onChanged: _validatePhone,
                  decoration: _glassInput(
                    hint: _selectedCountryCode == '+961' ? '71234567' : 'Phone number',
                    icon: Icons.phone_outlined,
                    error: _phoneError,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Password
          Text('Password', style: _labelStyle),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validatePassword,
            decoration: _glassInput(
              hint: 'Enter your password',
              icon: Icons.lock_outlined,
              error: _passwordError,
              suffix: IconButton(
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 5.w, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Terms
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                checkColor: Colors.white,
                activeColor: AppTheme.kjRed,
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Padding(
                    padding: EdgeInsets.only(top: 1.5.h),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.sp),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(text: 'Terms of Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Sign Up button
          SizedBox(
            width: double.infinity,
            height: 6.5.h,
            child: ElevatedButton(
              onPressed: _isFormValid() && !_isLoading ? _handleSignup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid() && !_isLoading ? AppTheme.kjRed : Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                elevation: _isFormValid() ? 4 : 0,
                shadowColor: AppTheme.kjRed.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Create Account', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _validateFullName(String v) {
    setState(() {
      if (v.isEmpty) {
        _fullNameError = 'Full name is required';
      } else if (v.trim().split(' ').length < 2) _fullNameError = 'Please enter your full name';
      else _fullNameError = null;
    });
  }

  void _validateEmail(String v) {
    setState(() {
      if (v.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) _emailError = 'Please enter a valid email';
      else _emailError = null;
    });
  }

  void _validatePhone(String v) {
    setState(() {
      if (v.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (_selectedCountryCode == '+961' && v.length < 7) _phoneError = 'At least 7 digits for Lebanon';
      else if (_selectedCountryCode != '+961' && v.length < 10) _phoneError = 'Please enter a valid number';
      else _phoneError = null;
    });
  }

  void _validatePassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _passwordError = 'Password is required';
      } else if (v.length < 8) _passwordError = 'At least 8 characters';
      else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) _passwordError = 'Need uppercase, lowercase & number';
      else _passwordError = null;
    });
  }

  bool _isFormValid() {
    return _fullNameController.text.isNotEmpty && _emailController.text.isNotEmpty && _phoneController.text.isNotEmpty && _passwordController.text.isNotEmpty && _acceptTerms && _fullNameError == null && _emailError == null && _phoneError == null && _passwordError == null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) { setState(() => _emailError = 'Please accept terms'); return; }

    setState(() { _isLoading = true; _fullNameError = null; _emailError = null; _phoneError = null; _passwordError = null; });
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fullPhone = '$_selectedCountryCode${_phoneController.text}';

    final success = await authProvider.signUp(_emailController.text.trim(), _passwordController.text, fullName: _fullNameController.text.trim(), phone: fullPhone);

    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please verify your email.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        widget.onSignupPressed?.call();
      }
    } else {
      HapticFeedback.heavyImpact();
      final error = authProvider.errorMessage ?? 'Signup failed';
      if (error.toLowerCase().contains('email')) {
        setState(() => _emailError = error);
      } else if (error.toLowerCase().contains('password')) setState(() => _passwordError = error);
      else setState(() => _emailError = error);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }
}