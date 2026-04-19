import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  const PhoneOtpVerificationScreen({super.key});

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  String _userPhone = '';

  // Demo mode — debug builds only, no env override in release
  bool get _isDemoMode => kDebugMode;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseService.client
            .from('users')
            .select('phone')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          setState(() {
            _userPhone = response['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('[PHONE_OTP] Error loading user phone: $e');
    }
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
    });

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

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseEnterTheComplete6Digit;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Demo mode: Accept fixed code 123456
      if (_isDemoMode && otp == '123456') {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client
              .from('users')
              .update({'phone_verified': true}).eq('id', user.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.demoModePhoneVerifiedSuccessfullyYou, maxLines: 1, overflow: TextOverflow.ellipsis),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          }
          return;
        }
      }

      // Production mode: Use Twilio verification
      final response = await SupabaseService.client.rpc(
        'verify_phone_otp',
        params: {'user_phone': _userPhone, 'otp_code': otp},
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.phoneVerifiedSuccessfullyYouCanNow, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? AppLocalizations.of(context)!.verificationFailed;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errorVerifyingCodePleaseTryAgain;
      });
      debugPrint('[PHONE_OTP] Verification error: $e');
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

    try {
      final response = await SupabaseService.client.rpc(
        'send_phone_otp',
        params: {'user_phone': _userPhone},
      );

      if (response['success'] == true) {
        final otp = response['otp'];

        const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
        final twilioResponse = await SupabaseService.client.functions.invoke(
          'send-phone-otp',
          body: {'phone': _userPhone, 'otp': otp},
        );

        if (twilioResponse.data['success'] == true) {
          _startCooldown();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.verificationCodeSentToYourPhone, maxLines: 1, overflow: TextOverflow.ellipsis),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.failedToSendSms;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? AppLocalizations.of(context)!.failedToSendCode;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errorSendingCodePleaseTryAgain;
      });
      debugPrint('[PHONE_OTP] Resend error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isDemoMode) _buildDemoModeBanner(),
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
    );
  }

  Widget _buildDemoModeBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.demoModeActive,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  AppLocalizations.of(context)!.useCode123456ToVerify,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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
            color: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_android,
            size: 10.w,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          AppLocalizations.of(context)!.verifyYourPhone,
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
          _userPhone,
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
      children: List.generate(6, (index) {
        return SizedBox(
          width: 12.w,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
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
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }

              if (index == 5 && value.isNotEmpty) {
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
                AppLocalizations.of(context)!.verifyPhone,
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