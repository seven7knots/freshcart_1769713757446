// ============================================================
// FILE: lib/presentation/marketplace_screen/widgets/marketplace_listings_feed_widget.dart
// ============================================================
// SESSION 28 REDESIGN:
// - Switched from ListView to 2-column SliverGrid (OLX/Dubizzle style)
// - Cleaner card design: image top, price prominent, minimal metadata
// - Sold overlay on image instead of badge
// - Smooth favorite toggle with haptic
// - Overflow fix: uses CustomScrollView with SliverPadding
//
// SESSION 29 FIX:
// - Empty state Column wrapped in SingleChildScrollView to prevent
//   "BOTTOM OVERFLOWED BY 78 PIXELS" when keyboard is open and
//   0 results are returned from a search query.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../../models/marketplace_listing_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    HapticFeedback.lightImpact();
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
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '\$${price.toInt()}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.listings.isEmpty) {
      // SESSION 29 FIX: SingleChildScrollView prevents overflow when the
      // keyboard is open and this empty state is taller than available space.
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 4.h),
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_off,
                      size: 10.w, color: theme.disabledColor),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.noListingsFound,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  AppLocalizations.of(context)!.tryAdjustingYourSearchOrFilters2,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (widget.onRefresh != null) ...[
                  SizedBox(height: 2.h),
                  OutlinedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context)!.refresh, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      );
    }

    // SESSION 28 FIX: CustomScrollView with SliverGrid prevents overflow
    // when keyboard is open — unlike ListView which can't shrink
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh?.call(),
      color: AppTheme.kjRed,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                // Golden ratio-ish: enough height for image + 3 lines of text
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final listing = widget.listings[index];
                  return _buildListingCard(context, listing, theme);
                },
                childCount: widget.listings.length,
              ),
            ),
          ),
          // Bottom padding so last row isn't cut by nav bar
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
        ],
      ),
    );
  }

  Widget _buildListingCard(
      BuildContext context, MarketplaceListingModel listing, ThemeData theme) {
    final isFavorite = _favorites.contains(listing.id);
    final imageUrl = listing.images.isNotEmpty ? listing.images[0] : null;

    final card = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pushNamed(
          context,
          AppRoutes.marketplaceListingDetailScreen,
          arguments: listing.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: imageUrl != null
                        ? CustomImageWidget(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            semanticLabel: listing.title,
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            color:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 8.w,
                              color: theme.disabledColor,
                            ),
                          ),
                  ),

                  // Sold overlay
                  if (listing.isSold)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: Container(
                          color: Colors.black.withOpacity(0.55),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 3.w, vertical: 0.6.h),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'SOLD',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Negotiable badge (top-left)
                  if (listing.isNegotiable && !listing.isSold)
                    Positioned(
                      top: 1.w,
                      left: 1.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Nego',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),

                  // Favorite button (top-right)
                  Positioned(
                    top: 1.w,
                    right: 1.w,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(listing.id),
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppTheme.kjRed
                              : Colors.grey.shade500,
                          size: 4.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area ──
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.fromLTRB(2.w, 1.h, 2.w, 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price
                    Text(
                      _formatPrice(listing.price),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.kjRed,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),

                    // Location + time row
                    Row(
                      children: [
                        if (listing.locationText != null &&
                            listing.locationText!.isNotEmpty) ...[
                          Icon(Icons.location_on,
                              size: 3.w,
                              color: Colors.grey),
                          SizedBox(width: 0.5.w),
                          Expanded(
                            child: Text(
                              listing.locationText!,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        Flexible(child: Text(
                          _timeAgo(listing.createdAt),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

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