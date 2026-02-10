import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_action_button.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import './widgets/categories_widget.dart';
import './widgets/deals_of_day_widget.dart';
import './widgets/featured_categories_widget.dart';
import './widgets/hero_banner_widget.dart';
import './widgets/quick_add_widget.dart';
import './widgets/recent_orders_widget.dart';
import './widgets/top_stores_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  String _userName = "Guest";
  String _currentLocation = "Downtown, Seattle";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    AnalyticsService.logScreenView(screenName: 'home_screen');
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.email?.split('@')[0] ?? "Guest";
        });
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(cartItemCountProvider);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAdminCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Create Category'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateEditor(contentType: 'category');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('Create Ad'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.adminAdsManagement);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: const Text('Create Store'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateEditor(contentType: 'store');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Create Product'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateEditor(contentType: 'product');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCreateEditor({
    required String contentType,
    Map<String, dynamic>? contentData,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: contentType,
        contentId: null,
        contentData: contentData,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Created')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCountAsync = ref.watch(cartItemCountProvider);
    final cartItemCount = cartCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                title: null,
                leading: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(),
                ),
                automaticallyImplyLeading: false,
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                actions: [
                  // Admin badge + button
                  provider.Consumer2<AuthProvider, AdminProvider>(
                    builder: (context, authProvider, adminProvider, child) {
                      if (adminProvider.isAdmin) {
                        return Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.adminLandingDashboard,
                                );
                              },
                              tooltip: 'Admin Dashboard',
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Marketplace icon
                  IconButton(
                    icon: Icon(Icons.store, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.marketplaceScreen);
                    },
                    tooltip: 'Marketplace',
                  ),
                  // Search icon
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface),
                    onPressed: () => AppRoutes.switchToTab(context, 1),
                    tooltip: 'Search products',
                  ),
                  // Cart icon with RED badge — opens as standalone push
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shopping_cart_outlined,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => AppRoutes.openCart(context),
                          tooltip: 'Shopping cart',
                        ),
                        if (cartItemCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.kjRed, // Red badge
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                cartItemCount > 99
                                    ? '99+'
                                    : cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Notifications
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'notifications_outlined',
                      color: theme.colorScheme.onSurface,
                      size: 6.w,
                    ),
                    onPressed: _showNotifications,
                    tooltip: 'Notifications',
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      ),
      floatingActionButton: _buildFloatingSearchButton(),
    );
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
            'Loading fresh deals...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(child: _buildStickyHeader()),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Admin mode bar
                    provider.Consumer2<AuthProvider, AdminProvider>(
                      builder: (context, authProvider, adminProvider, child) {
                        if (!adminProvider.isAdmin) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          color: Colors.orange.withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Admin Mode',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Spacer(),
                              AdminActionButton(
                                icon: Icons.edit,
                                label: 'Edit',
                                isCompact: true,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.adminEditOverlaySystem,
                                  );
                                },
                              ),
                              AdminActionButton(
                                icon: Icons.add,
                                label: 'Create',
                                isCompact: true,
                                onPressed: _openAdminCreateSheet,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const HeroBannerWidget(),
                    const CategoriesWidget(),
                    const TopStoresWidget(),
                    const QuickAddWidget(),
                    const FeaturedCategoriesWidget(),
                    const DealsOfDayWidget(),
                    const RecentOrdersWidget(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickyHeader() {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => AppRoutes.switchToTab(context, 4),
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: CustomImageWidget(
                        imageUrl:
                            "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=200",
                        fit: BoxFit.cover,
                        semanticLabel:
                            "Profile photo of a woman with shoulder-length brown hair smiling at camera",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: _showLocationSelector,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: theme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deliver to',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _currentLocation,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 5.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingSearchButton() {
    final theme = Theme.of(context);
    return theme.platform == TargetPlatform.android
        ? FloatingActionButton(
            onPressed: () => AppRoutes.switchToTab(context, 1),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            child: CustomIconWidget(
              iconName: 'search',
              color: Colors.white,
              size: 6.w,
            ),
          )
        : null;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showNotifications() {
    final theme = Theme.of(context);
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'local_shipping',
                color: theme.colorScheme.secondary,
                size: 6.w,
              ),
              title: const Text('Order #FG2024-003 is out for delivery'),
              subtitle: const Text('Expected delivery: 2:30 PM'),
              trailing: Text('5 min ago', style: theme.textTheme.bodySmall),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'local_offer',
                color: theme.colorScheme.tertiary,
                size: 6.w,
              ),
              title: const Text('Flash Sale: 50% off organic fruits'),
              subtitle: const Text('Limited time offer ends in 2 hours'),
              trailing: Text('1 hour ago', style: theme.textTheme.bodySmall),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showLocationSelector() {
    final theme = Theme.of(context);
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Delivery Location',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'my_location',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              title: const Text('Use Current Location'),
              subtitle: const Text('We\'ll detect your location automatically'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentLocation = "Current Location");
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'home',
                color: theme.colorScheme.secondary,
                size: 6.w,
              ),
              title: const Text('Home'),
              subtitle: const Text('Downtown, Seattle'),
              trailing: _currentLocation == "Downtown, Seattle"
                  ? CustomIconWidget(
                      iconName: 'check_circle',
                      color: theme.colorScheme.primary,
                      size: 5.w,
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentLocation = "Downtown, Seattle");
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'work',
                color: theme.colorScheme.tertiary,
                size: 6.w,
              ),
              title: const Text('Office'),
              subtitle: const Text('Bellevue, WA'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentLocation = "Bellevue, WA");
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 20.h;

  @override
  double get maxExtent => 20.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}