import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:sizer/sizer.dart';

import '../../providers/marketplace_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Use the dedicated myListingsProvider — fetches only current user's listings
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Ads',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createListingScreen)
                  .then((result) {
                if (result == true) {
                  ref.invalidate(myListingsProvider);
                }
              });
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 60, color: theme.disabledColor),
                  SizedBox(height: 2.h),
                  Text(
                    'No ads yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Create your first listing to get started',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createListingScreen,
                      ).then((result) {
                        if (result == true) {
                          ref.invalidate(myListingsProvider);
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Listing'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.5.h,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myListingsProvider),
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                final imageUrl = listing.images.isNotEmpty
                    ? listing.images[0]
                    : null;

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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(3.w),
                          ),
                          child: imageUrl != null
                              ? CustomImageWidget(
                                  imageUrl: imageUrl,
                                  width: 25.w,
                                  height: 12.h,
                                  fit: BoxFit.cover,
                                  semanticLabel: listing.title,
                                )
                              : Container(
                                  width: 25.w,
                                  height: 12.h,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.image,
                                      size: 8.w, color: theme.disabledColor),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        listing.title,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: listing.isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(1.w),
                                      ),
                                      child: Text(
                                        listing.isSold
                                            ? 'Sold'
                                            : listing.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: listing.isSold
                                              ? Colors.orange
                                              : listing.isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  '\$${listing.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Icon(Icons.visibility,
                                        size: 4.w,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing.views} views',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Icon(Icons.chat_bubble_outline,
                                        size: 4.w,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing.inquiries} inquiries',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            final service = MarketplaceService();
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.marketplaceListingDetailScreen,
                                arguments: listing.id,
                              );
                            } else if (value == 'sold') {
                              await service.markAsSold(listing.id);
                              ref.invalidate(myListingsProvider);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Listing'),
                                  content: const Text(
                                      'Are you sure you want to delete this listing?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await service.deleteListing(listing.id);
                                ref.invalidate(myListingsProvider);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            if (!listing.isSold)
                              const PopupMenuItem(
                                value: 'sold',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 20, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Mark as Sold'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                'Failed to load ads',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              TextButton(
                onPressed: () => ref.invalidate(myListingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: 3,
        onIndexChanged: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.marketplaceScreen);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen)
                .then((result) {
              if (result == true) ref.invalidate(myListingsProvider);
            });
          } else if (index == 4) {
            Navigator.pushNamed(context, AppRoutes.marketplaceAccountScreen);
          }
        },
      ),
    );
  }
}