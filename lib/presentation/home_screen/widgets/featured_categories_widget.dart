import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';

class FeaturedCategoriesWidget extends StatelessWidget {
  const FeaturedCategoriesWidget({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      "id": "cat-1",
      "categoryId": 1,
      "name": "Fresh Produce",
      "subtitle": "Fruits & Vegetables",
      "image": "https://images.unsplash.com/photo-1667988672217-10a31d5cca30",
      "semanticLabel":
          "Fresh organic vegetables including broccoli, carrots, and leafy greens in a wooden basket",
      "color": Color(0xFFFF3B30),
      "itemCount": 150,
    },
    {
      "id": "cat-2",
      "categoryId": 2,
      "name": "Dairy & Eggs",
      "subtitle": "Fresh from farm",
      "image": "https://images.unsplash.com/photo-1558475890-1ebfc06edcf5",
      "semanticLabel":
          "Glass bottles of fresh milk and various dairy products on a rustic wooden table",
      "color": Color(0xFF2196F3),
      "itemCount": 85,
    },
    {
      "id": "cat-3",
      "categoryId": 3,
      "name": "Meat & Seafood",
      "subtitle": "Premium quality",
      "image": "https://images.unsplash.com/photo-1580980906245-af3b357dcc84",
      "semanticLabel":
          "Fresh raw meat steaks with asparagus and herbs on dark wooden cutting board",
      "color": Color(0xFFE91E63),
      "itemCount": 120,
    },
    {
      "id": "cat-4",
      "categoryId": 4,
      "name": "Bakery",
      "subtitle": "Fresh baked daily",
      "image": "https://images.unsplash.com/photo-1596662850405-75dafe9a0338",
      "semanticLabel":
          "Sliced whole wheat bread loaf on wooden cutting board with flour dusting",
      "color": Color(0xFFFF9800),
      "itemCount": 95,
    },
    {
      "id": "cat-5",
      "categoryId": 5,
      "name": "Pantry Staples",
      "subtitle": "Essentials & more",
      "image": "https://images.unsplash.com/photo-1570384182225-e00c5765cd01",
      "semanticLabel":
          "Glass jars filled with various grains, pasta, and pantry staples on wooden shelves",
      "color": Color(0xFF795548),
      "itemCount": 200,
    },
    {
      "id": "cat-6",
      "categoryId": 6,
      "name": "Beverages",
      "subtitle": "Drinks & more",
      "image": "https://images.unsplash.com/photo-1676159434936-9c19c551d262",
      "semanticLabel":
          "Various colorful fruit juices and beverages in glass bottles arranged on white surface",
      "color": Color(0xFF9C27B0),
      "itemCount": 75,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = authProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop by Category',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Find everything you need',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isEditMode)
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.adminCategories),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 0.5.h),
                          margin: EdgeInsets.only(right: 2.w),
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
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.categoryListingsScreen,
                          arguments: const {
                            'categoryId': 'all',
                            'fromTab': true,
                          },
                        );
                      },
                      child: Text(
                        'See All',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 28.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final categoryCard = _buildCategoryCard(context, category);

                // Wrap with admin edit controls if in edit mode
                if (isEditMode) {
                  return AdminEditableItemWrapper(
                    contentType: 'category',
                    contentId: category['id']?.toString(),
                    contentData: {
                      'id': category['id'],
                      'name': category['name'],
                      'description': category['subtitle'],
                      'image_url': category['image'],
                      'is_active': true,
                    },
                    onDeleted: () {},
                    onUpdated: () {},
                    child: categoryCard,
                  );
                }

                return categoryCard;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _handleCategoryTap(context, category),
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: category["image"] as String,
                  fit: BoxFit.cover,
                  semanticLabel: category["semanticLabel"] as String,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 4.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category["name"] as String,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      category["subtitle"] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryTap(BuildContext context, Map<String, dynamic> category) {
    final int categoryId = (category["categoryId"] as int?) ?? 0;

    Navigator.pushNamed(
      context,
      AppRoutes.categoryListingsScreen,
      arguments: {
        'categoryId': categoryId,
        'fromTab': true,
      },
    );
  }
}

