import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryCategories = [
      {'id': 'vehicles', 'icon': Icons.directions_car, 'name': 'Vehicles'},
      {'id': 'properties', 'icon': Icons.home, 'name': 'Properties'},
      {
        'id': 'mobiles',
        'icon': Icons.phone_android,
        'name': 'Mobiles & Accessories',
      },
      {
        'id': 'electronics',
        'icon': Icons.tv,
        'name': 'Electronics & Appliances',
      },
      {'id': 'furniture', 'icon': Icons.chair, 'name': 'Furniture & Decor'},
    ];

    final otherCategories = [
      {
        'id': 'business',
        'icon': Icons.business_center,
        'name': 'Businesses & Industrial',
      },
      {'id': 'pets', 'icon': Icons.pets, 'name': 'Pets'},
      {'id': 'kids', 'icon': Icons.child_care, 'name': 'Kids & Babies'},
      {
        'id': 'sports',
        'icon': Icons.sports_basketball,
        'name': 'Sports & Equipment',
      },
      {'id': 'hobbies', 'icon': Icons.palette, 'name': 'Hobbies'},
      {'id': 'jobs', 'icon': Icons.work, 'name': 'Jobs'},
      {'id': 'fashion', 'icon': Icons.checkroom, 'name': 'Fashion & Beauty'},
      {'id': 'services', 'icon': Icons.build, 'name': 'Services'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All categories',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          ...primaryCategories.map((category) {
            return _buildCategoryTile(
              context,
              icon: category['icon'] as IconData,
              name: category['name'] as String,
              categoryId: category['id'] as String,
            );
          }),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Text(
              'Others',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...otherCategories.map((category) {
            return _buildCategoryTile(
              context,
              icon: category['icon'] as IconData,
              name: category['name'] as String,
              categoryId: category['id'] as String,
            );
          }),
        ],
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: 0,
        onIndexChanged: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen);
          } else if (index == 3) {
            Navigator.pushNamed(context, '/my-ads-screen');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/marketplace-account-screen');
          }
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required IconData icon,
    required String name,
    required String categoryId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.categoryListingsScreen,
          arguments: categoryId,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 6.w,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 6.w,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
