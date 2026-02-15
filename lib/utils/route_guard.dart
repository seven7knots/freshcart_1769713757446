// ============================================================
// FILE: lib/utils/route_guard.dart
// ============================================================
// Route access guard with deterministic role resolution.
// Model A enforced: admin > merchant > driver > user
// Source of truth:
// - AdminProvider.refreshRoles() (admin + merchant status from DB/RPC)
// - AuthProvider for driver flag + auth state
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/supabase_service.dart';

class RouteGuard {
  // ============================================================
  // ROUTE CATEGORIES
  // ============================================================

  /// Main tab routes (bottom navigation)
  static const Set<String> _tabRoutes = {
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.aiMate,
    AppRoutes.stores,
    AppRoutes.profile,
  };

  /// Admin-only routes
  static const Set<String> _adminRoutes = {
    AppRoutes.adminDashboard,
    AppRoutes.adminNavigationDrawer,
    AppRoutes.adminLandingDashboard,
    AppRoutes.adminUsersManagement,
    AppRoutes.adminRoleUpgradeManagement,
    AppRoutes.adminApplications,
    AppRoutes.adminGlobalEditInterface,
    AppRoutes.enhancedOrderManagement,
    AppRoutes.adminAdsManagement,
    AppRoutes.adminLogisticsManagement,
    AppRoutes.adminEditOverlaySystem,
    AppRoutes.adminCategories,
    AppRoutes.adminSubcategories,
  };

  /// Driver-only routes
  static const Set<String> _driverRoutes = {
    AppRoutes.driverLogin,
    AppRoutes.driverHome,
    AppRoutes.availableOrdersScreen,
    AppRoutes.driverPerformanceDashboard,
  };

  /// Merchant-only routes
  /// (keep placeholders; only enforced when your merchant routes exist)
  static const Set<String> _merchantRoutes = {
    // Example:
    // '/merchant-dashboard',
    // '/merchant-store-management',
    // '/merchant-products',
    // '/merchant-orders',
  };

  /// Public routes (no auth required)
  static const Set<String> _publicRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.authentication,
    AppRoutes.emailOtpVerification,
    AppRoutes.phoneOtpVerification,
  };

  // ============================================================
  // ROUTE TYPE CHECKS
  // ============================================================

  static bool isTabRoute(String route) => _tabRoutes.contains(route);

  static bool isAdminRoute(String route) {
    if (_adminRoutes.contains(route)) return true;
    return route.startsWith('/admin-') || route.startsWith('/admin/');
  }

  static bool isDriverRoute(String route) {
    if (_driverRoutes.contains(route)) return true;
    return route.startsWith('/driver-') || route.startsWith('/driver/');
  }

  static bool isMerchantRoute(String route) {
    if (_merchantRoutes.contains(route)) return true;
    return route.startsWith('/merchant-') || route.startsWith('/merchant/');
  }

  static bool isPublicRoute(String route) => _publicRoutes.contains(route);

  // ============================================================
  // MAIN ACCESS VERIFICATION
  // ============================================================

  /// Verify if user can access a route
  /// Returns true if access is allowed, false if redirected
  static Future<bool> verifyAccess(
    BuildContext context,
    String route,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[ROUTE_GUARD] Verifying access to: $route');
    debugPrint('[ROUTE_GUARD] isAuthenticated: ${authProvider.isAuthenticated}');
    debugPrint('[ROUTE_GUARD] authProvider.role: ${authProvider.role}');
    debugPrint('[ROUTE_GUARD] adminProvider.isAdmin (cached): ${adminProvider.isAdmin}');
    debugPrint('[ROUTE_GUARD] adminProvider.isMerchant (cached): ${adminProvider.isMerchant}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Tab routes should be handled via tab switching, not pushing
    if (isTabRoute(route)) {
      final index = _indexForTabRoute(route);
      AppRoutes.switchToTab(context, index);
      return false;
    }

    // Public routes - always allowed
    if (isPublicRoute(route)) return true;

    // Check authentication for non-public routes
    if (!authProvider.isAuthenticated) {
      debugPrint('[ROUTE_GUARD] Not authenticated, redirecting to auth');
      _redirectToAuth(context);
      return false;
    }

    // Refresh AuthProvider-derived role flags (if your AuthProvider maintains them)
    try {
      await authProvider.refreshUserRole();
    } catch (e) {
      debugPrint('[ROUTE_GUARD] authProvider.refreshUserRole failed (ignored): $e');
    }

    // IMPORTANT: deterministic role resolution from AdminProvider (DB/RPC)
    try {
      await adminProvider.refreshRoles(reason: 'route-guard-$route');
    } catch (e) {
      debugPrint('[ROUTE_GUARD] adminProvider.refreshRoles failed (fallback to cached): $e');
    }

    // Model A: admin always wins
    final bool isAdmin = adminProvider.isAdmin;
    final bool isMerchant = adminProvider.isMerchant; // approved merchant from DB
    final bool isDriver = authProvider.isDriver;

    debugPrint('[ROUTE_GUARD] resolved: isAdmin=$isAdmin isMerchant=$isMerchant isDriver=$isDriver');

    // Check verification status (admins bypass)
    if (!isAdmin) {
      final ok = await _checkVerification(context, route, authProvider);
      if (!ok) return false;
    }

    // Admin routes
    if (isAdminRoute(route)) {
      if (!isAdmin) {
        debugPrint('[ROUTE_GUARD] Admin route denied - not an admin');
        _showAccessDenied(context, 'Admin privileges required');
        _redirectToHomeForRole(context, authProvider, adminProvider);
        return false;
      }
      return true;
    }

    // Driver routes (admin allowed)
    if (isDriverRoute(route)) {
      if (!isDriver && !isAdmin) {
        debugPrint('[ROUTE_GUARD] Driver route denied - not a driver');
        _showAccessDenied(context, 'Driver privileges required');
        _redirectToHomeForRole(context, authProvider, adminProvider);
        return false;
      }
      return true;
    }

    // Merchant routes (admin allowed, merchant based on DB-approved status OR AuthProvider flag)
    if (isMerchantRoute(route)) {
      final bool allowMerchant = isAdmin || isMerchant || authProvider.isMerchant;
      if (!allowMerchant) {
        debugPrint('[ROUTE_GUARD] Merchant route denied - not a merchant');
        _showAccessDenied(context, 'Merchant privileges required');
        _redirectToHomeForRole(context, authProvider, adminProvider);
        return false;
      }
      return true;
    }

    // All other routes - allow if authenticated
    return true;
  }

  // ============================================================
  // VERIFICATION CHECK
  // ============================================================

  static Future<bool> _checkVerification(
    BuildContext context,
    String route,
    AuthProvider authProvider,
  ) async {
    if (route == AppRoutes.emailOtpVerification ||
        route == AppRoutes.phoneOtpVerification) {
      return true;
    }

    try {
      final user = authProvider.currentUser;
      if (user == null) return true;

      final response = await SupabaseService.client
          .from('users')
          .select('email_verified, phone_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return true;

      final emailVerified = response['email_verified'] ?? false;
      final phoneVerified = response['phone_verified'] ?? false;

      if (!emailVerified) {
        debugPrint('[ROUTE_GUARD] Email not verified, redirecting');
        Navigator.of(context).pushReplacementNamed(AppRoutes.emailOtpVerification);
        _showVerificationRequired(context, 'Please verify your email');
        return false;
      }

      if (!phoneVerified) {
        debugPrint('[ROUTE_GUARD] Phone not verified, redirecting');
        Navigator.of(context).pushReplacementNamed(AppRoutes.phoneOtpVerification);
        _showVerificationRequired(context, 'Please verify your phone number');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[ROUTE_GUARD] Error checking verification: $e');
      return true; // Allow on error to prevent blocking
    }
  }

  // ============================================================
  // ROLE-BASED HOME ROUTES (Model A enforced)
  // ============================================================

  static String getHomeRouteForRole(
    AuthProvider authProvider,
    AdminProvider adminProvider,
  ) {
    // Model A: admin wins even if merchant/driver flags exist
    if (adminProvider.isAdmin) return AppRoutes.adminLandingDashboard;

    if (authProvider.isDriver) return AppRoutes.driverHome;

    // Merchants and customers use same home in your current app
    return AppRoutes.home;
  }

  static void _redirectToHomeForRole(
    BuildContext context,
    AuthProvider authProvider,
    AdminProvider adminProvider,
  ) {
    final route = getHomeRouteForRole(authProvider, adminProvider);
    Navigator.of(context).pushReplacementNamed(route);
  }

  static void _redirectToAuth(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  static void _showAccessDenied(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access denied. $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showVerificationRequired(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TAB NAVIGATION HELPER
  // ============================================================

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

  // ============================================================
  // ROLE-BASED UI HELPERS (Model A enforced)
  // ============================================================

  static bool shouldShowAdminUI(BuildContext context) {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      return adminProvider.isAdmin;
    } catch (_) {
      return false;
    }
  }

  static bool shouldShowMerchantUI(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Admin always allowed; merchants based on approved merchant from DB OR auth flag
      return adminProvider.isAdmin || adminProvider.isMerchant || authProvider.isMerchant;
    } catch (_) {
      return false;
    }
  }

  static bool shouldShowDriverUI(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      return adminProvider.isAdmin || authProvider.isDriver;
    } catch (_) {
      return false;
    }
  }

  static List<DrawerItem> getDrawerItemsForRole(
    AuthProvider authProvider,
    AdminProvider adminProvider,
  ) {
    final items = <DrawerItem>[];

    // Common items
    items.add(const DrawerItem(
      icon: Icons.home,
      title: 'Home',
      route: AppRoutes.home,
    ));

    items.add(const DrawerItem(
      icon: Icons.history,
      title: 'Order History',
      route: AppRoutes.orderHistory,
    ));

    items.add(const DrawerItem(
      icon: Icons.person,
      title: 'Profile',
      route: AppRoutes.profile,
    ));

    // Merchant items (admin does NOT need merchant items unless you want them)
    // If you want admin to also see merchant items, change condition to:
    // if (adminProvider.isAdmin || adminProvider.isMerchant || authProvider.isMerchant)
    if (adminProvider.isMerchant || authProvider.isMerchant) {
      items.add(const DrawerItem(
        icon: Icons.store,
        title: 'My Store',
        route: '/merchant-dashboard',
        dividerBefore: true,
      ));
      items.add(const DrawerItem(
        icon: Icons.inventory,
        title: 'Products',
        route: '/merchant-products',
      ));
      items.add(const DrawerItem(
        icon: Icons.receipt_long,
        title: 'Store Orders',
        route: '/merchant-orders',
      ));
    }

    // Driver items
    if (authProvider.isDriver) {
      items.add(const DrawerItem(
        icon: Icons.delivery_dining,
        title: 'Driver Dashboard',
        route: AppRoutes.driverHome,
        dividerBefore: true,
      ));
      items.add(const DrawerItem(
        icon: Icons.list_alt,
        title: 'Available Orders',
        route: AppRoutes.availableOrdersScreen,
      ));
    }

    // Admin items (Model A: admin wins)
    if (adminProvider.isAdmin) {
      items.add(const DrawerItem(
        icon: Icons.admin_panel_settings,
        title: 'Admin Dashboard',
        route: AppRoutes.adminLandingDashboard,
        dividerBefore: true,
      ));
      items.add(const DrawerItem(
        icon: Icons.people,
        title: 'User Management',
        route: AppRoutes.adminUsersManagement,
      ));
      items.add(const DrawerItem(
        icon: Icons.pending_actions,
        title: 'Applications',
        route: AppRoutes.adminApplications,
      ));
      items.add(const DrawerItem(
        icon: Icons.edit,
        title: 'Edit Mode',
        route: AppRoutes.adminGlobalEditInterface,
      ));
    }

    return items;
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final String route;
  final bool dividerBefore;

  const DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    this.dividerBefore = false,
  });
}