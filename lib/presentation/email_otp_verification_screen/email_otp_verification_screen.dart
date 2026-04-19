import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

// ============================================================
// SESSION 39 — COMPLETE REWRITE
//
// APPROACH: Uses Supabase signInWithOtp() + verifyOTP() flow.
// This is Supabase's ACTUAL OTP flow — the signup confirmation
// flow (Confirm email toggle) only supports magic links, not OTP
// input fields.
//
// PREREQUISITE: "Confirm email" must be OFF in Supabase Auth.
// The app uses its own email_verified column in the users table
// as the gate instead.
//
// FLOW:
// 1. Screen loads → sends OTP via signInWithOtp(email)
// 2. User enters 6-digit code from email
// 3. verifyOTP() confirms the code
// 4. App updates users.email_verified = true
// 5. Navigate to home via AuthGate
// ============================================================
class EmailOtpVerificationScreen extends StatefulWidget {
  const EmailOtpVerificationScreen({super.key});

  @override
  State<EmailOtpVerificationScreen> createState() =>
      _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState
    extends State<EmailOtpVerificationScreen> {
  static const int _otpLength = 8;

  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  bool _isSendingInitial = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  String _userEmail = '';
  bool _emailInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_emailInitialized) {
      _emailInitialized = true;
      _initializeEmail();
    }
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Resolve the target email for verification. Priority:
  ///   1) Route argument {'email': '...'} passed by signup flow
  ///   2) currentUser.email (authenticated-but-unverified users)
  /// The signup confirmation email with the 8-digit token was already
  /// dispatched by auth.signUp() when "Confirm email" is ON, so we
  /// do NOT auto-send again on screen load.
  Future<void> _initializeEmail() async {
    try {
      String? email;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['email'] is String) {
        email = (args['email'] as String).trim();
      }
      email ??= SupabaseService.client.auth.currentUser?.email;

      if (email == null || email.isEmpty) {
        setState(() {
          _isSendingInitial = false;
          _errorMessage =
              'Could not determine your email. Please go back and sign up again.';
        });
        return;
      }

      setState(() {
        _userEmail = email!;
        _isSendingInitial = false;
      });
      _startCooldown();
      debugPrint('[EMAIL_OTP] Initialized for email: $_userEmail');
    } catch (e) {
      debugPrint('[EMAIL_OTP] _initializeEmail error: $e');
      setState(() {
        _isSendingInitial = false;
        _errorMessage = 'Error loading account info. Please go back.';
      });
    }
  }

  /// Resend the signup confirmation OTP. Uses auth.resend(type: signup),
  /// the correct Supabase API when "Confirm email" is ON.
  Future<void> _sendOtp({bool isInitial = false}) async {
    if (_userEmail.isEmpty) {
      setState(() {
        _errorMessage =
            'No email on file. Please go back and sign up again.';
      });
      return;
    }
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: _userEmail,
      );

      debugPrint('[EMAIL_OTP] Resent signup OTP to $_userEmail');

      if (mounted) {
        _startCooldown();
        if (!isInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.verificationCodeSentToYourEmail, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('[EMAIL_OTP] Send OTP AuthException: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      debugPrint('[EMAIL_OTP] Send OTP error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorSendingVerificationCodePleaseTry;
        });
      }
    } finally {
      if (mounted && isInitial) {
        setState(() {
          _isSendingInitial = false;
        });
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
    }
  }

  Future<void> _onVerificationSuccess() async {
    // Mark email_verified in our users table
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('users')
            .update({'email_verified': true}).eq('id', user.id);
        debugPrint('[EMAIL_OTP] email_verified set to true in users table');
      }
    } catch (e) {
      debugPrint('[EMAIL_OTP] Failed to update email_verified (non-fatal): $e');
    }

    // Refresh auth state
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserRole(force: true);
    } catch (e) {
      debugPrint('[EMAIL_OTP] AuthProvider reload error (non-fatal): $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  /// Verify the OTP code using Supabase verifyOTP with type: email.
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != _otpLength) {
      setState(() {
        _errorMessage = 'Please enter the complete $_otpLength-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService.client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: _userEmail,
      );

      debugPrint('[EMAIL_OTP] verifyOTP response: session=${response.session != null}, user=${response.user?.email}');

      if (response.session != null || response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.emailVerifiedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
          await _onVerificationSuccess();
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.verificationFailedPleaseCheckTheCode;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      debugPrint('[EMAIL_OTP] verifyOTP AuthException: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errorVerifyingCodePleaseTryAgain;
      });
      debugPrint('[EMAIL_OTP] verifyOTP error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    await _sendOtp(isInitial: false);

    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
        ),
        body: SafeArea(
          child: _isSendingInitial
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        AppLocalizations.of(context)!.sendingVerificationCode,
                        style: Theme.of(context).textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 4.h),
                      _buildOtpInput(),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 2.h),
                        _buildErrorMessage(),
                      ],
                      SizedBox(height: 4.h),
                      _buildVerifyButton(),
                      SizedBox(height: 3.h),
                      _buildResendSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.email_outlined,
            size: 10.w,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          AppLocalizations.of(context)!.verifyYourEmail,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Text(
          AppLocalizations.of(context)!.enterTheVerificationCodeSentTo,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 0.5.h),
        Text(
          _userEmail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 10.w,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < _otpLength - 1) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              if (index == _otpLength - 1 && value.isNotEmpty) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 3.h,
                width: 3.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.verifyEmail,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.didNotReceiveTheCode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        TextButton(
          onPressed: _resendCooldown > 0 || _isResending ? null : _resendOtp,
          child: _isResending
              ? SizedBox(
                  height: 2.h,
                  width: 2.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : AppLocalizations.of(context)!.resendCode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _resendCooldown > 0
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}