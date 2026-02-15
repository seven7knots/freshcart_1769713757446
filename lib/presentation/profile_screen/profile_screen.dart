// ============================================================
// FILE: lib/presentation/profile_screen/profile_screen.dart
// ============================================================
// Fully functional profile screen with:
// - No loyalty rewards widget
// - Working privacy & security, notifications, delivery prefs
// - Merged admin dashboard (single entry point)
// - Help section with WhatsApp + phone support
// - No language setting, theme only in preferences
// - Admin subscription management
// - Wishlist → favorites screen (functional)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/main_layout_wrapper.dart';
import '../my_addresses_screen/my_addresses_screen.dart';
import '../privacy_security_screen/privacy_security_screen.dart';
import '../notification_preferences_screen/notification_preferences_screen.dart';
import '../delivery_preferences_screen/delivery_preferences_screen.dart';
import '../admin_subscription_management_screen/admin_subscription_management_screen.dart';
import '../favorites_screen/favorites_screen.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _isLoading = false;
  int _totalOrders = 0;
  double _totalSpent = 0.0;
  bool _subscriptionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _refreshRoleData();
    _loadStats();
    _loadSubscriptionToggle();
  }

  Future<void> _refreshRoleData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserRole();
  }

  Future<void> _loadStats() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final ordersResult = await SupabaseService.client
          .from('orders')
          .select('id, total_amount')
          .eq('customer_id', userId);

      if (mounted) {
        final orders = ordersResult as List;
        double spent = 0;
        for (final o in orders) {
          spent += (o['total_amount'] as num?)?.toDouble() ?? 0;
        }
        setState(() {
          _totalOrders = orders.length;
          _totalSpent = spent;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSubscriptionToggle() async {
    try {
      final result = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'subscriptions_enabled')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _subscriptionsEnabled = result?['value'] == 'true' || result?['value'] == true;
        });
      }
    } catch (_) {
      // If app_config table or key doesn't exist, default to false
      if (mounted) setState(() => _subscriptionsEnabled = false);
    }
  }

  Future<void> _toggleSubscriptions() async {
    final newValue = !_subscriptionsEnabled;
    setState(() => _subscriptionsEnabled = newValue);

    try {
      // Upsert the value in app_config
      await SupabaseService.client.from('app_config').upsert({
        'key': 'subscriptions_enabled',
        'value': newValue.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newValue
              ? 'Subscriptions enabled — users can now access'
              : 'Subscriptions disabled — hidden from users'),
          backgroundColor: newValue ? Colors.green : Colors.grey,
        ));
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() => _subscriptionsEnabled = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to toggle subscriptions: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
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
                  style: theme.appBarTheme.titleTextStyle,
                ),
                automaticallyImplyLeading: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: Theme.of(context).appBarTheme.foregroundColor),
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
            final userData = _buildUserData(authProvider);

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
                          onEditPressed: () => _showEditProfileDialog(authProvider),
                          onAvatarChanged: (url) async {
                            await authProvider.refreshUserRole();
                            if (mounted) setState(() {});
                          },
                        ),
                        SizedBox(height: 3.h),

                        // ========================================
                        // ROLE-BASED SECTIONS
                        // ========================================

                        // Merchant Section
                        if (authProvider.isMerchant) ...[
                          _buildMerchantSection(authProvider),
                          SizedBox(height: 2.h),
                        ],

                        // Driver Section
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

                        // NO LOYALTY REWARDS WIDGET — removed completely

                        SettingsSectionWidget(
                          title: 'Quick Actions',
                          items: _getQuickActionItems(),
                        ),
                        SizedBox(height: 2.h),

                        // Admin section (only if admin) — MERGED single dashboard
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
                          items: _getAccountItems(authProvider),
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
      color: theme.brightness == Brightness.dark
          ? Colors.green.shade900.withOpacity(0.3)
          : Colors.green.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.merchantDashboard),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.store, color: Colors.white, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('My Store',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800)),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: Text('MERCHANT',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                  ),
                ]),
                SizedBox(height: 0.5.h),
                Text('Manage your stores, products & orders',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade700)),
              ]),
            ),
            Icon(Icons.chevron_right,
                color: theme.brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade700, size: 6.w),
          ]),
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
      color: theme.brightness == Brightness.dark
          ? Colors.blue.shade900.withOpacity(0.3)
          : Colors.blue.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.driverHome),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.delivery_dining, color: Colors.white, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Driver Mode',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade800)),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                    child: Text('DRIVER',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                  ),
                ]),
                SizedBox(height: 0.5.h),
                Text('View assigned orders & start deliveries',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.brightness == Brightness.dark ? Colors.blue.shade400 : Colors.blue.shade700)),
              ]),
            ),
            Icon(Icons.chevron_right,
                color: theme.brightness == Brightness.dark ? Colors.blue.shade400 : Colors.blue.shade700, size: 6.w),
          ]),
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
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: color.withOpacity(0.9))),
              SizedBox(height: 0.5.h),
              Text(subtitle, style: TextStyle(fontSize: 11.sp, color: color.withOpacity(0.7))),
            ]),
          ),
          Icon(Icons.hourglass_top, color: color, size: 5.w),
        ]),
      ),
    );
  }

  // ============================================================
  // BECOME A PARTNER
  // ============================================================

  void _showPartnerOptions(AuthProvider authProvider) {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(5.w),
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
              SizedBox(height: 2.5.h),
              Icon(Icons.handshake, color: AppTheme.kjRed, size: 12.w),
              SizedBox(height: 1.5.h),
              Text('Become a Partner',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: 0.5.h),
              Text('Choose how you want to partner with us',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              SizedBox(height: 3.h),

              if (authProvider.canApplyAsMerchant)
                _buildPartnerOption(
                  ctx: ctx,
                  icon: Icons.store,
                  title: 'Become a Merchant',
                  subtitle: 'Create your store, list products, and start selling',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.merchantApplication);
                  },
                ),

              if (authProvider.canApplyAsMerchant && authProvider.canApplyAsDriver)
                SizedBox(height: 1.5.h),

              if (authProvider.canApplyAsDriver)
                _buildPartnerOption(
                  ctx: ctx,
                  icon: Icons.delivery_dining,
                  title: 'Become a Driver',
                  subtitle: 'Deliver orders, set your own schedule, earn money',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.driverApplication);
                  },
                ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: color)),
                  SizedBox(height: 0.5.h),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 6.w),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================

  void _showEditProfileDialog(AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.fullName ?? '');
    final phoneController = TextEditingController(text: authProvider.phone ?? '');
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 5.w,
          right: 5.w,
          top: 3.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 3.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            SizedBox(height: 2.h),
            Text('Edit Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 0.5.h),
            Text('Update your personal information',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: 3.h),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: '+961 XX XXX XXX',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: authProvider.email ?? ''),
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                suffixIcon: Icon(Icons.lock, size: 4.w, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text('  Email cannot be changed here',
                style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red));
                    return;
                  }

                  Navigator.pop(ctx);

                  final success = await authProvider.updateProfile(
                    fullName: name,
                    phone: phone.isNotEmpty ? phone : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? 'Profile updated!' : 'Failed to update profile'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                    if (success) setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kjRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Changes', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
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
      "avatar": authProvider.avatarUrl ?? '',
      "membershipTier": "Member",
      "totalOrders": _totalOrders,
      "isPhoneVerified": authProvider.phoneVerified,
      "isEmailVerified": authProvider.emailVerified,
      "joinDate": "Recently",
    };
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: theme.colorScheme.primary),
        SizedBox(height: 2.h),
        Text('Loading profile...',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  // ============================================================
  // SECTION ITEMS
  // ============================================================

  List<Map<String, dynamic>> _getQuickActionItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "history",
        "iconColor": theme.colorScheme.primary,
        "title": "Order History",
        "subtitle": "View past orders and reorder",
        "onTap": () => _goToTab(3),
      },
      {
        "icon": "shopping_cart",
        "iconColor": theme.colorScheme.primary,
        "title": "Shopping Cart",
        "subtitle": "Continue your shopping",
        "onTap": () => Navigator.pushNamed(context, AppRoutes.shoppingCart),
      },
      {
        "icon": "favorite",
        "iconColor": theme.colorScheme.error,
        "title": "Favorites",
        "subtitle": "Your saved items",
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
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
        "subtitle": "Full system management",
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
        "iconColor": Colors.blue,
        "title": "Order Management",
        "subtitle": "Monitor and manage orders",
        "route": AppRoutes.enhancedOrderManagement,
      },
      {
        "icon": "card_membership",
        "iconColor": Colors.purple,
        "title": "Subscription Plans",
        "subtitle": "Manage plans & pricing",
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSubscriptionManagementScreen()),
            ),
      },
    ];
  }

  List<Map<String, dynamic>> _getAccountItems(AuthProvider authProvider) {
    final theme = Theme.of(context);
    return [
      {
        "icon": "person",
        "iconColor": theme.colorScheme.primary,
        "title": "Personal Information",
        "subtitle": authProvider.fullName ?? 'Name, email, phone number',
        "onTap": () => _showEditProfileDialog(authProvider),
      },
      if (authProvider.canApplyAsMerchant || authProvider.canApplyAsDriver)
        {
          "icon": "handshake",
          "iconColor": AppTheme.kjRed,
          "title": "Become a Partner",
          "subtitle": "Apply as a merchant or driver",
          "onTap": () => _showPartnerOptions(authProvider),
        },
      {
        "icon": "security",
        "iconColor": theme.colorScheme.primary,
        "title": "Privacy & Security",
        "subtitle": "Password, account security",
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
            ),
      },
      {
        "icon": "notifications",
        "iconColor": Colors.orange,
        "title": "Notification Preferences",
        "subtitle": "Order updates, promotions",
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
            ),
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
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
            ),
      },
      {
        "icon": "schedule",
        "iconColor": Colors.blue,
        "title": "Delivery Preferences",
        "subtitle": "Time slots, special instructions",
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryPreferencesScreen()),
            ),
      },
    ];
  }

  List<Map<String, dynamic>> _getPaymentItems() {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return [
      {
        "icon": "payment",
        "iconColor": theme.colorScheme.primary,
        "title": "Payment Method",
        "subtitle": "Cash on Delivery",
        "onTap": () => _showCashOnlyInfo(),
      },
      {
        "icon": "receipt_long",
        "iconColor": Colors.green,
        "title": "Spending Summary",
        "subtitle": "$_totalOrders order${_totalOrders == 1 ? '' : 's'} completed",
        "onTap": () => _showSpendingSummary(),
      },
      {
        "icon": "card_membership",
        "iconColor": _subscriptionsEnabled ? Colors.purple : Colors.grey,
        "title": "Subscription Plans",
        "subtitle": _subscriptionsEnabled
            ? "Manage your subscription"
            : "Coming soon",
        "onTap": _subscriptionsEnabled
            ? null
            : () => _showComingSoon('Subscription Plans'),
        "route": _subscriptionsEnabled ? AppRoutes.subscriptionManagement : null,
      },
      // Admin toggle for subscriptions (only visible to admins)
      if (adminProvider.isAdmin) {
        "icon": "admin_panel_settings",
        "iconColor": _subscriptionsEnabled ? Colors.green : Colors.grey,
        "title": "Subscriptions Toggle",
        "subtitle": _subscriptionsEnabled ? "ON — Users can access" : "OFF — Hidden from users",
        "onTap": () => _toggleSubscriptions(),
      },
    ];
  }

  void _showCashOnlyInfo() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.payment, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Payment Method'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.money, color: Colors.green),
              ),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSpendingSummary() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.receipt_long, color: Colors.green),
          const SizedBox(width: 8),
          const Text('Spending Summary'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('Total Orders', '$_totalOrders', Icons.shopping_bag, theme),
            SizedBox(height: 2.h),
            _buildSummaryRow('Total Spent', '\$${_totalSpent.toStringAsFixed(2)}', Icons.attach_money, theme),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        SizedBox(width: 3.w),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  // Language REMOVED — only theme toggle remains
  List<Map<String, dynamic>> _getPreferenceItems() {
    return [
      {
        "icon": "dark_mode",
        "iconColor": Theme.of(context).colorScheme.onSurfaceVariant,
        "title": "App Theme",
        "subtitle": _themeModeLabel(context),
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _themeModeShortLabel(themeProvider.themeMode),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 1.5.w),
                Icon(Icons.expand_more, color: cs.primary),
              ]),
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
        return Theme.of(context).brightness == Brightness.dark ? "System (Dark)" : "System (Light)";
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

  // Help section: WhatsApp + Phone, no help center, no live chat, no about
  List<Map<String, dynamic>> _getHelpItems() {
    return [
      {
        "icon": "phone",
        "iconColor": Colors.green,
        "title": "Customer Support 24/7",
        "subtitle": "+961 81-483570",
        "onTap": () => _launchPhone('+96181483570'),
      },
      {
        "icon": "chat",
        "iconColor": const Color(0xFF25D366),
        "title": "WhatsApp Support 24/7",
        "subtitle": "Chat with us on WhatsApp",
        "onTap": () => _launchWhatsApp('+96181483570'),
      },
    ];
  }

  // ============================================================
  // LAUNCH PHONE / WHATSAPP
  // ============================================================

  Future<void> _launchPhone(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    // Try WhatsApp deep link first, fallback to web
    final whatsappUri = Uri.parse('https://wa.me/${number.replaceAll('+', '')}');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // COMING SOON (minimal usage now)
  // ============================================================

  void _showComingSoon(String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Widget _buildSignOutButton() {
    final theme = Theme.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : () => _handleSignOut(authProvider),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 5.w,
                    width: 5.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.logout, size: 20),
                    SizedBox(width: 2.w),
                    Text('Sign Out',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
      notificationsProvider.clearNotifications();

      await authProvider.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.authentication, (route) => false);
      }
    }
  }

  // ============================================================
  // SETTINGS MENU
  // ============================================================

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4)),
          ),
          SizedBox(height: 3.h),
          ListTile(
            leading: Icon(Icons.share, color: theme.colorScheme.primary),
            title: const Text('Share Profile'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Profile Sharing');
            },
          ),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.primary),
            title: const Text('Export Data'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Data Export');
            },
          ),
          SizedBox(height: 2.h),
        ]),
      ),
    );
  }
}