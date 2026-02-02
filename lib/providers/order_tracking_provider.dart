import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/order_model.dart';

class OrderTrackingProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  RealtimeChannel? _orderStatusChannel;
  RealtimeChannel? _driverLocationChannel;

  OrderModel? _currentOrder;
  Map<String, dynamic>? _driverLocation;
  String? _error;
  bool _isLoading = false;

  OrderModel? get currentOrder => _currentOrder;
  Map<String, dynamic>? get driverLocation => _driverLocation;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Subscribe to order status changes
  Future<void> subscribeToOrderUpdates(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch initial order data
      final orderData = await _client.from('orders').select('''
            *,
            order_items (*),
            stores (name, name_ar, image_url, address),
            drivers:driver_id (
              id,
              user_id,
              vehicle_type,
              vehicle_plate,
              current_location_lat,
              current_location_lng
            )
          ''').eq('id', orderId).single();

      _currentOrder = OrderModel.fromJson(orderData);
      _isLoading = false;
      notifyListeners();

      // Subscribe to real-time order status changes
      _orderStatusChannel = _client
          .channel('order_status_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: orderId,
            ),
            callback: (payload) async {
              // Update order with new data
              final updatedData = await _client.from('orders').select('''
                    *,
                    order_items (*),
                    stores (name, name_ar, image_url, address),
                    drivers:driver_id (
                      id,
                      user_id,
                      vehicle_type,
                      vehicle_plate,
                      current_location_lat,
                      current_location_lng
                    )
                  ''').eq('id', orderId).single();

              _currentOrder = OrderModel.fromJson(updatedData);
              notifyListeners();

              // Show local notification
              _showOrderStatusNotification(payload.newRecord);
            },
          )
          .subscribe();

      // Subscribe to driver location if order has a driver
      if (_currentOrder?.driverId != null) {
        await _subscribeToDriverLocation(_currentOrder!.driverId!);
      }
    } catch (e) {
      _error = 'Failed to subscribe to order updates: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to driver location updates
  Future<void> _subscribeToDriverLocation(String driverId) async {
    try {
      // Get delivery ID for this order
      final delivery = await _client
          .from('deliveries')
          .select('id')
          .eq('order_id', _currentOrder!.id)
          .maybeSingle();

      if (delivery == null) return;

      final deliveryId = delivery['id'];

      _driverLocationChannel = _client
          .channel('driver_location_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'driver_location_history',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'delivery_id',
              value: deliveryId,
            ),
            callback: (payload) {
              _driverLocation = payload.newRecord;
              notifyListeners();
            },
          )
          .subscribe();

      // Fetch latest driver location
      final locationData = await _client
          .from('driver_location_history')
          .select()
          .eq('delivery_id', deliveryId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (locationData != null) {
        _driverLocation = locationData;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to subscribe to driver location: $e');
    }
  }

  // Show local notification for order status change
  void _showOrderStatusNotification(Map<String, dynamic> orderData) {
    final status = orderData['status'] as String?;
    if (status == null) return;

    String title = 'Order Update';
    String body = '';

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed';
        body = 'Your order has been confirmed and is being prepared.';
        break;
      case 'preparing':
        title = 'Order Being Prepared';
        body = 'Your order is being prepared by the store.';
        break;
      case 'ready':
        title = 'Order Ready';
        body = 'Your order is ready for pickup.';
        break;
      case 'picked_up':
        title = 'Order Picked Up';
        body = 'Your order has been picked up by the driver.';
        break;
      case 'in_transit':
        title = 'Order On The Way';
        body = 'Your order is on the way to you!';
        break;
      case 'delivered':
        title = 'Order Delivered';
        body = 'Your order has been delivered. Enjoy!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order has been cancelled.';
        break;
    }

    // In a real app, use flutter_local_notifications or awesome_notifications
    debugPrint('Notification: $title - $body');
  }

  // Unsubscribe from all channels
  void unsubscribe() {
    _orderStatusChannel?.unsubscribe();
    _driverLocationChannel?.unsubscribe();
    _orderStatusChannel = null;
    _driverLocationChannel = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
