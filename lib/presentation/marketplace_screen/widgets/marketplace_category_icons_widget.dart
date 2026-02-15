import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/marketplace_category_model.dart';
import '../../../services/marketplace_category_service.dart';
import '../../../theme/app_theme.dart';

/// Marketplace-only category icons — loaded from marketplace_categories table.
/// Shows only primary + active categories on the home row.
class MarketplaceCategoryIconsWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const MarketplaceCategoryIconsWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<MarketplaceCategoryIconsWidget> createState() =>
      _MarketplaceCategoryIconsWidgetState();
}

class _MarketplaceCategoryIconsWidgetState
    extends State<MarketplaceCategoryIconsWidget> {
  List<MarketplaceCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await MarketplaceCategoryService().getPrimaryCategories();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = AppTheme.kjRed;

    if (_isLoading) {
      return SizedBox(
        height: 12.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(height: 12.h);
    }

    return SizedBox(
      height: 12.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = widget.selectedCategory == cat.id;

          return GestureDetector(
            onTap: () {
              widget.onCategorySelected(isSelected ? null : cat.id);
            },
            child: Container(
              width: 20.w,
              margin: EdgeInsets.only(right: 3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryRed
                          : primaryRed.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryRed.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _getIconData(cat.icon),
                      color: isSelected ? Colors.white : primaryRed,
                      size: 7.w,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? primaryRed
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}