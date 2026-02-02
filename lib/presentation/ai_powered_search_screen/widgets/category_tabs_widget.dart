import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoryTabsWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryTabsWidget({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE50914)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(5.w),
              ),
              child: Center(
                child: Text(
                  _getCategoryLabel(category),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'All';
      case 'groceries':
        return 'Groceries';
      case 'restaurants':
        return 'Restaurants';
      case 'pharmacy':
        return 'Pharmacy';
      case 'retail':
        return 'Retail';
      case 'services':
        return 'Services';
      default:
        return category;
    }
  }
}
