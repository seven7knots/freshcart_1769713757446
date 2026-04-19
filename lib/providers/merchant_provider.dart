// ============================================================
// FILE: lib/providers/merchant_provider.dart
// ============================================================
// Merchant provider for merchant-specific operations
// Handles: merchant data, store management, products, orders
//
// FIXED: stores ownership + category linkage consistency
// FIXED (PostgREST PGRST200): explicit relationship embeds
// SESSION 8 FIX: createStore nullable categoryId
// SESSION 8 BUG 4 FIX: updateMerchant maybeSingle fallback
// SESSION 18 FIX: loadStats uses correct column 'total' instead
//   of non-existent 'total_amount'. Falls back to 'subtotal'.
// SESSION 20 FIXES:
//   - Revenue = subtotal only (excludes delivery fees — Talabat model)
//   - Real order count per store (not total_reviews)
//   - createProduct uses is_available (not is_active)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/merchant_model.dart';
import '../services/supabase_service.dart';

class MerchantProvider extends ChangeNotifier {
  SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // STATE
  // ============================================================

  Merchant? _merchant;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _stats;

  String? _selectedStoreId;

  // SESSION 20: Real order counts per store
  Map<String, int> _storeOrderCounts = {};

  // ============================================================
  // GETTERS
  // ============================================================

  Merchant? get merchant => _merchant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isMerchant => _merchant?.isApproved ?? false;
  bool get isPending => _merchant?.isPending ?? false;
  bool get isRejected => _merchant?.isRejected ?? false;
  bool get canOperate => _merchant?.canOperate ?? false;

  List<Map<String, dynamic>> get stores => _stores;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic>? get stats => _stats;

  String? get selectedStoreId => _selectedStoreId;

  // SESSION 20: Expose order counts
  Map<String, int> get storeOrderCounts => _storeOrderCounts;

  Map<String, dynamic>? get selectedStore {
    if (_selectedStoreId == null) return null;
    return _stores.firstWhere(
      (s) => s['id'] == _selectedStoreId,
      orElse: () => <String, dynamic>{},
    );
  }

  String? get rejectionReason => _merchant?.rejectionReason;

  // ============================================================
  // LOADING HELPERS
  // ============================================================

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // MERCHANT DATA LOADING
  // ============================================================

  Future<void> loadMyMerchant([String? userId]) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('[MERCHANT] No user logged in');
      _merchant = null;
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _setError(null);
      debugPrint('[MERCHANT] Loading merchant for user: $uid');

      final result = await _client
          .from('merchants')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (result != null) {
        _merchant = Merchant.fromMap(result);
        debugPrint(
            '[MERCHANT] Merchant loaded: status=${_merchant!.status.name}');

        // If approved, load stores
        if (_merchant!.isApproved) {
          await loadMyStores();
        }
      } else {
        _merchant = null;
        debugPrint('[MERCHANT] No merchant record found');
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[MERCHANT] Error loading merchant: $e');
      _merchant = null;
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> refresh() => loadMyMerchant();

  // ============================================================
  // MERCHANT APPLICATION
  // ============================================================

  Future<bool> createMerchant(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('[MERCHANT] Creating merchant application');

      final result = await _client.rpc(
        'apply_as_merchant',
        params: {
          'p_business_name': payload['business_name'],
          'p_business_type': payload['business_type'],
          'p_description': payload['description'],
          'p_address': payload['address'],
          'p_logo_url': payload['logo_url'],
        },
      );

      debugPrint('[MERCHANT] Application result: $result');

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        _setLoading(false);
        return false;
      }

      await loadMyMerchant(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error creating merchant: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateMerchant(
    String merchantId,
    Map<String, dynamic> updates,
  ) async {
    final uid = _client.auth.currentUser?.id;

    try {
      _setLoading(true);
      _setError(null);

      final data = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint(
          '[MERCHANT] Updating merchant: $merchantId (user: $uid)');

      Map<String, dynamic>? result;
      try {
        result = await _client
            .from('merchants')
            .update(data)
            .eq('id', merchantId)
            .select()
            .maybeSingle();
      } catch (e) {
        debugPrint(
            '[MERCHANT] id-based update failed: $e — trying user_id fallback');
        result = null;
      }

      if (result == null && uid != null) {
        debugPrint('[MERCHANT] Fallback: updating by user_id=$uid');
        result = await _client
            .from('merchants')
            .update(data)
            .eq('user_id', uid)
            .select()
            .maybeSingle();
      }

      if (result != null) {
        _merchant = Merchant.fromMap(result);
        debugPrint('[MERCHANT] Merchant updated successfully');
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        debugPrint('[MERCHANT] Error: update returned 0 rows');
        _setLoading(false);
        _setError('Could not update merchant profile — no matching record');
        return false;
      }
    } catch (e) {
      debugPrint('[MERCHANT] Error updating merchant: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // STORE MANAGEMENT
  // ============================================================

  Future<void> loadMyStores() async {
    final uid = _client.auth.currentUser?.id;

    if (_merchant == null || !_merchant!.isApproved || uid == null) {
      _stores = [];
      notifyListeners();
      return;
    }

    try {
      debugPrint(
          '[MERCHANT] Loading stores for merchant_id=${_merchant!.id}, owner_user_id=$uid');

      final result = await _client
          .from('stores')
          .select(
            '*, '
            'category:categories!stores_category_id_fkey(name), '
            'subcategory:categories!stores_subcategory_id_fkey(name)',
          )
          .eq('merchant_id', _merchant!.id)
          .eq('owner_user_id', uid)
          .order('created_at', ascending: false);

      _stores = _normalizeList(result);

      if (_selectedStoreId == null && _stores.isNotEmpty) {
        _selectedStoreId = _stores.first['id'] as String;
      }

      debugPrint('[MERCHANT] Loaded ${_stores.length} stores');

      // SESSION 20: Load real order counts per store
      await _loadStoreOrderCounts();

      notifyListeners();
    } catch (e) {
      debugPrint('[MERCHANT] Error loading stores: $e');
      _stores = [];
      _setError(e.toString());
    }
  }

  // ============================================================
  // SESSION 20: Load real order counts for each store
  // ============================================================

  Future<void> _loadStoreOrderCounts() async {
    if (_stores.isEmpty) {
      _storeOrderCounts = {};
      return;
    }

    try {
      final storeIds = _stores.map((s) => s['id'] as String).toList();

      final ordersResult = await _client
          .from('orders')
          .select('id, store_id')
          .inFilter('store_id', storeIds);

      final ordersList = _normalizeList(ordersResult);
      final counts = <String, int>{};

      for (final storeId in storeIds) {
        counts[storeId] =
            ordersList.where((o) => o['store_id'] == storeId).length;
      }

      _storeOrderCounts = counts;
      debugPrint('[MERCHANT] Order counts per store: $_storeOrderCounts');
    } catch (e) {
      debugPrint('[MERCHANT] Error loading store order counts: $e');
      _storeOrderCounts = {};
    }
  }

  Future<Map<String, dynamic>?> createStore({
    required String name,
    String? categoryId,
    String? description,
    String? imageUrl,
    String? category,
  }) async {
    final uid = _client.auth.currentUser?.id;

    if (_merchant == null || !_merchant!.isApproved) {
      _setError('Merchant not approved');
      return null;
    }
    if (uid == null) {
      _setError('Not authenticated');
      return null;
    }

    try {
      _setLoading(true);
      _setError(null);
      debugPrint('[MERCHANT] Creating store: $name');

      final payload = <String, dynamic>{
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'owner_user_id': uid,
        'merchant_id': _merchant!.id,
        'is_active': true,
        'is_demo': false,
        'is_accepting_orders': true,
      };

      if (categoryId != null &&
          categoryId.isNotEmpty &&
          categoryId != 'default') {
        payload['category_id'] = categoryId;
      }

      if (category != null && category.isNotEmpty) {
        payload['category'] = category;
      }

      payload.removeWhere((k, v) => v == null);

      final result = await _client
          .from('stores')
          .insert(payload)
          .select(
            '*, '
            'category:categories!stores_category_id_fkey(name), '
            'subcategory:categories!stores_subcategory_id_fkey(name)',
          )
          .single();

      _stores.insert(0, result);
      _selectedStoreId = result['id'] as String;

      _setLoading(false);
      notifyListeners();

      debugPrint('[MERCHANT] Store created: ${result['id']}');
      return result;
    } catch (e) {
      debugPrint('[MERCHANT] Error creating store: $e');
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> updateStore(
    String storeId,
    Map<String, dynamic> updates,
  ) async {
    final uid = _client.auth.currentUser?.id;

    if (_merchant == null || !_merchant!.isApproved) {
      _setError('Merchant not approved');
      return false;
    }
    if (uid == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final safeUpdates = Map<String, dynamic>.from(updates)
        ..remove('owner_id')
        ..remove('owner_user_id')
        ..remove('merchant_id')
        ..remove('id');

      safeUpdates['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from('stores')
          .update(safeUpdates)
          .eq('id', storeId)
          .eq('merchant_id', _merchant!.id)
          .eq('owner_user_id', uid)
          .select(
            '*, '
            'category:categories!stores_category_id_fkey(name), '
            'subcategory:categories!stores_subcategory_id_fkey(name)',
          )
          .single();

      final idx = _stores.indexWhere((s) => s['id'] == storeId);
      if (idx != -1) {
        _stores[idx] = result;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error updating store: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteStore(String storeId) async {
    final uid = _client.auth.currentUser?.id;

    if (_merchant == null || !_merchant!.isApproved) {
      _setError('Merchant not approved');
      return false;
    }
    if (uid == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      await _client
          .from('stores')
          .delete()
          .eq('id', storeId)
          .eq('merchant_id', _merchant!.id)
          .eq('owner_user_id', uid);

      _stores.removeWhere((s) => s['id'] == storeId);

      if (_selectedStoreId == storeId) {
        _selectedStoreId =
            _stores.isNotEmpty ? _stores.first['id'] as String : null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error deleting store: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  void selectStore(String storeId) {
    _selectedStoreId = storeId;
    notifyListeners();
    loadStoreProducts(storeId);
  }

  // ============================================================
  // PRODUCT MANAGEMENT
  // ============================================================

  Future<void> loadStoreProducts(String storeId) async {
    try {
      debugPrint('[MERCHANT] Loading products for store: $storeId');

      final result = await _client
          .from('products')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      _products = _normalizeList(result);

      debugPrint('[MERCHANT] Loaded ${_products.length} products');
      notifyListeners();
    } catch (e) {
      debugPrint('[MERCHANT] Error loading products: $e');
      _products = [];
      _setError(e.toString());
    }
  }

  Future<Map<String, dynamic>?> createProduct({
    required String name,
    required String storeId,
    double? price,
    String? description,
    String? imageUrl,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      debugPrint('[MERCHANT] Creating product: $name');

      // SESSION 20 FIX: Use is_available (actual DB column, not is_active)
      final payload = <String, dynamic>{
        'name': name,
        'store_id': storeId,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'is_available': true,
      }..removeWhere((k, v) => v == null);

      final result =
          await _client.from('products').insert(payload).select().single();

      _products.insert(0, result);

      _setLoading(false);
      notifyListeners();

      debugPrint('[MERCHANT] Product created: ${result['id']}');
      return result;
    } catch (e) {
      debugPrint('[MERCHANT] Error creating product: $e');
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final safeUpdates = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('store_id');

      safeUpdates['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from('products')
          .update(safeUpdates)
          .eq('id', productId)
          .select()
          .single();

      final idx = _products.indexWhere((p) => p['id'] == productId);
      if (idx != -1) {
        _products[idx] = result;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error updating product: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _client.from('products').delete().eq('id', productId);

      _products.removeWhere((p) => p['id'] == productId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error deleting product: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Future<void> loadOrders({String? status}) async {
    if (_merchant == null || _stores.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }

    try {
      debugPrint('[MERCHANT] Loading orders...');

      final storeIds = _stores.map((s) => s['id'] as String).toList();

      PostgrestFilterBuilder query = _client
          .from('orders')
          .select('*, stores(name)')
          .inFilter('store_id', storeIds);

      if (status != null) {
        query = query.eq('status', status);
      }

      final result =
          await query.order('created_at', ascending: false).limit(50);

      _orders = _normalizeList(result);

      debugPrint('[MERCHANT] Loaded ${_orders.length} orders');
      notifyListeners();
    } catch (e) {
      debugPrint('[MERCHANT] Error loading orders: $e');
      _orders = [];
      _setError(e.toString());
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final idx = _orders.indexWhere((o) => o['id'] == orderId);
      if (idx != -1) {
        _orders[idx] = {..._orders[idx], 'status': newStatus};
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('[MERCHANT] Error updating order status: $e');
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // STATS — SESSION 20 FIX:
  //   Merchant revenue = subtotal ONLY (product sales, excludes delivery fees)
  //   Delivery fees go to the platform (admin), not the merchant.
  //   This matches the Talabat/Toters marketplace model.
  // ============================================================

  Future<void> loadStats() async {
    if (_merchant == null || _stores.isEmpty) {
      _stats = null;
      notifyListeners();
      return;
    }

    try {
      final storeIds = _stores.map((s) => s['id'] as String).toList();

      final productsResult = await _client
          .from('products')
          .select('id')
          .inFilter('store_id', storeIds);

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // SESSION 20 FIX: Select subtotal, total, delivery_fee for proper revenue split
      final ordersResult = await _client
          .from('orders')
          .select('id, subtotal, total, delivery_fee, status')
          .inFilter('store_id', storeIds)
          .gte('created_at', startOfDay.toIso8601String());

      final ordersList = ordersResult as List;
      final completedOrders =
          ordersList.where((o) => o['status'] == 'delivered').toList();

      // SESSION 20 FIX: Merchant revenue = subtotal only (no delivery fees)
      // If subtotal is null, calculate as total - delivery_fee
      double todayRevenue = 0;
      for (final order in completedOrders) {
        final subtotal = order['subtotal'];
        final total = order['total'];
        final deliveryFee = order['delivery_fee'];

        if (subtotal != null) {
          todayRevenue += (subtotal as num).toDouble();
        } else if (total != null) {
          // Fallback: total - delivery_fee = merchant's share
          final totalAmount = (total as num).toDouble();
          final fee =
              deliveryFee != null ? (deliveryFee as num).toDouble() : 0.0;
          todayRevenue += (totalAmount - fee);
        }
      }

      _stats = {
        'total_stores': _stores.length,
        'total_products': (productsResult as List).length,
        'today_orders': ordersList.length,
        'today_revenue': todayRevenue,
        'pending_orders':
            ordersList.where((o) => o['status'] == 'pending').length,
        'completed_orders': completedOrders.length,
      };

      notifyListeners();
      debugPrint('[MERCHANT] Stats loaded: $_stats');
    } catch (e) {
      debugPrint('[MERCHANT] Error loading stats: $e');
      _stats = null;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<Map<String, dynamic>> _normalizeList(dynamic res) {
    if (res == null) return [];
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  void clear() {
    _merchant = null;
    _stores = [];
    _products = [];
    _orders = [];
    _stats = null;
    _selectedStoreId = null;
    _storeOrderCounts = {};
    _error = null;
    notifyListeners();
  }
}