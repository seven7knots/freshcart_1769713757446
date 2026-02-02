import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../providers/marketplace_provider.dart';

class ProductListingsWidget extends ConsumerWidget {
  const ProductListingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
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
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = isSelected ? null : category,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category[0].toUpperCase() + category.substring(1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isSelected ? Colors.white : Colors.black87,
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.createListingScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Listing'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 5.h),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Expanded(
          child: listingsAsync.when(
            data: (listings) {
              print('📦 Displaying ${listings.length} listings');
              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No listings found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        selectedCategory != null
                            ? 'Try selecting a different category'
                            : 'Be the first to create a listing!',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
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
                        color: Colors.white,
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12.0),
                            ),
                            child: CustomImageWidget(
                              imageUrl: imageUrl,
                              height: 15.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              semanticLabel: listing.title,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(2.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.title,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  '\$${listing.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                // Contact Seller button
                                if (!isOwnListing)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.marketplaceChatScreen,
                                          arguments: {
                                            'listingId': listing.id,
                                            'sellerId': listing.userId,
                                          },
                                        );
                                      },
                                      icon: Icon(Icons.chat, size: 3.w),
                                      label: Text(
                                        'Contact',
                                        style: TextStyle(fontSize: 10.sp),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE50914),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 1.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(2.w),
                                        ),
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
              print('❌ Error in ProductListingsWidget: $error');
              print('Stack: $stack');
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Error loading listings',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
}
