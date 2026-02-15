// ============================================================
// FILE: lib/presentation/marketplace_home_screen/widgets/product_listings_widget.dart
// ============================================================
// Updated with location bar: search + map button replaces old city dropdown
// ============================================================

import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/marketplace_provider.dart';
import './marketplace_location_picker.dart';

// Define missing location providers
final marketplaceLocationAddressProvider = StateProvider<String>((ref) => 'All Lebanon');
final marketplaceLocationCityProvider = StateProvider<String?>((ref) => null);
final marketplaceLocationLatProvider = StateProvider<double?>((ref) => null);
final marketplaceLocationLngProvider = StateProvider<double?>((ref) => null);

class ProductListingsWidget extends ConsumerWidget {
  const ProductListingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final locationAddress = ref.watch(marketplaceLocationAddressProvider);
    final theme = Theme.of(context);

    final filters = {
      'category': selectedCategory,
      'condition': null,
      'limit': 50,
      'offset': 0,
    };
    final listingsAsync = ref.watch(listingsProvider(filters));

    final categories = [
      'electronics',
      'furniture',
      'clothing',
      'home',
      'vehicles',
      'sports',
      'books',
      'other',
    ];

    return Column(
      children: [
        // ========================================
        // LOCATION BAR — replaces old city dropdown
        // ========================================
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: InkWell(
            onTap: () => _openLocationPicker(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.kjRed, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      locationAddress,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.kjRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: AppTheme.kjRed, size: 16),
                        SizedBox(width: 1.w),
                        Text('Map', style: TextStyle(fontSize: 11.sp, color: AppTheme.kjRed, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  SizedBox(width: 1.w),
                  // Clear location filter
                  if (ref.watch(marketplaceLocationCityProvider) != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(marketplaceLocationCityProvider.notifier).state = null;
                        ref.read(marketplaceLocationLatProvider.notifier).state = null;
                        ref.read(marketplaceLocationLngProvider.notifier).state = null;
                        ref.read(marketplaceLocationAddressProvider.notifier).state = 'All Lebanon';
                      },
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Category chips
        SizedBox(
          height: 5.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            children: categories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(selectedCategoryProvider.notifier).state =
                        isSelected ? null : category;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.kjRed : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category[0].toUpperCase() + category.substring(1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 1.h),

        // Create listing button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createListingScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Listing'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 5.h),
              backgroundColor: AppTheme.kjRed,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 1.h),

        // Listings grid
        Expanded(
          child: listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text('No listings found',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey[600])),
                      SizedBox(height: 1.h),
                      Text(
                        ref.watch(marketplaceLocationCityProvider) != null
                            ? 'Try expanding your search area or clearing the location filter'
                            : selectedCategory != null
                                ? 'Try selecting a different category'
                                : 'Be the first to create a listing!',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      if (ref.watch(marketplaceLocationCityProvider) != null) ...[
                        SizedBox(height: 2.h),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(marketplaceLocationCityProvider.notifier).state = null;
                            ref.read(marketplaceLocationLatProvider.notifier).state = null;
                            ref.read(marketplaceLocationLngProvider.notifier).state = null;
                            ref.read(marketplaceLocationAddressProvider.notifier).state = 'All Lebanon';
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Show all locations'),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: EdgeInsets.all(4.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 2.h,
                  childAspectRatio: 0.65,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  final isOwnListing = listing.userId == currentUserId;
                  final imageUrl = listing.images.isNotEmpty
                      ? listing.images[0]
                      : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e';
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.marketplaceListingDetailScreen,
                      arguments: listing.id,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with location badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                                child: CustomImageWidget(
                                  imageUrl: imageUrl,
                                  height: 15.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  semanticLabel: listing.title,
                                ),
                              ),
                              // Negotiable badge
                              if (listing.isNegotiable)
                                Positioned(
                                  top: 1.h,
                                  left: 1.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Negotiable',
                                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              // Location text
                              if (listing.locationText != null && listing.locationText!.isNotEmpty)
                                Positioned(
                                  bottom: 0.5.h,
                                  right: 0.5.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white, size: 10),
                                        SizedBox(width: 0.5.w),
                                        Text(
                                          listing.locationText!.length > 15
                                              ? '${listing.locationText!.substring(0, 15)}...'
                                              : listing.locationText!,
                                          style: TextStyle(color: Colors.white, fontSize: 8.sp),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.all(2.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.title,
                                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  '\$${listing.price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.kjRed),
                                ),
                                SizedBox(height: 1.h),
                                if (!isOwnListing)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.marketplaceChatScreen, arguments: {
                                          'listingId': listing.id,
                                          'sellerId': listing.userId,
                                        });
                                      },
                                      icon: Icon(Icons.chat, size: 3.w),
                                      label: Text('Contact', style: TextStyle(fontSize: 10.sp)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.kjRed,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 1.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      SizedBox(height: 2.h),
                      Text('Error loading listings',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.red[700])),
                      SizedBox(height: 1.h),
                      Text(error.toString(),
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          textAlign: TextAlign.center),
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(listingsProvider(filters)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPEN LOCATION PICKER
  // ============================================================

  Future<void> _openLocationPicker(BuildContext context, WidgetRef ref) async {
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
      ref.read(marketplaceLocationAddressProvider.notifier).state = result.address;
    }
  }
}