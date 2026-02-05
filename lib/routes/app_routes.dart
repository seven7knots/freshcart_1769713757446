import 'package:flutter/material.dart';
import '../features/admin/categories/admin_categories_screen.dart';
import '../features/admin/categories/admin_subcategories_screen.dart';
import '../presentation/admin_ads_management_screen/admin_ads_management_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/admin_landing_dashboard_screen/admin_landing_dashboard_screen.dart';
import '../presentation/admin_logistics_management_screen/admin_logistics_management_screen.dart';
import '../presentation/admin_navigation_drawer_screen/admin_navigation_drawer_screen.dart';
import '../presentation/admin_role_upgrade_management_screen/admin_role_upgrade_management_screen.dart';
import '../presentation/admin_users_management_screen/admin_users_management_screen.dart';
import '../presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart';
import '../presentation/ai_meal_planning_screen/ai_meal_planning_screen.dart';
import '../presentation/ai_powered_search_screen/ai_powered_search_screen.dart';
import '../presentation/all_categories_screen/all_categories_screen.dart';
import '../presentation/auth_gate_screen/auth_gate_screen.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/available_orders_screen/available_orders_screen.dart';
import '../presentation/category_listings_screen/category_listings_screen.dart';
import '../presentation/chat_list_screen/chat_list_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/create_listing_screen/create_listing_screen.dart';
import '../presentation/driver_home_screen/driver_home_screen.dart';
import '../presentation/driver_login_screen/driver_login_screen.dart';
import '../presentation/driver_performance_dashboard_screen/driver_performance_dashboard_screen.dart';
import '../presentation/email_otp_verification_screen/email_otp_verification_screen.dart';
import '../presentation/enhanced_order_management_screen/enhanced_order_management_screen.dart';
import '../presentation/marketplace_account_screen/marketplace_account_screen.dart';
import '../presentation/marketplace_chat_screen/marketplace_chat_screen.dart';
import '../presentation/marketplace_listing_detail_screen/marketplace_listing_detail_screen.dart';
import '../presentation/marketplace_screen/marketplace_screen.dart';
import '../presentation/merchant_profile_screen/merchant_profile_screen.dart';
import '../presentation/my_ads_screen/my_ads_screen.dart';
import '../presentation/my_bookings_screen/my_bookings_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';
import '../presentation/phone_otp_verification_screen/phone_otp_verification_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/role_upgrade_request_screen/role_upgrade_request_screen.dart';
import '../presentation/service_booking_screen/service_booking_screen.dart';
import '../presentation/service_detail_screen/service_detail_screen.dart';
import '../presentation/service_listing_screen/service_listing_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/subcategories_screen/subcategories_screen.dart';
import '../presentation/subscription_management_screen/subscription_management_screen.dart';
import '../widgets/main_layout_wrapper.dart';
// Import the standalone admin edit screen
import '../presentation/admin_edit_overlay_system_screen/admin_edit_standalone_screen.dart';

class AppRoutes {
  // Unauthenticated routes
  static const String initial = '/';
  static const String onboarding = '/onboarding-screen';
  static const String splash = '/splash-screen';
  static const String authentication = '/authentication-screen';
  static const String emailOtpVerification = '/email-otp-verification-screen';
  static const String phoneOtpVerification = '/phone-otp-verification-screen';
  static const String roleUpgradeRequest = '/role-upgrade-request-screen';

  // Main wrapper
  static const String mainLayout = '/main-layout';

  // Tabs (aliases)
  static const String home = '/home-screen';
  static const String search = '/search-screen';
  static const String shoppingCart = '/shopping-cart-screen';
  static const String orderHistory = '/order-history-screen';
  static const String profile = '/profile-screen';

  // Detail screens
  static const String productDetail = '/product-detail-screen';
  static const String productDetailScreen = productDetail;
  static const String checkout = '/checkout-screen';
  static const String orderTracking = '/order-tracking-screen';
  static const String subscriptionManagement = '/subscription-management-screen';

  // AI routes
  static const String aiChatAssistant = '/ai-chat-assistant-screen';
  static const String aiMealPlanning = '/ai-meal-planning-screen';
  static const String aiPoweredSearch = '/ai-powered-search-screen';

  // Marketplace routes (non-tab screens)
  static const String marketplaceScreen = '/marketplace-screen';
  static const String allCategoriesScreen = '/all-categories-screen';
  static const String categoryListingsScreen = '/category-listings-screen';
  static const String serviceListingScreen = '/service-listing-screen';
  static const String serviceDetailScreen = '/service-detail-screen';
  static const String serviceBookingScreen = '/service-booking-screen';
  static const String createListingScreen = '/create-listing-screen';
  static const String marketplaceListingDetailScreen = '/marketplace-listing-detail-screen';
  static const String myBookingsScreen = '/my-bookings-screen';
  static const String myAdsScreen = '/my-ads-screen';
  static const String marketplaceAccountScreen = '/marketplace-account-screen';

  // Messaging routes
  static const String chatListScreen = '/chat-list-screen';
  static const String marketplaceChatScreen = '/marketplace-chat-screen';

  // Driver routes
  static const String driverLogin = '/driver-login-screen';
  static const String driverHome = '/driver-home-screen';
  static const String driverPerformanceDashboard = '/driver-performance-dashboard-screen';
  static const String availableOrdersScreen = '/available-orders-screen';

  // Admin routes
  static const String adminDashboard = '/admin-dashboard-screen';
  static const String adminNavigationDrawer = '/admin-navigation-drawer-screen';
  static const String adminLandingDashboard = '/admin-landing-dashboard-screen';
  static const String adminUsersManagement = '/admin-users-management-screen';
  static const String adminRoleUpgradeManagement = '/admin-role-upgrade-management-screen';
  static const String enhancedOrderManagement = '/enhanced-order-management-screen';
  static const String adminAdsManagement = '/admin-ads-management-screen';
  static const String adminLogisticsManagement = '/admin-logistics-management-screen';
  // Admin special routes - NOW PROPERLY MAPPED
  static const String adminGlobalEditInterface = '/admin-global-edit-interface-screen';
  static const String adminEditOverlaySystem = '/admin-edit-overlay-system-screen';

  // Merchant (optional)
  static const String merchantProfile = '/merchant-profile-screen';

  // Public subcategories screen
  static const String subcategoriesScreen = '/subcategories-screen';

  // Admin Categories module
  static const String adminCategories = '/admin-categories-screen';
  static const String adminSubcategories = '/admin-subcategories-screen';

  static final Map<String, WidgetBuilder> routes = {
    // Auth gate / onboarding
    initial: (context) => const AuthGateScreen(),
    onboarding: (context) => const OnboardingScreen(),
    splash: (context) => const SplashScreen(),
    authentication: (context) => const AuthenticationScreen(),
    emailOtpVerification: (context) => const EmailOtpVerificationScreen(),
    phoneOtpVerification: (context) => const PhoneOtpVerificationScreen(),
    roleUpgradeRequest: (context) => const RoleUpgradeRequestScreen(),

    // Main layout (supports arguments: {'initialIndex': int})
    mainLayout: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final int initialIndex = (args is Map && args['initialIndex'] is int)
          ? args['initialIndex'] as int
          : 0;
      return MainLayoutWrapper(initialIndex: initialIndex);
    },

    // Tab aliases (compat)
    home: (context) => const MainLayoutWrapper(initialIndex: 0),
    search: (context) => const MainLayoutWrapper(initialIndex: 1),
    shoppingCart: (context) => const MainLayoutWrapper(initialIndex: 2),
    orderHistory: (context) => const MainLayoutWrapper(initialIndex: 3),
    profile: (context) => const MainLayoutWrapper(initialIndex: 4),

    // Details
    productDetail: (context) => const ProductDetailScreen(),
    checkout: (context) => const CheckoutScreen(),
    orderTracking: (context) => const OrderTrackingScreen(),
    subscriptionManagement: (context) => const SubscriptionManagementScreen(),

    // AI
    aiChatAssistant: (context) => const AIChatAssistantScreen(),
    aiMealPlanning: (context) => const AIMealPlanningScreen(),
    aiPoweredSearch: (context) => const AIPoweredSearchScreen(),

    // Marketplace
    marketplaceScreen: (context) => const MarketplaceScreen(),
    allCategoriesScreen: (context) => const AllCategoriesScreen(),
    categoryListingsScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      return CategoryListingsScreen(categoryId: args ?? 'all');
    },
    serviceListingScreen: (context) => const ServiceListingScreen(),
    serviceDetailScreen: (context) => const ServiceDetailScreen(),
    serviceBookingScreen: (context) => const ServiceBookingScreen(),
    createListingScreen: (context) => const CreateListingScreen(),
    marketplaceListingDetailScreen: (context) => const MarketplaceListingDetailScreen(),
    myBookingsScreen: (context) => const MyBookingsScreen(),
    myAdsScreen: (context) => const MyAdsScreen(),
    marketplaceAccountScreen: (context) => const MarketplaceAccountScreen(),

    // Messaging
    chatListScreen: (context) => const ChatListScreen(),
    marketplaceChatScreen: (context) => const MarketplaceChatScreen(),

    // Driver
    driverLogin: (context) => const DriverLoginScreen(),
    driverHome: (context) => const DriverHomeScreen(),
    driverPerformanceDashboard: (context) => const DriverPerformanceDashboardScreen(),
    availableOrdersScreen: (context) => const AvailableOrdersScreen(),

    // Admin
    adminDashboard: (context) => const AdminDashboardScreen(),
    adminNavigationDrawer: (context) => const AdminNavigationDrawerScreen(),
    adminLandingDashboard: (context) => const AdminLandingDashboardScreen(),
    adminUsersManagement: (context) => const AdminUsersManagementScreen(),
    adminRoleUpgradeManagement: (context) => const AdminRoleUpgradeManagementScreen(),
    enhancedOrderManagement: (context) => const EnhancedOrderManagementScreen(),
    adminAdsManagement: (context) => const AdminAdsManagementScreen(),
    adminLogisticsManagement: (context) => const AdminLogisticsManagementScreen(),

    // ✅ NEW: Admin Edit Overlay System - NOW PROPERLY MAPPED
    adminEditOverlaySystem: (context) => const AdminEditStandaloneScreen(),
    adminGlobalEditInterface: (context) => const AdminEditStandaloneScreen(),

    // Merchant (optional)
    merchantProfile: (context) => const MerchantProfileScreen(),

    // Public subcategories screen
    subcategoriesScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      return SubcategoriesScreen(
        parentCategoryId: (args?['parentCategoryId'] ?? '').toString(),
        parentCategoryName: (args?['parentCategoryName'] ?? 'Categories').toString(),
      );
    },

    // Admin Categories module
    adminCategories: (context) => const AdminCategoriesScreen(),

    // Admin Subcategories module
    adminSubcategories: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      return AdminSubcategoriesScreen(
        parentCategoryId: (args?['parentCategoryId'] ?? '').toString(),
        parentCategoryName: (args?['parentCategoryName'] ?? 'Category').toString(),
        parentCategoryType: (args?['parentCategoryType'] ?? '').toString(),
      );
    },
  };

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

  static void switchToTab(BuildContext context, int index) {
    final state = MainLayoutWrapper.of(context);
    if (state != null) {
      state.updateTabIndex(index);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      mainLayout,
      (route) => false,
      arguments: {'initialIndex': index},
    );
  }
}