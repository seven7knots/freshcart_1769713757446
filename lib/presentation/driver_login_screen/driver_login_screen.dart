import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = '+961${_phoneController.text.trim()}';

      await SupabaseService.client.auth.signInWithOtp(
        phone: phone,
      );

      setState(() {
        _otpSent = true;
        _isLoading = false;
        _resendCountdown = 60;
      });

      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your phone'),
            backgroundColor: AppTheme.primaryLight,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = '+961${_phoneController.text.trim()}';
      final otp = _otpController.text.trim();

      await SupabaseService.client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final userData = await SupabaseService.client
            .from('users')
            .select('role')
            .eq('id', userId)
            .single();

        if (userData['role'] != 'driver') {
          await SupabaseService.client.auth.signOut();
          setState(() {
            _errorMessage = 'This account is not registered as a driver';
            _isLoading = false;
          });
          return;
        }

        final driverData = await SupabaseService.client
            .from('drivers')
            .select('is_verified, is_active')
            .eq('user_id', userId)
            .single();

        if (!driverData['is_verified']) {
          await SupabaseService.client.auth.signOut();
          setState(() {
            _errorMessage = 'Your driver account is pending verification';
            _isLoading = false;
          });
          return;
        }

        if (!driverData['is_active']) {
          await SupabaseService.client.auth.signOut();
          setState(() {
            _errorMessage = 'Your driver account has been deactivated';
            _isLoading = false;
          });
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.driverHome);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Driver Login'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.authentication);
            },
            child: Text(
              'Customer App',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4.h),
                Icon(
                  Icons.local_shipping,
                  size: 20.w,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(height: 3.h),
                Text(
                  'Welcome Back, Driver',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Login to start accepting deliveries',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF616161),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                _buildPhoneField(),
                if (_otpSent) ...[
                  SizedBox(height: 3.h),
                  _buildOTPField(),
                  SizedBox(height: 2.h),
                  _buildResendButton(),
                ],
                if (_errorMessage != null) ...[
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppTheme.errorLight,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                _buildActionButton(),
                SizedBox(height: 3.h),
                _buildSupportSection(),
              ],
            ),
          ),
        ),
      ),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: !_otpSent,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: InputDecoration(
            hintText: '71234567',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
              child: Text(
                '+961',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length != 8) {
              return 'Phone number must be 8 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOTPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            hintText: '000000',
          ),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildResendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive OTP? ",
          style: TextStyle(
            color: const Color(0xFF616161),
            fontSize: 12.sp,
          ),
        ),
        TextButton(
          onPressed: _resendCountdown == 0 ? _sendOTP : null,
          child: Text(
            _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend',
            style: TextStyle(
              color: _resendCountdown > 0
                  ? const Color(0xFF616161)
                  : AppTheme.primaryLight,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        backgroundColor: AppTheme.primaryLight,
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.surfaceLight),
              ),
            )
          : Text(
              _otpSent ? 'Verify & Login' : 'Send OTP',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            color: const Color(0xFF616161),
            size: 8.w,
          ),
          SizedBox(height: 1.h),
          Text(
            'Need Help?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Contact Driver Support',
            style: TextStyle(
              color: const Color(0xFF616161),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: () {},
            child: Text(
              'Call Support',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
