import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class MarketplaceCategoryIconsWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const MarketplaceCategoryIconsWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'vehicles', 'icon': Icons.directions_car, 'label': 'Vehicles'},
      {'id': 'properties', 'icon': Icons.home, 'label': 'Properties'},
      {
        'id': 'mobiles',
        'icon': Icons.phone_android,
        'label': 'Mobiles & Accessories',
      },
      {
        'id': 'electronics',
        'icon': Icons.tv,
        'label': 'Electronics & Appliances',
      },
      {'id': 'furniture', 'icon': Icons.chair, 'label': 'Furniture & Decor'},
    ];

    return SizedBox(
      height: 12.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              onCategorySelected(isSelected ? null : category['id'] as String);
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
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.black87,
                      size: 7.w,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.black87,
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
