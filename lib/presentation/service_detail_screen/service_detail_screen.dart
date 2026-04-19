import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/marketplace_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceId = ModalRoute.of(context)!.settings.arguments as String;
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.serviceDetails,
            style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return Center(child: Text(AppLocalizations.of(context)!.serviceNotFound, maxLines: 1, overflow: TextOverflow.ellipsis));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.images.isNotEmpty)
                  CustomImageWidget(
                    imageUrl: service.images[0],
                    height: 25.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: service.name,
                  ),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(Icons.star, size: 20, color: Colors.amber),
                          SizedBox(width: 1.w),
                          Flexible(child: Text(
                              '${service.rating.toStringAsFixed(1)} (${service.totalBookings} bookings)',
                              style: TextStyle(fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(AppLocalizations.of(context)!.description,
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Text(service.description ?? AppLocalizations.of(context)!.noDescriptionAvailable,
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2.h),
                      Text(AppLocalizations.of(context)!.pricing,
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      _buildPricingRow(AppLocalizations.of(context)!.basePrice,
                          '\$${service.basePrice.toStringAsFixed(2)}'),
                      if (service.pricePerKm != null)
                        _buildPricingRow(AppLocalizations.of(context)!.perKilometer,
                            '\$${service.pricePerKm!.toStringAsFixed(2)}'),
                      if (service.pricePerHour != null)
                        _buildPricingRow(AppLocalizations.of(context)!.perHour,
                            '\$${service.pricePerHour!.toStringAsFixed(2)}'),
                      if (service.pricePerUnit != null)
                        _buildPricingRow('Per ${service.unitName ?? "Unit"}',
                            '\$${service.pricePerUnit!.toStringAsFixed(2)}'),
                      SizedBox(height: 3.h),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.serviceBookingScreen,
                            arguments: service.id),
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 6.h)),
                        child: Text(AppLocalizations.of(context)!.bookNow, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
            child: Text('Error: ${error.toString()}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
