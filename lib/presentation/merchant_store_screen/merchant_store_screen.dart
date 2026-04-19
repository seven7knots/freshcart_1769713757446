import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';
import '../../services/store_service.dart';
import '../../services/product_service.dart';
import '../../services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/bulk_import_service.dart';
import '../../l10n/generated/app_localizations.dart';

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
  List<Map<String, dynamic>> _storeOrders = [];
  bool _isLoading = true;
  String? _error;

  // SESSION 20: Track if initialTab was applied
  bool _initialTabApplied = false;

  // SESSION 34: Store ratings
  List<Map<String, dynamic>> _ratings = [];
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool _isLoadingRatings = false;


  // Store customization
  Color _selectedColor = Colors.white;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // SESSION 34 FIX: 4 tabs (Products, Categories, Orders, Reviews)
    _tabController = TabController(length: 4, vsync: this);
    // Listen for tab changes to update FAB visibility
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        // Load orders when Orders tab is selected for the first time
        if (_tabController.index == 2 && _storeOrders.isEmpty && _store != null) {
          _loadStoreOrders();
        }
        // SESSION 34: Lazy load reviews when tab selected
        if (_tabController.index == 3 && _ratings.isEmpty && _store != null) {
          _loadRatings();
        }
        // SESSION 34: Lazy load reviews when tab selected
        if (_tabController.index == 3 && _ratings.isEmpty && _store != null) {
          _loadRatings();
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // SESSION 20 FIX: Read initialTab from route arguments
      _applyInitialTab();
      _loadStoreData();
    });
  }

  // SESSION 20 FIX: Apply initialTab from navigation arguments
  void _applyInitialTab() {
    if (_initialTabApplied) return;
    _initialTabApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final initialTab = args['initialTab'] as int?;
      if (initialTab != null && initialTab >= 0 && initialTab < _tabController.length) {
        _tabController.animateTo(initialTab);
        // If navigating directly to Orders tab, load orders immediately
        if (initialTab == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_store != null) _loadStoreOrders();
          });
        }
      }
    }
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
          _error = AppLocalizations.of(context)!.noStoreSelected;
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

      // SESSION 20 FIX: If on Orders tab after load, fetch orders
      if (_tabController.index == 2 && _storeOrders.isEmpty) {
        _loadStoreOrders();
      }
      // SESSION 34: If on Reviews tab after load, fetch ratings
      if (_tabController.index == 3 && _ratings.isEmpty) {
        _loadRatings();
      }
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Error loading store: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SESSION 34: Load store ratings
  // ============================================================

  Future<void> _loadRatings() async {
    if (_store == null) return;
    setState(() => _isLoadingRatings = true);

    try {
      final response = await SupabaseService.client
          .from('store_ratings')
          .select('*, users!store_ratings_customer_id_fkey(full_name, email)')
          .eq('store_id', _store!.id)
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      final list = List<Map<String, dynamic>>.from(response);
      double total = 0;
      final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final r in list) {
        final rating = (r['rating'] as num?)?.toInt() ?? 0;
        total += rating;
        if (rating >= 1 && rating <= 5) dist[rating] = (dist[rating] ?? 0) + 1;
      }

      setState(() {
        _ratings = list;
        _averageRating = list.isEmpty ? 0.0 : total / list.length;
        _ratingDistribution = dist;
        _isLoadingRatings = false;
      });
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Error loading ratings: $e');
      setState(() => _isLoadingRatings = false);
    }
  }

  // ============================================================
  // SESSION 34: Load store ratings
  // ============================================================


  // ============================================================
  // SESSION 20: Load orders for merchant's store
  // ============================================================
  // ============================================================
  // AppBar bottom: store selector (multi-store merchants) + TabBar
  // ============================================================
  PreferredSizeWidget _buildAppBarBottom() {
    final merchantProvider =
        Provider.of<MerchantProvider>(context, listen: true);
    final hasMultipleStores = merchantProvider.stores.length > 1;
    final selectorHeight = hasMultipleStores ? 58.0 : 0.0;
    const tabBarHeight = 74.0;

    return PreferredSize(
      preferredSize: Size.fromHeight(selectorHeight + tabBarHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStoreSelector(),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: AppLocalizations.of(context)!.products),
              Tab(icon: Icon(Icons.category), text: AppLocalizations.of(context)!.categories),
              Tab(icon: Icon(Icons.receipt_long), text: AppLocalizations.of(context)!.orders),
              Tab(icon: Icon(Icons.star_rounded), text: AppLocalizations.of(context)!.reviews),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Store selector — switches merchant between their owned stores
  // ============================================================
  Widget _buildStoreSelector() {
    final theme = Theme.of(context);
    return Consumer<MerchantProvider>(
      builder: (context, merchantProvider, child) {
        final stores = merchantProvider.stores;
        if (stores.length < 2) {
          return const SizedBox.shrink();
        }
        final selectedId = merchantProvider.selectedStoreId;
        return Container(
          width: double.infinity,
          color: theme.colorScheme.surface,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Icon(Icons.storefront, size: 5.w, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedId,
                    hint: Text(
                      AppLocalizations.of(context)!.selectStore,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: stores.map((s) {
                      final id = s['id'] as String;
                      final name = s['name'] as String? ?? 'Unnamed Store';
                      final logoUrl = s['image_url'] as String?;
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(
                          children: [
                            Container(
                              width: 7.w,
                              height: 7.w,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                image: logoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(logoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: logoUrl == null
                                  ? Icon(Icons.store, size: 4.w, color: theme.colorScheme.outline)
                                  : null,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null && newId != selectedId) {
                        _onStoreChanged(newId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onStoreChanged(String newStoreId) async {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    merchantProvider.selectStore(newStoreId);
    setState(() {
      _storeOrders = [];
      _ratings = [];
      _averageRating = 0.0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    });
    await _loadStoreData();
    // Re-fetch tab-specific data if currently on that tab
    if (_tabController.index == 2) await _loadStoreOrders();
    if (_tabController.index == 3) await _loadRatings();
  }

  Future<void> _loadStoreOrders() async {
    if (_store == null) return;
    try {
      final response = await SupabaseService.client
          .from('orders')
          .select('*, stores(name)')
          .eq('store_id', _store!.id)
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _storeOrders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Error loading orders: $e');
    }
  }

    @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.storeManagement, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _store == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.storeManagement, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 15.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text(_error ?? AppLocalizations.of(context)!.storeNotFound2, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                icon: Icon(Icons.refresh,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  _loadStoreData();
                  if (_tabController.index == 2) _loadStoreOrders();
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Flexible(child: Text(AppLocalizations.of(context)!.storeSettings, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'customize',
                    child: Row(
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 8),
                        Flexible(child: Text(AppLocalizations.of(context)!.customizeDesign, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(_store!.isActive ? Icons.pause_circle : Icons.play_circle),
                        const SizedBox(width: 8),
                        Flexible(child: Text(_store!.isActive ? AppLocalizations.of(context)!.closeStore : AppLocalizations.of(context)!.openStore, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // Store selector (for merchants owning multiple stores) + 4 tabs
            bottom: _buildAppBarBottom(),
          ),
        ],
        // SESSION 34 FIX: 4 tab views — Reviews added
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
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'import_fab',
                  onPressed: _showBulkImportFlow,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(Icons.upload_file,
                      color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                SizedBox(height: 1.h),
                FloatingActionButton.extended(
                  heroTag: 'add_fab',
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.addProduct2, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            )
          : null,
    );
  }

  // ============================================================
  // STORE HEADER
  // ============================================================

  Widget _buildStoreHeader() {
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
                      borderRadius: BorderRadius.circular(16),
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
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _store!.isActive ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        title: AppLocalizations.of(context)!.noProductsYet,
        subtitle: AppLocalizations.of(context)!.addYourFirstProductToStart,
        actionLabel: AppLocalizations.of(context)!.addProduct3,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditProductDialog(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
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
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(width: 1.w),
                        ],
                        Text(
                          product.effectivePriceDisplay,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: product.isOnSale ? Colors.red : null,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.isAvailable ? AppLocalizations.of(context)!.available : AppLocalizations.of(context)!.unavailable2,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: product.isAvailable
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (product.stockQuantity != null) ...[
                          SizedBox(width: 2.w),
                          Text(
                            'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: product.isLowStock
                                  ? Colors.orange
                                  : Colors.grey,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleProductAction(product, action),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(product.isAvailable ? AppLocalizations.of(context)!.markUnavailable : AppLocalizations.of(context)!.markAvailable, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  PopupMenuItem(
                    value: 'feature',
                    child: Text(product.isFeatured ? AppLocalizations.of(context)!.unfeature : AppLocalizations.of(context)!.feature, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final categories = _products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();

    if (categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: AppLocalizations.of(context)!.noCategoriesYet2,
        subtitle: AppLocalizations.of(context)!.categoriesAreCreatedWhenYouAdd,
        actionLabel: AppLocalizations.of(context)!.addProduct3,
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
              child: const Icon(Icons.category),
            ),
            title: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('$productCount products', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Filter products tab to this category — future enhancement
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SESSION 9 M5: ORDERS TAB — Merchant-filtered orders
  // ============================================================

  Widget _buildOrdersTab() {
    if (_storeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: AppLocalizations.of(context)!.noOrdersYet2,
        subtitle: AppLocalizations.of(context)!.ordersWillAppearHereWhenCustomers,
      );
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadStoreOrders,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _storeOrders.length,
        itemBuilder: (context, index) {
          final order = _storeOrders[index];
          return _buildMerchantOrderCard(theme, order);
        },
      ),
    );
  }

  Widget _buildMerchantOrderCard(ThemeData theme, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderNumber = order['order_number'] as String? ?? orderId.substring(0, 8);
    final status = order['status'] as String? ?? 'pending';
    // SESSION 32 FIX: Show subtotal (merchant's product cut, excludes delivery/service fees)
    final total = (order['subtotal'] as num?)?.toDouble()
        ?? (order['total'] as num?)?.toDouble()
        ?? 0.0;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final paymentMethod = order['payment_method'] as String? ?? AppLocalizations.of(context)!.nA;
    final deliveryAddress = order['delivery_address'] as String? ?? AppLocalizations.of(context)!.nA;

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? customer?['email'] as String? ?? AppLocalizations.of(context)!.customer2;
    final customerPhone = customer?['phone'] as String? ?? order['customer_phone'] as String?;

    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(child: Text(
                  '#$orderNumber',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Divider(height: 2.h),
            _orderInfoRow(theme, Icons.person, customerName),
            if (customerPhone != null)
              _orderInfoRow(theme, Icons.phone, customerPhone),
            _orderInfoRow(theme, Icons.location_on, deliveryAddress),
            _orderInfoRow(
              theme,
              Icons.payment,
              paymentMethod == 'cash_on_delivery'
                  ? 'Cash on Delivery'
                  : paymentMethod == 'whish_money'
                      ? AppLocalizations.of(context)!.whishMoney
                      : paymentMethod,
            ),
            Row(
              children: [
                Icon(Icons.attach_money, size: 15, color: theme.colorScheme.onSurfaceVariant),
                SizedBox(width: 1.w),
                Flexible(child: Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    '${createdAt.toLocal().day}/${createdAt.toLocal().month} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            if (status == 'pending') ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(orderId, 'accepted'),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(AppLocalizations.of(context)!.accept, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(orderId, 'rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(AppLocalizations.of(context)!.reject, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'accepted') ...[
              SizedBox(height: 1.5.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _updateOrderStatus(orderId, 'picked_up'),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: Text(AppLocalizations.of(context)!.markReadyForPickup, maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orderInfoRow(ThemeData theme, IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.client.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${newStatus.replaceAll('_', ' ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.green,
        ),
      );
      _loadStoreOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  // ============================================================
  // SESSION 34: REVIEWS TAB
  // ============================================================

  Widget _buildReviewsTab() {
    if (_isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ratings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_outline_rounded,
        title: AppLocalizations.of(context)!.noReviewsYet,
        subtitle: AppLocalizations.of(context)!.customerRatingsWillAppearHereAfter,
      );
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingOverview(theme),
            SizedBox(height: 3.h),
            Text(
              'All Reviews (${_ratings.length})',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            ...List.generate(_ratings.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: _buildReviewCard(theme, _ratings[i]),
              );
            }),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview(ThemeData theme) {
    final total = _ratings.length;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _averageRating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 4.w,
                      );
                    }),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '$total review${total == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              flex: 3,
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = _ratingDistribution[star] ?? 0;
                  final fraction = total > 0 ? count / total : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      children: [
                        Text('$star',
                            style: TextStyle(
                                fontSize: 10.sp, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(width: 1.w),
                        Icon(Icons.star_rounded, size: 3.w, color: Colors.amber),
                        SizedBox(width: 1.5.w),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        SizedBox(
                          width: 7.w,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> review) {
    final user = review['users'] as Map<String, dynamic>?;
    final customerName = user?['full_name'] as String? ??
        user?['email'] as String? ??
        'Customer';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = DateTime.tryParse(review['created_at'] as String? ?? '');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 4.5.w,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: TextStyle(
                            fontSize: 12.sp, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 3.5.w,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              Text(comment,
                  style: TextStyle(fontSize: 12.sp, height: 1.4),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SESSION 34: REVIEWS TAB
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
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showStoreSettingsDialog();
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
        try {
          await ProductService.toggleAvailability(product.id, !product.isAvailable);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(product.isAvailable
                  ? '${product.name} marked unavailable'
                  : '${product.name} marked available', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
          _loadStoreData();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
          );
        }
        break;
      case 'feature':
        try {
          await ProductService.toggleFeatured(product.id, !product.isFeatured);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(product.isFeatured
                  ? '${product.name} unfeatured'
                  : '${product.name} featured!', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
          _loadStoreData();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
          );
        }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_store!.isActive ? AppLocalizations.of(context)!.storeIsNowClosed : AppLocalizations.of(context)!.storeIsNowOpen, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.green,
        ),
      );
      _loadStoreData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // SESSION 9 M6: STORE SETTINGS DIALOG
  // SESSION 17 M1 FIX: Image pickers replace URL text fields
  // ============================================================

  void _showStoreSettingsDialog() {
    if (_store == null) return;

    final nameController = TextEditingController(text: _store!.name);
    final descriptionController = TextEditingController(text: _store!.description ?? '');
    final addressController = TextEditingController(text: _store!.address ?? '');
    final minOrderController = TextEditingController(
      text: _store!.minimumOrder?.toStringAsFixed(2) ?? '',
    );
    final prepTimeController = TextEditingController(
      text: _store!.averagePrepTimeMinutes?.toString() ?? '',
    );
    final deliveryFeeController = TextEditingController(
      text: _store!.deliveryFeeOverride?.toStringAsFixed(2) ?? '',
    );

    bool isAcceptingOrders = _store!.isAcceptingOrders;
    bool isSaving = false;

    // ── M1 FIX: Image state for logo & banner ──
    String? logoUrl = _store!.imageUrl;
    String? bannerUrl = _store!.bannerUrl;
    XFile? pickedLogo;
    Uint8List? pickedLogoBytes;
    XFile? pickedBanner;
    Uint8List? pickedBannerBytes;
    bool logoRemoved = false;
    bool bannerRemoved = false;

    // Operating hours state
    final Map<String, Map<String, String>> operatingHours = {};
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    if (_store!.operatingHours != null) {
      for (final day in dayNames) {
        final dayData = _store!.operatingHours![day];
        if (dayData is Map) {
          operatingHours[day] = {
            'open': dayData['open']?.toString() ?? '09:00',
            'close': dayData['close']?.toString() ?? '22:00',
          };
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.storeSettings, maxLines: 1, overflow: TextOverflow.ellipsis),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info Section ──
                    _settingsSectionHeader(AppLocalizations.of(context)!.basicInformation),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.storeName,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.address,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // ── M1 FIX: Images Section with real image pickers ──
                    _settingsSectionHeader(AppLocalizations.of(context)!.storeLogo),
                    SizedBox(height: 1.h),
                    _buildImagePickerWidget(
                      existingImageUrl: logoRemoved ? null : logoUrl,
                      pickedImageBytes: pickedLogoBytes,
                      onTap: () async {
                        final img = await _pickImage();
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setDialogState(() {
                            pickedLogo = img;
                            pickedLogoBytes = bytes;
                            logoRemoved = false;
                          });
                        }
                      },
                      onRemove: (pickedLogoBytes != null ||
                              (!logoRemoved && logoUrl != null))
                          ? () {
                              setDialogState(() {
                                pickedLogo = null;
                                pickedLogoBytes = null;
                                logoRemoved = true;
                              });
                            }
                          : null,
                    ),
                    SizedBox(height: 2.h),
                    _settingsSectionHeader(AppLocalizations.of(context)!.bannerImage),
                    SizedBox(height: 1.h),
                    _buildImagePickerWidget(
                      existingImageUrl: bannerRemoved ? null : bannerUrl,
                      pickedImageBytes: pickedBannerBytes,
                      onTap: () async {
                        final img = await _pickImage();
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setDialogState(() {
                            pickedBanner = img;
                            pickedBannerBytes = bytes;
                            bannerRemoved = false;
                          });
                        }
                      },
                      onRemove: (pickedBannerBytes != null ||
                              (!bannerRemoved && bannerUrl != null))
                          ? () {
                              setDialogState(() {
                                pickedBanner = null;
                                pickedBannerBytes = null;
                                bannerRemoved = true;
                              });
                            }
                          : null,
                    ),

                    SizedBox(height: 3.h),

                    // ── Order Settings Section ──
                    _settingsSectionHeader(AppLocalizations.of(context)!.orderSettings),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minOrderController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Min Order (\$)',
                              hintText: AppLocalizations.of(context)!.optional,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: TextField(
                            controller: prepTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.prepTimeMin,
                              hintText: AppLocalizations.of(context)!.optional,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: deliveryFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Delivery Fee Override (\$)',
                        hintText: AppLocalizations.of(context)!.leaveEmptyForDefaultCalculation,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.acceptingOrders, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        isAcceptingOrders
                            ? AppLocalizations.of(context)!.customersCanPlaceOrders
                            : AppLocalizations.of(context)!.ordersPaused,
                        style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                      value: isAcceptingOrders,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setDialogState(() => isAcceptingOrders = v);
                      },
                    ),

                    SizedBox(height: 3.h),

                    // ── Operating Hours Section ──
                    _settingsSectionHeader(AppLocalizations.of(context)!.operatingHours2),
                    SizedBox(height: 1.h),
                    ...dayNames.map((day) {
                      final hasHours = operatingHours.containsKey(day);
                      final displayDay = '${day[0].toUpperCase()}${day.substring(1)}';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22.w,
                              child: Text(
                                displayDay.substring(0, 3),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: Checkbox(
                                value: hasHours,
                                onChanged: (v) {
                                  setDialogState(() {
                                    if (v == true) {
                                      operatingHours[day] = {'open': '09:00', 'close': '22:00'};
                                    } else {
                                      operatingHours.remove(day);
                                    }
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 3.w),
                            if (hasHours) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final time = await _pickTime(
                                      ctx,
                                      operatingHours[day]!['open']!,
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        operatingHours[day]!['open'] = time;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 0.8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      operatingHours[day]!['open']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 1.w),
                                child: Text('–', style: TextStyle(fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final time = await _pickTime(
                                      ctx,
                                      operatingHours[day]!['close']!,
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        operatingHours[day]!['close'] = time;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 0.8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      operatingHours[day]!['close']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.closedStatus,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.storeNameIsRequired, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          // ── M1 FIX: Upload images if picked ──
                          String? finalLogoUrl;
                          if (pickedLogo != null) {
                            finalLogoUrl = await _uploadStoreImage(pickedLogo!, 'logos');
                          } else if (logoRemoved) {
                            finalLogoUrl = null;
                          } else {
                            finalLogoUrl = logoUrl;
                          }

                          String? finalBannerUrl;
                          if (pickedBanner != null) {
                            finalBannerUrl = await _uploadStoreImage(pickedBanner!, 'banners');
                          } else if (bannerRemoved) {
                            finalBannerUrl = null;
                          } else {
                            finalBannerUrl = bannerUrl;
                          }

                          final updates = <String, dynamic>{
                            'name': name,
                            'description': descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            'address': addressController.text.trim().isEmpty
                                ? null
                                : addressController.text.trim(),
                            'image_url': finalLogoUrl,
                            'banner_url': finalBannerUrl,
                            'minimum_order': minOrderController.text.trim().isEmpty
                                ? null
                                : double.tryParse(minOrderController.text.trim()),
                            'average_prep_time_minutes': prepTimeController.text.trim().isEmpty
                                ? null
                                : int.tryParse(prepTimeController.text.trim()),
                            'delivery_fee_override': deliveryFeeController.text.trim().isEmpty
                                ? null
                                : double.tryParse(deliveryFeeController.text.trim()),
                            'is_accepting_orders': isAcceptingOrders,
                            'operating_hours': operatingHours.isEmpty ? null : operatingHours,
                          };

                          await StoreService.updateStore(_store!.id, updates);

                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.storeSettingsSaved, maxLines: 1, overflow: TextOverflow.ellipsis),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadStoreData();
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving settings: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context)!.saveSettings, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _settingsSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Future<String?> _pickTime(BuildContext ctx, String currentTime) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // SESSION 17 M1 FIX: CUSTOMIZE DIALOG — Full image upload
  // ============================================================

  void _showCustomizeDialog() {
    if (_store == null) return;

    String? logoUrl = _store!.imageUrl;
    String? bannerUrl = _store!.bannerUrl;
    XFile? pickedLogo;
    Uint8List? pickedLogoBytes;
    XFile? pickedBanner;
    Uint8List? pickedBannerBytes;
    bool logoRemoved = false;
    bool bannerRemoved = false;
    bool isSaving = false;

    Color tempColor = _selectedColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.customizeStoreDesign, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsSectionHeader(AppLocalizations.of(context)!.storeLogo),
                  SizedBox(height: 1.h),
                  _buildImagePickerWidget(
                    existingImageUrl: logoRemoved ? null : logoUrl,
                    pickedImageBytes: pickedLogoBytes,
                    onTap: () async {
                      final img = await _pickImage();
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setDialogState(() {
                          pickedLogo = img;
                          pickedLogoBytes = bytes;
                          logoRemoved = false;
                        });
                      }
                    },
                    onRemove: (pickedLogoBytes != null ||
                            (!logoRemoved && logoUrl != null))
                        ? () {
                            setDialogState(() {
                              pickedLogo = null;
                              pickedLogoBytes = null;
                              logoRemoved = true;
                            });
                          }
                        : null,
                  ),
                  SizedBox(height: 3.h),
                  _settingsSectionHeader(AppLocalizations.of(context)!.bannerImage),
                  SizedBox(height: 1.h),
                  _buildImagePickerWidget(
                    existingImageUrl: bannerRemoved ? null : bannerUrl,
                    pickedImageBytes: pickedBannerBytes,
                    onTap: () async {
                      final img = await _pickImage();
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setDialogState(() {
                          pickedBanner = img;
                          pickedBannerBytes = bytes;
                          bannerRemoved = false;
                        });
                      }
                    },
                    onRemove: (pickedBannerBytes != null ||
                            (!bannerRemoved && bannerUrl != null))
                        ? () {
                            setDialogState(() {
                              pickedBanner = null;
                              pickedBannerBytes = null;
                              bannerRemoved = true;
                            });
                          }
                        : null,
                  ),
                  SizedBox(height: 3.h),
                  _settingsSectionHeader(AppLocalizations.of(context)!.backgroundColor),
                  SizedBox(height: 1.h),
                  Text(
                    AppLocalizations.of(context)!.fallbackColorWhenNoBannerIs,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
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
                          setDialogState(() => tempColor = color);
                        },
                        child: Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: tempColor == color
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: tempColor == color ? 3 : 1,
                            ),
                          ),
                          child: tempColor == color
                              ? Icon(Icons.check,
                                  size: 4.w, color: Colors.blue)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final hasImageChanges = pickedLogo != null ||
                          pickedBanner != null ||
                          logoRemoved ||
                          bannerRemoved;
                      final hasColorChange = tempColor != _selectedColor;

                      if (!hasImageChanges && !hasColorChange) {
                        Navigator.pop(dialogContext);
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final updates = <String, dynamic>{};

                        if (pickedLogo != null) {
                          final url = await _uploadStoreImage(
                              pickedLogo!, 'logos');
                          updates['image_url'] = url;
                        } else if (logoRemoved) {
                          updates['image_url'] = null;
                        }

                        if (pickedBanner != null) {
                          final url = await _uploadStoreImage(
                              pickedBanner!, 'banners');
                          updates['banner_url'] = url;
                        } else if (bannerRemoved) {
                          updates['banner_url'] = null;
                        }

                        if (updates.isNotEmpty) {
                          await StoreService.updateStore(
                              _store!.id, updates);
                        }

                        if (hasColorChange) {
                          setState(() => _selectedColor = tempColor);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.storeDesignUpdated, maxLines: 1, overflow: TextOverflow.ellipsis),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadStoreData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.saveDesign, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE HELPERS
  // ============================================================

  Future<String?> _uploadProductImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.path.split('.').last.toLowerCase();
      final url = await SupabaseService.uploadImageBytes(
        bytes,
        bucket: 'uploads',
        folder: 'products',
        extension: ext,
      );
      return url;
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Image upload failed: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Image upload failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<String?> _uploadStoreImage(XFile imageFile, String folder) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.path.split('.').last.toLowerCase();
      final url = await SupabaseService.uploadImageBytes(
        bytes,
        bucket: 'uploads',
        folder: 'stores/$folder',
        extension: ext,
      );
      debugPrint('[MERCHANT_STORE] Store image uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('[MERCHANT_STORE] Store image upload failed: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Image upload failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<XFile?> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(AppLocalizations.of(context)!.chooseImageSource,
                style: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.gallery, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: Text(AppLocalizations.of(context)!.camera, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return null;
    try {
      return await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildImagePickerWidget({
    required String? existingImageUrl,
    required Uint8List? pickedImageBytes,
    required VoidCallback onTap,
    required VoidCallback? onRemove,
  }) {
    final theme = Theme.of(context);
    final hasImage = pickedImageBytes != null ||
        (existingImageUrl != null && existingImageUrl.isNotEmpty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 18.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3), width: 1.5),
        ),
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: pickedImageBytes != null
                      ? Image.memory(pickedImageBytes, fit: BoxFit.cover)
                      : CachedNetworkImage(imageUrl: existingImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image,
                                  size: 8.w,
                                  color: Colors.red.shade300))),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(11))),
                    child: Text(AppLocalizations.of(context)!.tapToChangeImage,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: theme.colorScheme.surface, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16)))),
              ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 10.w, color: theme.colorScheme.primary),
                    SizedBox(height: 1.h),
                    Text(AppLocalizations.of(context)!.tapToAddImage,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 0.5.h),
                    Text(AppLocalizations.of(context)!.galleryOrCamera,
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
      ),
    );
  }

  // ============================================================
  // ADD PRODUCT DIALOG
  // ============================================================


  // ============================================================
  // BULK IMPORT FLOW
  // ============================================================

  void _showBulkImportFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 10.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.importProducts,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              Text(
                'Upload a CSV file with your product catalog. '
                'Required columns: Name, Price. Optional: Category, Description, '
                'Sale Price, Stock, SKU, Barcode, Image URL.',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickAndParseFile();
                  },
                  icon: const Icon(Icons.upload_file, size: 22),
                  label: Text(AppLocalizations.of(context)!.chooseFile, maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadTemplate();
                  },
                  icon: const Icon(Icons.download, size: 22),
                  label: Text(AppLocalizations.of(context)!.downloadCsvTemplate, maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      // Try bytes first, fallback to reading from path (Android often needs this)
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && file.path != null) {
        debugPrint('[BULK_IMPORT] bytes null, reading from path: ${file.path}');
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (e) {
          debugPrint('[BULK_IMPORT] File read error: $e');
        }
      }
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReadFile, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
        return;
      }
      debugPrint('[BULK_IMPORT] Got ${bytes.length} bytes from file: ${file.name}');
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      List<ImportRow> rows;
      try {
        rows = BulkImportService.parseCSV(bytes);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing file: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
        return;
      }
      if (!mounted) return;
      Navigator.pop(context);
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noProductRowsFound, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange),
        );
        return;
      }
      _showImportPreview(rows, file.name);
    } catch (e) {
      debugPrint('[BULK_IMPORT] File pick error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
      );
    }
  }

  void _showImportPreview(List<ImportRow> rows, String fileName) {
    final validCount = rows.where((r) => r.isValid).length;
    final errorCount = rows.length - validCount;
    bool isImporting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(children: [
              Icon(Icons.preview, color: Theme.of(ctx).colorScheme.primary),
              SizedBox(width: 2.w),
              Expanded(child: Text(AppLocalizations.of(context)!.importPreview, style: TextStyle(fontSize: 15.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              height: 55.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      _importStatChip(Icons.list_alt, '${rows.length}', AppLocalizations.of(context)!.total),
                      SizedBox(width: 3.w),
                      _importStatChip(Icons.check_circle_outline, '$validCount', AppLocalizations.of(context)!.valid, color: Colors.green),
                      SizedBox(width: 3.w),
                      if (errorCount > 0) _importStatChip(Icons.error_outline, '$errorCount', AppLocalizations.of(context)!.errors, color: Colors.red),
                    ]),
                  ),
                  SizedBox(height: 1.h),
                  Text('File: $fileName', style: TextStyle(fontSize: 10.sp, color: Theme.of(ctx).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.5.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (_, index) {
                        final row = rows[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(2.5.w),
                          decoration: BoxDecoration(
                            color: row.isValid ? null : Colors.red.shade50,
                            border: Border.all(color: row.isValid ? Colors.grey.shade300 : Colors.red.shade300),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(row.isValid ? Icons.check_circle : Icons.error, size: 4.w, color: row.isValid ? Colors.green : Colors.red),
                              SizedBox(width: 1.5.w),
                              Expanded(child: Text(row.name.isEmpty ? '(empty name)' : row.name, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (row.price != null) Text('\$${row.price!.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                            if (row.category != null) Padding(padding: EdgeInsets.only(top: 0.3.h), child: Text(row.category!, style: TextStyle(fontSize: 10.sp, color: Theme.of(ctx).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (!row.isValid) Padding(padding: EdgeInsets.only(top: 0.5.h), child: Text(row.errors.join('; '), style: TextStyle(fontSize: 9.sp, color: Colors.red.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isImporting ? null : () => Navigator.pop(dialogContext), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ElevatedButton.icon(
                onPressed: isImporting || validCount == 0 ? null : () async {
                  setDialogState(() => isImporting = true);
                  try {
                    final importResult = await BulkImportService.importProducts(storeId: _store!.id, rows: rows);
                    if (!context.mounted) return;
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${importResult.successCount} products imported${importResult.errorCount > 0 ? ", ${importResult.errorCount} failed" : ""}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: importResult.errorCount > 0 ? Colors.orange : Colors.green,
                      duration: const Duration(seconds: 4),
                    ));
                    _loadStoreData();
                  } catch (e) {
                    setDialogState(() => isImporting = false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                  }
                },
                icon: isImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload, size: 20),
                label: Text(isImporting ? AppLocalizations.of(context)!.importing : 'Import $validCount Products', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _importStatChip(IconData icon, String value, String label, {Color? color}) {
    return Expanded(child: Column(children: [
      Icon(icon, size: 5.w, color: color),
      SizedBox(height: 0.3.h),
      Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: TextStyle(fontSize: 9.sp, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));
  }

  Future<void> _downloadTemplate() async {
    try {
      final csvContent = BulkImportService.generateTemplate();
      final bytes = utf8.encode(csvContent);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/kj_product_template.csv');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.templateSavedToTempFolder, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
      );
    }
  }


  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.addProduct2, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImagePickerWidget(
                    existingImageUrl: null,
                    pickedImageBytes: pickedImageBytes,
                    onTap: () async {
                      final img = await _pickImage();
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setDialogState(() {
                          pickedImage = img;
                          pickedImageBytes = bytes;
                        });
                      }
                    },
                    onRemove: pickedImageBytes != null
                        ? () {
                            setDialogState(() {
                              pickedImage = null;
                              pickedImageBytes = null;
                            });
                          }
                        : null,
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.productName,
                          border: OutlineInputBorder())),
                  SizedBox(height: 2.h),
                  TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.price2,
                          prefixText: '\$',
                          border: OutlineInputBorder())),
                  SizedBox(height: 2.h),
                  TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.category,
                          hintText: AppLocalizations.of(context)!.eGBurgersDrinks,
                          border: OutlineInputBorder())),
                  SizedBox(height: 2.h),
                  TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.description,
                          border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(AppLocalizations.of(context)!.nameAndPriceAreRequired, maxLines: 1, overflow: TextOverflow.ellipsis)));
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        String? imageUrl;
                        if (pickedImage != null) {
                          imageUrl =
                              await _uploadProductImage(pickedImage!);
                        }
                        await ProductService.createProduct(
                          storeId: _store!.id,
                          name: nameController.text.trim(),
                          price:
                              double.parse(priceController.text.trim()),
                          category:
                              categoryController.text.trim().isEmpty
                                  ? null
                                  : categoryController.text.trim(),
                          description:
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                          imageUrl: imageUrl,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(AppLocalizations.of(context)!.productAddedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
                                backgroundColor: Colors.green));
                        _loadStoreData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                                backgroundColor: Colors.red));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.add, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PRODUCT DIALOG
  // ============================================================

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toStringAsFixed(2));
    final salePriceController = TextEditingController(
        text: product.salePrice?.toStringAsFixed(2) ?? '');
    final descriptionController =
        TextEditingController(text: product.description ?? '');
    final categoryController =
        TextEditingController(text: product.category ?? '');
    final stockController =
        TextEditingController(text: product.stockQuantity?.toString() ?? '');
    final skuController = TextEditingController(text: product.sku ?? '');

    bool isAvailable = product.isAvailable;
    bool isFeatured = product.isFeatured;
    bool isSaving = false;

    String? existingImageUrl = product.imageUrl;
    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    bool imageRemoved = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(children: [
              Expanded(child: Text(AppLocalizations.of(context)!.editProduct, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Tooltip(
                message: isAvailable ? AppLocalizations.of(context)!.available : AppLocalizations.of(context)!.unavailable2,
                child: Switch(
                    value: isAvailable,
                    activeColor: Colors.green,
                    onChanged: (v) =>
                        setDialogState(() => isAvailable = v)),
              ),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePickerWidget(
                      existingImageUrl:
                          imageRemoved ? null : existingImageUrl,
                      pickedImageBytes: pickedImageBytes,
                      onTap: () async {
                        final img = await _pickImage();
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setDialogState(() {
                            pickedImage = img;
                            pickedImageBytes = bytes;
                            imageRemoved = false;
                          });
                        }
                      },
                      onRemove: (pickedImageBytes != null ||
                              (!imageRemoved && existingImageUrl != null))
                          ? () {
                              setDialogState(() {
                                pickedImage = null;
                                pickedImageBytes = null;
                                imageRemoved = true;
                              });
                            }
                          : null,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.productName,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label))),
                    SizedBox(height: 2.h),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.price2,
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder()))),
                      SizedBox(width: 3.w),
                      Expanded(
                          child: TextField(
                              controller: salePriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.salePrice,
                                  prefixText: '\$ ',
                                  border: const OutlineInputBorder(),
                                  hintText: AppLocalizations.of(context)!.optional,
                                  suffixIcon: salePriceController
                                          .text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 18),
                                          onPressed: () => setDialogState(
                                              () => salePriceController
                                                  .clear()))
                                      : null),
                              onChanged: (_) =>
                                  setDialogState(() {}))),
                    ]),
                    if (salePriceController.text.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      _buildSalePriceInfo(
                          priceController.text, salePriceController.text),
                    ],
                    SizedBox(height: 2.h),
                    TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.category,
                            hintText: AppLocalizations.of(context)!.eGBurgersDrinksDesserts,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category))),
                    SizedBox(height: 2.h),
                    TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.description,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true)),
                    SizedBox(height: 2.h),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.stockQty,
                                  hintText: AppLocalizations.of(context)!.optional,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory)))),
                      SizedBox(width: 3.w),
                      Expanded(
                          child: TextField(
                              controller: skuController,
                              decoration: InputDecoration(
                                  labelText: 'SKU',
                                  hintText: AppLocalizations.of(context)!.optional,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.qr_code)))),
                    ]),
                    SizedBox(height: 2.h),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.featuredProduct, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          isFeatured
                              ? AppLocalizations.of(context)!.shownInFeaturedSection
                              : AppLocalizations.of(context)!.notFeatured,
                          style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                      value: isFeatured,
                      activeColor: Colors.amber,
                      secondary: Icon(
                          isFeatured ? Icons.star : Icons.star_border,
                          color: isFeatured ? Colors.amber : null),
                      onChanged: (v) =>
                          setDialogState(() => isFeatured = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final priceText = priceController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(AppLocalizations.of(context)!.productNameIsRequired, maxLines: 1, overflow: TextOverflow.ellipsis)));
                          return;
                        }
                        if (priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(AppLocalizations.of(context)!.priceIsRequired, maxLines: 1, overflow: TextOverflow.ellipsis)));
                          return;
                        }
                        final price = double.tryParse(priceText);
                        if (price == null || price < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter a valid price')));
                          return;
                        }

                        double? salePrice;
                        final salePriceText =
                            salePriceController.text.trim();
                        if (salePriceText.isNotEmpty) {
                          salePrice = double.tryParse(salePriceText);
                          if (salePrice == null || salePrice < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter a valid sale price')));
                            return;
                          }
                          if (salePrice >= price) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.salePriceMustBeLessThan2, maxLines: 1, overflow: TextOverflow.ellipsis)));
                            return;
                          }
                        }

                        int? stock;
                        final stockText = stockController.text.trim();
                        if (stockText.isNotEmpty) {
                          stock = int.tryParse(stockText);
                          if (stock == null || stock < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter a valid stock quantity')));
                            return;
                          }
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          String? imageUrl;
                          if (pickedImage != null) {
                            imageUrl = await _uploadProductImage(
                                pickedImage!);
                          } else if (imageRemoved) {
                            imageUrl = null;
                          } else {
                            imageUrl = existingImageUrl;
                          }

                          final updates = <String, dynamic>{
                            'name': name,
                            'price': price,
                            'sale_price': salePrice,
                            'description': descriptionController.text
                                    .trim()
                                    .isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            'category': categoryController.text
                                    .trim()
                                    .isEmpty
                                ? null
                                : categoryController.text.trim(),
                            'image_url': imageUrl,
                            'stock_quantity': stock,
                            'sku': skuController.text.trim().isEmpty
                                ? null
                                : skuController.text.trim(),
                            'is_available': isAvailable,
                            'is_featured': isFeatured,
                          };

                          await ProductService.updateProduct(
                              product.id, updates);
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '"$name" updated successfully!', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor: Colors.green));
                          _loadStoreData();
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Error updating product: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor: Colors.red));
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.saveChanges, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalePriceInfo(String priceText, String salePriceText) {
    final price = double.tryParse(priceText);
    final salePrice = double.tryParse(salePriceText);

    if (price == null || salePrice == null || price <= 0 || salePrice <= 0) {
      return const SizedBox.shrink();
    }

    if (salePrice >= price) {
      return Padding(
        padding: EdgeInsets.only(left: 1.w),
        child: Text(
          AppLocalizations.of(context)!.salePriceMustBeLessThan2,
          style: TextStyle(color: Colors.red, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    final discount = (((price - salePrice) / price) * 100).round();
    return Padding(
      padding: EdgeInsets.only(left: 1.w),
      child: Row(
        children: [
          Icon(Icons.local_offer, size: 3.5.w, color: Colors.green),
          SizedBox(width: 1.w),
          Flexible(child: Text(
            '$discount% off  (\$${price.toStringAsFixed(2)} → \$${salePrice.toStringAsFixed(2)})',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM DELETE PRODUCT
  // ============================================================

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProduct, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text('Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ProductService.deleteProduct(product.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.productDeleted, maxLines: 1, overflow: TextOverflow.ellipsis),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStoreData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
