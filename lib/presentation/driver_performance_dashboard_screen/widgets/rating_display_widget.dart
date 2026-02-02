import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RatingDisplayWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Rating',
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(rating),
                  SizedBox(height: 0.5.h),
                  Text(
                    totalRatings > 0
                        ? 'Based on $totalRatings ratings'
                        : 'No ratings yet',
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildRatingBar(5, 0.8),
          SizedBox(height: 1.h),
          _buildRatingBar(4, 0.15),
          SizedBox(height: 1.h),
          _buildRatingBar(3, 0.03),
          SizedBox(height: 1.h),
          _buildRatingBar(2, 0.01),
          SizedBox(height: 1.h),
          _buildRatingBar(1, 0.01),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            color: Colors.amber,
            size: 5.w,
          );
        } else if (index < rating) {
          return Icon(
            Icons.star_half,
            color: Colors.amber,
            size: 5.w,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.amber,
            size: 5.w,
          );
        }
      }),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Builder(
      builder: (context) {
        return Row(
          children: [
            Text(
              '$stars',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 11.sp,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 3.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppTheme.borderDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 1.h,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 10.sp,
              ),
            ),
          ],
        );
      },
    );
  }
}
