import 'dart:async';

import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/product_grid_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_suggestions_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _recentSearches = [];
  final List<String> _trendingProducts = [];
  List<String> _categories = [];

  List<Product> _searchResults = [];
  List<FilterChip> _activeFilters = [];
  Map<String, dynamic> _currentFilters = {};

  bool _isSearching = false;
  bool _isLoading = false;
  bool _showSuggestions = true;
  bool _categoriesLoaded = false;

  final bool _showVoiceSearch = false;
  final bool _showBarcodeScanner = false;

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
      // Load some initial products to display
      final products = await ProductService.getAllProducts(
        availableOnly: true,
        excludeDemo: true,
      );

      if (mounted) {
        setState(() {
          _searchResults = products.take(20).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SEARCH] Error loading initial products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  void _goToTab(int index) {
    AppRoutes.switchToTab(context, index);
  }

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

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      await _loadInitialProducts();
      setState(() {
        _showSuggestions = true;
        _isSearching = false;
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
      // Search products from database
      final results = await ProductService.searchProducts(
        query,
        availableOnly: true,
      );

      if (mounted) {
        final filteredResults = _applyFilters(results);
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SEARCH] Error performing search: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    List<Product> filtered = List.from(products);

    // Filter by categories
    final selectedCategories = _currentFilters['categories'] as List<String>?;
    if (selectedCategories?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return selectedCategories!.contains(product.category);
      }).toList();
    }

    // Filter by price range
    final minPrice = _currentFilters['minPrice'] as double?;
    final maxPrice = _currentFilters['maxPrice'] as double?;
    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((product) {
        final price = product.effectivePrice;
        return (minPrice == null || price >= minPrice) &&
            (maxPrice == null || price <= maxPrice);
      }).toList();
    }

    // Filter by brands (store names in this case)
    final selectedBrands = _currentFilters['brands'] as List<String>?;
    if (selectedBrands?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return product.storeName != null &&
            selectedBrands!.contains(product.storeName);
      }).toList();
    }

    // Note: Dietary filters would require adding dietary info to Product model
    // Skipping for now

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

    setState(() {
      _activeFilters = chips;
    });
  }

  void _removeFilter(String filterId) {
    if (filterId.startsWith('category_')) {
      final category = filterId.replaceFirst('category_', '');
      final categories = (_currentFilters['categories'] as List<String>?) ?? [];
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

  void _onProductTap(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: product,
    );
  }

  void _onAddToCart(Product product) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => _goToTab(2),
        ),
      ),
    );
  }

  void _onAddToWishlist(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to wishlist'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onShare(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${product.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
                backgroundColor: cs.surface,
                foregroundColor: cs.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: cs.shadow.withOpacity(0.10),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => _goToTab(2),
                    tooltip: 'Shopping cart',
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
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(
                  children: [
                    SearchBarWidget(
                      controller: _searchController,
                      onChanged: _handleSearchChange,
                      onSubmitted: _handleSearchSubmit,
                      onVoicePressed: _showVoiceSearch ? () {} : null,
                      onBarcodePressed: _showBarcodeScanner ? () {} : null,
                      onAIPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.aiChatAssistant),
                      isLoading: _isLoading,
                    ),
                    if (_activeFilters.isNotEmpty)
                      FilterChipsWidget(
                        activeFilters: _activeFilters,
                        onFilterPressed: _showFilterBottomSheet,
                        onRemoveFilter: _removeFilter,
                      ),
                    Expanded(
                      child: _showSuggestions && !_isSearching
                          ? SearchSuggestionsWidget(
                              recentSearches: _recentSearches,
                              trendingProducts: _trendingProducts,
                              categories: _categories,
                              onSuggestionTap: (suggestion) {
                                _searchController.text = suggestion;
                                _performSearch(suggestion);
                              },
                              onClearRecentSearches: () {
                                setState(() => _recentSearches.clear());
                              },
                            )
                          : ProductGridWidget(
                              products: _searchResults,
                              isLoading: _isLoading,
                              onProductTap: _onProductTap,
                              onAddToCart: _onAddToCart,
                              onAddToWishlist: _onAddToWishlist,
                              onShare: _onShare,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}