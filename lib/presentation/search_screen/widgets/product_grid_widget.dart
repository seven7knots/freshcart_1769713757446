// ============================================================
// FILE: lib/presentation/search_screen/widgets/product_grid_widget.dart
// ============================================================
// Product grid with HEART ICON on each card, wired to FavoritesProvider.
// Tapping the heart saves/removes from Supabase user_favorites.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/product_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/animated_press_button.dart';

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(Product)? onProductTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onAddToWishlist;
  final Function(Product)? onShare;

  const ProductGridWidget({
    super.key,
    required this.products,
    this.isLoading = false,
    this.onLoadMore,
    this.onProductTap,
    this.onAddToCart,
    this.onAddToWishlist,
    this.onShare,
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
        padding: EdgeInsets.all(4.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length + (isLoading ? 4 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return _buildSkeletonCard(context);
          }
          return _buildProductCard(context, products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);

    return AnimatedPressButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onProductTap?.call(product);
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showQuickActions(context, product);
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
              // Product image with heart overlay
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        CustomImageWidget(
                          imageUrl: product.imageUrl ??
                              'https://images.unsplash.com/photo-1565804212260-280f967e431b',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          semanticLabel: product.name,
                        ),
                        // Sale badge
                        if (product.isOnSale)
                          Positioned(
                            top: 1.h,
                            left: 1.h,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // ========================================
                        // HEART / FAVORITE ICON — TOP RIGHT
                        // ========================================
                        Positioned(
                          top: 0.5.h,
                          right: 0.5.h,
                          child: Consumer<FavoritesProvider>(
                            builder: (context, favProvider, _) {
                              final isFav = favProvider.isDeliveryFavorite(product.id);
                              return GestureDetector(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  await favProvider.toggleDeliveryFavorite(product.id);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Out of stock overlay
                        if (!product.canOrder)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    product.isOutOfStock
                                        ? 'Out of Stock'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      color: theme.colorScheme.onError,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Product details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        product.storeName ?? product.category ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.isOnSale) ...[
                                  Text(
                                    product.priceDisplay,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    product.salePriceDisplay!,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    product.priceDisplay,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (product.canOrder)
                            AnimatedPressButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onAddToCart?.call(product);
                              },
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'add',
                                  color: theme.colorScheme.onPrimary,
                                  size: 16,
                                ),
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

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 1.5.h,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 2.h,
                        width: 20.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
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
            CustomIconWidget(
              iconName: 'search_off',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'No products found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
        Text(
          'Popular Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: categories.map((category) {
            return AnimatedPressButton(
              onPressed: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showQuickActions(BuildContext context, Product product) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Favorite toggle in quick actions — also wired
            Consumer<FavoritesProvider>(
              builder: (context, favProvider, _) {
                final isFav = favProvider.isDeliveryFavorite(product.id);
                return ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                    await favProvider.toggleDeliveryFavorite(product.id);
                  },
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('View Similar'),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Share Product'),
              onTap: () {
                Navigator.pop(ctx);
                onShare?.call(product);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}