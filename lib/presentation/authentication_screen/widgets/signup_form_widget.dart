// ============================================================
// FILE: lib/presentation/authentication_screen/widgets/signup_form_widget.dart
// ============================================================
// UPDATED: After signup → callback routes through AuthGate.
// No OTP redirect. Snackbar says "Account created!" instead
// of "Please verify your email".
//
// SESSION 27 FIX:
// - Professional phone input with flag emojis + bottom sheet picker
// - Strips leading zeros before prepending country code
//   (e.g. user types 03167967 → saved as +9613167967)
// SESSION 28 FIX:
// - Country picker bottom sheet overflow fixed (same pattern as phone_collection_screen)
//   isScrollControlled: true + ConstrainedBox(maxHeight: 60% screen) + ListView
// SESSION 29 FIX:
// - After successful signup, navigate to emailOtpVerification screen
//   instead of calling onSignupPressed (which bypassed email verification).
//   Email must be verified before the user can access the app.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';

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
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.redAccent.shade100)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5)),
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
          Text(AppLocalizations.of(context)!.fullName, style: _labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validateFullName,
            decoration: _glassInput(hint: AppLocalizations.of(context)!.enterYourFullName, icon: Icons.person_outline, error: _fullNameError),
          ),
          SizedBox(height: 2.h),

          // Email
          Text(AppLocalizations.of(context)!.email, style: _labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validateEmail,
            decoration: _glassInput(hint: AppLocalizations.of(context)!.enterYourEmail, icon: Icons.email_outlined, error: _emailError),
          ),
          SizedBox(height: 2.h),

          // Password
          Text(AppLocalizations.of(context)!.password, style: _labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: _inputStyle,
            cursorColor: Colors.white,
            onChanged: _validatePassword,
            decoration: _glassInput(
              hint: AppLocalizations.of(context)!.enterYourPassword,
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
                          TextSpan(text: AppLocalizations.of(context)!.iAgreeToThe),
                          TextSpan(text: AppLocalizations.of(context)!.termsOfService, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          TextSpan(text: AppLocalizations.of(context)!.andText),
                          TextSpan(text: AppLocalizations.of(context)!.privacyPolicy, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  : Text(AppLocalizations.of(context)!.createAccount, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      } else if (v.trim().split(' ').length < 2) {
        _fullNameError = 'Please enter your full name';
      } else {
        _fullNameError = null;
      }
    });
  }

  void _validateEmail(String v) {
    setState(() {
      if (v.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
        _emailError = AppLocalizations.of(context)!.pleaseEnterAValidEmail;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _passwordError = 'Password is required';
      } else if (v.length < 8) {
        _passwordError = 'At least 8 characters';
      } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
        _passwordError = 'Need uppercase, lowercase & number';
      } else {
        _passwordError = null;
      }
    });
  }

  bool _isFormValid() {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _acceptTerms &&
        _fullNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _emailError = 'Please accept terms');
      return;
    }

    setState(() {
      _isLoading = true;
      _fullNameError = null;
      _emailError = null;
      _passwordError = null;
    });
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.accountCreatedPleaseVerifyYourEmail, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        // SESSION 29 FIX: Route to email OTP verification instead of
        // directly to home. User must verify email before accessing the app.
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.emailOtpVerification,
          arguments: {'email': _emailController.text.trim()},
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      final error = authProvider.errorMessage ?? 'Signup failed';
      if (error.toLowerCase().contains('email')) {
        setState(() => _emailError = error);
      } else if (error.toLowerCase().contains('password')) {
        setState(() => _passwordError = error);
      } else {
        setState(() => _emailError = error);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}