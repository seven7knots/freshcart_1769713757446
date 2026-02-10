import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Reviews section — currently a placeholder since reviews aren't in the DB yet.
/// Shows a "Write a Review" button and a message that reviews are coming soon.
/// When a reviews table is added, this can be wired to real data.
class ProductReviewsSection extends StatelessWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 2.h),
      Text('Customer Reviews', style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      SizedBox(height: 2.h),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(Icons.rate_review_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: 1.5.h),
          Text('No reviews yet', style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          SizedBox(height: 0.5.h),
          Text('Be the first to review this product',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reviews feature coming soon!')));
              },
              icon: const Icon(Icons.edit),
              label: const Text('Write a Review'),
            ),
          ),
        ]),
      ),
      SizedBox(height: 2.h),
    ]);
  }
}