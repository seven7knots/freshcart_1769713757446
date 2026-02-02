import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import './analytics_service.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  // Create order using server-authoritative RPC
  Future<OrderModel> createOrder({
    required String storeId,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required List<Map<String, dynamic>> items,
    String? deliveryInstructions,
    String? customerPhone,
    DateTime? scheduledFor,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Call server-authoritative RPC function
      final response = await _client.rpc(
        'create_order_with_validation',
        params: {
          'p_store_id': storeId,
          'p_delivery_address': deliveryAddress,
          'p_delivery_lat': deliveryLat,
          'p_delivery_lng': deliveryLng,
          'p_delivery_instructions': deliveryInstructions,
          'p_customer_phone': customerPhone,
          'p_scheduled_for': scheduledFor?.toIso8601String(),
          'p_items': items,
        },
      );

      final orderId = response['order_id'] as String;
      final total = response['total'] as num;
      final subtotal = response['subtotal'] as num;
      final deliveryFee = response['delivery_fee'] as num;
      final tax = response['tax'] as num;

      // Track purchase event
      await AnalyticsService.logPurchase(
        orderId: orderId,
        total: total.toDouble(),
        tax: tax.toDouble(),
        deliveryFee: deliveryFee.toDouble(),
        items: items,
      );

      // Fetch complete order details
      return await getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID with items
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await _client.from('orders').select('''
            *,
            order_items (*),
            stores (name, name_ar, image_url)
          ''').eq('id', orderId).single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders({
    String? status,
    int limit = 20,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query = _client.from('orders').select('''
            *,
            order_items (*),
            stores (name, name_ar, image_url)
          ''').eq('customer_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  // Update order status using server-authoritative RPC
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? reason,
  }) async {
    try {
      final response = await _client.rpc(
        'update_order_status',
        params: {
          'p_order_id': orderId,
          'p_new_status': status,
          'p_reason': reason,
        },
      );

      if (response['success'] != true) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order using server-authoritative RPC
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await updateOrderStatus(orderId, 'cancelled', reason: reason);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Assign driver to order (merchant/admin only)
  Future<void> assignDriver(String orderId, String driverId) async {
    try {
      final response = await _client.rpc(
        'assign_driver_to_order',
        params: {'p_order_id': orderId, 'p_driver_id': driverId},
      );

      if (response['success'] != true) {
        throw Exception('Failed to assign driver');
      }
    } catch (e) {
      throw Exception('Failed to assign driver: $e');
    }
  }

  // Confirm cash collection (driver only)
  Future<void> confirmCashCollection(String orderId, double amount) async {
    try {
      final response = await _client.rpc(
        'confirm_cash_collection',
        params: {'p_order_id': orderId, 'p_amount': amount},
      );

      if (response['success'] != true) {
        throw Exception('Failed to confirm cash collection');
      }
    } catch (e) {
      throw Exception('Failed to confirm cash collection: $e');
    }
  }

  // Admin confirm cash (admin only)
  Future<void> adminConfirmCash(String orderId) async {
    try {
      final response = await _client.rpc(
        'admin_confirm_cash',
        params: {'p_order_id': orderId},
      );

      if (response['success'] != true) {
        throw Exception('Failed to confirm cash');
      }
    } catch (e) {
      throw Exception('Failed to confirm cash: $e');
    }
  }

  // Get order events (audit trail)
  Future<List<Map<String, dynamic>>> getOrderEvents(String orderId) async {
    try {
      final response = await _client
          .from('order_events')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load order events: $e');
    }
  }

  // Get active order (in progress)
  Future<Map<String, dynamic>?> getActiveOrder() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (*),
            stores (name, name_ar, image_url, address),
            drivers:driver_id (id, user_id, vehicle_type, vehicle_plate, current_location_lat, current_location_lng)
          ''')
          .eq('customer_id', userId)
          .inFilter('status', [
            'confirmed',
            'preparing',
            'ready',
            'picked_up',
            'in_transit',
          ])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}
