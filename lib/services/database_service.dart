// Enhanced DatabaseService with model integration
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  SupabaseClient get _client => SupabaseService.client;

  // ==================== CART OPERATIONS ====================

  /// Get all cart items for the current user
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.from('cart_items').select('''
            *,
            products (
              id,
              name,
              name_ar,
              price,
              sale_price,
              image_url,
              images,
              is_available,
              options,
              store_id,
              stores (
                name,
                name_ar
              )
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load cart items: $e');
    }
  }

  /// Add item to cart or update quantity if exists
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    List<Map<String, dynamic>>? optionsSelected,
    String? specialInstructions,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if item already exists in cart
      final existing = await _client
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        // Update existing item
        final newQuantity = (existing['quantity'] as int) + quantity;
        final response = await _client
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'options_selected': optionsSelected ?? [],
              'special_instructions': specialInstructions,
            })
            .eq('id', existing['id'])
            .select()
            .single();
        return response;
      } else {
        // Insert new item
        final response = await _client
            .from('cart_items')
            .insert({
              'user_id': userId,
              'product_id': productId,
              'quantity': quantity,
              'options_selected': optionsSelected ?? [],
              'special_instructions': specialInstructions,
            })
            .select()
            .single();
        return response;
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeCartItem(cartItemId);
        return;
      }

      await _client
          .from('cart_items')
          .update({'quantity': quantity}).eq('id', cartItemId);
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  /// Remove item from cart
  Future<void> removeCartItem(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      throw Exception('Failed to remove cart item: $e');
    }
  }

  /// Clear all cart items for current user
  Future<void> clearCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('cart_items').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response =
          await _client.from('cart_items').select('id').eq('user_id', userId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create order from cart items
  Future<Map<String, dynamic>> createOrder({
    required String storeId,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required double subtotal,
    required double deliveryFee,
    required double serviceFee,
    required double tax,
    required double total,
    String? deliveryInstructions,
    String? customerPhone,
    String? promoCodeId,
    double discount = 0.0,
    double tip = 0.0,
    String paymentMethod = 'cash',
    DateTime? scheduledFor,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get cart items
      final cartItems = await getCartItems();
      if (cartItems.isEmpty) throw Exception('Cart is empty');

      // Create order
      final orderResponse = await _client
          .from('orders')
          .insert({
            'customer_id': userId,
            'store_id': storeId,
            'status': 'pending',
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'service_fee': serviceFee,
            'tax': tax,
            'discount': discount,
            'tip': tip,
            'total': total,
            'currency': 'USD',
            'payment_method': paymentMethod,
            'payment_status': 'pending',
            'delivery_address': deliveryAddress,
            'delivery_lat': deliveryLat,
            'delivery_lng': deliveryLng,
            'delivery_instructions': deliveryInstructions,
            'customer_phone': customerPhone,
            'scheduled_for': scheduledFor?.toIso8601String(),
            'promo_code_id': promoCodeId,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items from cart
      final orderItems = cartItems.map((cartItem) {
        final product = cartItem['products'] as Map<String, dynamic>;
        return {
          'order_id': orderId,
          'product_id': cartItem['product_id'],
          'product_name': product['name'],
          'product_name_ar': product['name_ar'],
          'product_image': product['image_url'],
          'quantity': cartItem['quantity'],
          'unit_price': product['sale_price'] ?? product['price'],
          'total_price': (product['sale_price'] ?? product['price']) *
              cartItem['quantity'],
          'currency': 'USD',
          'options_selected': cartItem['options_selected'],
          'special_instructions': cartItem['special_instructions'],
        };
      }).toList();

      await _client.from('order_items').insert(orderItems);

      // Clear cart after successful order
      await clearCart();

      return orderResponse;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by ID with items
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await _client.from('orders').select('''
            *,
            order_items (*),
            stores (name, name_ar, image_url, address)
          ''').eq('id', orderId).single();

      return response;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Get user orders
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

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _client.from('orders').update({'status': status}).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _client.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
      }).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
