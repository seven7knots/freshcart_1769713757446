// ============================================================
// FILE: lib/presentation/authentication_screen/widgets/login_form_widget.dart
// ============================================================
// UPDATED: After login → AuthGate (/) which checks phone & routes.
// Fixed hardcoded '/home-screen' route to use AuthGate flow.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';

class LoginFormWidget extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPasswordPressed;

  const LoginFormWidget({
    super.key,
    this.onLoginPressed,
    this.onForgotPasswordPressed,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _glassInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13.sp),
      prefixIcon: Padding(
        padding: EdgeInsets.all(3.w),
        child: Icon(prefixIcon, size: 5.w, color: Colors.white.withOpacity(0.5)),
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: TextStyle(color: Colors.redAccent.shade100, fontSize: 11.sp),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.redAccent.shade100),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailField(),
          SizedBox(height: 2.h),
          _buildPasswordField(),
          SizedBox(height: 1.h),
          _buildForgotPasswordLink(),
          SizedBox(height: 3.h),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.email, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp),
          cursorColor: Colors.white,
          onChanged: (value) => _validateEmail(value),
          decoration: _glassInputDecoration(
            hint: AppLocalizations.of(context)!.enterYourEmail,
            prefixIcon: Icons.email_outlined,
            errorText: _emailError,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.password, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp),
          cursorColor: Colors.white,
          onChanged: (value) => _validatePassword(value),
          decoration: _glassInputDecoration(
            hint: AppLocalizations.of(context)!.enterYourPassword,
            prefixIcon: Icons.lock_outlined,
            errorText: _passwordError,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                size: 5.w,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: widget.onForgotPasswordPressed ?? () => _showForgotPasswordBottomSheet(),
        child: Text(
          AppLocalizations.of(context)!.forgotPassword,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 12.sp,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildLoginButton() {
    final isValid = _isFormValid() && !_isLoading;
    return SizedBox(
      width: double.infinity,
      height: 6.5.h,
      child: ElevatedButton(
        onPressed: isValid ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppTheme.kjRed : Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          elevation: isValid ? 4 : 0,
          shadowColor: AppTheme.kjRed.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context)!.login,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
      ),
    );
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        _emailError = AppLocalizations.of(context)!.pleaseEnterAValidEmail;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  bool _isFormValid() {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _emailError == null &&
        _passwordError == null;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await authProvider.signIn(email, password);

    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.mediumImpact();
      // UPDATED: Use the callback which routes through AuthGate
      // instead of hardcoded '/home-screen'. AuthGate will check
      // if user has a phone number and route accordingly.
      widget.onLoginPressed?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? AppLocalizations.of(context)!.loginFailed, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _showForgotPasswordBottomSheet() {
    final emailController = TextEditingController();
    String? emailError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 10.w, height: 0.5.h,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(AppLocalizations.of(context)!.resetPassword, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                Text('Enter your email and we\'ll send you a verification code', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setModalState(() {
                      if (value.isEmpty) {
                        emailError = 'Email is required';
                      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        emailError = AppLocalizations.of(context)!.pleaseEnterAValidEmail;
                      } else {
                        emailError = null;
                      }
                    });
                  },
                  decoration: InputDecoration(hintText: AppLocalizations.of(context)!.enterYourEmail, prefixIcon: Icon(Icons.email_outlined), errorText: emailError),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: emailError == null && emailController.text.isNotEmpty
                        ? () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final success = await authProvider.resetPassword(emailController.text.trim());
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.resetPasswordVerify,
                                  arguments: emailController.text.trim(),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(authProvider.errorMessage ?? AppLocalizations.of(context)!.failed, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 2.h)),
                    child: Text('Send verification code', style: TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}