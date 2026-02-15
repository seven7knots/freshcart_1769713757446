import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/marketplace_category_model.dart';
import '../../routes/app_routes.dart';
import '../../services/marketplace_category_service.dart';
import '../../theme/app_theme.dart';

/// All Categories screen for the MARKETPLACE only.
/// Loads categories from the marketplace_categories table.
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  List<MarketplaceCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats =
          await MarketplaceCategoryService().getCategories(activeOnly: true);
      if (mounted) setState(() { _categories = cats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconData(String iconName) {
    const map = <String, IconData>{
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'phone_android': Icons.phone_android,
      'tv': Icons.tv,
      'chair': Icons.chair,
      'business_center': Icons.business_center,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'sports_soccer': Icons.sports_soccer,
      'palette': Icons.palette,
      'work': Icons.work,
      'checkroom': Icons.checkroom,
      'handyman': Icons.handyman,
      'category': Icons.category,
    };
    return map[iconName.toLowerCase()] ?? Icons.category;
  }

  void _onCategoryTap(String categoryId) {
    Navigator.pushNamed(
      context,
      AppRoutes.categoryListingsScreen,
      arguments: categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = _categories.where((c) => c.isPrimary).toList();
    final secondary = _categories.where((c) => !c.isPrimary).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Categories',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    children: [
                      // Primary categories
                      ...primary.map((cat) => _buildCategoryTile(cat, theme)),

                      // "Others" section header
                      if (secondary.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h, bottom: 1.h),
                          child: Text(
                            'Others',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      // Secondary categories
                      ...secondary
                          .map((cat) => _buildCategoryTile(cat, theme)),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryTile(
      MarketplaceCategoryModel cat, ThemeData theme) {
    final primaryRed = AppTheme.kjRed;

    return GestureDetector(
      onTap: () => _onCategoryTap(cat.id),
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
            // Red circle icon
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(cat.icon),
                size: 6.w,
                color: primaryRed,
              ),
            ),
            SizedBox(width: 4.w),

            // Category name
            Expanded(
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),

            // Chevron
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
}