import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class MarketplaceListingsFeedWidget extends StatefulWidget {
  final List<Map<String, dynamic>> listings;

  const MarketplaceListingsFeedWidget({super.key, required this.listings});

  @override
  State<MarketplaceListingsFeedWidget> createState() =>
      _MarketplaceListingsFeedWidgetState();
}

class _MarketplaceListingsFeedWidgetState
    extends State<MarketplaceListingsFeedWidget> {
  final Set<String> _favorites = {};

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No listings found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: widget.listings.length,
      itemBuilder: (context, index) {
        final listing = widget.listings[index];
        final isFavorite = _favorites.contains(listing['id']);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.marketplaceListingDetailScreen,
              arguments: listing['id'],
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
                        imageUrl: listing['image'] as String,
                        width: double.infinity,
                        height: 20.h,
                        fit: BoxFit.cover,
                        semanticLabel: listing['title'] as String,
                      ),
                    ),
                    Positioned(
                      top: 2.w,
                      right: 2.w,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(listing['id'] as String),
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.grey[600],
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
                        listing['title'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '\$${(listing['price'] as double).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 4.w,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            listing['location'] as String,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.access_time,
                            size: 4.w,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            listing['postedDate'] as String,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
