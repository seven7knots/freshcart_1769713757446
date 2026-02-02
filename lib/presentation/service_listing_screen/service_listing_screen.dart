import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/marketplace_provider.dart';

class ServiceListingScreen extends ConsumerWidget {
  const ServiceListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceType =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'taxi';
    final servicesAsync = ref.watch(servicesByTypeProvider(serviceType));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          serviceType.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: servicesAsync.when(
        data: (services) {
          print('📦 Displaying ${services.length} services for $serviceType');
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(height: 2.h),
                  Text(
                    'No providers available',
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Check back later for service providers',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.serviceDetailScreen,
                  arguments: service.id,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CustomImageWidget(
                          imageUrl: service.images.isNotEmpty
                              ? service.images[0]
                              : 'https://images.unsplash.com/photo-1560179707-f14e90ef3623',
                          width: 20.w,
                          height: 20.w,
                          fit: BoxFit.cover,
                          semanticLabel: service.name,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            if (service.description != null)
                              Text(
                                service.description!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 1.h),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 1.w),
                                Text(
                                  '${service.rating.toStringAsFixed(1)} (${service.totalBookings} bookings)',
                                  style: TextStyle(fontSize: 11.sp),
                                ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              'From \$${service.basePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 60, color: Theme.of(context).colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                'Error loading services',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                error.toString(),
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.refresh(servicesByTypeProvider(serviceType)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
