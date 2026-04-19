import 'dart:async';

import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/product_grid_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_suggestions_widget.dart';
import './widgets/store_results_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _recentSearches = [];
  final List<String> _trendingProducts = [];
  List<String> _categories = [];

  // SESSION 19: Three result types
  List<Product> _searchResults = [];
  List<StoreResultCard> _storeResults = [];
  List<CategoryResultCard> _categoryResults = [];

  List<FilterChip> _activeFilters = [];
  Map<String, dynamic> _currentFilters = {};

  bool _isSearching = false;
  bool _isLoading = false;
  bool _showSuggestions = true;
  bool _categoriesLoaded = false;

  final bool _showVoiceSearch = false;
  final bool _showBarcodeScanner = false;

  static SupabaseClient get _supabase => SupabaseService.client;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getTopLevelCategories();
      if (mounted) {
        setState(() {
          _categories = categories.map((c) => c.name).toList();
          _categoriesLoaded = true;
        });
        debugPrint('[SEARCH] Loaded ${_categories.length} categories');
      }
    } catch (e) {
      debugPrint('[SEARCH] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _categoriesLoaded = true;
        });
      }
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);

    try {
      final products = await ProductService.getAllProducts(
        availableOnly: true,
        excludeDemo: true,
      );

      debugPrint('[SEARCH] Initial products loaded: ${products.length}');

      if (mounted) {
        setState(() {
          _searchResults = products.take(20).toList();
          _storeResults = [];
          _categoryResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SEARCH] Error loading initial products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  bool get _hasSuggestions =>
      _recentSearches.isNotEmpty ||
      _trendingProducts.isNotEmpty ||
      _categories.isNotEmpty;

  void _handleSearchChange(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _handleSearchSubmit(String query) {
    _debounce?.cancel();
    _performSearch(query);
  }

  // ============================================================
  // Smart suggestion tap — detect category vs text search
  // ============================================================

  void _handleSuggestionTap(String suggestion) {
    final isCategoryTap = _categories
        .any((cat) => cat.toLowerCase() == suggestion.toLowerCase());

    if (isCategoryTap) {
      debugPrint(
          '[SEARCH] Category tapped: $suggestion — filtering by category');
      _searchController.text = suggestion;
      _performSearch(suggestion);
    } else {
      debugPrint(
          '[SEARCH] Suggestion tapped: $suggestion — performing text search');
      _searchController.text = suggestion;
      _performSearch(suggestion);
    }
  }

  // ============================================================
  // SESSION 20 FIX (Bug 1): min_order → minimum_order
  // ============================================================

  Future<List<StoreResultCard>> _searchStores(String query) async {
    try {
      final results = await _supabase
          .from('stores')
          .select(
              'id, name, description, category, rating, is_active, image_url, delivery_fee, minimum_order')
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(10);

      final stores = (results as List)
          .map((s) => StoreResultCard.fromMap(s as Map<String, dynamic>))
          .toList();

      debugPrint('[SEARCH] Found ${stores.length} stores for "$query"');
      return stores;
    } catch (e) {
      debugPrint('[SEARCH] Store search error: $e');
      return [];
    }
  }

  // ============================================================
  // SESSION 19: Search categories/subcategories from Supabase
  // ============================================================

  Future<List<CategoryResultCard>> _searchCategories(String query) async {
    try {
      final results = await _supabase
          .from('categories')
          .select('id, name, name_ar, type, icon, image_url, parent_id')
          .eq('is_active', true)
          .eq('is_demo', false)
          .or('name.ilike.%$query%,name_ar.ilike.%$query%')
          .order('sort_order', ascending: true)
          .limit(10);

      final categories = (results as List)
          .map((c) => CategoryResultCard.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint('[SEARCH] Found ${categories.length} categories for "$query"');
      return categories;
    } catch (e) {
      debugPrint('[SEARCH] Category search error: $e');
      return [];
    }
  }

  // ============================================================
  // SESSION 19: Unified search — categories + stores + products
  // ============================================================

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      await _loadInitialProducts();
      setState(() {
        _showSuggestions = true;
        _isSearching = false;
        _storeResults = [];
        _categoryResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _showSuggestions = false;
    });

    // Add to recent searches
    if (!_recentSearches.contains(query.toLowerCase())) {
      setState(() {
        _recentSearches.insert(0, query.toLowerCase());
        if (_recentSearches.length > 5) _recentSearches.removeLast();
      });
    }

    try {
      // Search categories, stores, and products IN PARALLEL
      final results = await Future.wait([
        _searchCategories(query),
        _searchStores(query),
        ProductService.searchProducts(query, availableOnly: true),
      ]);

      final categoryResults = results[0] as List<CategoryResultCard>;
      final storeResults = results[1] as List<StoreResultCard>;
      final productResults = results[2] as List<Product>;

      debugPrint(
          '[SEARCH] Unified "$query": ${categoryResults.length} categories, '
          '${storeResults.length} stores, ${productResults.length} products');

      if (mounted) {
        final filteredProducts = _applyFilters(productResults);
        setState(() {
          _categoryResults = categoryResults;
          _storeResults = storeResults;
          _searchResults = filteredProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SEARCH] Error performing search: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _storeResults = [];
          _categoryResults = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    List<Product> filtered = List.from(products);

    final selectedCategories = _currentFilters['categories'] as List<String>?;
    if (selectedCategories?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return selectedCategories!.contains(product.category);
      }).toList();
    }

    final minPrice = _currentFilters['minPrice'] as double?;
    final maxPrice = _currentFilters['maxPrice'] as double?;
    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((product) {
        final price = product.effectivePrice;
        return (minPrice == null || price >= minPrice) &&
            (maxPrice == null || price <= maxPrice);
      }).toList();
    }

    final selectedBrands = _currentFilters['brands'] as List<String>?;
    if (selectedBrands?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return product.storeName != null &&
            selectedBrands!.contains(product.storeName);
      }).toList();
    }

    return filtered;
  }

  void _updateActiveFilters() {
    final List<FilterChip> chips = [];

    final categories = _currentFilters['categories'] as List<String>?;
    if (categories?.isNotEmpty == true) {
      for (final category in categories!) {
        chips.add(FilterChip(
          id: 'category_$category',
          label: category,
          category: 'category',
        ));
      }
    }

    final minPrice = _currentFilters['minPrice'] as double?;
    final maxPrice = _currentFilters['maxPrice'] as double?;
    if (minPrice != null || maxPrice != null) {
      chips.add(FilterChip(
        id: 'price',
        label: '\$${minPrice?.round() ?? 0} - \$${maxPrice?.round() ?? 100}',
        category: 'price',
      ));
    }

    final brands = _currentFilters['brands'] as List<String>?;
    if (brands?.isNotEmpty == true) {
      for (final brand in brands!) {
        chips.add(FilterChip(
          id: 'brand_$brand',
          label: brand,
          category: 'brand',
        ));
      }
    }

    setState(() => _activeFilters = chips);
  }

  void _removeFilter(String filterId) {
    if (filterId.startsWith('category_')) {
      final category = filterId.replaceFirst('category_', '');
      final categories =
          (_currentFilters['categories'] as List<String>?) ?? [];
      categories.remove(category);
      if (categories.isEmpty) {
        _currentFilters.remove('categories');
      } else {
        _currentFilters['categories'] = categories;
      }
    } else if (filterId == 'price') {
      _currentFilters.remove('minPrice');
      _currentFilters.remove('maxPrice');
    } else if (filterId.startsWith('brand_')) {
      final brand = filterId.replaceFirst('brand_', '');
      final brands = (_currentFilters['brands'] as List<String>?) ?? [];
      brands.remove(brand);
      if (brands.isEmpty) {
        _currentFilters.remove('brands');
      } else {
        _currentFilters['brands'] = brands;
      }
    } else if (filterId.startsWith('dietary_')) {
      final diet = filterId.replaceFirst('dietary_', '');
      final dietary = (_currentFilters['dietary'] as List<String>?) ?? [];
      dietary.remove(diet);
      if (dietary.isEmpty) {
        _currentFilters.remove('dietary');
      } else {
        _currentFilters['dietary'] = dietary;
      }
    } else if (filterId == 'rating') {
      _currentFilters.remove('minRating');
    }

    _updateActiveFilters();
    _performSearch(_searchController.text);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() => _currentFilters = filters);
          _updateActiveFilters();
          _performSearch(_searchController.text);
        },
        onClearAll: () {
          setState(() {
            _currentFilters.clear();
            _activeFilters.clear();
          });
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  // ============================================================
  // SESSION 19: Navigation handlers
  // ============================================================

  void _onProductTap(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  void _onStoreTap(StoreResultCard store) {
    Navigator.pushNamed(
      context,
      AppRoutes.storeDetail,
      arguments: {'storeId': store.id},
    );
  }

  void _onCategoryTap(CategoryResultCard category) {
    Navigator.pushNamed(
      context,
      AppRoutes.categoryStoresScreen,
      arguments: {
        'categoryId': category.id,
        'categoryName': category.name,
      },
    );
  }

  // ============================================================
  // SESSION 33 FIX #1: Actually add to cart via CartNotifier
  // Previously this was only showing a snackbar and never
  // calling CartNotifier — so 0 items were ever added.
  // ============================================================

  Future<void> _onAddToCart(Product product) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(cartNotifierProvider.notifier).addToCart(
            productId: product.id,
            quantity: 1,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart', maxLines: 1, overflow: TextOverflow.ellipsis),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.viewCart,
              onPressed: () => AppRoutes.openCart(context),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[SEARCH] ❌ Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onAddToWishlist(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to wishlist', maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onShare(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${product.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: _shouldShowBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: null,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: cs.shadow.withOpacity(0.10),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => AppRoutes.openCart(context),
                    tooltip: AppLocalizations.of(context)!.shoppingCart,
                  ),
                ],
              ),
            ),
          ];
        },
        body: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    onChanged: _handleSearchChange,
                    onSubmitted: _handleSearchSubmit,
                    onVoicePressed: _showVoiceSearch ? () {} : null,
                    onBarcodePressed: _showBarcodeScanner ? () {} : null,
                    onAIPressed: () => AppRoutes.switchToTab(context, 2),
                    isLoading: _isLoading,
                  ),
                  if (_activeFilters.isNotEmpty)
                    FilterChipsWidget(
                      activeFilters: _activeFilters,
                      onFilterPressed: _showFilterBottomSheet,
                      onRemoveFilter: _removeFilter,
                    ),
                  Expanded(
                    child: _showSuggestions && !_isSearching && _hasSuggestions
                        ? SearchSuggestionsWidget(
                            recentSearches: _recentSearches,
                            trendingProducts: _trendingProducts,
                            categories: _categories,
                            onSuggestionTap: _handleSuggestionTap,
                            onClearRecentSearches: () {
                              setState(() => _recentSearches.clear());
                            },
                          )
                        : _buildResultsView(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SESSION 19: Unified results — categories → stores → products
  // ============================================================

  Widget _buildResultsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasCategories = _categoryResults.isNotEmpty;
    final hasStores = _storeResults.isNotEmpty;
    final hasProducts = _searchResults.isNotEmpty;

    if (!hasCategories && !hasStores && !hasProducts && _isSearching) {
      return _buildEmptyState();
    }

    // ── Single ListView — no nested scroll views ──────────────
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Categories section
        if (hasCategories)
          CategoryResultsWidget(
            categories: _categoryResults,
            onCategoryTap: _onCategoryTap,
          ),

        // Stores section
        if (hasStores)
          StoreResultsWidget(
            stores: _storeResults,
            onStoreTap: _onStoreTap,
          ),

        // Divider + products header
        if ((hasCategories || hasStores) && hasProducts)
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  height: 1,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 2.w),
                    Flexible(child: Text(
                      'Products (${_searchResults.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                SizedBox(height: 0.5.h),
              ],
            ),
          ),

        // Products grid — inline, not in a separate scroll view
        if (hasProducts)
          ProductGridWidget(
            products: _searchResults,
            isLoading: false,
            onProductTap: _onProductTap,
            onAddToCart: _onAddToCart,
            onRemoveFromCart: (_) {},
            onAddToWishlist: _onAddToWishlist,
            onShare: _onShare,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),

        // No products but has other results
        if (!hasProducts && (hasCategories || hasStores))
          Padding(
            padding: EdgeInsets.all(6.w),
            child: Text(
              AppLocalizations.of(context)!.noProductsFoundForThisSearch,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),

        SizedBox(height: 4.h),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noResultsFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tryADifferentSearchTermOr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}