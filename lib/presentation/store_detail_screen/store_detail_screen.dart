import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../widgets/animated_press_button.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeId;

  const StoreDetailScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingStore = false;
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  
  String? _errorStore;
  String? _errorCategories;
  String? _errorProducts;

  Store? _store;
  List<Category> _storeCategories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    await Future.wait([
      _loadStore(),
      _loadStoreCategories(),
      _loadProducts(),
    ]);
  }

  Future<void> _loadStore() async {
    setState(() {
      _isLoadingStore = true;
      _errorStore = null;
    });

    try {
      final store = await StoreService.getStoreById(widget.storeId);
      
      if (mounted) {
        setState(() {
          _store = store;
          _isLoadingStore = false;
        });
      }
    } catch (e) {
      debugPrint('[STORE_DETAIL] Error loading store: $e');
      if (mounted) {
        setState(() {
          _errorStore = e.toString();
          _isLoadingStore = false;
        });
      }
    }
  }

  Future<void> _loadStoreCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorCategories = null;
    });

    try {
      // Get all categories and filter for store-specific ones
      // Since there's no direct getStoreCategories method, we'll get all categories
      // and filter based on naming convention or other logic
      // For now, we'll just load all active categories as merchant-created categories
      // would be set up through the admin panel with specific store associations
      
      final categories = await CategoryService.getAllCategories(
        activeOnly: true,
        excludeDemo: true,
      );
      
      // Filter to only show categories that might be relevant to this store
      // This is a placeholder - you may want to add a store_id field to categories table
      final storeCategories = categories.where((cat) => cat.isTopLevel).toList();
      
      if (mounted) {
        setState(() {
          _storeCategories = storeCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('[STORE_DETAIL] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _errorCategories = e.toString();
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _errorProducts = null;
    });

    try {
      final products = await ProductService.getProductsByStore(
        widget.storeId,
        availableOnly: true,
      );
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[STORE_DETAIL] Error loading products: $e');
      if (mounted) {
        setState(() {
          _errorProducts = e.toString();
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _filterProductsByCategory(String? categoryName) {
    setState(() {
      _selectedCategoryId = categoryName;
      if (categoryName == null) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product.category == categoryName)
            .toList();
      }
    });
  }

  void _navigateToProduct(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  void _addToCart(Product product) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => AppRoutes.switchToTab(context, 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingStore) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorStore != null || _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Not Found')),
        body: _buildErrorState(theme, _errorStore ?? 'Store not found'),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(theme),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Products'),
                    Tab(text: 'About'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(theme),
            _buildAboutTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 30.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _store!.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: _store!.imageUrl ??
                  'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
              fit: BoxFit.cover,
              semanticLabel: 'Store banner of ${_store!.name}',
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            if (!_store!.isActive || !_store!.isAcceptingOrders)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Currently Closed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sharing ${_store!.name}')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorites')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: CustomScrollView(
        slivers: [
          // Store Info Card
          SliverToBoxAdapter(
            child: _buildStoreInfoCard(theme),
          ),

          // Categories Filter
          if (_storeCategories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCategoriesFilter(theme),
            ),

          // Products Grid
          if (_isLoadingProducts)
            SliverFillRemaining(
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_errorProducts != null)
            SliverFillRemaining(
              child: _buildErrorState(theme, _errorProducts!),
            )
          else if (_filteredProducts.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyProducts(theme),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(4.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 3.w,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildProductCard(_filteredProducts[index], theme);
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_store!.rating > 0) ...[
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 5.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  _store!.ratingDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  '(${_store!.totalReviews})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ],
              Icon(
                Icons.access_time,
                size: 4.w,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 1.w),
              Text(
                _store!.prepTimeDisplay,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_store!.category != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _store!.category!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            'Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 6.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            children: [
              // All Products
              Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: AnimatedPressButton(
                  onPressed: () => _filterProductsByCategory(null),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: _selectedCategoryId == null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'All',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _selectedCategoryId == null
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Category chips
              ..._storeCategories.map((category) {
                final isSelected = _selectedCategoryId == category.id;
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: AnimatedPressButton(
                    onPressed: () => _filterProductsByCategory(category.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    return AnimatedPressButton(
      onPressed: () => _navigateToProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: product.imageUrl ??
                          'https://images.unsplash.com/photo-1565804212260-280f967e431b',
                      fit: BoxFit.cover,
                      semanticLabel: product.name,
                    ),
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
                    if (!product.canOrder)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
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
                                'Out of Stock',
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
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
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
                            onPressed: () => _addToCart(product),
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                color: theme.colorScheme.onPrimary,
                                size: 18,
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
    );
  }

  Widget _buildAboutTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_store!.description != null) ...[
            Text(
              'About',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _store!.description!,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),
          ],
          _buildInfoRow(
            theme,
            Icons.category,
            'Category',
            _store!.category ?? 'Not specified',
          ),
          _buildInfoRow(
            theme,
            Icons.access_time,
            'Preparation Time',
            _store!.prepTimeDisplay,
          ),
          if (_store!.rating > 0)
            _buildInfoRow(
              theme,
              Icons.star,
              'Rating',
              '${_store!.ratingDisplay} (${_store!.totalReviews} reviews)',
            ),
          _buildInfoRow(
            theme,
            Icons.store,
            'Status',
            (_store!.isActive && _store!.isAcceptingOrders)
                ? 'Open'
                : 'Closed',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 6.w,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 3.h),
            Text(
              'No products available',
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 1.h),
            Text(
              _selectedCategoryId != null
                  ? 'No products in this category'
                  : 'This store hasn\'t added any products yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadStoreData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate(this.child);

  @override
  double get minExtent => child.preferredSize.height;

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}