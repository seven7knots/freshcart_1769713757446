import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import './widgets/available_order_card_widget.dart';
import './widgets/filter_options_widget.dart';

class AvailableOrdersScreen extends ConsumerStatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  ConsumerState<AvailableOrdersScreen> createState() =>
      _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends ConsumerState<AvailableOrdersScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableOrders = [];
  String? _error;

  // Filter state
  double _maxDistance = 10.0; // km
  double _minEarnings = 0.0; // USD
  List<String> _preferredStoreTypes = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();

    // Track available orders screen view
    AnalyticsService.logScreenView(screenName: 'available_orders_screen');
  }

  Future<void> _loadAvailableOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual driver location from provider
      final driverLat = 33.8938; // Beirut example
      final driverLng = 35.5018;

      // Fetch available orders from Supabase
      final response = await SupabaseService.client
          .from('orders')
          .select('''
            *,
            stores (
              id,
              name,
              name_ar,
              image_url,
              address,
              location_lat,
              location_lng
            ),
            order_items (
              id,
              quantity,
              product_name
            )
          ''')
          .eq('status', 'pending')
          .isFilter('driver_id', null)
          .order('created_at', ascending: false)
          .limit(20);

      // Calculate distance and earnings for each order
      final ordersWithMetadata = (response as List).map((order) {
        final store = order['stores'] as Map<String, dynamic>?;
        final storeLat = store?['location_lat'] as double? ?? 0.0;
        final storeLng = store?['location_lng'] as double? ?? 0.0;
        final deliveryLat = order['delivery_lat'] as double? ?? 0.0;
        final deliveryLng = order['delivery_lng'] as double? ?? 0.0;

        // Calculate distance from driver to store
        final distanceToStore = _calculateDistance(
          driverLat,
          driverLng,
          storeLat,
          storeLng,
        );

        // Calculate distance from store to customer
        final distanceToCustomer = _calculateDistance(
          storeLat,
          storeLng,
          deliveryLat,
          deliveryLng,
        );

        final totalDistance = distanceToStore + distanceToCustomer;

        // Calculate estimated earnings (base + per km)
        final baseEarnings = 3.0; // USD
        final perKmRate = 0.5; // USD per km
        final estimatedEarnings = baseEarnings + (totalDistance * perKmRate);
        final tip = order['tip'] as double? ?? 0.0;
        final totalEarnings = estimatedEarnings + tip;

        return {
          ...order,
          'distance_km': totalDistance,
          'estimated_earnings': totalEarnings,
          'distance_to_store': distanceToStore,
        };
      }).toList();

      // Apply filters
      final filteredOrders = ordersWithMetadata
          .where((order) {
            final distance = order['distance_km'] as double;
            final earnings = order['estimated_earnings'] as double;

            if (distance > _maxDistance) return false;
            if (earnings < _minEarnings) return false;

            return true;
          })
          .toList()
          .cast<Map<String, dynamic>>();

      // Sort by earnings (highest first)
      filteredOrders.sort((a, b) {
        final earningsA = a['estimated_earnings'] as double;
        final earningsB = b['estimated_earnings'] as double;
        return earningsB.compareTo(earningsA);
      });

      setState(() {
        _availableOrders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available orders: $e';
        _isLoading = false;
      });
    }
  }

  // Haversine formula for distance calculation
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterOptionsWidget(
        maxDistance: _maxDistance,
        minEarnings: _minEarnings,
        preferredStoreTypes: _preferredStoreTypes,
        onApply: (maxDistance, minEarnings, storeTypes) {
          setState(() {
            _maxDistance = maxDistance;
            _minEarnings = minEarnings;
            _preferredStoreTypes = storeTypes;
          });
          _loadAvailableOrders();
        },
      ),
    );
  }

  Future<void> _handleAcceptOrder(String orderId) async {
    final startTime = DateTime.now();

    try {
      final driverId = SupabaseService.client.auth.currentUser?.id;

      if (driverId == null) {
        throw Exception('Driver not authenticated');
      }

      // Get order details for tracking
      final orderData = await SupabaseService.client
          .from('orders')
          .select('total, delivery_fee')
          .eq('id', orderId)
          .single();

      final estimatedEarnings =
          (orderData['delivery_fee'] as num?)?.toDouble() ?? 0.0;

      // Update order with driver assignment
      await SupabaseService.client.from('orders').update(
          {'driver_id': driverId, 'status': 'confirmed'}).eq('id', orderId);

      // Create delivery record
      await SupabaseService.client.from('deliveries').insert({
        'order_id': orderId,
        'driver_id': driverId,
        'status': 'assigned',
      });

      // Calculate response time
      final responseTime = DateTime.now().difference(startTime).inSeconds;

      // Track driver order accepted
      await AnalyticsService.logDriverOrderAccepted(
        driverId: driverId,
        orderId: orderId,
        estimatedEarnings: estimatedEarnings,
        responseTimeSeconds: responseTime,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );

        // Navigate to active delivery screen
        Navigator.pushNamed(
          context,
          AppRoutes.orderTracking,
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Available Orders',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading available orders...',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 15.w, color: Colors.red),
                      SizedBox(height: 2.h),
                      Text(
                        'Error',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _loadAvailableOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 1.5.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _availableOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 15.w,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No Available Orders',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Check back later for new delivery opportunities',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          ElevatedButton.icon(
                            onPressed: _loadAvailableOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.lightTheme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 1.5.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _loadAvailableOrders,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 2.h),
                        itemCount: _availableOrders.length,
                        itemBuilder: (context, index) {
                          final order = _availableOrders[index];
                          return AvailableOrderCardWidget(
                            order: order,
                            onAccept: () => _handleAcceptOrder(order['id']),
                          );
                        },
                      ),
                    ),
    );
  }
}
