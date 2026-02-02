import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FeaturedCategoriesWidget extends StatelessWidget {
  const FeaturedCategoriesWidget({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      "id": 1,
      "name": "Fresh Produce",
      "subtitle": "Fruits & Vegetables",
      "image": "https://images.unsplash.com/photo-1667988672217-10a31d5cca30",
      "semanticLabel":
          "Fresh organic vegetables including broccoli, carrots, and leafy greens in a wooden basket",
      "color": Color(0xFFFF3B30),
      "itemCount": 150,
    },
    {
      "id": 2,
      "name": "Dairy & Eggs",
      "subtitle": "Fresh from farm",
      "image": "https://images.unsplash.com/photo-1558475890-1ebfc06edcf5",
      "semanticLabel":
          "Glass bottles of fresh milk and various dairy products on a rustic wooden table",
      "color": Color(0xFF2196F3),
      "itemCount": 85,
    },
    {
      "id": 3,
      "name": "Meat & Seafood",
      "subtitle": "Premium quality",
      "image": "https://images.unsplash.com/photo-1580980906245-af3b357dcc84",
      "semanticLabel":
          "Fresh raw meat steaks with asparagus and herbs on dark wooden cutting board",
      "color": Color(0xFFE91E63),
      "itemCount": 120,
    },
    {
      "id": 4,
      "name": "Bakery",
      "subtitle": "Fresh baked daily",
      "image": "https://images.unsplash.com/photo-1596662850405-75dafe9a0338",
      "semanticLabel":
          "Sliced whole wheat bread loaf on wooden cutting board with flour dusting",
      "color": Color(0xFFFF9800),
      "itemCount": 95,
    },
    {
      "id": 5,
      "name": "Pantry Staples",
      "subtitle": "Essentials & more",
      "image": "https://images.unsplash.com/photo-1570384182225-e00c5765cd01",
      "semanticLabel":
          "Glass jars filled with various grains, pasta, and pantry staples on wooden shelves",
      "color": Color(0xFF795548),
      "itemCount": 200,
    },
    {
      "id": 6,
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/search-screen'),
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
                return _buildCategoryCard(context, category);
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
      onLongPress: () => _showCategoryOptions(context, category),
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: category["image"] as String,
                  fit: BoxFit.cover,
                  semanticLabel: category["semanticLabel"] as String,
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Category Badge
              Positioned(
                top: 3.w,
                right: 3.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: (category["color"] as Color).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category["itemCount"]} items',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              // Content
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
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      category["subtitle"] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(width: 1.w),
                          CustomIconWidget(
                            iconName: 'arrow_forward',
                            color: Colors.white,
                            size: 4.w,
                          ),
                        ],
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
    Navigator.pushNamed(context, '/search-screen');
  }

  void _showCategoryOptions(
      BuildContext context, Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              category["name"] as String,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border',
                color: Theme.of(context).colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                'Add to Favorites',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category["name"]} added to favorites'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: Theme.of(context).colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                'Share Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing ${category["name"]} category'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
