import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Customer Rating',
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Row(children: [
          Text(rating.toStringAsFixed(1),
              style: TextStyle(color: cs.onSurface, fontSize: 32.sp, fontWeight: FontWeight.bold)),
          SizedBox(width: 3.w),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStarRating(rating),
            SizedBox(height: 0.5.h),
            Text(
              totalRatings > 0 ? 'Based on $totalRatings ratings' : 'No ratings yet',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp),
            ),
          ]),
        ]),
        SizedBox(height: 2.h),
        _buildRatingBar(context, 5, 0.8),
        SizedBox(height: 1.h),
        _buildRatingBar(context, 4, 0.15),
        SizedBox(height: 1.h),
        _buildRatingBar(context, 3, 0.03),
        SizedBox(height: 1.h),
        _buildRatingBar(context, 2, 0.01),
        SizedBox(height: 1.h),
        _buildRatingBar(context, 1, 0.01),
      ]),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 5.w);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: 5.w);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 5.w);
        }
      }),
    );
  }

  Widget _buildRatingBar(BuildContext context, int stars, double percentage) {
    final cs = Theme.of(context).colorScheme;

    return Row(children: [
      Text('$stars', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.sp)),
      SizedBox(width: 2.w),
      Icon(Icons.star, color: Colors.amber, size: 3.w),
      SizedBox(width: 2.w),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: cs.outline.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 1.h,
          ),
        ),
      ),
      SizedBox(width: 2.w),
      Text('${(percentage * 100).toInt()}%',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp)),
    ]);
  }
}