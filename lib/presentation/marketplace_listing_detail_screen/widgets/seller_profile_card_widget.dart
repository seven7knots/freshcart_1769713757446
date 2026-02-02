import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_image_widget.dart';

class SellerProfileCardWidget extends StatelessWidget {
  final Map<String, dynamic> sellerProfile;
  final String listingUserId;

  const SellerProfileCardWidget({
    super.key,
    required this.sellerProfile,
    required this.listingUserId,
  });

  @override
  Widget build(BuildContext context) {
    final sellerName =
        sellerProfile['full_name'] as String? ?? 'Unknown Seller';
    final sellerImage = sellerProfile['profile_image_url'] as String?;
    final memberSince = sellerProfile['created_at'] as String?;

    DateTime? joinDate;
    if (memberSince != null) {
      try {
        joinDate = DateTime.parse(memberSince);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
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
          Text(
            'Seller Information',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              // Seller Avatar
              CircleAvatar(
                radius: 8.w,
                backgroundColor: Colors.grey[300],
                child: sellerImage != null
                    ? ClipOval(
                        child: CustomImageWidget(
                          imageUrl: sellerImage,
                          width: 16.w,
                          height: 16.w,
                          fit: BoxFit.cover,
                          semanticLabel: sellerName,
                        ),
                      )
                    : Icon(Icons.person, size: 8.w, color: Colors.grey[600]),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    if (joinDate != null)
                      Text(
                        'Member since ${_formatDate(joinDate)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 16, color: Colors.green[600]),
                        SizedBox(width: 1.w),
                        Text(
                          'Verified Seller',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // View All Listings Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to seller's listings
                Navigator.pushNamed(
                  context,
                  AppRoutes.marketplaceScreen,
                  arguments: {'sellerId': listingUserId},
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'View All Listings',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }
}
