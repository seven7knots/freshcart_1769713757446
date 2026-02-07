import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/store_model.dart';
import '../../models/category_model.dart';
import '../../routes/app_routes.dart';
import '../../services/store_service.dart';
import '../../services/category_service.dart';
import '../../widgets/animated_press_button.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  String? _error;
  
  List<Store> _allStores = [];
  List<Store> _filteredStores = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadStores();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stores = await StoreService.getAllStores(activeOnly: false);
      
      if (mounted) {
        setState(() {
          _allStores = stores;
          _filteredStores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[STORES_SCREEN] Error loading stores: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await CategoryService.getTopLevelCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('[STORES_SCREEN] Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _filterStores() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredStores = _allStores.where((store) {
        // Filter by search query
        final matchesSearch = query.isEmpty ||
            store.name.toLowerCase().contains(query) ||
            (store.description?.toLowerCase().contains(query) ?? false) ||
            (store.category?.toLowerCase().contains(query) ?? false);
        
        // Filter by category - match category name string
        bool matchesCategory = true;
        if (_selectedCategoryId != null) {
          // Find the selected category name
          final selectedCategory = _categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => Category(
              id: '',
              name: '',
              type: 'product',
              sortOrder: 0,
              isActive: true,
              isDemo: false,
            ),
          );
          // Match store's category string with selected category name
          matchesCategory = store.category == selectedCategory.name;
        }
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _filterStores();
  }

  void _navigateToStore(Store store) {
    Navigator.pushNamed(
      context,
      AppRoutes.merchantStore,
      arguments: {'storeId': store.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'All Stores',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStores();
              _loadCategories();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(theme),
          
          // Category Filter
          if (_categories.isNotEmpty)
            _buildCategoryFilter(theme),
          
          // Store Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Text(
                  '${_filteredStores.length} ${_filteredStores.length == 1 ? 'Store' : 'Stores'}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_selectedCategoryId != null) ...[
                  Text(
                    ' in ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _categories
                        .firstWhere((c) => c.id == _selectedCategoryId)
                        .name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  AnimatedPressButton(
                    onPressed: () => _onCategorySelected(null),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Stores Grid/List
          Expanded(
            child: _isLoading
                ? _buildLoadingState(theme)
                : _error != null
                    ? _buildErrorState(theme)
                    : _filteredStores.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildStoresGrid(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterStores(),
        decoration: InputDecoration(
          hintText: 'Search stores...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStores();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return SizedBox(
      height: 6.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        children: [
          // All Categories chip
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: AnimatedPressButton(
              onPressed: () => _onCategorySelected(null),
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
          ..._categories.map((category) {
            final isSelected = _selectedCategoryId == category.id;
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: AnimatedPressButton(
                onPressed: () => _onCategorySelected(category.id),
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
    );
  }

  Widget _buildStoresGrid(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadStores,
      child: GridView.builder(
        padding: EdgeInsets.all(4.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredStores.length,
        itemBuilder: (context, index) {
          return _buildStoreCard(_filteredStores[index], theme);
        },
      ),
    );
  }

  Widget _buildStoreCard(Store store, ThemeData theme) {
    return AnimatedPressButton(
      onPressed: () => _navigateToStore(store),
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
            // Store Image
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
                      imageUrl: store.imageUrl ??
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                      fit: BoxFit.cover,
                      semanticLabel: 'Store front of ${store.name}',
                    ),
                    if (!store.isActive || !store.isAcceptingOrders)
                      Container(
                        color: theme.colorScheme.surface.withOpacity(0.8),
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
                              'Closed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Rating badge
                    if (store.rating > 0)
                      Positioned(
                        top: 1.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 3.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                store.ratingDisplay,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Store Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    if (store.category != null)
                      Text(
                        store.category!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 3.w,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          store.prepTimeDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
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

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
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
              'Failed to load stores',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadStores,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 3.h),
            Text(
              'No stores found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchController.text.isNotEmpty || _selectedCategoryId != null
                  ? 'Try adjusting your search or filter'
                  : 'No stores available yet',
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
}