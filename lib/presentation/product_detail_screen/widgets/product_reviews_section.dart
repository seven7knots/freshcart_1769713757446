import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductReviewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final double averageRating;
  final int totalReviews;

  const ProductReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingSummary(),
        SizedBox(height: 2.h),
        _buildRatingDistribution(),
        SizedBox(height: 3.h),
        _buildReviewsList(),
        SizedBox(height: 2.h),
        _buildWriteReviewButton(context),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Row(
      children: [
        Text(
          averageRating.toStringAsFixed(1),
          style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 2.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return CustomIconWidget(
                  iconName: index < averageRating.floor()
                      ? 'star'
                      : index < averageRating
                          ? 'star_half'
                          : 'star_border',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 16,
                );
              }),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Based on $totalReviews reviews',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final Map<int, int> distribution = {};
    for (int i = 1; i <= 5; i++) {
      distribution[i] =
          reviews.where((review) => (review['rating'] as int) == i).length;
    }

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = distribution[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.5.h),
          child: Row(
            children: [
              Text(
                '$rating',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 1.w),
              CustomIconWidget(
                iconName: 'star',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 14,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Container(
                  height: 1.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '$count',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewsList() {
    final displayReviews = reviews.take(3).toList();

    return Column(
      children:
          displayReviews.map((review) => _buildReviewCard(review)).toList(),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 5.w,
                child: CustomImageWidget(
                  imageUrl: review['userAvatar'] as String,
                  width: 10.w,
                  height: 10.w,
                  fit: BoxFit.cover,
                  semanticLabel: review['userAvatarSemanticLabel'] as String,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] as String,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return CustomIconWidget(
                              iconName: index < (review['rating'] as int)
                                  ? 'star'
                                  : 'star_border',
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              size: 14,
                            );
                          }),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          review['date'] as String,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
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
          Text(
            review['comment'] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildHelpfulButton(review['helpfulCount'] as int, true),
              SizedBox(width: 2.w),
              _buildHelpfulButton(review['notHelpfulCount'] as int, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulButton(int count, bool isHelpful) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isHelpful ? 'thumb_up' : 'thumb_down',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 14,
          ),
          SizedBox(width: 1.w),
          Text(
            isHelpful ? 'Helpful ($count)' : 'Not helpful ($count)',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // Navigate to write review screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Write review feature coming soon!'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
          );
        },
        child: Text('Write a Review'),
      ),
    );
  }
}
