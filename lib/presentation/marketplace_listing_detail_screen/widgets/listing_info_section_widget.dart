import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/marketplace_listing_model.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class ListingInfoSectionWidget extends StatelessWidget {
  final MarketplaceListingModel listing;

  const ListingInfoSectionWidget({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Text(
            '\$${listing.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (listing.isNegotiable)
            Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Text(
                AppLocalizations.of(context)!.negotiable,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          SizedBox(height: 2.h),

          // Title
          Text(
            listing.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),

          // Category and Condition
          Row(
            children: [
              if (listing.category != null) ...[
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    listing.category!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 2.w),
              ],
              if (listing.condition != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getConditionColor(listing.condition!)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    listing.condition!.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _getConditionColor(listing.condition!),
                      fontWeight: FontWeight.w500,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          SizedBox(height: 2.h),

          // Description
          if (listing.description != null &&
              listing.description!.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.description,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              listing.description!,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
          ],

          // Location
          if (listing.locationText != null &&
              listing.locationText!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.grey),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    listing.locationText!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            SizedBox(height: 1.h),
          ],

          // Views and Inquiries
          Row(
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.grey.shade500),
              SizedBox(width: 1.w),
              Flexible(child: Text(
                '${listing.views} views',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 4.w),
              Icon(Icons.chat_bubble_outline,
                  size: 16, color: Colors.grey.shade500),
              SizedBox(width: 1.w),
              Flexible(child: Text(
                '${listing.inquiries} inquiries',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like_new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.deepOrange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}