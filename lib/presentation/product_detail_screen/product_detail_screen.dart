import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import './widgets/expandable_section.dart';
import './widgets/product_info_section.dart';
import './widgets/product_reviews_section.dart';
import './widgets/quantity_selector.dart';
import './widgets/related_products_section.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
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
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> _refreshProduct() async {
    if (_product == null) return;
    await _loadProduct(_product!.id);
  }

  bool _canManageProduct(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.isAdmin) return true;
    if (_product == null) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.userId;
    if (uid == null) return false;
    // Check if user owns the store (would need store data, so for now admin-only inline)
    return false;
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
                Text('Product not found', style: theme.textTheme.titleLarge),
                SizedBox(height: 2.h),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
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
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? theme.colorScheme.error : Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${product.name}'))),
              ),
            ],
          ),

          // Admin/Merchant Controls
          if (canManage)
            SliverToBoxAdapter(child: _buildAdminControls(theme, product)),

          // Product Info
          SliverToBoxAdapter(
            child: ProductInfoSection(
              product: product,
              storeName: _storeName,
              isWishlisted: _isFavorite,
              onWishlistToggle: () {
                HapticFeedback.lightImpact();
                setState(() => _isFavorite = !_isFavorite);
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  SizedBox(width: 2.w),
                  Text('This product is currently unavailable',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),

          // Description
          if (product.description != null && product.description!.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ExpandableSection(
                title: 'Product Overview',
                initiallyExpanded: true,
                content: Text(product.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
            )),

          // Nutritional Info (if available)
          if (product.nutritionalInfo != null && product.nutritionalInfo!.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ExpandableSection(
                title: 'Nutrition Facts',
                content: _buildNutritionalInfo(theme, product.nutritionalInfo!),
              ),
            )),

          // Reviews placeholder
          SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ProductReviewsSection(productId: product.id),
          )),

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
      // Gradient overlay for status bar readability
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
        Expanded(child: Text('Manage Product',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600))),
        // Edit
        _adminButton(Icons.edit, 'Edit', Colors.blue, () => _openEditModal(product)),
        SizedBox(width: 1.w),
        // Sale / Pricing
        _adminButton(Icons.local_offer, 'Sale', Colors.deepOrange, () => _showSalePricingDialog(product)),
        SizedBox(width: 1.w),
        // Delete
        _adminButton(Icons.delete, 'Delete', Colors.red, () => _confirmDeleteProduct(product)),
      ]),
    );
  }

  Widget _adminButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(message: tooltip, child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
            const Text('Sale / Pricing'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Current price display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Text('Original Price: ', style: Theme.of(context).textTheme.bodyMedium),
                Text('${product.currency} ${originalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            // Sale price input
            TextField(
              controller: salePriceCtrl,
              decoration: InputDecoration(
                labelText: 'Sale Price',
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
            // Quick discount buttons
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final pct in [10, 20, 25, 30, 50])
                ActionChip(
                  label: Text('$pct% OFF'),
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
                label: const Text('Remove Sale', style: TextStyle(color: Colors.red)),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sale price must be less than original price'), backgroundColor: Colors.red));
                      return;
                    }
                  }
                  _refreshProduct();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pricing updated'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(removeSale ? 'Remove Sale' : 'Apply'),
            ),
          ],
        );
      });
    });
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Product?'),
      content: Text('Are you sure you want to delete "${product.name}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ProductService.deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red));
                Navigator.pop(context);
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete'),
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
          Text('Total', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text('${product.currency} ${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
        ])),
        SizedBox(width: 4.w),
        Expanded(flex: 2, child: ElevatedButton.icon(
          onPressed: _isAddingToCart ? null : () => _addToCart(product),
          icon: _isAddingToCart
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_shopping_cart),
          label: const Text('Add to Cart'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        )),
      ]),
    );
  }

  Future<void> _addToCart(Product product) async {
    HapticFeedback.mediumImpact();
    setState(() => _isAddingToCart = true);
    try {
      await DatabaseService.instance.addToCart(
        productId: product.id,
        quantity: _quantity,
      );
      if (mounted) {
        setState(() => _isAddingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} x$_quantity added to cart'),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'View Cart', textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/shopping-cart-screen')),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add to cart: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildNutritionalInfo(ThemeData theme, Map<String, dynamic> info) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...info.entries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: 0.5.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e.key, style: theme.textTheme.bodyMedium),
          Text(e.value.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      )),
    ]);
  }
}