// ============================================================
// FILE: lib/providers/driver_provider.dart
// ============================================================
// Driver provider for driver-specific operations
// Handles: online status, location, orders, stats
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_model.dart';
import '../services/supabase_service.dart';

class DriverProvider extends ChangeNotifier {
  SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // STATE
  // ============================================================

  Driver? _driver;
  bool _isLoading = false;
  String? _error;

  // Available orders for pickup
  List<Map<String, dynamic>> _availableOrders = [];

  // Current active order
  Map<String, dynamic>? _currentOrder;

  // Earnings and stats
  Map<String, dynamic>? _todayStats;

  // Location update timer
  Timer? _locationTimer;

  // ============================================================
  // GETTERS
  // ============================================================

  Driver? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isOnline => _driver?.isOnline ?? false;
  bool get isAvailable => _driver?.isAvailable ?? false;
  bool get canTakeOrders => _driver?.canTakeOrders ?? false;

  List<Map<String, dynamic>> get availableOrders => _availableOrders;
  Map<String, dynamic>? get currentOrder => _currentOrder;
  Map<String, dynamic>? get todayStats => _todayStats;

  bool get hasActiveOrder => _currentOrder != null;

  // Stats getters
  int get totalDeliveries => _driver?.totalDeliveries ?? 0;
  double get totalEarnings => _driver?.totalEarnings ?? 0;
  double get rating => _driver?.rating ?? 5.0;

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
  // DRIVER DATA LOADING
  // ============================================================

  /// Load driver data for current user
  Future<void> loadMyDriver() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[DRIVER] No user logged in');
      _driver = null;
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      debugPrint('[DRIVER] Loading driver for user: $userId');

      final result = await _client
          .from('drivers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result != null) {
        _driver = Driver.fromMap(result);
        debugPrint('[DRIVER] Driver loaded: status=${_driver!.status.name}');
      } else {
        _driver = null;
        debugPrint('[DRIVER] No driver record found');
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[DRIVER] Error loading driver: $e');
      _driver = null;
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // ============================================================
  // ONLINE STATUS
  // ============================================================

  /// Go online (start accepting orders)
  Future<bool> goOnline() async {
    if (_driver == null || !_driver!.isApproved) {
      _setError('Driver not approved');
      return false;
    }

    try {
      _setLoading(true);

      await _client
          .from('drivers')
          .update({
            'is_online': true,
            'is_available': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _driver!.id);

      _driver = _driver!.copyWith(isOnline: true, isAvailable: true);
      
      // Start location updates
      _startLocationUpdates();

      _setLoading(false);
      notifyListeners();

      debugPrint('[DRIVER] Now online');
      return true;
    } catch (e) {
      debugPrint('[DRIVER] Error going online: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Go offline (stop accepting orders)
  Future<bool> goOffline() async {
    if (_driver == null) return false;

    try {
      _setLoading(true);

      await _client
          .from('drivers')
          .update({
            'is_online': false,
            'is_available': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _driver!.id);

      _driver = _driver!.copyWith(isOnline: false, isAvailable: false);
      
      // Stop location updates
      _stopLocationUpdates();

      _setLoading(false);
      notifyListeners();

      debugPrint('[DRIVER] Now offline');
      return true;
    } catch (e) {
      debugPrint('[DRIVER] Error going offline: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Toggle online/offline status
  Future<bool> toggleOnlineStatus() async {
    if (isOnline) {
      return await goOffline();
    } else {
      return await goOnline();
    }
  }

  // ============================================================
  // LOCATION UPDATES
  // ============================================================

  void _startLocationUpdates() {
    _stopLocationUpdates(); // Cancel any existing timer

    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateLocation(),
    );

    // Immediately update location
    _updateLocation();
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _updateLocation() async {
    // In a real app, you'd get the actual device location here
    // For now, this is a placeholder
    debugPrint('[DRIVER] Location update triggered');
    
    // TODO: Implement actual location tracking
    // final position = await Geolocator.getCurrentPosition();
    // await updateDriverLocation(position.latitude, position.longitude);
  }

  /// Update driver location in database
  Future<void> updateDriverLocation(double lat, double lng) async {
    if (_driver == null) return;

    try {
      await _client
          .from('drivers')
          .update({
            'current_lat': lat,
            'current_lng': lng,
            'last_location_update': DateTime.now().toIso8601String(),
          })
          .eq('id', _driver!.id);

      _driver = _driver!.copyWith(
        currentLat: lat,
        currentLng: lng,
        lastLocationUpdate: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('[DRIVER] Error updating location: $e');
    }
  }

  // ============================================================
  // ORDERS
  // ============================================================

  /// Load available orders for pickup
  Future<void> loadAvailableOrders() async {
    if (_driver == null || !_driver!.canTakeOrders) {
      _availableOrders = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);

      final result = await _client
          .from('orders')
          .select('*, stores(name, address, image_url)')
          .eq('status', 'ready')
          .isFilter('driver_id', null)
          .order('created_at', ascending: false)
          .limit(20);

      _availableOrders = _normalizeList(result);

      debugPrint('[DRIVER] Loaded ${_availableOrders.length} available orders');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[DRIVER] Error loading available orders: $e');
      _availableOrders = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  /// Accept an order for delivery
  Future<bool> acceptOrder(String orderId) async {
    if (_driver == null || !_driver!.canTakeOrders) {
      _setError('Cannot accept orders');
      return false;
    }

    try {
      _setLoading(true);

      await _client
          .from('orders')
          .update({
            'driver_id': _driver!.userId,
            'status': 'assigned',
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .isFilter('driver_id', null); // Only update if not already assigned

      // Update driver availability
      await _client
          .from('drivers')
          .update({'is_available': false})
          .eq('id', _driver!.id);

      _driver = _driver!.copyWith(isAvailable: false);

      // Load the accepted order
      await loadCurrentOrder();

      // Refresh available orders
      await loadAvailableOrders();

      _setLoading(false);
      notifyListeners();

      debugPrint('[DRIVER] Order accepted: $orderId');
      return true;
    } catch (e) {
      debugPrint('[DRIVER] Error accepting order: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Load current active order
  Future<void> loadCurrentOrder() async {
    if (_driver == null) {
      _currentOrder = null;
      notifyListeners();
      return;
    }

    try {
      final result = await _client
          .from('orders')
          .select('*, stores(name, address, image_url, phone)')
          .eq('driver_id', _driver!.userId)
          .inFilter('status', ['assigned', 'picked_up', 'in_transit'])
          .maybeSingle();

      _currentOrder = result;
      notifyListeners();

      debugPrint('[DRIVER] Current order: ${_currentOrder?['id']}');
    } catch (e) {
      debugPrint('[DRIVER] Error loading current order: $e');
      _currentOrder = null;
    }
  }

  /// Update order status (picked up, in transit, delivered)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _setLoading(true);

      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add timestamp based on status
      switch (newStatus) {
        case 'picked_up':
          updates['picked_up_at'] = DateTime.now().toIso8601String();
          break;
        case 'in_transit':
          // No special timestamp
          break;
        case 'delivered':
          updates['delivered_at'] = DateTime.now().toIso8601String();
          break;
      }

      await _client
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .eq('driver_id', _driver!.userId);

      // If delivered, make driver available again
      if (newStatus == 'delivered') {
        await _client
            .from('drivers')
            .update({'is_available': true})
            .eq('id', _driver!.id);

        _driver = _driver!.copyWith(isAvailable: true);
        _currentOrder = null;
      } else {
        await loadCurrentOrder();
      }

      _setLoading(false);
      notifyListeners();

      debugPrint('[DRIVER] Order status updated to: $newStatus');
      return true;
    } catch (e) {
      debugPrint('[DRIVER] Error updating order status: $e');
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Mark order as picked up
  Future<bool> markPickedUp(String orderId) => 
      updateOrderStatus(orderId, 'picked_up');

  /// Mark order as in transit
  Future<bool> markInTransit(String orderId) => 
      updateOrderStatus(orderId, 'in_transit');

  /// Mark order as delivered
  Future<bool> markDelivered(String orderId) => 
      updateOrderStatus(orderId, 'delivered');

  // ============================================================
  // STATS & EARNINGS
  // ============================================================

  /// Load today's stats
  Future<void> loadTodayStats() async {
    if (_driver == null) {
      _todayStats = null;
      notifyListeners();
      return;
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final result = await _client
          .from('orders')
          .select('id, delivery_fee, status')
          .eq('driver_id', _driver!.userId)
          .eq('status', 'delivered')
          .gte('delivered_at', startOfDay.toIso8601String());

      final orders = result as List;
      
      double todayEarnings = 0;
      for (final order in orders) {
        final fee = order['delivery_fee'];
        if (fee != null) {
          todayEarnings += (fee as num).toDouble();
        }
      }

      _todayStats = {
        'deliveries': orders.length,
        'earnings': todayEarnings,
      };

      notifyListeners();
      debugPrint('[DRIVER] Today stats: $_todayStats');
    } catch (e) {
      debugPrint('[DRIVER] Error loading today stats: $e');
      _todayStats = {'deliveries': 0, 'earnings': 0.0};
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

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }
}

