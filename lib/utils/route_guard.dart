// ============================================================
// FILE: lib/utils/route_guard.dart
// ============================================================
// ISSUE 2 FIX: Removed refreshUserRole() call on every navigation.
// Now uses cached role data from AuthProvider, which is already
// kept up-to-date by the Supabase auth stream listener.
//
// Also removed the separate Supabase query for verification check —
// now uses cached emailVerified/phoneVerified from AuthProvider.
//
// Before fix: 4+ Supabase queries per guarded navigation
// After fix:  0 Supabase queries per guarded navigation
//
// ISSUE 3 FIX: Excluded driver application from
// driver-only route guard. This screen must be accessible to
// regular customers so they can apply to become drivers.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../l10n/generated/app_localizations.dart';

class RouteGuard {
  /// Routes that correspond to tabs in MainLayoutWrapper.
  /// These should never be pushed as standalone routes — use switchToTab instead.
  static const Set<String> _tabRoutes = {
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.aiMate,
    AppRoutes.stores,
    AppRoutes.profile,
  };

  /// Routes that start with /driver- but should be accessible to ALL users.
  /// Driver application is an entry point for customers who want to become drivers.
  static const Set<String> _publicDriverRoutes = {
    AppRoutes.driverApplication,
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
        route == AppRoutes.adminEditOverlaySystem ||
        route == AppRoutes.adminLogisticsManagement ||
        route == AppRoutes.adminApplications ||
        route == AppRoutes.adminRoleUpgradeManagement ||
        route == AppRoutes.adminCategories ||
        route == AppRoutes.adminSubcategories;
  }

  static bool isDriverRoute(String route) {
    // ISSUE 3 FIX: Don't block public driver routes (application)
    if (_publicDriverRoutes.contains(route)) return false;

    return route.startsWith('/driver-') ||
        route == AppRoutes.driverHome ||
        route == AppRoutes.availableOrdersScreen ||
        route == AppRoutes.driverPerformanceDashboard;
  }

  /// Verify whether the current user is allowed to access [route].
  ///
  /// Returns `true` if access is granted, `false` if a redirect was triggered.
  ///
  /// ISSUE 2 FIX: This method now uses CACHED role data from AuthProvider
  /// instead of calling refreshUserRole() on every navigation.
  /// AuthProvider's role data is kept current by the Supabase auth stream
  /// listener in main.dart, so there's no need to hit the database here.
  ///
  /// All Navigator redirects use [WidgetsBinding.addPostFrameCallback] so
  /// this method is safe to call from initState / post-frame callbacks.
  /// It MUST NOT be called synchronously inside a widget build method.
  static Future<bool> verifyAccess(
    BuildContext context,
    String route,
  ) async {
    if (!context.mounted) return false;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // —— Tab routes should switch tabs, not push ——————————————————
    if (isTabRoute(route)) {
      final index = _indexForTabRoute(route);
      _deferredAction(context, () {
        AppRoutes.switchToTab(context, index);
      });
      return false;
    }

    // ============================================================
    // ISSUE 2 FIX: REMOVED refreshUserRole() call
    // ============================================================
    // Previously we had:
    //   if (authProvider.isAuthenticated) {
    //     try { await authProvider.refreshUserRole(); } catch (e) { debugPrint('[ROUTE_GUARD] Silent error: $e'); }
    //   }
    //
    // This was causing 3+ Supabase queries (users + merchants + drivers)
    // on EVERY guarded route navigation. The role data is already loaded
    // by AuthProvider's init and kept current by the Supabase auth stream
    // listener, so this was completely redundant.
    // ============================================================

    if (!context.mounted) return false;

    // —— Verification check using CACHED data ————————————————————
    // ISSUE 2 FIX: Use AuthProvider's cached verification status
    // instead of making a separate Supabase query every time.
    if (_requiresVerification(route) && authProvider.isAuthenticated) {
      // Use cached role — no DB query needed
      if (!authProvider.isAdmin) {
        if (!authProvider.emailVerified) {
          _redirectTo(context, AppRoutes.emailOtpVerification,
              message: 'Please complete email verification to access the app');
          return false;
        }
        if (!authProvider.phoneVerified) {
          _redirectTo(context, AppRoutes.phoneOtpVerification,
              message: 'Please complete phone verification to access the app');
          return false;
        }
      }
    }

    if (!context.mounted) return false;

    // —— Admin route access check ————————————————————————————————
    if (isAdminRoute(route)) {
      if (!authProvider.isAdmin) {
        final redirectRoute = getHomeRouteForRole(authProvider);
        _redirectTo(context, redirectRoute,
            message: 'Access denied. Admin privileges required.',
            isError: true);
        return false;
      }
    }

    // —— Driver route access check ———————————————————————————————
    if (isDriverRoute(route)) {
      if (!authProvider.isDriver && !authProvider.isAdmin) {
        _redirectTo(context, AppRoutes.mainLayout,
            message: 'Access denied. Driver privileges required.',
            isError: true);
        return false;
      }
    }

    return true;
  }

  /// Whether a given route requires email/phone verification.
  static bool _requiresVerification(String route) {
    const exempt = {
      AppRoutes.initial,
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.authentication,
      AppRoutes.emailOtpVerification,
      AppRoutes.phoneOtpVerification,
    };
    return !exempt.contains(route);
  }

  /// Safely redirect using addPostFrameCallback to avoid Navigator-during-build errors.
  static void _redirectTo(
    BuildContext context,
    String route, {
    String? message,
    bool isError = false,
  }) {
    _deferredAction(context, () {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(route);

      if (message != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// Execute an action in a post-frame callback if we're currently building,
  /// or immediately if we're not.
  static void _deferredAction(BuildContext context, VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        action();
      }
    });
  }

  static String getHomeRouteForRole(AuthProvider authProvider) {
    if (authProvider.isAdmin) return AppRoutes.adminLandingDashboard;
    if (authProvider.isDriver) return AppRoutes.driverHome;
    return AppRoutes.mainLayout;
  }

  static int _indexForTabRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.search:
        return 1;
      case AppRoutes.aiMate:
        return 2;
      case AppRoutes.stores:
        return 3;
      case AppRoutes.profile:
        return 4;
      default:
        return 0;
    }
  }
}