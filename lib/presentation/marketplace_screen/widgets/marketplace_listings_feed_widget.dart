import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../../models/marketplace_listing_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/custom_image_widget.dart';

class MarketplaceListingsFeedWidget extends StatefulWidget {
  final List<MarketplaceListingModel> listings;
  final VoidCallback? onRefresh;

  const MarketplaceListingsFeedWidget({
    super.key,
    required this.listings,
    this.onRefresh,
  });

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

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatPrice(double price, String currency) {
    final priceStr = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return '\$$priceStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: theme.disabledColor),
            SizedBox(height: 2.h),
            Text(
              'No listings found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.onRefresh != null) ...[
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh?.call(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        itemCount: widget.listings.length,
        itemBuilder: (context, index) {
          final listing = widget.listings[index];
          return _buildListingCard(context, listing, theme);
        },
      ),
    );
  }

  Widget _buildListingCard(
      BuildContext context, MarketplaceListingModel listing, ThemeData theme) {
    final isFavorite = _favorites.contains(listing.id);
    final imageUrl =
        listing.images.isNotEmpty ? listing.images[0] : null;

    final card = GestureDetector(
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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(3.w)),
                  child: imageUrl != null
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 20.h,
                          fit: BoxFit.cover,
                          semanticLabel: listing.title,
                        )
                      : Container(
                          width: double.infinity,
                          height: 20.h,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 12.w,
                            color: theme.disabledColor,
                          ),
                        ),
                ),
                // Favorite button
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(listing.id),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                  ),
                ),
                // Sold badge
                if (listing.isSold)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text(
                        'SOLD',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Negotiable badge
                if (listing.isNegotiable && !listing.isSold)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text(
                        'Negotiable',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info section
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _formatPrice(listing.price, listing.currency),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      if (listing.locationText != null &&
                          listing.locationText!.isNotEmpty) ...[
                        Icon(
                          Icons.location_on,
                          size: 4.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(
                            listing.locationText!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 3.w),
                      ],
                      if (listing.createdAt != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 4.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _timeAgo(listing.createdAt),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Condition chip
                  if (listing.condition != null &&
                      listing.condition!.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Text(
                        listing.condition!.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with admin editable wrapper if admin
    return provider.Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isAdmin && adminProvider.isEditMode) {
          return AdminEditableItemWrapper(
            contentType: 'marketplace',
            contentId: listing.id,
            contentData: listing.toJson(),
            onUpdated: () => widget.onRefresh?.call(),
            onDeleted: () => widget.onRefresh?.call(),
            child: card,
          );
        }
        return card;
      },
    );
  }
}