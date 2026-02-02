import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantOrdersProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _newOrdersChannel;

  List<Map<String, dynamic>> _pendingOrders = [];
  String? _error;
  bool _isLoading = false;

  List<Map<String, dynamic>> get pendingOrders => _pendingOrders;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Subscribe to new pending orders for a store
  Future<void> subscribeToNewOrders(String storeId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch initial pending orders
      final orders = await _client
          .from('orders')
          .select('''
            *,
            order_items (*),
            users:customer_id (full_name, phone, profile_image_url)
          ''')
          .eq('store_id', storeId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _pendingOrders = List<Map<String, dynamic>>.from(orders);
      _isLoading = false;
      notifyListeners();

      // Subscribe to real-time new orders
      _newOrdersChannel = _client
          .channel('new_orders_$storeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'store_id',
              value: storeId,
            ),
            callback: (payload) async {
              final newOrderId = payload.newRecord['id'];

              // Fetch complete order data with relations
              final orderData = await _client.from('orders').select('''
                    *,
                    order_items (*),
                    users:customer_id (full_name, phone, profile_image_url)
                  ''').eq('id', newOrderId).single();

              // Add to pending orders list
              _pendingOrders.insert(0, orderData);
              notifyListeners();

              // Show alert and play sound
              _showNewOrderAlert(orderData);

              // Send SMS to merchant (via Twilio edge function)
              await _sendMerchantSMS(orderData);
            },
          )
          .subscribe();

      // Also listen for status changes to remove from pending
      _client
          .channel('order_status_changes_$storeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'store_id',
              value: storeId,
            ),
            callback: (payload) {
              final orderId = payload.newRecord['id'];
              final newStatus = payload.newRecord['status'];

              // Remove from pending if status changed
              if (newStatus != 'pending') {
                _pendingOrders.removeWhere((order) => order['id'] == orderId);
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (e) {
      _error = 'Failed to subscribe to new orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show alert for new order
  void _showNewOrderAlert(Map<String, dynamic> orderData) {
    final orderNumber = orderData['order_number'] ?? 'New Order';
    final total = orderData['total'] ?? 0.0;

    debugPrint('🔔 NEW ORDER ALERT: $orderNumber - Total: \$$total');
    // In a real app, play sound and show prominent notification
  }

  // Send SMS to merchant via Twilio edge function
  Future<void> _sendMerchantSMS(Map<String, dynamic> orderData) async {
    try {
      final orderNumber = orderData['order_number'];
      final total = orderData['total'];

      await _client.functions.invoke(
        'send-booking-notification',
        body: {
          'type': 'merchant_new_order',
          'orderNumber': orderNumber,
          'total': total,
          'message': 'New order #$orderNumber received. Total: \$$total',
        },
      );
    } catch (e) {
      debugPrint('Failed to send merchant SMS: $e');
    }
  }

  // Unsubscribe from channels
  void unsubscribe() {
    _newOrdersChannel?.unsubscribe();
    _newOrdersChannel = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
