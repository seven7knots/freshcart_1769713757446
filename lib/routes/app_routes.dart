import 'package:flutter/material.dart';

import '../presentation/admin_ads_management_screen/admin_ads_management_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/admin_edit_overlay_system_screen/admin_edit_overlay_system_screen.dart';
import '../presentation/admin_users_management_screen/admin_users_management_screen.dart';
import '../presentation/admin_role_upgrade_management_screen/admin_role_upgrade_management_screen.dart';
import '../presentation/global_admin_controls_overlay_screen/global_admin_controls_overlay_screen.dart';
import '../presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart';
import '../presentation/ai_meal_planning_screen/ai_meal_planning_screen.dart';
import '../presentation/ai_powered_search_screen/ai_powered_search_screen.dart';
import '../presentation/auth_gate_screen/auth_gate_screen.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/available_orders_screen/available_orders_screen.dart';
import '../presentation/chat_list_screen/chat_list_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/create_listing_screen/create_listing_screen.dart';
import '../presentation/driver_home_screen/driver_home_screen.dart';
import '../presentation/driver_login_screen/driver_login_screen.dart';
import '../presentation/driver_performance_dashboard_screen/driver_performance_dashboard_screen.dart';
import '../presentation/enhanced_order_management_screen/enhanced_order_management_screen.dart';
import '../presentation/marketplace_chat_screen/marketplace_chat_screen.dart';
import '../presentation/marketplace_listing_detail_screen/marketplace_listing_detail_screen.dart';
import '../presentation/admin_navigation_drawer_screen/admin_navigation_drawer_screen.dart';
import '../presentation/admin_landing_dashboard_screen/admin_landing_dashboard_screen.dart';
import '../presentation/merchant_profile_screen/merchant_profile_screen.dart';
import '../presentation/my_ads_screen/my_ads_screen.dart';
import '../presentation/my_bookings_screen/my_bookings_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/service_booking_screen/service_booking_screen.dart';
import '../presentation/service_detail_screen/service_detail_screen.dart';
import '../presentation/service_listing_screen/service_listing_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/subscription_management_screen/subscription_management_screen.dart';
import '../widgets/main_layout_wrapper.dart';
import '../presentation/marketplace_screen/marketplace_screen.dart';
import '../presentation/all_categories_screen/all_categories_screen.dart';
import '../presentation/marketplace_account_screen/marketplace_account_screen.dart';
import '../presentation/category_listings_screen/category_listings_screen.dart';
import '../presentation/email_otp_verification_screen/email_otp_verification_screen.dart';
import '../presentation/phone_otp_verification_screen/phone_otp_verification_screen.dart';
import '../presentation/role_upgrade_request_screen/role_upgrade_request_screen.dart';
import '../presentation/admin_logistics_management_screen/admin_logistics_management_screen.dart';

class AppRoutes {
  // Unauthenticated routes
  static const String initial = '/';
  static const String onboarding = '/onboarding-screen';
  static const String splash = '/splash-screen';
  static const String authentication = '/authentication-screen';
  static const String emailOtpVerification = '/email-otp-verification-screen';
  static const String phoneOtpVerification = '/phone-otp-verification-screen';
  static const String roleUpgradeRequest = '/role-upgrade-request-screen';

  // Main layout wrapper - entry point for authenticated app
  static const String mainLayout = '/main-layout';

  // Main tab routes - all go through MainLayoutWrapper
  static const String home = '/home-screen';
  static const String search = '/search-screen';
  static const String shoppingCart = '/shopping-cart-screen';
  static const String orderHistory = '/order-history-screen';
  static const String profile = '/profile-screen';

  // Detail screens - these should be pushed within the MainLayoutWrapper context
  static const String productDetail = '/product-detail-screen';
  static const String checkout = '/checkout-screen';
  static const String orderTracking = '/order-tracking-screen';
  static const String subscriptionManagement =
      '/subscription-management-screen';

  // AI routes
  static const String aiChatAssistant = '/ai-chat-assistant-screen';
  static const String aiMealPlanning = '/ai-meal-planning-screen';
  static const String aiPoweredSearch = '/ai-powered-search-screen';

  // Marketplace routes
  static const String marketplaceScreen = '/marketplace-screen';
  static const String allCategoriesScreen = '/all-categories-screen';
  static const String categoryListingsScreen = '/category-listings-screen';
  static const String serviceListingScreen = '/service-listing-screen';
  static const String serviceDetailScreen = '/service-detail-screen';
  static const String serviceBookingScreen = '/service-booking-screen';
  static const String createListingScreen = '/create-listing-screen';
  static const String listingDetailScreen = '/listing-detail-screen';
  static const String marketplaceListingDetailScreen =
      '/marketplace-listing-detail-screen';
  static const String myBookingsScreen = '/my-bookings-screen';
  static const String myListingsScreen = '/my-listings-screen';
  static const String myAdsScreen = '/my-ads-screen';
  static const String marketplaceAccountScreen = '/marketplace-account-screen';

  // Messaging routes
  static const String chatListScreen = '/chat-list-screen';
  static const String marketplaceChatScreen = '/marketplace-chat-screen';

  // Driver routes
  static const String driverLogin = '/driver-login-screen';
  static const String driverHome = '/driver-home-screen';
  static const String driverPerformanceDashboard =
      '/driver-performance-dashboard-screen';
  static const String availableOrdersScreen = '/available-orders-screen';
  static const String activeDeliveryScreen = '/active-delivery-screen';

  // Admin routes
  static const String adminDashboard = '/admin-dashboard-screen';
  static const String adminNavigationDrawer = '/admin-navigation-drawer-screen';
  static const String adminLandingDashboard = '/admin-landing-dashboard-screen';
  static const String adminUsersManagement = '/admin-users-management-screen';
  static const String adminRoleUpgradeManagement =
      '/admin-role-upgrade-management-screen';
  static const String adminGlobalEditInterface =
      '/admin-global-edit-interface-screen';
  static const String globalAdminControlsOverlay =
      '/global-admin-controls-overlay-screen';
  static const String enhancedOrderManagement =
      '/enhanced-order-management-screen';
  static const String adminAdsManagement = '/admin-ads-management-screen';
  static const String adminEditOverlaySystem =
      '/admin-edit-overlay-system-screen';
  static const String adminLogisticsManagement =
      '/admin-logistics-management-screen';

  // Store Owner routes
  static const String storeOwnerDashboard = '/store-owner-dashboard-screen';
  static const String merchantProfile = '/merchant-profile-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const AuthGateScreen(),
    onboarding: (context) => const OnboardingScreen(),
    splash: (context) => const SplashScreen(),
    authentication: (context) => const AuthenticationScreen(),
    emailOtpVerification: (context) => const EmailOtpVerificationScreen(),
    phoneOtpVerification: (context) => const PhoneOtpVerificationScreen(),
    roleUpgradeRequest: (context) => const RoleUpgradeRequestScreen(),

    // Main layout - default entry point after authentication,
    mainLayout: (context) => const MainLayoutWrapper(initialIndex: 0),

    // Main authenticated screens with persistent bottom navigation,
    home: (context) => const MainLayoutWrapper(initialIndex: 0),
    search: (context) => const MainLayoutWrapper(initialIndex: 1),
    shoppingCart: (context) => const MainLayoutWrapper(initialIndex: 2),
    orderHistory: (context) => const MainLayoutWrapper(initialIndex: 3),
    profile: (context) => const MainLayoutWrapper(initialIndex: 4),

    // Detail screens - wrapped to maintain bottom navigation context,
    productDetail: (context) => const ProductDetailScreen(),
    checkout: (context) => const CheckoutScreen(),
    orderTracking: (context) => const OrderTrackingScreen(),
    subscriptionManagement: (context) => const SubscriptionManagementScreen(),

    // AI screens,
    aiChatAssistant: (context) => const AIChatAssistantScreen(),
    aiMealPlanning: (context) => const AIMealPlanningScreen(),
    aiPoweredSearch: (context) => const AIPoweredSearchScreen(),

    // Marketplace routes,
    marketplaceScreen: (context) => const MarketplaceScreen(),
    allCategoriesScreen: (context) => const AllCategoriesScreen(),
    categoryListingsScreen: (context) => const CategoryListingsScreen(),
    serviceListingScreen: (context) => const ServiceListingScreen(),
    serviceDetailScreen: (context) => const ServiceDetailScreen(),
    serviceBookingScreen: (context) => const ServiceBookingScreen(),
    createListingScreen: (context) => const CreateListingScreen(),
    marketplaceListingDetailScreen: (context) =>
        const MarketplaceListingDetailScreen(),
    myBookingsScreen: (context) => const MyBookingsScreen(),

    // Messaging routes,
    chatListScreen: (context) => const ChatListScreen(),
    marketplaceChatScreen: (context) => const MarketplaceChatScreen(),

    // Driver routes,
    driverLogin: (context) => const DriverLoginScreen(),
    driverHome: (context) => const DriverHomeScreen(),
    driverPerformanceDashboard: (context) =>
        const DriverPerformanceDashboardScreen(),
    availableOrdersScreen: (context) => const AvailableOrdersScreen(),

    // Admin routes,
    adminDashboard: (context) => const AdminDashboardScreen(),
    adminNavigationDrawer: (context) => const AdminNavigationDrawerScreen(),
    adminLandingDashboard: (context) => const AdminLandingDashboardScreen(),
    adminUsersManagement: (context) => const AdminUsersManagementScreen(),
    adminRoleUpgradeManagement: (context) =>
        const AdminRoleUpgradeManagementScreen(),
    enhancedOrderManagement: (context) => const EnhancedOrderManagementScreen(),
    adminAdsManagement: (context) => const AdminAdsManagementScreen(),
    adminEditOverlaySystem: (context) => const AdminEditOverlaySystemScreen(
          contentType: 'general',
          child: Scaffold(body: Center(child: Text('Overlay System Active'))),
        ),
    adminLogisticsManagement: (context) =>
        const AdminLogisticsManagementScreen(),
    globalAdminControlsOverlay: (context) =>
        const GlobalAdminControlsOverlayScreen(
          contentType: 'general',
          child: Scaffold(body: Center(child: Text('Admin Controls Active'))),
        ),

    // Store Owner routes,
    merchantProfile: (context) => const MerchantProfileScreen(),
    myAdsScreen: (context) => const MyAdsScreen(),
    marketplaceAccountScreen: (context) => const MarketplaceAccountScreen(),
  };

  /// Helper method to get the correct route for a tab index
  static String getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return home;
      case 1:
        return search;
      case 2:
        return shoppingCart;
      case 3:
        return orderHistory;
      case 4:
        return profile;
      default:
        return home;
    }
  }
}
