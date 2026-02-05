import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/category_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';

class CategoriesWidget extends StatefulWidget {
  const CategoriesWidget({super.key});

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

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
      final rows = await _categoryService.getRootCategories();
      setState(() {
        _categories = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _hasSubcategories(dynamic categoryId) async {
    try {
      final subs =
          await _categoryService.getSubcategories(categoryId.toString());
      return subs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onCategoryTap(Map<String, dynamic> category) async {
    final id = category['id'];
    final name = (category['name'] as String?) ?? 'Category';

    final isMarketplace = category['is_marketplace'] == true;
    if (isMarketplace) {
      Navigator.pushNamed(context, AppRoutes.marketplaceScreen);
      return;
    }

    final hasSubs = await _hasSubcategories(id);
    if (hasSubs) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': id,
          'parentCategoryName': name,
        },
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.categoryListingsScreen,
      arguments: {
        'categoryId': id,
        'fromTab': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = authProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.adminCategories),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
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
          SizedBox(height: 1.h),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                  ),
                ],
              ),
            )
          else if (_categories.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Text(
                'No categories yet. Create them from Admin → Categories.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
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
                        contentId: category['id']?.toString(),
                        contentData: category,
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
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, ThemeData theme) {
    final name = (category['name'] as String?) ?? 'Category';
    final colorHex = category['color'] as int?;
    final bg = colorHex != null ? Color(colorHex) : theme.colorScheme.primary;
    final iconName = (category['icon'] as String?) ?? 'category';

    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 2.h,
          horizontal: 3.w,
        ),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bg.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mapIcon(iconName),
              color: bg,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _mapIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'store':
        return Icons.store;
      case 'pharmacy':
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'marketplace':
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }
}

