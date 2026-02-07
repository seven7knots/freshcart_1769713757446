import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/admin_action_button.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/expandable_section.dart';
import './widgets/product_info_section.dart';
import './widgets/product_reviews_section.dart';
import './widgets/quantity_selector.dart';
import './widgets/related_products_section.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isAddingToCart = false;
  int _cartItemCount = 0;

  // Mock product data
  final Map<String, dynamic> _productData = {
    "id": 1,
    "name": "Organic Bananas",
    "brand": "Fresh Farms",
    "price": "\$3.99",
    "originalPrice": "\$4.99",
    "discount": 20,
    "rating": 4.5,
    "reviewCount": 128,
    "inStock": true,
    "stockCount": 15,
    "description":
        """Fresh, organic bananas sourced directly from sustainable farms. 
    These premium bananas are perfect for snacking, smoothies, or baking. 
    Rich in potassium, vitamin B6, and dietary fiber.""",
    "ingredients": "100% Organic Bananas",
    "nutritionFacts": """Per 100g:
    • Calories: 89
    • Carbohydrates: 23g
    • Dietary Fiber: 2.6g
    • Sugars: 12g
    • Protein: 1.1g
    • Potassium: 358mg
    • Vitamin B6: 0.4mg""",
    "images": [
      "https://images.pexels.com/photos/2872755/pexels-photo-2872755.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/5966630/pexels-photo-5966630.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/2238309/pexels-photo-2238309.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    ],
    "semanticLabels": [
      "Fresh yellow bananas arranged in a bunch on a white background",
      "Close-up view of ripe organic bananas with natural spots showing ripeness",
      "Single peeled banana showing the creamy white flesh inside",
    ],
  };

  // Mock reviews data
  final List<Map<String, dynamic>> _reviewsData = [
    {
      "id": 1,
      "userName": "Sarah Johnson",
      "userAvatar":
          "https://images.unsplash.com/photo-1539813349302-cf36e01e5795",
      "userAvatarSemanticLabel":
          "Profile photo of a smiling woman with blonde hair wearing a blue shirt",
      "rating": 5,
      "date": "2 days ago",
      "comment":
          "These bananas are absolutely perfect! Sweet, fresh, and arrived in excellent condition. Will definitely order again.",
      "helpfulCount": 12,
      "notHelpfulCount": 1,
    },
    {
      "id": 2,
      "userName": "Mike Chen",
      "userAvatar":
          "https://images.unsplash.com/photo-1687256457585-3608dfa736c5",
      "userAvatarSemanticLabel":
          "Profile photo of an Asian man with short black hair wearing glasses and a white t-shirt",
      "rating": 4,
      "date": "1 week ago",
      "comment":
          "Great quality bananas, perfect for my morning smoothies. Only minor issue was one banana was a bit overripe.",
      "helpfulCount": 8,
      "notHelpfulCount": 0,
    },
    {
      "id": 3,
      "userName": "Emma Rodriguez",
      "userAvatar":
          "https://images.unsplash.com/photo-1639214815013-b148933615e6",
      "userAvatarSemanticLabel":
          "Profile photo of a Hispanic woman with long dark hair wearing a green sweater",
      "rating": 5,
      "date": "2 weeks ago",
      "comment":
          "Excellent organic bananas! My kids love them and I feel good knowing they're pesticide-free.",
      "helpfulCount": 15,
      "notHelpfulCount": 2,
    },
  ];

  // Mock related products data
  final List<Map<String, dynamic>> _relatedProducts = [
    {
      "id": 2,
      "name": "Organic Apples",
      "brand": "Fresh Farms",
      "price": "\$4.99",
      "image": "https://images.unsplash.com/photo-1508431822127-707daa5c7f21",
      "semanticLabel":
          "Fresh red apples with green leaves arranged in a wooden basket",
    },
    {
      "id": 3,
      "name": "Fresh Strawberries",
      "brand": "Berry Best",
      "price": "\$5.99",
      "image": "https://images.unsplash.com/photo-1640958899516-c08a59225611",
      "semanticLabel":
          "Bright red strawberries with green tops arranged on a white plate",
    },
    {
      "id": 4,
      "name": "Organic Oranges",
      "brand": "Citrus Grove",
      "price": "\$3.49",
      "image": "https://images.unsplash.com/photo-1650978908957-17183c684360",
      "semanticLabel":
          "Fresh orange citrus fruits cut in half showing the juicy interior",
    },
    {
      "id": 5,
      "name": "Fresh Blueberries",
      "brand": "Berry Best",
      "price": "\$6.99",
      "image": "https://images.unsplash.com/photo-1468165196271-4e91eae54eb2",
      "semanticLabel":
          "Fresh blueberries scattered on a white surface with some in a small bowl",
    },
  ];

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    // Track product view
    _trackProductView();
    AnalyticsService.logScreenView(screenName: 'product_detail_screen');
  }

  void _trackProductView() {
    AnalyticsService.logViewItem(
      itemId: _productData['id'].toString(),
      itemName: _productData['name'],
      category: _productData['brand'] ?? 'general',
      price: 3.99, // Parse from price string in real implementation
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get the current tab index from MainLayoutWrapper
    final parentState = MainLayoutWrapper.of(context);
    final currentTabIndex = parentState?.currentIndex ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _productData['name'],
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Admin Edit Control
          Consumer2<AuthProvider, AdminProvider>(
            builder: (context, authProvider, adminProvider, child) {
              if (adminProvider.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {
                    _showAdminEditDialog();
                  },
                  tooltip: 'Admin: Edit Product',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Add to wishlist',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareProduct,
            tooltip: 'Share product',
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: null,
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                    onPressed: _toggleFavorite,
                    tooltip: 'Add to wishlist',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: _shareProduct,
                    tooltip: 'Share product',
                  ),
                ],
              ),
            ),
          ];
        },
        body: _buildMainContent(),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          // Update parent tab index and pop detail screen
          parentState?.updateTabIndex(index);
          if (index != currentTabIndex) {
            Navigator.pop(context);
          }
        },
        variant: BottomBarVariant.primary,
      ),
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Controls (visible only to admin)
                  Consumer2<AuthProvider, AdminProvider>(
                    builder: (context, authProvider, adminProvider, child) {
                      if (!adminProvider.isAdmin) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        color: Colors.orange.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Admin Mode - Manage Products',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Spacer(),
                            AdminActionButton(
                              icon: Icons.edit,
                              label: 'Edit',
                              isCompact: true,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edit product details'),
                                  ),
                                );
                              },
                            ),
                            AdminActionButton(
                              icon: Icons.delete,
                              label: 'Delete',
                              isCompact: true,
                              color: Colors.red,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delete product'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ProductInfoSection(
                    product: _productData,
                    isWishlisted: _isWishlisted,
                    onWishlistToggle: _toggleWishlist,
                  ),
                  if (_productData['inStock'] as bool)
                    QuantitySelector(
                      quantity: _quantity,
                      onQuantityChanged: (newQuantity) {
                        setState(() {
                          _quantity = newQuantity;
                        });
                      },
                      maxQuantity: _productData['stockCount'] as int,
                      enabled: !_isAddingToCart,
                    ),
                  SizedBox(height: 2.h),
                  ExpandableSection(
                    title: 'Product Overview',
                    initiallyExpanded: true,
                    content: Text(
                      _productData['description'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  ExpandableSection(
                    title: 'Ingredients',
                    content: Text(
                      _productData['ingredients'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  ExpandableSection(
                    title: 'Nutrition Facts',
                    content: Text(
                      _productData['nutritionFacts'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Customer Reviews',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: ProductReviewsSection(
                      reviews: _reviewsData,
                      averageRating: _productData['rating'] as double,
                      totalReviews: _productData['reviewCount'] as int,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  RelatedProductsSection(relatedProducts: _relatedProducts),
                  SizedBox(height: 12.h), // Bottom padding for nav bar
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddToCartSection() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _calculateTotalPrice(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isAddingToCart
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onSecondary,
                          ),
                        ),
                      )
                    : Text(
                        'Add to Cart',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotalPrice() {
    final priceString = _productData['price'] as String;
    final price = double.parse(priceString.replaceAll('\$', ''));
    final total = price * _quantity;
    return '\$${total.toStringAsFixed(2)}';
  }

  void _toggleWishlist() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    setState(() {
      _isWishlisted = !_isWishlisted;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWishlisted ? 'Added to wishlist' : 'Removed from wishlist',
        ),
        backgroundColor: _isWishlisted
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSurfaceVariant,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addToCart() async {
    final theme = Theme.of(context);
    HapticFeedback.mediumImpact();
    setState(() {
      _isAddingToCart = true;
    });

    // Simulate API call
    await Future.delayed(Duration(milliseconds: 800));

    setState(() {
      _isAddingToCart = false;
      _cartItemCount += _quantity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_productData['name']} added to cart!'),
        backgroundColor: theme.colorScheme.secondary,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: theme.colorScheme.onSecondary,
          onPressed: _navigateToCart,
        ),
      ),
    );
  }

  void _shareProduct() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  void _navigateToCart() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/shopping-cart-screen');
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showAdminEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Admin Product Controls'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit product functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProduct();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.grey),
              title: const Text('Hide Product'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Product hidden')));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
