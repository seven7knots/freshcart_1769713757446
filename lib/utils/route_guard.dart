import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/supabase_service.dart';

/// Route guard middleware to protect admin-only routes
class RouteGuard {
  /// Check if user has admin access
  static bool isAdminRoute(String route) {
    return route.startsWith('/admin-') ||
        route == AppRoutes.adminDashboard ||
        route == AppRoutes.adminNavigationDrawer ||
        route == AppRoutes.adminLandingDashboard ||
        route == AppRoutes.adminUsersManagement ||
        route == AppRoutes.adminGlobalEditInterface ||
        route == AppRoutes.enhancedOrderManagement ||
        route == AppRoutes.adminAdsManagement ||
        route == AppRoutes.adminEditOverlaySystem ||
        route == AppRoutes.globalAdminControlsOverlay;
  }

  /// Check if user has driver access
  static bool isDriverRoute(String route) {
    return route.startsWith('/driver-') ||
        route == AppRoutes.driverLogin ||
        route == AppRoutes.driverHome ||
        route == AppRoutes.availableOrdersScreen;
  }

  /// Verify access and redirect if unauthorized
  static Future<bool> verifyAccess(
    BuildContext context,
    String route,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is verified for protected routes (skip for auth/onboarding routes)
    if (route != AppRoutes.emailOtpVerification &&
        route != AppRoutes.phoneOtpVerification &&
        route != AppRoutes.authentication &&
        route != AppRoutes.splash &&
        route != AppRoutes.onboarding) {
      try {
        final user = authProvider.currentUser;
        if (user != null) {
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
                  '[ROUTE_GUARD] Admin user - bypassing verification check');
              // Continue to role-based access checks below
            } else {
              // For non-admin users: enforce verification
              if (!emailVerified || !phoneVerified) {
                if (!emailVerified) {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.emailOtpVerification);
                } else if (!phoneVerified) {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.phoneOtpVerification);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please complete email and phone verification to access the app'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
                return false;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ROUTE_GUARD] Error checking verification: $e');
      }
    }

    // Check admin routes
    if (isAdminRoute(route)) {
      if (!authProvider.isAdmin) {
        // Redirect to appropriate home based on role
        String redirectRoute;
        if (authProvider.isDriver) {
          redirectRoute = AppRoutes.driverHome;
        } else {
          redirectRoute = AppRoutes.home;
        }

        Navigator.of(context).pushReplacementNamed(redirectRoute);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
    }

    // Check driver routes
    if (isDriverRoute(route)) {
      if (!authProvider.isDriver && !authProvider.isAdmin) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Driver privileges required.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
    }

    return true;
  }

  /// Get appropriate home route based on user role
  static String getHomeRouteForRole(AuthProvider authProvider) {
    if (authProvider.isAdmin) {
      return AppRoutes.adminLandingDashboard;
    } else if (authProvider.isDriver) {
      return AppRoutes.driverHome;
    } else {
      return AppRoutes.home;
    }
  }
}
