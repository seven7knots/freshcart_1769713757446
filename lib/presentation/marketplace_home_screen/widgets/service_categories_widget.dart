import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ServiceCategoriesWidget extends StatelessWidget {
  const ServiceCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'icon': Icons.local_taxi,
        'name': 'Taxi',
        'type': 'taxi',
        'description': 'Quick rides around town'
      },
      {
        'icon': Icons.car_repair,
        'name': 'Towing',
        'type': 'towing',
        'description': 'Vehicle towing service'
      },
      {
        'icon': Icons.water_drop,
        'name': 'Water Delivery',
        'type': 'water_delivery',
        'description': 'Fresh water delivery'
      },
      {
        'icon': Icons.local_gas_station,
        'name': 'Diesel Delivery',
        'type': 'diesel_delivery',
        'description': 'Fuel delivery service'
      },
      {
        'icon': Icons.restaurant,
        'name': 'Private Chef',
        'type': 'private_chef',
        'description': 'Personal cooking service'
      },
      {
        'icon': Icons.fitness_center,
        'name': 'Personal Trainer',
        'type': 'personal_trainer',
        'description': 'Fitness coaching'
      },
      {
        'icon': Icons.drive_eta,
        'name': 'Private Driver',
        'type': 'private_driver',
        'description': 'Personal driver service'
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.serviceListingScreen,
                arguments: category['type']);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category['icon'] as IconData,
                    size: 40, color: AppTheme.lightTheme.colorScheme.primary),
                SizedBox(height: 1.h),
                Text(category['name'] as String,
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                SizedBox(height: 0.5.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(category['description'] as String,
                      style:
                          TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
