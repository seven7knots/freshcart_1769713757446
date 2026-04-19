// ============================================================
// FILE: lib/presentation/search_screen/widgets/product_grid_widget.dart
// ============================================================
// SESSION 33 FIX #9:
// - Each product card is now a StatefulWidget (_ProductCardItem)
// - Plus icon shows a quantity counter once tapped
// - Tapping + increments, tapping - decrements (removes at 0)
// - Each tap calls onAddToCart so CartNotifier stays in sync
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/product_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/animated_press_button.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(Product)? onProductTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onRemoveFromCart;
  final Function(Product)? onAddToWishlist;
  final Function(Product)? onShare;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ProductGridWidget({
    super.key,
    required this.products,
    this.isLoading = false,
    this.onLoadMore,
    this.onProductTap,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onAddToWishlist,
    this.onShare,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !isLoading) {
      return _buildEmptyState(context);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            !isLoading) {
          onLoadMore?.call();
        }
        return false;
      },
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: EdgeInsets.all(4.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 0.65,
        ),
        itemCount: products.length + (isLoading ? 4 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return _buildSkeletonCard(context);
          }
          return _ProductCardItem(
            product: products[index],
            onProductTap: onProductTap,
            onAddToCart: onAddToCart,
            onRemoveFromCart: onRemoveFromCart,
            onAddToWishlist: onAddToWishlist,
            onShare: onShare,
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 2.h, width: 80.w, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
                  SizedBox(height: 1.h),
                  Container(height: 1.5.h, width: 60.w, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 2.h, width: 20.w, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
                      Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: 'search_off', color: theme.colorScheme.onSurfaceVariant, size: 64),
            SizedBox(height: 3.h),
            Text(AppLocalizations.of(context)!.noProductsFound, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text('Try adjusting your search or filters to find what you\'re looking for', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            _buildPopularCategories(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCategories(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['Fruits', 'Vegetables', 'Dairy', 'Snacks', 'Beverages'];
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.popularCategories, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: categories.map((category) {
            return AnimatedPressButton(
              onPressed: () { HapticFeedback.lightImpact(); },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Text(category, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProductCardItem extends StatefulWidget {
  final Product product;
  final Function(Product)? onProductTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onRemoveFromCart;
  final Function(Product)? onAddToWishlist;
  final Function(Product)? onShare;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const _ProductCardItem({
    required this.product,
    this.onProductTap,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onAddToWishlist,
    this.onShare,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<_ProductCardItem> createState() => _ProductCardItemState();
}

class _ProductCardItemState extends State<_ProductCardItem> {
  int _quantity = 0;

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() => _quantity++);
    widget.onAddToCart?.call(widget.product);
  }

  void _decrement() {
    if (_quantity <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _quantity--);
    widget.onRemoveFromCart?.call(widget.product);
  }

  void _showQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12.w, height: 0.5.h, margin: EdgeInsets.symmetric(vertical: 2.h), decoration: BoxDecoration(color: theme.colorScheme.outline, borderRadius: BorderRadius.circular(14))),
            Consumer<FavoritesProvider>(
              builder: (context, favProvider, _) {
                final isFav = favProvider.isDeliveryFavorite(widget.product.id);
                return ListTile(
                  leading: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : theme.colorScheme.onSurface, size: 24),
                  title: Text(isFav ? AppLocalizations.of(context)!.removeFromFavorites2 : AppLocalizations.of(context)!.addToFavorites, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async { Navigator.pop(ctx); HapticFeedback.lightImpact(); await favProvider.toggleDeliveryFavorite(widget.product.id); },
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'visibility', color: theme.colorScheme.onSurface, size: 24),
              title: Text(AppLocalizations.of(context)!.viewSimilar, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'share', color: theme.colorScheme.onSurface, size: 24),
              title: Text(AppLocalizations.of(context)!.shareProduct, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () { Navigator.pop(ctx); widget.onShare?.call(widget.product); },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;

    return AnimatedPressButton(
      onPressed: () { HapticFeedback.lightImpact(); widget.onProductTap?.call(product); },
      child: GestureDetector(
        onLongPress: () { HapticFeedback.mediumImpact(); _showQuickActions(context); },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), color: theme.colorScheme.surfaceContainerHighest),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        CustomImageWidget(imageUrl: product.imageUrl ?? 'https://images.unsplash.com/photo-1565804212260-280f967e431b', width: double.infinity, height: double.infinity, fit: BoxFit.cover, semanticLabel: product.name),
                        if (product.isOnSale)
                          Positioned(
                            top: 1.h, left: 1.h,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
                              child: Text('-${product.discountPercent}%', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        Positioned(
                          top: 0.5.h, right: 0.5.h,
                          child: Consumer<FavoritesProvider>(
                            builder: (context, favProvider, _) {
                              final isFav = favProvider.isDeliveryFavorite(product.id);
                              return GestureDetector(
                                onTap: () async { HapticFeedback.lightImpact(); await favProvider.toggleDeliveryFavorite(product.id); },
                                child: Container(
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 18),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!product.canOrder)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
                                  child: Text(product.isOutOfStock ? AppLocalizations.of(context)!.outOfStock2 : AppLocalizations.of(context)!.unavailable2, style: TextStyle(color: theme.colorScheme.onError, fontSize: 10.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Text(product.storeName ?? product.category ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (product.isOnSale) ...[
                                  Text(product.priceDisplay, style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(product.salePriceDisplay!, style: theme.textTheme.titleSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ] else
                                  Text(product.priceDisplay, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (product.canOrder)
                            _quantity == 0
                                ? AnimatedPressButton(
                                    onPressed: _increment,
                                    child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                                      child: CustomIconWidget(iconName: 'add', color: theme.colorScheme.onPrimary, size: 16),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(onTap: _decrement, child: Padding(padding: EdgeInsets.all(1.5.w), child: Icon(Icons.remove, color: theme.colorScheme.onPrimary, size: 14))),
                                        Padding(padding: EdgeInsets.symmetric(horizontal: 1.w), child: Text('$_quantity', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        GestureDetector(onTap: _increment, child: Padding(padding: EdgeInsets.all(1.5.w), child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 14))),
                                      ],
                                    ),
                                  ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
