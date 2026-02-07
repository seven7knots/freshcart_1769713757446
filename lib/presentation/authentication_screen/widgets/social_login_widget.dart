import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback? onGooglePressed;

  const SocialLoginWidget({
    super.key,
    this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Or continue with',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        _buildGoogleSignInButton(context),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 6.5.h,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          (onGooglePressed ?? () => _handleGoogleLogin(context))();
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Google__G__logo.svg-1769832236212.jpg',
              height: 18.sp,
              width: 18.sp,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 2.5.w),
            Text(
              'Login with Google',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google login failed'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }
}
