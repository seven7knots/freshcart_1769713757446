import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/marketplace_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final filters = {'userId': currentUserId, 'limit': 50, 'offset': 0};
    final listingsAsync = ref.watch(listingsProvider(filters));

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Ads',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createListingScreen);
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
                  Icon(Icons.list_alt, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 2.h),
                  Text(
                    'No ads yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Create your first listing to get started',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createListingScreen,
                      );
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

          return ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                        child: CustomImageWidget(
                          imageUrl: imageUrl,
                          width: 25.w,
                          height: 12.h,
                          fit: BoxFit.cover,
                          semanticLabel: listing.title,
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
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(1.w),
                                    ),
                                    child: Text(
                                      listing.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: listing.isActive
                                            ? Colors.green[700]
                                            : Colors.grey[600],
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
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 4.w,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '${listing.views} views',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 4.w,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '${listing.inquiries} inquiries',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            // Navigate to edit screen
                          } else if (value == 'delete') {
                            // Show delete confirmation
                          } else if (value == 'toggle') {
                            // Toggle active status
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
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  listing.isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  listing.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              SizedBox(height: 2.h),
              Text(
                'Failed to load ads',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 1.h),
              TextButton(
                onPressed: () {
                  ref.invalidate(listingsProvider(filters));
                },
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
            Navigator.pushNamed(context, AppRoutes.marketplaceScreen);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen);
          } else if (index == 4) {
            Navigator.pushNamed(context, '/marketplace-account-screen');
          }
        },
      ),
    );
  }
}
