// ============================================================
// FILE: lib/presentation/home_screen/home_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_address_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/category_service.dart';
import '../../services/location_service.dart';
import '../../services/store_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_action_button.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import '../map_location_picker/map_location_picker_screen.dart';
import '../notifications_screen/notifications_screen.dart';
import './widgets/categories_widget.dart';
import './widgets/deals_of_day_widget.dart';
import './widgets/hero_banner_widget.dart';
import './widgets/quick_add_widget.dart';
import './widgets/recent_orders_widget.dart';
import './widgets/top_stores_widget.dart';
import '../../widgets/shimmer_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/generated/app_localizations.dart';

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
  String _currentLocation = "Tap to set location";
  bool _hasLocation = false;

  bool _showWave1 = false;
  bool _showWave2 = false;
  bool _showWave3 = false;
  bool _showAboveFold = false;

  final _locationService = LocationService();

  static DateTime? _lastHomeInitTime;
  static const _homeInitCooldown = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();

      if (_lastHomeInitTime != null &&
          now.difference(_lastHomeInitTime!) < _homeInitCooldown) {
        debugPrint('[HOME] initState SKIPPED — remount within cooldown');
        if (mounted) {
          setState(() {
            _showAboveFold = true;
            _showWave1 = true;
            _showWave2 = true;
            _showWave3 = true;
          });
        }
        _loadLocalUserInfo();
        return;
      }

      _lastHomeInitTime = now;
      debugPrint('[HOME] initState — first mount, loading data');
      _loadInitialData();
      _initNotifications();
      _startStaggeredLoad();
    });
    AnalyticsService.logScreenView(screenName: 'home_screen');
  }

  void _startStaggeredLoad() {
    // Above-the-fold widgets (HeroBanner, Categories) mount first,
    // then waves follow — spreads init across frames to prevent jank.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showAboveFold = true);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showWave1 = true);
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showWave2 = true);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showWave3 = true);
    });
  }

  void _initNotifications() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final notifProvider = provider.Provider.of<NotificationsProvider>(
        context,
        listen: false,
      );
      notifProvider.initialize(user.id);
    }
  }

  Future<void> _loadLocalUserInfo() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userName = user.email?.split('@')[0] ?? "Guest";
        });
      }

      final cachedAddr = await _locationService.getCachedAddress();
      if (cachedAddr != null && mounted) {
        setState(() {
          _currentLocation = cachedAddr.address;
          _hasLocation = true;
        });
      }
    } catch (e) { debugPrint('[HOME_SCREEN] Silent error: $e'); }
  }

  Future<void> _loadInitialData() async {
    await _loadLocalUserInfo();
    // Pre-warm service caches before waves mount.
    // CategoryService and StoreService deduplicate in-flight requests,
    // so when each widget fires its own fetch it hits the cache
    // and resolves instantly instead of waiting on a cold network call.
    CategoryService.getTopLevelCategories().ignore();
    StoreService.getAllStores(activeOnly: true, excludeDemo: true).ignore();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();

    CategoryService.clearCache();
    StoreService.clearCache();

    ref.read(cartNotifierProvider.notifier).loadCart();

    ref.invalidate(featuredProductsProvider);
    ref.invalidate(allStoresProvider);
    ref.invalidate(featuredStoresProvider);

    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final notifProvider = provider.Provider.of<NotificationsProvider>(
        context,
        listen: false,
      );
      await notifProvider.fetchNotifications(user.id);
    }

    _lastHomeInitTime = null;

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.contentRefreshed, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(height: 2.h),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(AppLocalizations.of(context)!.createCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateEditor(contentType: 'category');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(AppLocalizations.of(context)!.createAd, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, AppRoutes.adminAdsManagement);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: Text(AppLocalizations.of(context)!.createStore, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateEditor(contentType: 'store');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(AppLocalizations.of(context)!.createProduct, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.created, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final theme = Theme.of(context);
    final barFg =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverOverlapAbsorber(
            handle:
                NestedScrollView.sliverOverlapAbsorberHandleFor(context),
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
              backgroundColor: theme.appBarTheme.backgroundColor,
              foregroundColor: barFg,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 2,
              shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
              actions: [
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
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.adminDashboard,
                              );
                            },
                            tooltip: AppLocalizations.of(context)!.adminDashboard,
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.search_rounded, color: barFg),
                  onPressed: () => AppRoutes.switchToTab(context, 1),
                  tooltip: AppLocalizations.of(context)!.searchProducts,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart_outlined, color: barFg),
                        onPressed: () => AppRoutes.openCart(context),
                        tooltip: AppLocalizations.of(context)!.shoppingCart,
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.kjRed,
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
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                    ],
                  ),
                ),
                provider.Consumer<NotificationsProvider>(
                  builder: (context, notifProvider, child) {
                    final unreadCount = notifProvider.unreadCount;
                    return Stack(
                      children: [
                        IconButton(
                          icon: CustomIconWidget(
                            iconName: 'notifications_outlined',
                            color: barFg,
                            size: 6.w,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen()),
                            );
                          },
                          tooltip: AppLocalizations.of(context)!.notifications,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.kjRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ];
      },
      body: _buildMainContent(bottomPadding),
    );
  }

  Widget _buildMainContent(double bottomPadding) {
    return Builder(
      builder: (BuildContext context) {
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context),
              ),
              SliverToBoxAdapter(child: _buildStickyHeader()),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    provider.Consumer2<AuthProvider, AdminProvider>(
                      builder:
                          (context, authProvider, adminProvider, child) {
                        if (!adminProvider.isAdmin)
                          return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          color: Colors.orange.withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 2.w),
                              Flexible(child: Text(AppLocalizations.of(context)!.adminMode,
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const Spacer(),
                              AdminActionButton(
                                  icon: Icons.edit,
                                  label: AppLocalizations.of(context)!.edit,
                                  isCompact: true,
                                  onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.adminEditOverlaySystem)),
                              AdminActionButton(
                                  icon: Icons.add,
                                  label: AppLocalizations.of(context)!.create,
                                  isCompact: true,
                                  onPressed: _openAdminCreateSheet),
                            ],
                          ),
                        );
                      },
                    ),

                    // ABOVE THE FOLD — deferred to spread init across frames
                    if (_showAboveFold) ...[
                      const HeroBannerWidget(),
                      const CategoriesWidget(),
                    ] else ...[
                      const ShimmerHeroBanner(),
                      const ShimmerCategoriesRow(),
                    ],

                    // WAVE 1
                    if (_showWave1)
                      const TopStoresWidget()
                    else
                      const ShimmerProductRow(),

                    // WAVE 2
                    if (_showWave2) ...[
                      const QuickAddWidget(),
                      const DealsOfDayWidget(),
                    ] else if (_showWave1)
                      const ShimmerProductRow(),

                    // WAVE 3
                    if (_showWave3)
                      const RecentOrdersWidget()
                    else if (_showWave2)
                      SizedBox(height: 10.h),

                    SizedBox(height: bottomPadding),
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      _userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              GestureDetector(
                onTap: () => AppRoutes.switchToTab(context, 4),
                child: Container(
                  width: 11.w,
                  height: 11.w,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: theme.colorScheme.primary, width: 2)),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: _buildProfileAvatar()),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          GestureDetector(
            onTap: _showLocationSelector,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        theme.colorScheme.outline.withOpacity(0.2),
                    width: 1),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                      iconName: 'location_on',
                      color: theme.colorScheme.primary,
                      size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.deliverTo2,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          _currentLocation,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_hasLocation)
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 4.w)
                  else
                    CustomIconWidget(
                        iconName: 'keyboard_arrow_down',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 5.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: false);
    final avatarUrl = authProvider.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: 
        avatarUrl,
        fit: BoxFit.cover,
        width: 11.w,
        height: 11.w,
        errorWidget: (_, __, ___) => _defaultHomeAvatar(),
      );
    }
    return _defaultHomeAvatar();
  }

  Widget _defaultHomeAvatar() {
    final initial =
        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Container(
      width: 11.w,
      height: 11.w,
      color:
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
              fontSize: 5.w,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  // FIX: hardcoded white, isScrollControlled + ConstrainedBox cap,
  // Flexible ListView for saved addresses, bottomInset padding
  void _showLocationSelector() async {
    final savedAddresses = await _locationService.loadSavedAddresses();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset =
            MediaQuery.of(sheetContext).padding.bottom;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.selectDeliveryLocation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.5.h),

                // Pick on Map
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.kjRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map,
                        color: AppTheme.kjRed, size: 6.w),
                  ),
                  title: Text(AppLocalizations.of(context)!.pickOnMap,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      AppLocalizations.of(context)!.searchOrTapToSelectLocation2,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result =
                        await Navigator.push<UserAddress>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UniversalMapPickerScreen(
                                mode: MapPickerMode.delivery),
                      ),
                    );
                    if (result != null && mounted) {
                      await _locationService
                          .cacheSelectedAddress(result);
                      await _locationService.addAddress(
                          result.copyWith(label: AppLocalizations.of(context)!.recent));
                      setState(() {
                        _currentLocation = result.address;
                        _hasLocation = true;
                      });
                    }
                  },
                ),

                // Use Current Location
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.my_location,
                        color: Colors.blue, size: 6.w),
                  ),
                  title: Text(AppLocalizations.of(context)!.useCurrentLocation,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(AppLocalizations.of(context)!.detectAutomatically,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final position = await _locationService
                        .getCurrentPosition();
                    if (position == null && mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                              content: Text(
                                  AppLocalizations.of(context)!.couldNotGetLocationPleaseEnable, maxLines: 1, overflow: TextOverflow.ellipsis),
                              backgroundColor: Colors.orange));
                      return;
                    }
                    if (position != null && mounted) {
                      final address =
                          await _locationService.reverseGeocode(
                              position.latitude,
                              position.longitude);
                      final userAddr = UserAddress(
                          address: address,
                          lat: position.latitude,
                          lng: position.longitude,
                          label: AppLocalizations.of(context)!.gps);
                      await _locationService
                          .cacheSelectedAddress(userAddr);
                      setState(() {
                        _currentLocation = address;
                        _hasLocation = true;
                      });
                    }
                  },
                ),

                // Saved addresses — Flexible prevents overflow
                if (savedAddresses.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Divider(color: Colors.grey.shade200),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Text(
                        AppLocalizations.of(context)!.savedAddresses,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: savedAddresses.length,
                      itemBuilder: (_, index) {
                        final addr = savedAddresses[index];
                        final isSelected =
                            _currentLocation == addr.address;
                        return ListTile(
                          leading: Icon(
                            addr.label == 'WORK'
                                ? Icons.work
                                : addr.label == 'HOME'
                                    ? Icons.home
                                    : Icons.location_on,
                            color: AppTheme.kjRed,
                            size: 6.w,
                          ),
                          title: Text(addr.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(addr.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _locationService
                                .cacheSelectedAddress(addr);
                            setState(() {
                              _currentLocation = addr.address;
                              _hasLocation = true;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],

                // Safe area bottom padding — eliminates overflow
                SizedBox(height: 2.h + bottomInset),
              ],
            ),
          ),
        );
      },
    );
  }
}