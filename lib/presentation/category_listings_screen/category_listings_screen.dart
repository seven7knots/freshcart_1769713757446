import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerStatefulWidget, ConsumerState;
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../models/marketplace_listing_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_action_button.dart';
import '../../widgets/custom_image_widget.dart';
import '../marketplace_screen/widgets/marketplace_search_bar_widget.dart';

/// Provider that fetches listings for a specific category string.
/// Using String as family key — stable equality, no Map identity issues.
final _categoryListingsProvider = riverpod.FutureProvider.autoDispose
    .family<List<MarketplaceListingModel>, String>((ref, category) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getListings(
    category: category == 'all' ? null : category,
  );
});

/// This screen is EXCLUSIVELY for marketplace listing categories.
class CategoryListingsScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryListingsScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryListingsScreen> createState() =>
      _CategoryListingsScreenState();
}

class _CategoryListingsScreenState
    extends ConsumerState<CategoryListingsScreen> {
  String _searchQuery = '';
  final Set<String> _favorites = {};

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  String _getMarketplaceCategoryName(String categoryId) {
    const names = <String, String>{
      'vehicles': 'Vehicles',
      'properties': 'Properties',
      'mobiles': 'Mobiles & Accessories',
      'electronics': 'Electronics & Appliances',
      'furniture': 'Furniture & Decor',
      'business': 'Businesses & Industrial',
      'pets': 'Pets',
      'kids': 'Kids & Babies',
      'sports': 'Sports & Equipment',
      'hobbies': 'Hobbies',
      'jobs': 'Jobs',
      'fashion': 'Fashion & Beauty',
      'services': 'Services',
      'all': 'All Listings',
    };
    return names[categoryId.toLowerCase()] ?? 'Marketplace';
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingsAsync = ref.watch(_categoryListingsProvider(widget.categoryId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getMarketplaceCategoryName(widget.categoryId),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          provider.Consumer2<AuthProvider, AdminProvider>(
            builder: (context, authProvider, adminProvider, child) {
              if (!adminProvider.isAdmin) return const SizedBox.shrink();
              return Row(
                children: [
                  AdminActionButton(
                    icon: Icons.add,
                    label: 'Add',
                    isCompact: true,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.createListingScreen)
                          .then((result) {
                        if (result == true) {
                          ref.invalidate(
                              _categoryListingsProvider(widget.categoryId));
                        }
                      });
                    },
                  ),
                  SizedBox(width: 2.w),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MarketplaceSearchBarWidget(onSearchChanged: _onSearchChanged),
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                var filtered = listings;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = listings.where((l) {
                    return l.title.toLowerCase().contains(q) ||
                        (l.description?.toLowerCase().contains(q) ?? false) ||
                        (l.locationText?.toLowerCase().contains(q) ?? false);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 60,
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(height: 2.h),
                        Text('No listings found',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant)),
                        SizedBox(height: 1.h),
                        Text('Try a different category or search term',
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        _categoryListingsProvider(widget.categoryId));
                  },
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final listing = filtered[index];
                      return _buildListingCard(context, listing, theme);
                    },
                  ),
                );
              },
              loading: () => Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: theme.colorScheme.error),
                    SizedBox(height: 2.h),
                    Text('Error loading listings',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant)),
                    SizedBox(height: 1.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(error.toString(),
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(
                          _categoryListingsProvider(widget.categoryId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(
      BuildContext context, MarketplaceListingModel listing, ThemeData theme) {
    final isFavorite = _favorites.contains(listing.id);
    final imageUrl = listing.images.isNotEmpty ? listing.images[0] : null;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.marketplaceListingDetailScreen,
          arguments: listing.id,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(3.w)),
                  child: imageUrl != null
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 20.h,
                          fit: BoxFit.cover,
                          semanticLabel: listing.title,
                        )
                      : Container(
                          width: double.infinity,
                          height: 20.h,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 12.w, color: theme.disabledColor),
                        ),
                ),
                // Favorite
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(listing.id),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                  ),
                ),
                // Sold badge
                if (listing.isSold)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text('SOLD',
                          style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                // Negotiable badge
                if (listing.isNegotiable && !listing.isSold)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text('Negotiable',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '\$${listing.price.toStringAsFixed(listing.price.truncateToDouble() == listing.price ? 0 : 2)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      if (listing.locationText != null &&
                          listing.locationText!.isNotEmpty) ...[
                        Icon(Icons.location_on,
                            size: 4.w,
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(
                            listing.locationText!,
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 3.w),
                      ],
                      if (listing.createdAt != null) ...[
                        Icon(Icons.access_time,
                            size: 4.w,
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: 1.w),
                        Text(
                          _timeAgo(listing.createdAt),
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  // Condition chip
                  if (listing.condition != null &&
                      listing.condition!.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text(
                        listing.condition!.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}