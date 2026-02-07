import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/merchant_provider.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';
import '../../services/store_service.dart';
import '../../services/product_service.dart';

class MerchantStoreScreen extends StatefulWidget {
  const MerchantStoreScreen({super.key});

  @override
  State<MerchantStoreScreen> createState() => _MerchantStoreScreenState();
}

class _MerchantStoreScreenState extends State<MerchantStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Store? _store;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  // Store customization
  Color _selectedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStoreData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
      final storeId = merchantProvider.selectedStoreId;

      if (storeId == null) {
        setState(() {
          _error = 'No store selected';
          _isLoading = false;
        });
        return;
      }

      final store = await StoreService.getStoreById(storeId);
      final products = await ProductService.getProductsByStore(storeId, availableOnly: false);

      setState(() {
        _store = store;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Error loading store: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Management')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 15.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text(_error ?? 'Store not found'),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 25.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildStoreHeader(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStoreData,
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit Store'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'customize',
                    child: Row(
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 8),
                        Text('Customize Design'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new),
                        SizedBox(width: 8),
                        Text('Toggle Open/Closed'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.inventory), text: 'Products'),
                Tab(icon: Icon(Icons.category), text: 'Categories'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
                Tab(icon: Icon(Icons.reviews), text: 'Reviews'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildCategoriesTab(),
            _buildOrdersTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }

  // ============================================================
  // STORE HEADER
  // ============================================================

  Widget _buildStoreHeader() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _selectedColor,
        image: _store!.bannerUrl != null
            ? DecorationImage(
                image: NetworkImage(_store!.bannerUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 3),
                      image: _store!.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_store!.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _store!.imageUrl == null
                        ? Icon(Icons.store, size: 8.w)
                        : null,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _store!.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: _store!.isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _store!.isActive ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(Icons.star, color: Colors.amber, size: 4.w),
                            SizedBox(width: 1.w),
                            Text(
                              _store!.ratingDisplay,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCTS TAB
  // ============================================================

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Products Yet',
        subtitle: 'Add your first product to start selling',
        actionLabel: 'Add Product',
        onAction: _showAddProductDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditProductDialog(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(Icons.image, color: theme.colorScheme.outline)
                    : null,
              ),
              SizedBox(width: 3.w),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isFeatured)
                          Icon(Icons.star, color: Colors.amber, size: 4.w),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        if (product.isOnSale) ...[
                          Text(
                            product.priceDisplay,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.outline,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: 1.w),
                        ],
                        Text(
                          product.effectivePriceDisplay,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: product.isOnSale ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: product.isAvailable
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: product.isAvailable
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                        if (product.stockQuantity != null) ...[
                          SizedBox(width: 2.w),
                          Text(
                            'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: product.isLowStock
                                  ? Colors.orange
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) => _handleProductAction(product, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(product.isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                  ),
                  PopupMenuItem(
                    value: 'feature',
                    child: Text(product.isFeatured ? 'Unfeature' : 'Feature'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES TAB
  // ============================================================

  Widget _buildCategoriesTab() {
    // Get unique categories from products
    final categories = _products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();

    if (categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Yet',
        subtitle: 'Categories are created when you add products with categories',
        actionLabel: 'Add Product',
        onAction: _showAddProductDialog,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final productCount = _products.where((p) => p.category == category).length;

        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.category),
            ),
            title: Text(category),
            subtitle: Text('$productCount products'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show products in this category
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // ORDERS TAB
  // ============================================================

  Widget _buildOrdersTab() {
    return _buildEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Orders Yet',
      subtitle: 'Orders will appear here when customers place them',
    );
  }

  // ============================================================
  // REVIEWS TAB
  // ============================================================

  Widget _buildReviewsTab() {
    return _buildEmptyState(
      icon: Icons.reviews_outlined,
      title: 'No Reviews Yet',
      subtitle: 'Customer reviews will appear here',
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15.w, color: theme.colorScheme.outline),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditStoreDialog();
        break;
      case 'customize':
        _showCustomizeDialog();
        break;
      case 'toggle':
        _toggleStoreStatus();
        break;
    }
  }

  void _handleProductAction(Product product, String action) async {
    switch (action) {
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'toggle':
        await ProductService.toggleAvailability(product.id, !product.isAvailable);
        _loadStoreData();
        break;
      case 'feature':
        await ProductService.toggleFeatured(product.id, !product.isFeatured);
        _loadStoreData();
        break;
      case 'delete':
        _confirmDeleteProduct(product);
        break;
    }
  }

  Future<void> _toggleStoreStatus() async {
    if (_store == null) return;

    try {
      await StoreService.toggleStoreStatus(_store!.id, !_store!.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_store!.isActive ? 'Store is now closed' : 'Store is now open'),
          backgroundColor: Colors.green,
        ),
      );
      _loadStoreData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditStoreDialog() {
    // TODO: Implement edit store dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit store dialog coming soon')),
    );
  }

  void _showCustomizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Store Design'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose your store\'s background color:'),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                Colors.white,
                Colors.grey.shade100,
                Colors.blue.shade50,
                Colors.green.shade50,
                Colors.orange.shade50,
                Colors.purple.shade50,
                Colors.pink.shade50,
                Colors.teal.shade50,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedColor == color ? Colors.blue : Colors.grey.shade300,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Burgers, Drinks',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  priceController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and price are required')),
                );
                return;
              }

              try {
                await ProductService.createProduct(
                  storeId: _store!.id,
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text.trim()),
                  category: categoryController.text.trim().isEmpty
                      ? null
                      : categoryController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStoreData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    // TODO: Implement full edit product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit product dialog coming soon')),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ProductService.deleteProduct(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStoreData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

