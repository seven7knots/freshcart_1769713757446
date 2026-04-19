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
// - Share Profile & Export Data (implemented)
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
import '../favorites_screen/favorites_screen.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _isLoading = false;
  int _totalOrders = 0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshRoleData();
    _loadStats();
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
          .select('id, total')
          .eq('customer_id', userId);

      if (mounted) {
        final orders = ordersResult as List;
        double spent = 0;
        for (final o in orders) {
          spent += (o['total'] as num?)?.toDouble() ?? 0;
        }
        setState(() {
          _totalOrders = orders.length;
          _totalSpent = spent;
        });
      }
    } catch (e) { debugPrint('[PROFILE_SCREEN] Silent error: $e'); }
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
                  AppLocalizations.of(context)!.profile,
                  style: theme.appBarTheme.titleTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    tooltip: AppLocalizations.of(context)!.settings,
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
                            await authProvider.refreshUserRole(force: true);
                            if (mounted) setState(() {});
                          },
                        ),
                        SizedBox(height: 3.h),

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
                            title: AppLocalizations.of(context)!.merchantApplicationPending,
                            subtitle: AppLocalizations.of(context)!.yourMerchantApplicationIsUnderReview,
                            icon: Icons.store,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 2.h),
                        ],

                        if (authProvider.hasPendingDriverApplication) ...[
                          _buildPendingApplicationCard(
                            title: AppLocalizations.of(context)!.driverApplicationPending,
                            subtitle: AppLocalizations.of(context)!.yourDriverApplicationIsUnderReview,
                            icon: Icons.delivery_dining,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 2.h),
                        ],

                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.quickActions,
                          items: _getQuickActionItems(),
                        ),
                        SizedBox(height: 2.h),

                        // Admin section
                        Consumer<AdminProvider>(
                          builder: (context, adminProvider, child) {
                            if (!adminProvider.isAdmin) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                SettingsSectionWidget(
                                  title: AppLocalizations.of(context)!.adminPanel,
                                  items: _getAdminItems(adminProvider),
                                ),
                                SizedBox(height: 2.h),
                              ],
                            );
                          },
                        ),

                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.account,
                          items: _getAccountItems(authProvider),
                        ),
                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.deliveryAddresses,
                          items: _getDeliveryItems(),
                        ),
                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.paymentBilling,
                          items: _getPaymentItems(),
                        ),
                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.appPreferences,
                          items: _getPreferenceItems(),
                        ),
                        SettingsSectionWidget(
                          title: AppLocalizations.of(context)!.helpSupport,
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
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.store, color: Colors.white, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(AppLocalizations.of(context)!.myStore,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(14)),
                    child: Text('MERCHANT',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                SizedBox(height: 0.5.h),
                Text(AppLocalizations.of(context)!.manageYourStoresProductsOrders,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.delivery_dining, color: Colors.white, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(AppLocalizations.of(context)!.driverMode,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(14)),
                    child: Text('DRIVER',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                SizedBox(height: 0.5.h),
                Text(AppLocalizations.of(context)!.viewAssignedOrdersStartDeliveries,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.brightness == Brightness.dark ? Colors.blue.shade400 : Colors.blue.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: color.withOpacity(0.9)), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 0.5.h),
              Text(subtitle, style: TextStyle(fontSize: 11.sp, color: color.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 2.5.h),
              Icon(Icons.handshake, color: AppTheme.kjRed, size: 12.w),
              SizedBox(height: 1.5.h),
              Text(AppLocalizations.of(context)!.becomeAPartner,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 0.5.h),
              Text(AppLocalizations.of(context)!.chooseHowYouWantToPartner,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 3.h),

              if (authProvider.canApplyAsMerchant)
                _buildPartnerOption(
                  ctx: ctx,
                  icon: Icons.store,
                  title: AppLocalizations.of(context)!.becomeAMerchant,
                  subtitle: AppLocalizations.of(context)!.createYourStoreListProductsAnd,
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
                  title: AppLocalizations.of(context)!.becomeADriver,
                  subtitle: AppLocalizations.of(context)!.deliverOrdersSetYourOwnSchedule,
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 8.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
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
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 2.h),
            Text(AppLocalizations.of(context)!.editProfile, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Text(AppLocalizations.of(context)!.updateYourPersonalInformation,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 3.h),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fullName,
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
                labelText: AppLocalizations.of(context)!.phoneNumber,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: AppLocalizations.of(context)!.phoneNumberPlaceholder,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: authProvider.email ?? ''),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                suffixIcon: Icon(Icons.lock, size: 4.w, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(AppLocalizations.of(context)!.emailCannotBeChangedHere,
                style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        SnackBar(content: Text(AppLocalizations.of(context)!.nameCannotBeEmpty, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                    return;
                  }

                  Navigator.pop(ctx);

                  final success = await authProvider.updateProfile(
                    fullName: name,
                    phone: phone.isNotEmpty ? phone : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? AppLocalizations.of(context)!.profileUpdated : AppLocalizations.of(context)!.failedToUpdateProfile, maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                    if (success) setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kjRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(AppLocalizations.of(context)!.saveChanges, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      "membershipTier": 'Member',
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
        Text(AppLocalizations.of(context)!.loadingProfile,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        "title": AppLocalizations.of(context)!.orderHistory,
        "subtitle": AppLocalizations.of(context)!.viewPastOrdersAndReorder,
        "onTap": () => Navigator.pushNamed(context, AppRoutes.orderHistory),
      },
      {
        "icon": "shopping_cart",
        "iconColor": theme.colorScheme.primary,
        "title": AppLocalizations.of(context)!.shoppingCart2,
        "subtitle": AppLocalizations.of(context)!.continueYourShopping,
        "onTap": () => Navigator.pushNamed(context, AppRoutes.shoppingCart),
      },
      {
        "icon": "favorite",
        "iconColor": theme.colorScheme.error,
        "title": AppLocalizations.of(context)!.favorites,
        "subtitle": AppLocalizations.of(context)!.yourSavedItems,
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
        "title": AppLocalizations.of(context)!.adminDashboard,
        "subtitle": AppLocalizations.of(context)!.fullSystemManagement,
        "route": AppRoutes.adminDashboard,
      },
      {
        "icon": "pending_actions",
        "iconColor": Colors.orange,
        "title": AppLocalizations.of(context)!.applications,
        "subtitle": "${adminProvider.pendingApplicationsCount} pending",
        "route": AppRoutes.adminApplications,
      },
      {
        "icon": "people",
        "iconColor": theme.colorScheme.primary,
        "title": AppLocalizations.of(context)!.userManagement,
        "subtitle": AppLocalizations.of(context)!.viewAndManageAllUsers,
        "route": AppRoutes.adminUsersManagement,
      },
      {
        "icon": "shopping_bag",
        "iconColor": Colors.blue,
        "title": AppLocalizations.of(context)!.orderManagement,
        "subtitle": AppLocalizations.of(context)!.monitorAndManageOrders,
        "route": AppRoutes.enhancedOrderManagement,
      },

    ];
  }

  List<Map<String, dynamic>> _getAccountItems(AuthProvider authProvider) {
    final theme = Theme.of(context);
    return [
      {
        "icon": "person",
        "iconColor": theme.colorScheme.primary,
        "title": AppLocalizations.of(context)!.personalInformation,
        "subtitle": authProvider.fullName ?? 'Name, email, phone number',
        "onTap": () => _showEditProfileDialog(authProvider),
      },
      if (authProvider.canApplyAsMerchant || authProvider.canApplyAsDriver)
        {
          "icon": "handshake",
          "iconColor": AppTheme.kjRed,
          "title": AppLocalizations.of(context)!.becomeAPartner,
          "subtitle": AppLocalizations.of(context)!.applyAsAMerchantOrDriver,
          "onTap": () => _showPartnerOptions(authProvider),
        },
      {
        "icon": "security",
        "iconColor": theme.colorScheme.primary,
        "title": AppLocalizations.of(context)!.privacySecurity,
        "subtitle": AppLocalizations.of(context)!.passwordAccountSecurity,
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
            ),
      },
      {
        "icon": "notifications",
        "iconColor": Colors.orange,
        "title": AppLocalizations.of(context)!.notificationPreferences,
        "subtitle": AppLocalizations.of(context)!.orderUpdatesPromotions,
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
        "title": AppLocalizations.of(context)!.deliveryAddresses2,
        "subtitle": AppLocalizations.of(context)!.manageYourDeliveryLocations,
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
            ),
      },
      {
        "icon": "schedule",
        "iconColor": Colors.blue,
        "title": AppLocalizations.of(context)!.deliveryPreferences,
        "subtitle": AppLocalizations.of(context)!.timeSlotsSpecialInstructions,
        "onTap": () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryPreferencesScreen()),
            ),
      },
    ];
  }

  List<Map<String, dynamic>> _getPaymentItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "payment",
        "iconColor": theme.colorScheme.primary,
        "title": AppLocalizations.of(context)!.paymentMethod,
        "subtitle": AppLocalizations.of(context)!.cashOnDelivery,
        "onTap": () => _showCashOnlyInfo(),
      },
      {
        "icon": "receipt_long",
        "iconColor": Colors.green,
        "title": AppLocalizations.of(context)!.spendingSummary,
        "subtitle": "$_totalOrders order${_totalOrders == 1 ? '' : 's'} completed",
        "onTap": () => _showSpendingSummary(),
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
          Flexible(child: Text(AppLocalizations.of(context)!.paymentMethod, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.money, color: Colors.green),
              ),
              title: Text(AppLocalizations.of(context)!.cashOnDelivery, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppLocalizations.of(context)!.payWhenYourOrderArrives, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok2, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          const Icon(Icons.receipt_long, color: Colors.green),
          const SizedBox(width: 8),
          Flexible(child: Text(AppLocalizations.of(context)!.spendingSummary, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(AppLocalizations.of(context)!.totalOrders, '$_totalOrders', Icons.shopping_bag, theme),
            SizedBox(height: 2.h),
            _buildSummaryRow(AppLocalizations.of(context)!.totalSpent, '\$${_totalSpent.toStringAsFixed(2)}', Icons.attach_money, theme),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        SizedBox(width: 3.w),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Flexible(child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  List<Map<String, dynamic>> _getPreferenceItems() {
    return [
      {
        "icon": "dark_mode",
        "iconColor": Theme.of(context).colorScheme.onSurfaceVariant,
        "title": AppLocalizations.of(context)!.appTheme,
        "subtitle": _themeModeLabel(context),
        "trailing": Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final cs = Theme.of(context).colorScheme;
            return PopupMenuButton<ThemeMode>(
              tooltip: AppLocalizations.of(context)!.theme,
              initialValue: themeProvider.themeMode,
              onSelected: (mode) => themeProvider.setThemeMode(mode),
              itemBuilder: (context) => [
                PopupMenuItem(value: ThemeMode.system, child: Text(AppLocalizations.of(context)!.system, maxLines: 1, overflow: TextOverflow.ellipsis)),
                PopupMenuItem(value: ThemeMode.light, child: Text(AppLocalizations.of(context)!.light, maxLines: 1, overflow: TextOverflow.ellipsis)),
                PopupMenuItem(value: ThemeMode.dark, child: Text(AppLocalizations.of(context)!.dark, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Text(
                  _themeModeShortLabel(themeProvider.themeMode),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        return AppLocalizations.of(context)!.darkMode;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.lightMode;
    }
  }

  String _themeModeShortLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppLocalizations.of(context)!.system2;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.light2;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.dark2;
    }
  }

  List<Map<String, dynamic>> _getHelpItems() {
    return [
      {
        "icon": "phone",
        "iconColor": Colors.green,
        "title": AppLocalizations.of(context)!.customerSupport247,
        "subtitle": "+961 81-483570",
        "onTap": () => _launchPhone('+96181483570'),
      },
      {
        "icon": "chat",
        "iconColor": const Color(0xFF25D366),
        "title": AppLocalizations.of(context)!.whatsappSupport247,
        "subtitle": AppLocalizations.of(context)!.chatWithUsOnWhatsapp,
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
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLaunchPhoneDialer, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLaunchPhoneDialer, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final whatsappUri = Uri.parse('https://wa.me/${number.replaceAll('+', '')}');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsapp, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
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
        content: Text('$feature — coming soon!', maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Flexible(child: Text(AppLocalizations.of(context)!.signOut,
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.surface, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        title: Text(AppLocalizations.of(context)!.signOut, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo6, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(AppLocalizations.of(context)!.signOut, maxLines: 1, overflow: TextOverflow.ellipsis),
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
  // SETTINGS MENU — Share Profile & Export Data
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
                borderRadius: BorderRadius.circular(10)),
          ),
          SizedBox(height: 3.h),
          ListTile(
            leading: Icon(Icons.share, color: theme.colorScheme.primary),
            title: Text(AppLocalizations.of(context)!.shareProfile, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(AppLocalizations.of(context)!.inviteFriendsToKjDelivery, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(context);
              _shareProfile();
            },
          ),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.primary),
            title: Text(AppLocalizations.of(context)!.exportData, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(AppLocalizations.of(context)!.downloadYourOrderHistory, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(context);
              _exportOrderHistory();
            },
          ),
          SizedBox(height: 2.h),
        ]),
      ),
    );
  }

  // ============================================================
  // SHARE PROFILE — User's name + app download link
  // ============================================================

  void _shareProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.fullName ?? AppLocalizations.of(context)!.aFriend;

    final shareText = '$userName invites you to try KJ Delivery! '
        'Get fresh groceries and meals delivered to your door in Lebanon. '
        'Download now: https://play.google.com/store/apps/details?id=com.kjdelivery.app';

    try {
      await SharePlus.instance.share(
        ShareParams(text: shareText),
      );
    } catch (e) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.inviteLinkCopiedToClipboard, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ============================================================
  // EXPORT DATA — Order history as CSV file
  // ============================================================

  Future<void> _exportOrderHistory() async {
    final theme = Theme.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          SizedBox(width: 5.w),
          Flexible(child: Text(AppLocalizations.of(context)!.exportingOrderHistory, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Fetch all orders
      final ordersData = await SupabaseService.client
          .from('orders')
          .select('id, order_number, status, total, delivery_fee, subtotal, delivery_address, created_at, updated_at')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      final orders = ordersData as List;

      if (orders.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noOrdersToExport, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Build CSV
      final buffer = StringBuffer();
      buffer.writeln('Order Number,Status,Subtotal,Delivery Fee,Total,Address,Date');

      for (final order in orders) {
        final orderNum = order['order_number'] ?? order['id'] ?? '';
        final status = order['status'] ?? '';
        final subtotal = (order['subtotal'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final deliveryFee = (order['delivery_fee'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final total = (order['total'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final address = (order['delivery_address'] as String? ?? '').replaceAll(',', ';');
        final createdAt = order['created_at'] ?? '';

        buffer.writeln('$orderNum,$status,\$$subtotal,\$$deliveryFee,\$$total,"$address",$createdAt');
      }

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kj_delivery_orders.csv');
      await file.writeAsString(buffer.toString());

      if (mounted) Navigator.pop(context); // Close loading dialog

      // Share the file
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: AppLocalizations.of(context)!.kjDeliveryOrderHistory,
          ),
        );
      } catch (e) {
        // Fallback: show success with file path
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${orders.length} orders to ${file.path}', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
    }
  }
}