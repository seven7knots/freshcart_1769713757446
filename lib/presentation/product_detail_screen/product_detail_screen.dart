// ============================================================
// FILE: lib/presentation/product_detail_screen/product_detail_screen.dart
// ============================================================
// Product detail with REAL favorites integration via FavoritesProvider.
// Heart icon now saves/removes from Supabase user_favorites table.
// FIX: Uses CartNotifier (via Riverpod) instead of DatabaseService.instance
//      directly, so the cart state stays in sync across screens.
// SESSION 20 FIX: All snackbars auto-dismiss properly (Issue 4)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import './widgets/expandable_section.dart';
import './widgets/product_info_section.dart';
import './widgets/quantity_selector.dart';
import './widgets/related_products_section.dart';
import '../../l10n/generated/app_localizations.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({super.key, this.product, this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isLoading = false;
  Product? _product;
  List<Product> _relatedProducts = [];
  String? _storeName;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _storeName = widget.product!.storeName;
      _loadRelatedProducts();
      if (_storeName == null) _loadStoreName();
    } else if (widget.productId != null) {
      _loadProduct(widget.productId!);
    }
  }

  Future<void> _loadProduct(String id) async {
    setState(() => _isLoading = true);
    try {
      final product = await ProductService.getProductById(id);
      if (mounted) {
        setState(() {
          _product = product;
          _storeName = product?.storeName;
          _isLoading = false;
        });
        if (product != null) {
          _loadRelatedProducts();
          if (_storeName == null) _loadStoreName();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStoreName() async {
    if (_product == null) return;
    try {
      final store = await StoreService.getStoreById(_product!.storeId);
      if (mounted && store != null) {
        setState(() => _storeName = store.name);
      }
    } catch (e) { debugPrint('[PRODUCT_DETAIL_SCREEN] Silent error: $e'); }
  }

  Future<void> _loadRelatedProducts() async {
    if (_product == null) return;
    try {
      final products = await ProductService.getProductsByStore(
        _product!.storeId,
        availableOnly: true,
        excludeDemo: true,
      );
      if (mounted) {
        setState(() {
          _relatedProducts = products.where((p) => p.id != _product!.id).take(6).toList();
        });
      }
    } catch (e) { debugPrint('[PRODUCT_DETAIL_SCREEN] Silent error: $e'); }
  }

  Future<void> _refreshProduct() async {
    if (_product == null) return;
    await _loadProduct(_product!.id);
  }

  bool _canManageProduct(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.isAdmin) return true;
    return false;
  }

  // ============================================================
  // SESSION 20 FIX: Centralized snackbar helper (Issue 4)
  // - Clears any existing snackbar before showing new one
  // - Uses floating behavior so it doesn't stick to scaffold
  // - Explicit 2-second duration for guaranteed auto-dismiss
  // ============================================================
  void _showSnackBar(String message, {Color? backgroundColor, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 2.h, left: 4.w, right: 4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: action,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                SizedBox(height: 2.h),
                Text(AppLocalizations.of(context)!.productNotFound, style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 2.h),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.goBack, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ])),
      );
    }

    final product = _product!;
    final canManage = _canManageProduct(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Image App Bar
          SliverAppBar(
            expandedHeight: 35.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(product, theme),
            ),
            actions: [
              // ========================================
              // FAVORITE BUTTON — WIRED TO PROVIDER
              // ========================================
              Consumer<FavoritesProvider>(
                builder: (context, favProvider, _) {
                  final isFav = favProvider.isDeliveryFavorite(product.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final nowFav = await favProvider.toggleDeliveryFavorite(product.id);
                      // SESSION 20 FIX: Use centralized snackbar helper
                      _showSnackBar(
                        nowFav ? AppLocalizations.of(context)!.addedToFavorites : AppLocalizations.of(context)!.removedFromFavorites2,
                        backgroundColor: nowFav ? Colors.green : Colors.grey,
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Admin/Merchant Controls
          if (canManage)
            SliverToBoxAdapter(child: _buildAdminControls(theme, product)),

          // Product Info — also wired to favorites
          SliverToBoxAdapter(
            child: Consumer<FavoritesProvider>(
              builder: (context, favProvider, _) {
                return ProductInfoSection(
                  product: product,
                  storeName: _storeName,
                  isWishlisted: favProvider.isDeliveryFavorite(product.id),
                  onWishlistToggle: () async {
                    HapticFeedback.lightImpact();
                    await favProvider.toggleDeliveryFavorite(product.id);
                  },
                );
              },
            ),
          ),

          // Quantity + Add to Cart
          if (product.canOrder)
            SliverToBoxAdapter(child: Column(children: [
              QuantitySelector(
                quantity: _quantity,
                onQuantityChanged: (q) => setState(() => _quantity = q),
                maxQuantity: product.stockQuantity ?? 99,
                enabled: !_isAddingToCart,
              ),
              _buildAddToCartButton(theme, product),
            ])),

          if (!product.canOrder)
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  SizedBox(width: 2.w),
                  Flexible(child: Text(AppLocalizations.of(context)!.thisProductIsCurrentlyUnavailable,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            )),

          // Description
          if (product.description != null && product.description!.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ExpandableSection(
                title: AppLocalizations.of(context)!.productOverview,
                initiallyExpanded: true,
                content: Text(product.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            )),

          // Nutritional Info
          if (product.nutritionalInfo != null && product.nutritionalInfo!.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ExpandableSection(
                title: AppLocalizations.of(context)!.nutritionFacts,
                content: _buildNutritionalInfo(theme, product.nutritionalInfo!),
              ),
            )),

          // Reviews removed — ratings handled via store_ratings table

          // Related Products
          if (_relatedProducts.isNotEmpty)
            SliverToBoxAdapter(child: RelatedProductsSection(products: _relatedProducts)),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 4.h)),
        ],
      ),
    );
  }

  Widget _buildImageGallery(Product product, ThemeData theme) {
    final images = product.allImages;
    if (images.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(child: Icon(Icons.shopping_bag, size: 80, color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    if (images.length == 1) {
      return Stack(fit: StackFit.expand, children: [
        CustomImageWidget(imageUrl: images.first, fit: BoxFit.cover),
        Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.1)],
        ))),
      ]);
    }

    return Stack(children: [
      PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, i) => CustomImageWidget(imageUrl: images[i], fit: BoxFit.cover),
      ),
      Positioned(top: 0, left: 0, right: 0, height: 100,
        child: Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
        )))),
    ]);
  }

  Widget _buildAdminControls(ThemeData theme, Product product) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      color: Colors.orange.withOpacity(0.1),
      child: Row(children: [
        const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
        SizedBox(width: 2.w),
        Expanded(child: Text(AppLocalizations.of(context)!.manageProduct,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        _adminButton(Icons.edit, AppLocalizations.of(context)!.edit, Colors.blue, () => _openEditModal(product)),
        SizedBox(width: 1.w),
        _adminButton(Icons.local_offer, AppLocalizations.of(context)!.sale, Colors.deepOrange, () => _showSalePricingDialog(product)),
        SizedBox(width: 1.w),
        _adminButton(Icons.delete, AppLocalizations.of(context)!.delete, Colors.red, () => _confirmDeleteProduct(product)),
      ]),
    );
  }

  Widget _adminButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(message: tooltip, child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 20),
      ),
    ));
  }

  void _openEditModal(Product product) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => ContentEditModalWidget(
        contentType: 'product',
        contentId: product.id,
        contentData: product.toMap(),
        onSaved: () { Navigator.pop(ctx); _refreshProduct(); },
      ),
    );
  }

  void _showSalePricingDialog(Product product) {
    final salePriceCtrl = TextEditingController(text: product.salePrice?.toStringAsFixed(2) ?? '');
    final originalPrice = product.price;
    bool removeSale = false;

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        final saleVal = double.tryParse(salePriceCtrl.text.trim());
        final discount = saleVal != null && saleVal < originalPrice
            ? (((originalPrice - saleVal) / originalPrice) * 100).round()
            : 0;

        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.local_offer, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Flexible(child: Text(AppLocalizations.of(context)!.salePricing, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Flexible(child: Text(AppLocalizations.of(context)!.originalPrice, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Flexible(child: Text('${product.currency} ${originalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: salePriceCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.salePrice,
                border: const OutlineInputBorder(),
                prefixText: '${product.currency} ',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: discount > 0 ? '$discount% OFF' : null,
                suffixStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setDialogState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final pct in [10, 20, 25, 30, 50])
                ActionChip(
                  label: Text('$pct% OFF', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () {
                    final newPrice = originalPrice * (1 - pct / 100);
                    salePriceCtrl.text = newPrice.toStringAsFixed(2);
                    setDialogState(() {});
                  },
                ),
            ]),
            if (product.isOnSale) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setDialogState(() => removeSale = true),
                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                label: Text(AppLocalizations.of(context)!.removeSale, style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (removeSale) {
                    await ProductService.removeSalePrice(product.id);
                  } else {
                    final newSalePrice = double.tryParse(salePriceCtrl.text.trim());
                    if (newSalePrice != null && newSalePrice < originalPrice && newSalePrice > 0) {
                      await ProductService.updatePrice(product.id, originalPrice, salePrice: newSalePrice);
                    } else if (newSalePrice == null || salePriceCtrl.text.trim().isEmpty) {
                      await ProductService.removeSalePrice(product.id);
                    } else {
                      // SESSION 20 FIX: Use centralized snackbar helper
                      _showSnackBar(AppLocalizations.of(context)!.salePriceMustBeLessThan, backgroundColor: Colors.red);
                      return;
                    }
                  }
                  _refreshProduct();
                  // SESSION 20 FIX: Use centralized snackbar helper
                  _showSnackBar(AppLocalizations.of(context)!.pricingUpdated, backgroundColor: Colors.green);
                } catch (e) {
                  // SESSION 20 FIX: Use centralized snackbar helper
                  _showSnackBar('Error: $e', backgroundColor: Colors.red);
                }
              },
              child: Text(removeSale ? AppLocalizations.of(context)!.removeSale2 : AppLocalizations.of(context)!.apply2, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
      });
    });
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteProduct2, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: Text('Are you sure you want to delete "${product.name}"? This cannot be undone.', maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ProductService.deleteProduct(product.id);
              if (mounted) {
                // SESSION 20 FIX: Use centralized snackbar helper
                _showSnackBar(AppLocalizations.of(context)!.productDeleted, backgroundColor: Colors.red);
                Navigator.pop(context);
              }
            } catch (e) {
              // SESSION 20 FIX: Use centralized snackbar helper
              _showSnackBar('Error: $e', backgroundColor: Colors.red);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: Text(AppLocalizations.of(context)!.delete, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ));
  }

  Widget _buildAddToCartButton(ThemeData theme, Product product) {
    final total = product.effectivePrice * _quantity;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context)!.total, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${product.currency} ${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        SizedBox(width: 4.w),
        Expanded(flex: 2, child: ElevatedButton.icon(
          onPressed: _isAddingToCart ? null : () => _addToCart(product),
          icon: _isAddingToCart
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.surface))
              : const Icon(Icons.add_shopping_cart),
          label: Text(AppLocalizations.of(context)!.addToCart, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        )),
      ]),
    );
  }

  // SESSION 20 FIX: _addToCart now uses _showSnackBar helper
  Future<void> _addToCart(Product product) async {
    HapticFeedback.mediumImpact();
    setState(() => _isAddingToCart = true);
    try {
      await ref.read(cartNotifierProvider.notifier).addToCart(
        productId: product.id,
        quantity: _quantity,
      );
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _showSnackBar(
          '${product.name} x$_quantity added to cart',
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.viewCart,
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/shopping-cart-screen'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _showSnackBar('Failed to add to cart: $e', backgroundColor: Colors.red);
      }
    }
  }

  Widget _buildNutritionalInfo(ThemeData theme, Map<String, dynamic> info) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...info.entries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: 0.5.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(e.key, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(e.value.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      )),
    ]);
  }
}