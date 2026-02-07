import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../models/category_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/category_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';

class CategoriesWidget extends StatefulWidget {
  const CategoriesWidget({super.key});

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadRootCategories();
  }

  Future<void> _loadRootCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get top-level categories (where parent_id is null)
      final categories = await CategoryService.getTopLevelCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CATEGORIES_WIDGET] Error loading categories: $e');
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
    final hasSubcats = await CategoryService.hasSubcategories(category.id);
    
    if (!mounted) return;

    if (hasSubcats) {
      // Navigate to subcategories screen
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': category.id,
          'parentCategoryName': category.name,
        },
      );
    } else {
      // Navigate to category listings (products/stores in this category)
      Navigator.pushNamed(
        context,
        AppRoutes.categoryListingsScreen,
        arguments: category.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Categories',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isEditMode)
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminCategories),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
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
                            'Add',
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
                  onPressed: _loadRootCategories,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh categories',
                ),
              ],
            ),
          ),
          
          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState(theme)
          else if (_categories.isEmpty)
            _buildEmptyState(theme)
          else
            _buildCategoriesGrid(theme, isEditMode),
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

  Widget _buildErrorState(ThemeData theme) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Failed to load categories',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadRootCategories,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
              Icons.category_outlined,
              size: 10.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 1.h),
            Text(
              'No categories yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Categories will appear here once created',
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

  Widget _buildCategoriesGrid(ThemeData theme, bool isEditMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Wrap(
        spacing: 3.w,
        runSpacing: 2.h,
        children: _categories.map((category) {
          final categoryCard = _buildCategoryCard(category, theme);

          // Wrap with admin edit controls if in edit mode
          if (isEditMode) {
            return SizedBox(
              width: (100.w - (4.w * 2) - 3.w) / 2,
              child: AdminEditableItemWrapper(
                contentType: 'category',
                contentId: category.id,
                contentData: category.toMap(),
                onDeleted: _loadRootCategories,
                onUpdated: _loadRootCategories,
                child: categoryCard,
              ),
            );
          }

          return SizedBox(
            width: (100.w - (4.w * 2) - 3.w) / 2,
            child: categoryCard,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, ThemeData theme) {
    // Determine icon and color
    final iconData = _getIconForCategory(category.icon);
    final bgColor = _getColorForType(category.type, theme);

    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bgColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: bgColor,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              category.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.storeCount > 0) ...[
              SizedBox(height: 0.5.h),
              Text(
                '${category.storeCount} stores',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 9.sp,
                ),
              ),
            ],
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
      default:
        return Icons.category;
    }
  }

  Color _getColorForType(String? type, ThemeData theme) {
    if (type == null || type.isEmpty) return theme.colorScheme.primary;
    
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
      default:
        return theme.colorScheme.primary;
    }
  }
}