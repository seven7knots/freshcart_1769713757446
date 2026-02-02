import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      "id": 1,
      "name": "Restaurants",
      "icon": Icons.restaurant,
      "color": Color(0xFFFF6B6B),
      "route": "/search-screen",
    },
    {
      "id": 2,
      "name": "Convenience Store",
      "icon": Icons.store,
      "color": Color(0xFF4ECDC4),
      "route": "/search-screen",
    },
    {
      "id": 3,
      "name": "Pharmacies",
      "icon": Icons.local_pharmacy,
      "color": Color(0xFF95E1D3),
      "route": "/search-screen",
    },
    {
      "id": 4,
      "name": "Market Place",
      "icon": Icons.shopping_bag,
      "color": Color(0xFFFFA07A),
      "route": "/marketplace-screen",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _categories.map((category) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: _buildCategoryCard(context, category),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          category["route"] as String,
          arguments: {'category': category["name"]},
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: (category["color"] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (category["color"] as Color).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category["icon"] as IconData,
              color: category["color"] as Color,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              category["name"] as String,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
}
