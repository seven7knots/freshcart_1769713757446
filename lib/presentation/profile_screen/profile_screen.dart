import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/loyalty_rewards_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshRoleData();
  }

  Future<void> _refreshRoleData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserRole();
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  void _goToTab(int index) {
    final wrapper = MainLayoutWrapper.of(context);
    if (wrapper != null) {
      wrapper.updateTabIndex(index);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.getRouteForIndex(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: _shouldShowBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: Text(
                  'Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                automaticallyImplyLeading: false,
                pinned: true,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _showSettingsMenu,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ];
        },
        body: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        if (_isLoading) return _buildLoadingState();

        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Build user data from auth provider
            final userData = _buildUserData(authProvider);
            final rewardsData = _buildRewardsData();

            return CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileHeaderWidget(
                          userData: userData,
                          onEditPressed: _editProfile,
                        ),
                        SizedBox(height: 3.h),

                        // ========================================
                        // ROLE-BASED SECTIONS
                        // ========================================

                        // Merchant Section (if approved merchant)
                        if (authProvider.isMerchant) ...[
                          _buildMerchantSection(authProvider),
                          SizedBox(height: 2.h),
                        ],

                        // Driver Section (if approved driver)
                        if (authProvider.isDriver) ...[
                          _buildDriverSection(authProvider),
                          SizedBox(height: 2.h),
                        ],

                        // Pending Applications Alerts
                        if (authProvider.hasPendingMerchantApplication) ...[
                          _buildPendingApplicationCard(
                            title: 'Merchant Application Pending',
                            subtitle: 'Your merchant application is under review',
                            icon: Icons.store,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 2.h),
                        ],

                        if (authProvider.hasPendingDriverApplication) ...[
                          _buildPendingApplicationCard(
                            title: 'Driver Application Pending',
                            subtitle: 'Your driver application is under review',
                            icon: Icons.delivery_dining,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 2.h),
                        ],

                        // Apply Buttons (for customers without pending apps)
                        if (authProvider.canApplyAsMerchant || authProvider.canApplyAsDriver) ...[
                          _buildApplySection(authProvider),
                          SizedBox(height: 2.h),
                        ],

                        LoyaltyRewardsWidget(
                          rewardsData: rewardsData,
                          onViewAllPressed: _viewAllRewards,
                        ),
                        SettingsSectionWidget(
                          title: 'Quick Actions',
                          items: _getQuickActionItems(),
                        ),
                        SizedBox(height: 2.h),

                        // Admin section (only if admin)
                        Consumer<AdminProvider>(
                          builder: (context, adminProvider, child) {
                            if (!adminProvider.isAdmin) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                SettingsSectionWidget(
                                  title: "Admin Panel",
                                  items: _getAdminItems(adminProvider),
                                ),
                                SizedBox(height: 2.h),
                              ],
                            );
                          },
                        ),

                        SettingsSectionWidget(
                          title: "Account",
                          items: _getAccountItems(),
                        ),
                        SettingsSectionWidget(
                          title: 'Delivery & Addresses',
                          items: _getDeliveryItems(),
                        ),
                        SettingsSectionWidget(
                          title: 'Payment & Billing',
                          items: _getPaymentItems(),
                        ),
                        SettingsSectionWidget(
                          title: 'App Preferences',
                          items: _getPreferenceItems(),
                        ),
                        SettingsSectionWidget(
                          title: 'Help & Support',
                          items: _getHelpItems(),
                        ),
                        SizedBox(height: 2.h),
                        _buildSignOutButton(),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // MERCHANT SECTION
  // ============================================================

  Widget _buildMerchantSection(AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.merchantDashboard),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'My Store',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'MERCHANT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Manage your stores, products & orders',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.green.shade700,
                size: 6.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DRIVER SECTION
  // ============================================================

  Widget _buildDriverSection(AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.driverHome),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Driver Mode',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DRIVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'View assigned orders & start deliveries',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.blue.shade700,
                size: 6.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PENDING APPLICATION CARD
  // ============================================================

  Widget _buildPendingApplicationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 6.w),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.hourglass_top, color: color, size: 5.w),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APPLY SECTION (for customers)
  // ============================================================

  Widget _buildApplySection(AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Become a Partner',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Expand your opportunities with us',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                if (authProvider.canApplyAsMerchant)
                  Expanded(
                    child: _buildApplyButton(
                      icon: Icons.store,
                      label: 'Become a\nMerchant',
                      color: Colors.green,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.merchantApplication),
                    ),
                  ),
                if (authProvider.canApplyAsMerchant && authProvider.canApplyAsDriver)
                  SizedBox(width: 3.w),
                if (authProvider.canApplyAsDriver)
                  Expanded(
                    child: _buildApplyButton(
                      icon: Icons.delivery_dining,
                      label: 'Become a\nDriver',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.driverApplication),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 8.w),
            SizedBox(height: 1.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Map<String, dynamic> _buildUserData(AuthProvider authProvider) {
    return {
      "id": authProvider.userId ?? '',
      "name": authProvider.fullName ?? 'User',
      "email": authProvider.email ?? '',
      "phone": authProvider.phone ?? '',
      "avatar": authProvider.avatarUrl,
      "membershipTier": "Member",
      "totalOrders": 0,
      "loyaltyPoints": 0,
      "totalSaved": 0.0,
      "isPhoneVerified": authProvider.phoneVerified,
      "isEmailVerified": authProvider.emailVerified,
      "joinDate": "Recently",
    };
  }

  Map<String, dynamic> _buildRewardsData() {
    return {
      "currentPoints": 0,
      "nextTierPoints": 1000,
      "nextTier": "Silver",
      "freeDeliveries": 0,
      "cashbackRate": 2,
    };
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          SizedBox(height: 2.h),
          Text(
            'Loading profile...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickActionItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "history",
        "iconColor": theme.colorScheme.primary,
        "title": "Order History",
        "subtitle": "View past orders and reorder",
        "route": AppRoutes.orderHistory,
        "onTap": () => _goToTab(3),
      },
      {
        "icon": "shopping_cart",
        "iconColor": theme.colorScheme.secondary,
        "title": "Shopping Cart",
        "subtitle": "Continue your shopping",
        "route": AppRoutes.shoppingCart,
        "onTap": () => _goToTab(2),
      },
      {
        "icon": "favorite",
        "iconColor": theme.colorScheme.error,
        "title": "Wishlist",
        "subtitle": "Saved items for later",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getAdminItems(AdminProvider adminProvider) {
    final theme = Theme.of(context);
    return [
      {
        "icon": "admin_panel_settings",
        "iconColor": theme.colorScheme.error,
        "title": "Admin Dashboard",
        "subtitle": "Manage users, orders, and system",
        "route": AppRoutes.adminDashboard,
      },
      {
        "icon": "pending_actions",
        "iconColor": Colors.orange,
        "title": "Applications",
        "subtitle": "${adminProvider.pendingApplicationsCount} pending",
        "route": AppRoutes.adminApplications,
      },
      {
        "icon": "people",
        "iconColor": theme.colorScheme.primary,
        "title": "User Management",
        "subtitle": "View and manage all users",
        "route": AppRoutes.adminUsersManagement,
      },
      {
        "icon": "shopping_bag",
        "iconColor": theme.colorScheme.secondary,
        "title": "Order Management",
        "subtitle": "Monitor and manage orders",
        "route": AppRoutes.enhancedOrderManagement,
      },
    ];
  }

  List<Map<String, dynamic>> _getAccountItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "person",
        "iconColor": theme.colorScheme.primary,
        "title": "Personal Information",
        "subtitle": "Name, email, phone number",
        "route": null,
      },
      {
        "icon": "security",
        "iconColor": theme.colorScheme.secondary,
        "title": "Privacy & Security",
        "subtitle": "Password, biometric settings",
        "route": null,
      },
      {
        "icon": "notifications",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Notification Preferences",
        "subtitle": "Order updates, promotions",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getDeliveryItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "location_on",
        "iconColor": theme.colorScheme.primary,
        "title": "Delivery Addresses",
        "subtitle": "Manage your delivery locations",
        "route": null,
      },
      {
        "icon": "schedule",
        "iconColor": theme.colorScheme.secondary,
        "title": "Delivery Preferences",
        "subtitle": "Time slots, special instructions",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getPaymentItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "payment",
        "iconColor": theme.colorScheme.primary,
        "title": "Payment Methods",
        "subtitle": "Manage cards and payment options",
        "route": null,
      },
      {
        "icon": "account_balance_wallet",
        "iconColor": theme.colorScheme.secondary,
        "title": "Wallet",
        "subtitle": "View balance and transactions",
        "route": null,
      },
      {
        "icon": "card_membership",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Subscription Plans",
        "subtitle": "Manage your subscription",
        "route": AppRoutes.subscriptionManagement,
      },
    ];
  }

  List<Map<String, dynamic>> _getPreferenceItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "language",
        "iconColor": theme.colorScheme.primary,
        "title": "Language",
        "subtitle": "English (US)",
        "route": null,
      },
      {
        "icon": "dark_mode",
        "iconColor": theme.colorScheme.onSurfaceVariant,
        "title": "App Theme",
        "subtitle": _themeModeLabel(context),
        "route": null,
        "trailing": Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final cs = Theme.of(context).colorScheme;
            return PopupMenuButton<ThemeMode>(
              tooltip: 'Theme',
              initialValue: themeProvider.themeMode,
              onSelected: (mode) => themeProvider.setThemeMode(mode),
              itemBuilder: (context) => const [
                PopupMenuItem(value: ThemeMode.system, child: Text('System')),
                PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _themeModeShortLabel(themeProvider.themeMode),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(width: 1.5.w),
                  Icon(Icons.expand_more, color: cs.primary),
                ],
              ),
            );
          },
        ),
      },
    ];
  }

  String _themeModeLabel(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    switch (tp.themeMode) {
      case ThemeMode.system:
        return Theme.of(context).brightness == Brightness.dark
            ? "System (Dark)"
            : "System (Light)";
      case ThemeMode.dark:
        return "Dark mode";
      case ThemeMode.light:
        return "Light mode";
    }
  }

  String _themeModeShortLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  List<Map<String, dynamic>> _getHelpItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "help",
        "iconColor": theme.colorScheme.primary,
        "title": "Help Center",
        "subtitle": "FAQs and support articles",
        "route": null,
      },
      {
        "icon": "chat",
        "iconColor": theme.colorScheme.secondary,
        "title": "Live Chat",
        "subtitle": "Get instant help",
        "route": null,
      },
      {
        "icon": "info",
        "iconColor": theme.colorScheme.onSurfaceVariant,
        "title": "About KJ Delivery",
        "subtitle": "Version 2.1.0",
        "route": null,
      },
    ];
  }

  Widget _buildSignOutButton() {
    final theme = Theme.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () => _handleSignOut(authProvider),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 5.w,
                    width: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onError,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      SizedBox(width: 2.w),
                      Text(
                        'Sign Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(AuthProvider authProvider) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notificationsProvider = Provider.of<NotificationsProvider>(
        context,
        listen: false,
      );
      notificationsProvider.clearNotifications();

      await authProvider.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.authentication,
          (route) => false,
        );
      }
    }
  }

  void _editProfile() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit profile feature coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _viewAllRewards() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rewards center coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSettingsMenu() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'download',
                color: theme.colorScheme.secondary,
                size: 6.w,
              ),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile sharing feature coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportData() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data export feature coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}