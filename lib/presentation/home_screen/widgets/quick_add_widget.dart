import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/product_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/product_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/animated_press_button.dart';

class QuickAddWidget extends StatefulWidget {
  const QuickAddWidget({super.key});

  @override
  State<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends State<QuickAddWidget> {
  final Map<String, int> _quantities = {};
  
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadQuickAddProducts();
  }

  Future<void> _loadQuickAddProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load featured products for quick add
      final products = await ProductService.getFeaturedProducts(limit: 10);
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[QUICK_ADD_WIDGET] Error loading products: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Add',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Your frequently purchased items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (isEditMode)
                  InkWell(
                    onTap: () => _addNewProduct(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            'Add Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _loadQuickAddProducts,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh products',
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_products.isEmpty)
            _buildEmptyState()
          else
            _buildProductsList(isEditMode),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Failed to load products',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadQuickAddProducts,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 10.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 1.h),
            Text(
              'No products yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Products will appear here once created',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(bool isEditMode) {
    return SizedBox(
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final productCard = _buildQuickAddCard(product);

          if (isEditMode) {
            return AdminEditableItemWrapper(
              contentType: 'product',
              contentId: product.id,
              contentData: product.toMap(),
              onDeleted: _loadQuickAddProducts,
              onUpdated: _loadQuickAddProducts,
              child: productCard,
            );
          }

          return productCard;
        },
      ),
    );
  }

  void _addNewProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to product creation'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildQuickAddCard(Product product) {
    final quantity = _quantities[product.id] ?? 0;
    final isAvailable = product.canOrder;

    return AnimatedPressButton(
      onPressed: isAvailable ? () => _handleProductTap(product) : null,
      child: Container(
        width: 40.w,
        margin: EdgeInsets.only(right: 3.w),
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
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
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
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.isOutOfStock ? 'Out of Stock' : 'Unavailable',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.onError,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Sale badge
                      if (product.isOnSale)
                        Positioned(
                          top: 1.h,
                          left: 2.w,
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
                    ],
                  ),
                ),
              ),
            ),
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    if (product.storeName != null)
                      Text(
                        product.storeName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.isOnSale) ...[
                              Text(
                                product.priceDisplay,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                product.salePriceDisplay!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ] else
                              Text(
                                product.priceDisplay,
                                style:
                                    Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                              ),
                          ],
                        ),
                        isAvailable
                            ? _buildQuantitySelector(product.id)
                            : const SizedBox.shrink(),
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

  Widget _buildQuantitySelector(String productId) {
    final quantity = _quantities[productId] ?? 0;

    return quantity == 0
        ? AnimatedPressButton(
            onPressed: () => _updateQuantity(productId, 1),
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'add',
                color: Theme.of(context).colorScheme.onPrimary,
                size: 4.w,
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedPressButton(
                  onPressed: () => _updateQuantity(productId, quantity - 1),
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomIconWidget(
                      iconName: 'remove',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 3.w,
                    ),
                  ),
                ),
                Container(
                  width: 8.w,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                AnimatedPressButton(
                  onPressed: () => _updateQuantity(productId, quantity + 1),
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomIconWidget(
                      iconName: 'add',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 3.w,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  void _handleProductTap(Product product) {
    // Navigate to product detail screen
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _quantities.remove(productId);
      } else {
        _quantities[productId] = newQuantity;
      }
    });
    
    // TODO: Integrate with cart provider to actually add to cart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newQuantity > 0 ? 'Updated cart' : 'Removed from cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}