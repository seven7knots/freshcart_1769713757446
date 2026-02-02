import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_action_button.dart';
import '../../widgets/custom_image_widget.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';
import '../marketplace_screen/widgets/marketplace_search_bar_widget.dart';

class CategoryListingsScreen extends ConsumerStatefulWidget {
  const CategoryListingsScreen({super.key});

  @override
  ConsumerState<CategoryListingsScreen> createState() =>
      _CategoryListingsScreenState();
}

class _CategoryListingsScreenState
    extends ConsumerState<CategoryListingsScreen> {
  String _searchQuery = '';
  final Set<String> _favorites = {};

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
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

  String _getCategoryName(String categoryId) {
    final categoryNames = {
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
    };
    return categoryNames[categoryId] ?? 'Category';
  }

  @override
  Widget build(BuildContext context) {
    final categoryId =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'electronics';
    final filters = {'category': categoryId, 'limit': 50, 'offset': 0};
    final listingsAsync = ref.watch(listingsProvider(filters));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getCategoryName(categoryId),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Admin Controls (visible only to admin)
          provider.Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isAdmin) return const SizedBox.shrink();
              return Row(
                children: [
                  AdminActionButton(
                    icon: Icons.add,
                    label: 'Add',
                    isCompact: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Add new item to category')),
                      );
                    },
                  ),
                  AdminActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    isCompact: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit category')),
                      );
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
          MarketplaceSearchBarWidget(
            onSearchChanged: _onSearchChanged,
          ),
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                var filteredListings = listings;
                if (_searchQuery.isNotEmpty) {
                  filteredListings = listings.where((listing) {
                    return listing.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (filteredListings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 60,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        SizedBox(height: 2.h),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Try adjusting your search',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    final isFavorite = _favorites.contains(listing.id);
                    final imageUrl = listing.images.isNotEmpty
                        ? listing.images[0]
                        : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e';

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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(3.w),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .shadow
                                  .withValues(alpha: 0.05),
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
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(3.w),
                                  ),
                                  child: CustomImageWidget(
                                    imageUrl: imageUrl,
                                    width: double.infinity,
                                    height: 20.h,
                                    fit: BoxFit.cover,
                                    semanticLabel: listing.title,
                                  ),
                                ),
                                Positioned(
                                  top: 2.w,
                                  right: 2.w,
                                  child: GestureDetector(
                                    onTap: () => _toggleFavorite(listing.id),
                                    child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .shadow
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                        size: 5.w,
                                      ),
                                    ),
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
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    '\$${listing.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 4.w,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        listing.locationText ?? 'Lebanon',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
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
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: Theme.of(context).colorScheme.error),
                    SizedBox(height: 2.h),
                    Text(
                      'Error loading listings',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      error.toString(),
                      style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: 0,
        onIndexChanged: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.marketplaceScreen,
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen);
          } else if (index == 3) {
            Navigator.pushNamed(context, '/my-ads-screen');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/marketplace-account-screen');
          }
        },
      ),
    );
  }
}
