import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/marketplace_provider.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceId = ModalRoute.of(context)!.settings.arguments as String;
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Service Details',
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return const Center(child: Text('Service not found'));
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
                              fontSize: 20.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(Icons.star, size: 20, color: Colors.amber),
                          SizedBox(width: 1.w),
                          Text(
                              '${service.rating.toStringAsFixed(1)} (${service.totalBookings} bookings)',
                              style: TextStyle(fontSize: 13.sp)),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text('Description',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 1.h),
                      Text(service.description ?? 'No description available',
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      SizedBox(height: 2.h),
                      Text('Pricing',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 1.h),
                      _buildPricingRow('Base Price',
                          '\$${service.basePrice.toStringAsFixed(2)}'),
                      if (service.pricePerKm != null)
                        _buildPricingRow('Per Kilometer',
                            '\$${service.pricePerKm!.toStringAsFixed(2)}'),
                      if (service.pricePerHour != null)
                        _buildPricingRow('Per Hour',
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
                        child: const Text('Book Now'),
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
                    fontSize: 12.sp))),
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp)),
          Text(value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
