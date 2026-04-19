import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class ServiceCategoriesWidget extends StatelessWidget {
  const ServiceCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final categories = [
      {
        'icon': Icons.local_taxi,
        'name': AppLocalizations.of(context)!.taxi,
        'type': 'taxi',
        'description': AppLocalizations.of(context)!.quickRidesAroundTown
      },
      {
        'icon': Icons.car_repair,
        'name': AppLocalizations.of(context)!.towing,
        'type': 'towing',
        'description': AppLocalizations.of(context)!.vehicleTowingService
      },
      {
        'icon': Icons.water_drop,
        'name': AppLocalizations.of(context)!.waterDelivery,
        'type': 'water_delivery',
        'description': AppLocalizations.of(context)!.freshWaterDelivery
      },
      {
        'icon': Icons.local_gas_station,
        'name': AppLocalizations.of(context)!.dieselDelivery,
        'type': 'diesel_delivery',
        'description': AppLocalizations.of(context)!.fuelDeliveryService
      },
      {
        'icon': Icons.restaurant,
        'name': AppLocalizations.of(context)!.privateChef,
        'type': 'private_chef',
        'description': AppLocalizations.of(context)!.personalCookingService
      },
      {
        'icon': Icons.fitness_center,
        'name': AppLocalizations.of(context)!.personalTrainer,
        'type': 'personal_trainer',
        'description': AppLocalizations.of(context)!.fitnessCoaching
      },
      {
        'icon': Icons.drive_eta,
        'name': AppLocalizations.of(context)!.privateDriver,
        'type': 'private_driver',
        'description': AppLocalizations.of(context)!.personalDriverService
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
              color: theme.colorScheme.surface,
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
                    size: 40, color: theme.colorScheme.primary),
                SizedBox(height: 1.h),
                Text(category['name'] as String,
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(category['description'] as String,
                      style:
                          TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant),
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