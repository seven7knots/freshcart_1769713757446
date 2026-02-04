import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/supabase_service.dart';

class RouteGuard {
  static const Set<String> _tabRoutes = {
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.shoppingCart,
    AppRoutes.orderHistory,
    AppRoutes.profile,
  };

  static bool isTabRoute(String route) => _tabRoutes.contains(route);

  static bool isAdminRoute(String route) {
    return route.startsWith('/admin-') ||
        route == AppRoutes.adminDashboard ||
        route == AppRoutes.adminNavigationDrawer ||
        route == AppRoutes.adminLandingDashboard ||
        route == AppRoutes.adminUsersManagement ||
        route == AppRoutes.adminGlobalEditInterface ||
        route == AppRoutes.enhancedOrderManagement ||
        route == AppRoutes.adminAdsManagement ||
        route == AppRoutes.adminEditOverlaySystem;
  }

  static bool isDriverRoute(String route) {
    return route.startsWith('/driver-') ||
        route == AppRoutes.driverLogin ||
        route == AppRoutes.driverHome ||
        route == AppRoutes.availableOrdersScreen;
  }

  static Future<bool> verifyAccess(
    BuildContext context,
    String route,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Prevent pushing tab routes. Tabs must be switched via AppRoutes.switchToTab.
    if (isTabRoute(route)) {
      final index = _indexForTabRoute(route);
      AppRoutes.switchToTab(context, index);
      return false;
    }

    // Refresh role to reduce race conditions (especially right after login).
    if (authProvider.isAuthenticated) {
      await authProvider.refreshUserRole();
    }

    // Verification check (keep existing behavior, but admins bypass)
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
              .select('role, email_verified, phone_verified')
              .eq('id', user.id)
              .maybeSingle();

          if (response != null) {
            final role = (response['role'] as String?)?.toLowerCase();
            final emailVerified = response['email_verified'] ?? false;
            final phoneVerified = response['phone_verified'] ?? false;

            if (role != 'admin') {
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
                      'Please complete email and phone verification to access the app',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
                return false;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (isAdminRoute(route)) {
      if (!authProvider.isAdmin) {
        final redirectRoute = getHomeRouteForRole(authProvider);
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

  static String getHomeRouteForRole(AuthProvider authProvider) {
    if (authProvider.isAdmin) return AppRoutes.adminLandingDashboard;
    if (authProvider.isDriver) return AppRoutes.driverHome;
    return AppRoutes.home;
  }

  static int _indexForTabRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.search:
        return 1;
      case AppRoutes.shoppingCart:
        return 2;
      case AppRoutes.orderHistory:
        return 3;
      case AppRoutes.profile:
        return 4;
      default:
        return 0;
    }
  }
}
