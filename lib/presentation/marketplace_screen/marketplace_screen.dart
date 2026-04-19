// ============================================================
// FILE: lib/presentation/marketplace_screen/marketplace_screen.dart
// ============================================================
// SESSION 28 FIX:
// - resizeToAvoidBottomInset: false on Scaffold prevents the
//   "BOTTOM OVERFLOWED BY 139 PIXELS" error when keyboard opens
//   (the keyboard was pushing up the fixed Column layout)
// - No other logic changes — all existing features preserved
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerStatefulWidget, ConsumerState;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/marketplace_listing_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../widgets/admin_action_button.dart';
import '../marketplace_admin_screen/marketplace_admin_screen.dart';
import '../marketplace_home_screen/widgets/marketplace_location_picker.dart';
import './widgets/marketplace_ad_box_widget.dart';
import './widgets/marketplace_bottom_nav_widget.dart';
import './widgets/marketplace_category_icons_widget.dart';
import './widgets/marketplace_listings_feed_widget.dart';
import './widgets/marketplace_search_bar_widget.dart';
import './widgets/marketplace_top_bar_widget.dart';
import '../../l10n/generated/app_localizations.dart';

final _marketplaceHomeFeedProvider = riverpod.FutureProvider.autoDispose<
    List<MarketplaceListingModel>>((ref) async {
  final service = ref.watch(marketplaceServiceProvider);

  final locationLat = ref.watch(marketplaceLocationLatProvider);
  final locationLng = ref.watch(marketplaceLocationLngProvider);
  final locationCity = ref.watch(marketplaceLocationCityProvider);

  return service.getListings(
    locationLat: locationLat,
    locationLng: locationLng,
    locationCity: locationCity,
    radiusKm: 30,
  );
});

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  int _currentNavIndex = 0;

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
  }

  void _onNavIndexChanged(int index) {
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.chatListScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.createListingScreen)
            .then((result) {
          if (result == true) _refreshListings();
        });
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.myAdsScreen);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.marketplaceAccountScreen);
        break;
    }
  }

  void _refreshListings() {
    ref.invalidate(_marketplaceHomeFeedProvider);
  }

  Future<void> _openLocationPicker() async {
    HapticFeedback.lightImpact();

    final currentLat = ref.read(marketplaceLocationLatProvider);
    final currentLng = ref.read(marketplaceLocationLngProvider);

    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceLocationPicker(
          initialLocation: currentLat != null && currentLng != null
              ? LatLng(currentLat, currentLng)
              : null,
        ),
      ),
    );

    if (result != null) {
      ref.read(marketplaceLocationLatProvider.notifier).state = result.latitude;
      ref.read(marketplaceLocationLngProvider.notifier).state = result.longitude;
      ref.read(marketplaceLocationCityProvider.notifier).state = result.city;
      ref.read(marketplaceLocationAddressProvider.notifier).state =
          result.address;
      _refreshListings();
    }
  }

  void _clearLocation() {
    HapticFeedback.lightImpact();
    ref.read(marketplaceLocationCityProvider.notifier).state = null;
    ref.read(marketplaceLocationLatProvider.notifier).state = null;
    ref.read(marketplaceLocationLngProvider.notifier).state = null;
    ref.read(marketplaceLocationAddressProvider.notifier).state = 'All Lebanon';
    _refreshListings();
  }

  List<MarketplaceListingModel> _applyFilters(
      List<MarketplaceListingModel> listings) {
    var filtered = listings;

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered =
          filtered.where((l) => l.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((l) {
        return l.title.toLowerCase().contains(q) ||
            (l.description?.toLowerCase().contains(q) ?? false) ||
            (l.locationText?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingsAsync = ref.watch(_marketplaceHomeFeedProvider);
    final locationAddress = ref.watch(marketplaceLocationAddressProvider);
    final hasCustomLocation =
        ref.watch(marketplaceLocationCityProvider) != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // SESSION 28 FIX: Prevent "BOTTOM OVERFLOWED BY 139 PIXELS".
      // The marketplace is a feed — keyboard should overlay it, not push it up.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            MarketplaceTopBarWidget(
              selectedLocation: locationAddress,
              onLocationTap: _openLocationPicker,
              onClearLocation: _clearLocation,
              hasCustomLocation: hasCustomLocation,
            ),

            MarketplaceSearchBarWidget(onSearchChanged: _onSearchChanged),

            const MarketplaceAdBoxWidget(),

            // Admin controls
            provider.Consumer2<AuthProvider, AdminProvider>(
              builder: (context, authProvider, adminProvider, child) {
                if (!adminProvider.isAdmin) return const SizedBox.shrink();
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  color: Colors.orange.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 2.w),
                      Flexible(child: Text(
                        AppLocalizations.of(context)!.adminMode,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Spacer(),
                      AdminActionButton(
                        icon: Icons.settings,
                        label: AppLocalizations.of(context)!.manage,
                        isCompact: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MarketplaceAdminScreen(),
                            ),
                          );
                        },
                      ),
                      AdminActionButton(
                        icon: Icons.refresh,
                        label: AppLocalizations.of(context)!.refresh,
                        isCompact: true,
                        onPressed: _refreshListings,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Categories header
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.allCategories2,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.allCategoriesScreen),
                    child: Text(
                      AppLocalizations.of(context)!.seeAll2,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

            // Category icons
            MarketplaceCategoryIconsWidget(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),

            // Active filter chip if category selected
            if (_selectedCategory != null)
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 0),
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        size: 4.w,
                        color: Colors.grey),
                    SizedBox(width: 1.w),
                    Flexible(child: Text(
                      AppLocalizations.of(context)!.filtered,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: () => _onCategorySelected(null),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close,
                                size: 3.w,
                                color: theme.colorScheme.onErrorContainer),
                            SizedBox(width: 1.w),
                            Text(
                              AppLocalizations.of(context)!.clearFilter,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Listings count row
            listingsAsync.whenData((listings) {
              final filtered = _applyFilters(listings);
              return Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.3.h),
                child: Row(
                  children: [
                    Flexible(child: Text(
                      '${filtered.length} listing${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).value ??
                const SizedBox.shrink(),

            // Feed
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  final filtered = _applyFilters(listings);
                  if (filtered.isEmpty && hasCustomLocation) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 12.w, color: Colors.grey.shade400),
                            SizedBox(height: 2.h),
                            Text(
                              AppLocalizations.of(context)!.noListingsNearThisLocation,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 1.h),
                            Text(
                              AppLocalizations.of(context)!.tryExpandingYourSearchAreaOr2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 2.h),
                            ElevatedButton.icon(
                              onPressed: _clearLocation,
                              icon: const Icon(Icons.public),
                              label: Text(AppLocalizations.of(context)!.showAllLebanon, maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kjRed,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return MarketplaceListingsFeedWidget(
                    listings: filtered,
                    onRefresh: _refreshListings,
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 12.w, color: theme.colorScheme.error),
                        SizedBox(height: 2.h),
                        Text(
                          AppLocalizations.of(context)!.failedToLoadListings,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 1.h),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        ElevatedButton.icon(
                          onPressed: _refreshListings,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: _currentNavIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}