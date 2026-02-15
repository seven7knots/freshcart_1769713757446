// ============================================================
// FILE: lib/presentation/marketplace_screen/marketplace_screen.dart
// ============================================================
// Updated: Location dropdown replaced with Google Maps picker.
// Tapping location bar opens full-screen map.
// Listings filtered by proximity when location is selected.
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

/// A simple provider that fetches ALL active marketplace listings directly.
final _marketplaceHomeFeedProvider = riverpod.FutureProvider.autoDispose<
    List<MarketplaceListingModel>>((ref) async {
  final service = ref.watch(marketplaceServiceProvider);

  // Read location state from providers
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
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onNavIndexChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });

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

  /// Open the Google Maps location picker
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
      // Refresh listings with new location
      _refreshListings();
    }
  }

  /// Clear location filter back to "All Lebanon"
  void _clearLocation() {
    HapticFeedback.lightImpact();
    ref.read(marketplaceLocationCityProvider.notifier).state = null;
    ref.read(marketplaceLocationLatProvider.notifier).state = null;
    ref.read(marketplaceLocationLngProvider.notifier).state = null;
    ref.read(marketplaceLocationAddressProvider.notifier).state = 'All Lebanon';
    _refreshListings();
  }

  /// Filter listings by local search query and selected category
  List<MarketplaceListingModel> _applyFilters(
      List<MarketplaceListingModel> listings) {
    var filtered = listings;

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered =
          filtered.where((l) => l.category == _selectedCategory).toList();
    }

    // Search filter
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
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — now opens map picker on tap
            MarketplaceTopBarWidget(
              selectedLocation: locationAddress,
              onLocationTap: _openLocationPicker,
              onClearLocation: _clearLocation,
              hasCustomLocation: hasCustomLocation,
            ),

            // Search bar
            MarketplaceSearchBarWidget(onSearchChanged: _onSearchChanged),

            // Ad banner
            const MarketplaceAdBoxWidget(),

            // Admin controls
            provider.Consumer2<AuthProvider, AdminProvider>(
              builder: (context, authProvider, adminProvider, child) {
                if (adminProvider.isAdmin) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: Colors.orange, size: 20),
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
                          icon: Icons.settings,
                          label: 'Manage',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MarketplaceAdminScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 2.w),
                        AdminActionButton(
                          icon: Icons.refresh,
                          label: 'Refresh',
                          onPressed: _refreshListings,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Categories header + See all
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All categories',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, AppRoutes.allCategoriesScreen);
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category icons row
            MarketplaceCategoryIconsWidget(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),

            // Listings feed
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
                                size: 12.w, color: Colors.grey[400]),
                            SizedBox(height: 2.h),
                            Text(
                              'No listings near this location',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Try expanding your search area or browse all of Lebanon',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            ElevatedButton.icon(
                              onPressed: _clearLocation,
                              icon: const Icon(Icons.public),
                              label: const Text('Show All Lebanon'),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
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
                          'Failed to load listings',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        ElevatedButton.icon(
                          onPressed: _refreshListings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
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