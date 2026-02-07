import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/category_model.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all top-level categories with their subcategories
      final categories = await CategoryService.getCategoriesWithSubcategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ALL_CATEGORIES] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onCategoryTap(Category category) async {
    // Check if this category has subcategories
    if (category.hasSubcategories) {
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': category.id,
          'parentCategoryName': category.name,
        },
      );
    } else {
      // Check from database if it has subcategories
      final hasSubcats = await CategoryService.hasSubcategories(category.id);
      
      if (!mounted) return;

      if (hasSubcats) {
        Navigator.pushNamed(
          context,
          AppRoutes.subcategoriesScreen,
          arguments: {
            'parentCategoryId': category.id,
            'parentCategoryName': category.name,
          },
        );
      } else {
        // Navigate to category listings
        Navigator.pushNamed(
          context,
          AppRoutes.categoryListingsScreen,
          arguments: category.id,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Categories',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_categories.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryTile(context, category);
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 15.w,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Failed to load categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadCategories,
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
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 15.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Categories will appear here once created by admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    final theme = Theme.of(context);
    final iconData = _getIconForCategory(category.icon);
    final color = _getColorForType(category.type);
    final hasSubcategories = category.hasSubcategories;

    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 6.w,
                color: color,
              ),
            ),
            SizedBox(width: 4.w),
            
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (category.description != null && category.description!.isNotEmpty) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      category.description!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasSubcategories) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      '${category.subcategories!.length} subcategories',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Arrow or count badge
            if (hasSubcategories)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${category.subcategories!.length}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chevron_right,
                      size: 4.w,
                      color: color,
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 6.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.category;
    
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'store':
      case 'shop':
        return Icons.store;
      case 'pharmacy':
      case 'local_pharmacy':
      case 'medical':
        return Icons.local_pharmacy;
      case 'grocery':
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag;
      case 'fastfood':
      case 'fast_food':
        return Icons.fastfood;
      case 'coffee':
      case 'cafe':
        return Icons.coffee;
      case 'bakery':
      case 'cake':
        return Icons.cake;
      case 'electronics':
      case 'devices':
        return Icons.devices;
      case 'fashion':
      case 'checkroom':
        return Icons.checkroom;
      case 'home':
      case 'house':
        return Icons.home;
      case 'sports':
      case 'fitness':
        return Icons.sports;
      case 'pets':
      case 'pet':
        return Icons.pets;
      case 'services':
      case 'handyman':
        return Icons.handyman;
      case 'beauty':
      case 'spa':
        return Icons.spa;
      case 'marketplace':
        return Icons.storefront;
      case 'vehicles':
      case 'car':
        return Icons.directions_car;
      case 'properties':
      case 'real_estate':
        return Icons.apartment;
      case 'mobiles':
      case 'phone':
        return Icons.phone_android;
      case 'furniture':
        return Icons.chair;
      case 'business':
        return Icons.business_center;
      case 'kids':
      case 'baby':
        return Icons.child_care;
      case 'hobbies':
        return Icons.palette;
      case 'jobs':
      case 'work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  Color _getColorForType(String? type) {
    if (type == null || type.isEmpty) return Colors.blue;
    
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Colors.orange;
      case 'grocery':
        return Colors.green;
      case 'pharmacy':
        return Colors.red;
      case 'retail':
      case 'shopping':
        return Colors.blue;
      case 'services':
        return Colors.purple;
      case 'marketplace':
        return Colors.teal;
      case 'bakery':
        return Colors.brown;
      case 'electronics':
        return Colors.indigo;
      case 'fashion':
        return Colors.pink;
      case 'vehicles':
        return Colors.blueGrey;
      case 'properties':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}