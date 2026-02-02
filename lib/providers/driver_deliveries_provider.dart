import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverDeliveriesProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _deliveryAssignmentChannel;

  List<Map<String, dynamic>> _assignedDeliveries = [];
  String? _error;
  bool _isLoading = false;

  List<Map<String, dynamic>> get assignedDeliveries => _assignedDeliveries;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Subscribe to delivery assignments for a driver
  Future<void> subscribeToDeliveryAssignments(String driverId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch initial assigned deliveries
      final deliveries = await _client
          .from('deliveries')
          .select('''
            *,
            orders:order_id (
              *,
              order_items (*),
              stores (name, name_ar, address, location_lat, location_lng),
              users:customer_id (full_name, phone)
            )
          ''')
          .eq('driver_id', driverId)
          .eq('status', 'assigned')
          .order('created_at', ascending: false);

      _assignedDeliveries = List<Map<String, dynamic>>.from(deliveries);
      _isLoading = false;
      notifyListeners();

      // Subscribe to real-time delivery assignments
      _deliveryAssignmentChannel = _client
          .channel('delivery_assignments_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'deliveries',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) async {
              final deliveryId = payload.newRecord['id'];

              // Fetch complete delivery data with relations
              final deliveryData = await _client.from('deliveries').select('''
                    *,
                    orders:order_id (
                      *,
                      order_items (*),
                      stores (name, name_ar, address, location_lat, location_lng),
                      users:customer_id (full_name, phone)
                    )
                  ''').eq('id', deliveryId).single();

              // Add to assigned deliveries list
              _assignedDeliveries.insert(0, deliveryData);
              notifyListeners();

              // Show alert
              _showDeliveryAssignmentAlert(deliveryData);

              // Send SMS to driver (via Twilio edge function)
              await _sendDriverSMS(deliveryData);
            },
          )
          .subscribe();

      // Also listen for status changes to remove from assigned
      _client
          .channel('delivery_status_changes_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'deliveries',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              final deliveryId = payload.newRecord['id'];
              final newStatus = payload.newRecord['status'];

              // Remove from assigned if status changed
              if (newStatus != 'assigned') {
                _assignedDeliveries.removeWhere(
                  (delivery) => delivery['id'] == deliveryId,
                );
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (e) {
      _error = 'Failed to subscribe to delivery assignments: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show alert for new delivery assignment
  void _showDeliveryAssignmentAlert(Map<String, dynamic> deliveryData) {
    final order = deliveryData['orders'] as Map<String, dynamic>?;
    final orderNumber = order?['order_number'] ?? 'New Delivery';

    debugPrint('🚗 NEW DELIVERY ASSIGNMENT: $orderNumber');
    // In a real app, show prominent notification and play sound
  }

  // Send SMS to driver via Twilio edge function
  Future<void> _sendDriverSMS(Map<String, dynamic> deliveryData) async {
    try {
      final order = deliveryData['orders'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'];
      final store = order?['stores'] as Map<String, dynamic>?;
      final storeName = store?['name'];

      await _client.functions.invoke(
        'send-booking-notification',
        body: {
          'type': 'driver_delivery_assignment',
          'orderNumber': orderNumber,
          'storeName': storeName,
          'message':
              'New delivery assigned: Order #$orderNumber from $storeName',
        },
      );
    } catch (e) {
      debugPrint('Failed to send driver SMS: $e');
    }
  }

  // Unsubscribe from channels
  void unsubscribe() {
    _deliveryAssignmentChannel?.unsubscribe();
    _deliveryAssignmentChannel = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
