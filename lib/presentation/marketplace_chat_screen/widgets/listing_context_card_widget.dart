import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListingContextCardWidget extends StatelessWidget {
  final Map<String, dynamic> listing;

  const ListingContextCardWidget({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final title = listing['title'] as String? ?? 'Listing';
    final price = listing['price'] as num? ?? 0;
    final images = listing['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] as String? : null;
    final status = listing['status'] as String? ?? 'active';

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Listing image
          ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image, size: 6.w, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 15.w,
                    height: 15.w,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, size: 6.w, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 3.w),
          // Listing details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '\$$price',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE50914),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'active'
                        ? Colors.green[50]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    status == 'active' ? 'Available' : status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: status == 'active'
                          ? Colors.green[700]
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // View listing button
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 4.w),
            onPressed: () {
              // Navigate to listing detail
            },
          ),
        ],
      ),
    );
  }
}
