import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
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

  final List<String> _recentSearches = [
    'organic apples',
    'fresh milk',
    'whole wheat bread'
  ];
  final List<String> _trendingProducts = [
    'avocados',
    'greek yogurt',
    'quinoa',
    'almond milk'
  ];
  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Bakery',
    'Snacks'
  ];

  List<Map<String, dynamic>> _searchResults = [];
  List<FilterChip> _activeFilters = [];
  Map<String, dynamic> _currentFilters = {};

  bool _isSearching = false;
  bool _isLoading = false;
  bool _showSuggestions = true;

  final bool _showVoiceSearch = false;
  final bool _showBarcodeScanner = false;

  // Mock product data
  final List<Map<String, dynamic>> _allProducts = [
    {
      "id": 1,
      "name": "Organic Bananas",
      "category": "Fruits",
      "price": "\$3.99",
      "rating": 4.5,
      "brand": "Organic Valley",
      "image": "https://images.unsplash.com/photo-1565804212260-280f967e431b",
      "semanticLabel": "Fresh yellow bananas in a bunch on white background",
      "dietary": ["Organic", "Vegan"],
    },
    {
      "id": 2,
      "name": "Fresh Whole Milk",
      "category": "Dairy",
      "price": "\$4.29",
      "rating": 4.8,
      "brand": "Farm Fresh",
      "image": "https://images.unsplash.com/photo-1631175316696-ee41839378dc",
      "semanticLabel": "Glass bottle of fresh white milk with blue label",
      "dietary": ["Organic"],
    },
    {
      "id": 3,
      "name": "Sourdough Bread",
      "category": "Bakery",
      "price": "\$5.99",
      "rating": 4.6,
      "brand": "Fresh Market",
      "image": "https://images.unsplash.com/photo-1586187524207-71b5dcf0fb84",
      "semanticLabel":
          "Rustic sourdough bread loaf with golden crust on wooden surface",
      "dietary": ["Vegetarian"],
    },
    {
      "id": 4,
      "name": "Greek Yogurt",
      "category": "Dairy",
      "price": "\$6.49",
      "rating": 4.7,
      "brand": "Pure & Simple",
      "image": "https://images.unsplash.com/photo-1562114808-b4b33cf60f4f",
      "semanticLabel": "White bowl of creamy Greek yogurt with wooden spoon",
      "dietary": ["Organic", "Vegetarian"],
    },
    {
      "id": 5,
      "name": "Free Range Eggs",
      "category": "Dairy",
      "price": "\$7.99",
      "rating": 4.9,
      "brand": "Nature's Best",
      "image": "https://images.unsplash.com/photo-1602268130253-6eaee701b532",
      "semanticLabel": "Dozen brown free-range eggs in cardboard carton",
      "dietary": ["Organic"],
    },
    {
      "id": 6,
      "name": "Organic Spinach",
      "category": "Vegetables",
      "price": "\$3.49",
      "rating": 4.4,
      "brand": "Green Choice",
      "image": "https://images.unsplash.com/photo-1518008147256-2f83e826c536",
      "semanticLabel": "Fresh green spinach leaves in clear plastic container",
      "dietary": ["Organic", "Vegan"],
    },
    {
      "id": 7,
      "name": "Almond Milk",
      "category": "Beverages",
      "price": "\$4.99",
      "rating": 4.3,
      "brand": "Pure & Simple",
      "image": "https://images.unsplash.com/photo-1601436423474-51738541c1b1",
      "semanticLabel":
          "Carton of unsweetened almond milk with almonds scattered around",
      "dietary": ["Vegan", "Gluten-Free"],
    },
    {
      "id": 8,
      "name": "Quinoa",
      "category": "Pantry Staples",
      "price": "\$8.99",
      "rating": 4.6,
      "brand": "Nature's Best",
      "image": "https://images.unsplash.com/photo-1623428187969-5da2dcea5ebf",
      "semanticLabel": "Bowl of uncooked quinoa grains with wooden spoon",
      "dietary": ["Organic", "Gluten-Free", "Vegan"],
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = List.from(_allProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  void _goToTab(int index) {
  AppRoutes.switchToTab(context, index);
}


  void _handleSearchChange(String query) => _performSearch(query);

  void _handleSearchSubmit(String query) => _performSearch(query);

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = List.from(_allProducts);
        _showSuggestions = true;
        _isSearching = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _showSuggestions = false;
    });

    if (!_recentSearches.contains(query.toLowerCase())) {
      _recentSearches.insert(0, query.toLowerCase());
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      final results = _allProducts.where((product) {
        final name = (product["name"] as String).toLowerCase();
        final category = (product["category"] as String).toLowerCase();
        final brand = (product["brand"] as String).toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            category.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();

      final filteredResults = _applyFilters(results);

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> filtered = List.from(products);

    final selectedCategories = _currentFilters['categories'] as List<String>?;
    if (selectedCategories?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return selectedCategories!.contains(product['category']);
      }).toList();
    }

    final minPrice = _currentFilters['minPrice'] as double?;
    final maxPrice = _currentFilters['maxPrice'] as double?;
    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((product) {
        final priceStr = (product['price'] as String).replaceAll('\$', '');
        final price = double.tryParse(priceStr) ?? 0;
        return (minPrice == null || price >= minPrice) &&
            (maxPrice == null || price <= maxPrice);
      }).toList();
    }

    final selectedBrands = _currentFilters['brands'] as List<String>?;
    if (selectedBrands?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        return selectedBrands!.contains(product['brand']);
      }).toList();
    }

    final selectedDietary = _currentFilters['dietary'] as List<String>?;
    if (selectedDietary?.isNotEmpty == true) {
      filtered = filtered.where((product) {
        final productDietary =
            (product['dietary'] as List<dynamic>).cast<String>();
        return selectedDietary!.any((diet) => productDietary.contains(diet));
      }).toList();
    }

    final minRating = _currentFilters['minRating'] as int?;
    if (minRating != null) {
      filtered = filtered.where((product) {
        final rating = product['rating'] as double;
        return rating >= minRating;
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

    final dietary = _currentFilters['dietary'] as List<String>?;
    if (dietary?.isNotEmpty == true) {
      for (final diet in dietary!) {
        chips.add(FilterChip(
          id: 'dietary_$diet',
          label: diet,
          category: 'dietary',
        ));
      }
    }

    final minRating = _currentFilters['minRating'] as int?;
    if (minRating != null) {
      chips.add(FilterChip(
        id: 'rating',
        label: '$minRating+ stars',
        category: 'rating',
      ));
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

  void _onProductTap(Map<String, dynamic> product) {
    Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product);
  }

  void _onAddToCart(Map<String, dynamic> product) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product["name"]} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => _goToTab(2),
        ),
      ),
    );
  }

  void _onAddToWishlist(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product["name"]} added to wishlist'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onShare(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${product["name"]}'),
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
