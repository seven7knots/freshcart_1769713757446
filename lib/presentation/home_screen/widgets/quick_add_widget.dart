// ============================================================
// FILE: lib/presentation/home_screen/widgets/quick_add_widget.dart
// ============================================================
// SESSION 24 FIX: Use shared featuredProductsProvider instead of
// calling ProductService.getFeaturedProducts() directly.
//
// CHANGES:
// 1. Removed _isLoading, _error, _products local state
// 2. Removed _loadQuickAddProducts() method
// 3. Now uses ref.watch(featuredProductsProvider) — same provider
//    that DealsOfDayWidget uses. One fetch, two widgets share it.
// 4. Refresh/admin callbacks use ref.invalidate() instead of
//    calling the service directly.
// 5. All cart logic, UI, admin edit mode UNCHANGED.
//
// SESSION 27 FIX:
// - Removed ref.invalidate(cartItemCountProvider) — it's now a
//   derived Provider<int> that auto-updates when cartNotifierProvider
//   changes. No manual invalidation needed.
//
// SESSION 38 FIX:
// - removeItem() and updateQuantity() are now properly awaited.
// - Replaced whenData() callbacks (fire-and-forget) with
//   valueOrNull pattern so errors are caught by the outer try/catch
//   and UI reverts correctly on failure.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/product_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/animated_press_button.dart';
import '../../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

class QuickAddWidget extends ConsumerStatefulWidget {
  const QuickAddWidget({super.key});

  @override
  ConsumerState<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends ConsumerState<QuickAddWidget> {
  final Map<String, int> _quantities = {};

  void _handleProductTap(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  Future<void> _addToCart(Product product, int newQuantity) async {
    final oldQuantity = _quantities[product.id] ?? 0;

    // Update local state immediately for responsive UI
    HapticFeedback.lightImpact();
    setState(() {
      if (newQuantity <= 0) {
        _quantities.remove(product.id);
      } else {
        _quantities[product.id] = newQuantity;
      }
    });

    try {
      final cartNotifier = ref.read(cartNotifierProvider.notifier);

      if (newQuantity > oldQuantity) {
        final delta = newQuantity - oldQuantity;
        await cartNotifier.addToCart(
          productId: product.id,
          quantity: delta,
        );
        debugPrint('[QUICK_ADD] Added $delta x ${product.name} to cart');
      } else if (newQuantity <= 0 && oldQuantity > 0) {
        final items = ref.read(cartNotifierProvider).valueOrNull ?? [];
        String? cartItemId;
        for (final item in items) {
          if ((item['product_id'] as String?) == product.id) {
            cartItemId = item['id'] as String?;
            break;
          }
        }
        if (cartItemId != null) {
          await cartNotifier.removeItem(cartItemId);
          debugPrint('[QUICK_ADD] Removed ${product.name} from cart');
        }
      } else if (newQuantity < oldQuantity && newQuantity > 0) {
        final items = ref.read(cartNotifierProvider).valueOrNull ?? [];
        String? cartItemId;
        for (final item in items) {
          if ((item['product_id'] as String?) == product.id) {
            cartItemId = item['id'] as String?;
            break;
          }
        }
        if (cartItemId != null) {
          await cartNotifier.updateQuantity(cartItemId, newQuantity);
          debugPrint('[QUICK_ADD] Updated ${product.name} qty to $newQuantity');
        }
      }

      // SESSION 27: No need to invalidate cartItemCountProvider —
      // it's now a derived provider that auto-updates when
      // cartNotifierProvider state changes via loadCart().
    } catch (e) {
      debugPrint('[QUICK_ADD] Error updating cart: $e');
      // Revert local state on error
      if (mounted) {
        setState(() {
          if (oldQuantity <= 0) {
            _quantities.remove(product.id);
          } else {
            _quantities[product.id] = oldQuantity;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cart: ${e.toString()}', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show success feedback
    if (!mounted) return;
    if (newQuantity > 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newQuantity > oldQuantity ? AppLocalizations.of(context)!.addedToCart : AppLocalizations.of(context)!.updatedCart, maxLines: 1, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.viewCart,
            onPressed: () => AppRoutes.openCart(context),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.removedFromCart, maxLines: 1, overflow: TextOverflow.ellipsis),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = legacy.Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    // SESSION 39: Use frequently purchased products (customer's order history)
    // Falls back to featured products if no purchase history
    final frequentAsync = ref.watch(frequentlyPurchasedProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.quickAdd,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Text(
                        AppLocalizations.of(context)!.yourFrequentlyPurchasedItems,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isEditMode)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.orange, size: 20),
                    ),
                    onPressed: () => _addNewProduct(context),
                    tooltip: AppLocalizations.of(context)!.addProduct,
                  ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),

          frequentAsync.when(
            loading: () => _buildLoadingState(),
            error: (_, __) => _buildErrorState(),
            data: (frequentProducts) {
              // If customer has purchase history, show those
              if (frequentProducts.isNotEmpty) {
                return _buildProductsList(frequentProducts, isEditMode);
              }
              // Otherwise fall back to featured products
              return featuredAsync.when(
                loading: () => _buildLoadingState(),
                error: (_, __) => _buildErrorState(),
                data: (featured) {
                  if (featured.isEmpty) return _buildEmptyState();
                  final capped = featured.length > 10 ? featured.sublist(0, 10) : featured;
                  return _buildProductsList(capped, isEditMode);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 34.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          width: 40.w,
          margin: EdgeInsets.only(right: 3.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(2.5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 25.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        height: 12,
                        width: 15.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 20.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 10.w, color: theme.colorScheme.error),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.failedToLoadProducts,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            TextButton.icon(
              onPressed: () => ref.invalidate(featuredProductsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 20.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 10.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.noProductsYet2,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Text(
              AppLocalizations.of(context)!.productsWillAppearHereOnceCreated,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(List<Product> products, bool isEditMode) {
    return SizedBox(
      height: 34.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final productCard = _buildQuickAddCard(product);

          if (isEditMode) {
            return AdminEditableItemWrapper(
              contentType: 'product',
              contentId: product.id,
              contentData: product.toMap(),
              onDeleted: () => ref.invalidate(featuredProductsProvider),
              onUpdated: () => ref.invalidate(featuredProductsProvider),
              child: productCard,
            );
          }

          return productCard;
        },
      ),
    );
  }

  void _addNewProduct(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ContentEditModalWidget(
        contentType: 'product',
        contentId: null,
        contentData: null,
        onSaved: () {
          ref.invalidate(featuredProductsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.productCreatedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickAddCard(Product product) {
    final isAvailable = product.canOrder;

    return AnimatedPressButton(
      onPressed: isAvailable ? () => _handleProductTap(product) : null,
      child: Container(
        width: 40.w,
        margin: EdgeInsets.only(right: 3.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImageWidget(
                        imageUrl: product.imageUrl ??
                            'https://images.unsplash.com/photo-1565804212260-280f967e431b',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: product.name,
                      ),
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withAlpha(128),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 3.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.error,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.isOutOfStock
                                      ? AppLocalizations.of(context)!.outOfStock2
                                      : AppLocalizations.of(context)!.unavailable2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ),
                        ),
                      if (product.isOnSale && isAvailable)
                        Positioned(
                          top: 1.h,
                          left: 2.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.3.h),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(2.5.w, 1.5.w, 2.5.w, 2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.storeName != null) ...[
                      SizedBox(height: 0.2.h),
                      Text(
                        product.storeName!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 10,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (product.isOnSale) ...[
                                Text(
                                  product.priceDisplay,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        decoration: TextDecoration
                                            .lineThrough,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 10,
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  product.salePriceDisplay!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ] else
                                Text(
                                  product.priceDisplay,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (isAvailable)
                          _buildQuantitySelector(product),
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
  }

  Widget _buildQuantitySelector(Product product) {
    final quantity = _quantities[product.id] ?? 0;

    return quantity == 0
        ? AnimatedPressButton(
            onPressed: () => _addToCart(product, 1),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add,
                      size: 14,
                      color:
                          Theme.of(context).colorScheme.onPrimary),
                  SizedBox(width: 1.w),
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.add2,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedPressButton(
                  onPressed: () =>
                      _addToCart(product, quantity - 1),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      quantity == 1
                          ? Icons.delete_outline
                          : Icons.remove,
                      size: 15,
                      color: quantity == 1
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 1.5.w),
                  child: Text(
                    quantity.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                AnimatedPressButton(
                  onPressed: () =>
                      _addToCart(product, quantity + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.add,
                      size: 15,
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}