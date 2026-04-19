// ============================================================
// FILE: lib/presentation/authentication_screen/widgets/social_login_widget.dart
// ============================================================
// UPDATED: Styled for glass/dark background auth screen
// ISSUE 1 FIX: Added navigation after successful Google sign-in
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/route_guard.dart';
import '../../../l10n/generated/app_localizations.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback? onGooglePressed;

  const SocialLoginWidget({super.key, this.onGooglePressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                AppLocalizations.of(context)!.orContinueWith,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
          ],
        ),
        SizedBox(height: 2.5.h),
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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
              errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, size: 24.sp, color: Colors.red),
            ),
            SizedBox(width: 2.5.w),
            Text(
              AppLocalizations.of(context)!.loginWithGoogle,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (!context.mounted) return;

    if (success) {
      // Navigate to the appropriate home screen based on user role
      final homeRoute = RouteGuard.getHomeRouteForRole(authProvider);
      debugPrint('[SOCIAL_LOGIN] Google sign-in success, navigating to: $homeRoute');

      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRoute,
        (route) => false, // Remove all previous routes (clears back stack)
      );
    } else {
      // Only show error if there actually is one (not for user cancellation)
      final error = authProvider.errorMessage;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}