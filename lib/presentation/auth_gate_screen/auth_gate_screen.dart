import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/route_guard.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('users')
          .select('role, is_verified, email_verified, phone_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final role = response['role'] as String?;
        final emailVerified = response['email_verified'] ?? false;
        final phoneVerified = response['phone_verified'] ?? false;

        // Admin bypass: Allow admins to access app without verification
        if (role == 'admin') {
          debugPrint(
              '[AUTH_GATE] Admin user detected - bypassing verification');
          final homeRoute = RouteGuard.getHomeRouteForRole(authProvider);
          Navigator.of(context).pushReplacementNamed(homeRoute);
          return;
        }

        // For non-admin users (customer, driver, merchant): enforce verification
        if (!emailVerified) {
          debugPrint(
              '[AUTH_GATE] Email not verified - redirecting to email OTP');
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.emailOtpVerification);
          return;
        }

        if (!phoneVerified) {
          debugPrint(
              '[AUTH_GATE] Phone not verified - redirecting to phone OTP');
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.phoneOtpVerification);
          return;
        }

        // Both verifications complete - proceed to appropriate home
        debugPrint('[AUTH_GATE] User fully verified - proceeding to home');
        final homeRoute = RouteGuard.getHomeRouteForRole(authProvider);
        Navigator.of(context).pushReplacementNamed(homeRoute);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
      }
    } catch (e) {
      debugPrint('[AUTH_GATE] Error checking auth state: $e');
      Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[AUTH_GATE] 🎨 Building AuthGate UI');
    // Always render a visible Scaffold to prevent black screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            CustomImageWidget(
              imageUrl: 'assets/images/img_app_logo.svg',
              height: 80.h,
              width: 80.w,
              semanticLabel: 'FreshCart logo with shopping cart icon',
            ),
            SizedBox(height: 3.h),
            // Loading indicator
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            // Loading text
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
