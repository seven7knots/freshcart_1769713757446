// ============================================================
// FILE: lib/providers/admin_provider.dart
// ============================================================
// Admin provider with dashboard, user management, and
// merchant/driver application approval functionality
//
// Model A role resolution: admin > merchant > user
// Source of truth for admin: RPC is_admin()
// Source of truth for merchant: merchants.status == 'approved' for current user
// UPDATED: Handles driver applications using is_verified/is_active flags
// ISSUE 2 FIX: Debounced refreshRoles to prevent redundant API calls
// SESSION 20 FIX: Admin revenue = sum of delivery_fee (not order total)
// SESSION 27 FIXES:
// - Removed wallet adjustment method (no wallet system)
// - loadUsers now fetches order counts per user
// - Revenue card uses total_revenue consistently
// SESSION 28 FIXES:
// - Revenue now counts ALL non-cancelled orders (not just 'delivered')
//   because delivery fee is earned when order is confirmed, not just on delivery
// - Cancellation deductions: cancelled orders' delivery_fees are excluded
// - Added daily / monthly / yearly revenue breakdown
// - Removed all hardcoded revenue values
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/merchant_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // STATE
  // ============================================================

  bool _isAdmin = false;
  bool _isMerchant = false;
  bool _isLoading = false;
  String? _error;
  bool _isEditMode = false;

  // ISSUE 2 FIX: Debounce tracking for refreshRoles
  DateTime? _lastRoleRefresh;
  bool _isRefreshingRoles = false;
  static const _roleRefreshCooldown = Duration(seconds: 2);

  // Dashboard
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _recentOrders = [];

  // SESSION 28: Revenue breakdown (today / month / year / all-time)
  // All values are delivery_fee sums from NON-CANCELLED orders only.
  Map<String, double> _revenueBreakdown = {
    'today': 0.0,
    'this_month': 0.0,
    'this_year': 0.0,
    'all_time': 0.0,
  };

  // Users
  List<Map<String, dynamic>> _users = [];

  // Applications
  List<Merchant> _pendingMerchants = [];
  List<Driver> _pendingDrivers = [];
  List<Merchant> _allMerchants = [];
  List<Driver> _allDrivers = [];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isAdmin => _isAdmin;
  bool get isMerchant => _isMerchant;

  String get effectiveRole {
    if (_isAdmin) return 'admin';
    if (_isMerchant) return 'merchant';
    return 'user';
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditMode => _isEditMode;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get users => _users;

  // SESSION 28: Revenue breakdown getter
  Map<String, double> get revenueBreakdown => _revenueBreakdown;

  List<Merchant> get pendingMerchants => _pendingMerchants;
  List<Driver> get pendingDrivers => _pendingDrivers;
  List<Merchant> get allMerchants => _allMerchants;
  List<Driver> get allDrivers => _allDrivers;

  int get pendingApplicationsCount =>
      _pendingMerchants.length + _pendingDrivers.length;

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
  // ROLE RESOLUTION (Model A) — WITH DEBOUNCE
  // ============================================================

  Future<void> checkAdminStatus({String reason = 'unknown'}) async {
    await refreshRoles(reason: reason);
  }

  Future<void> refreshRoles({String reason = 'unknown', bool force = false}) async {
    if (_isRefreshingRoles) {
      debugPrint('[ROLE] refreshRoles SKIPPED (already in progress) - reason: $reason');
      return;
    }

    if (!force && _lastRoleRefresh != null) {
      final elapsed = DateTime.now().difference(_lastRoleRefresh!);
      if (elapsed < _roleRefreshCooldown) {
        debugPrint('[ROLE] refreshRoles SKIPPED (cooldown ${elapsed.inMilliseconds}ms) - reason: $reason');
        return;
      }
    }

    _isRefreshingRoles = true;
    debugPrint('[ROLE] refreshRoles - reason: $reason');

    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('[ROLE] No user logged in -> admin=false merchant=false');
      _isAdmin = false;
      _isMerchant = false;
      _isRefreshingRoles = false;
      _lastRoleRefresh = DateTime.now();
      notifyListeners();
      return;
    }

    bool admin = false;
    bool merchant = false;

    // 1) ADMIN CHECK
    try {
      final result = await _client.rpc('is_admin');
      admin = (result == true);
      debugPrint('[ROLE] RPC is_admin => $admin');
    } catch (e) {
      debugPrint('[ROLE] RPC is_admin failed, fallback query: $e');
      try {
        final row = await _client
            .from('users')
            .select('role, is_active')
            .eq('id', user.id)
            .maybeSingle();

        admin = row != null &&
            row['role'] == 'admin' &&
            row['is_active'] == true;
        debugPrint('[ROLE] users(role,is_active) => admin=$admin');
      } catch (e2) {
        debugPrint('[ROLE] users fallback failed => admin=false : $e2');
        admin = false;
      }
    }

    // 2) MERCHANT CHECK
    try {
      final m = await _client
          .from('merchants')
          .select('status')
          .eq('user_id', user.id)
          .maybeSingle();

      final status = (m?['status']?.toString() ?? '').trim().toLowerCase();
      merchant = (status == 'approved');
      debugPrint('[ROLE] merchants(status="$status") => merchant=$merchant');
    } catch (e) {
      debugPrint('[ROLE] merchant check failed => merchant=false : $e');
      merchant = false;
    }

    _isAdmin = admin;
    _isMerchant = merchant;
    _isRefreshingRoles = false;
    _lastRoleRefresh = DateTime.now();

    debugPrint(
      '[ROLE] resolved => isAdmin=$_isAdmin isMerchant=$_isMerchant effectiveRole=$effectiveRole',
    );
    notifyListeners();
  }

  // ============================================================
  // ADMIN ACCESS CHECK
  // ============================================================

  Future<bool> _ensureAdmin() async {
    if (_lastRoleRefresh == null) {
      await refreshRoles(reason: 'ensureAdmin-first-check');
    }
    return _isAdmin;
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<void> loadDashboardStats() async {
    debugPrint('[ADMIN] Loading dashboard stats...');
    _setLoading(true);
    _setError(null);

    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied: not an admin');
        _setLoading(false);
        return;
      }

      // Try RPC first for base stats
      try {
        final result = await _client.rpc('get_admin_dashboard_stats');
        _dashboardStats = _normalizeStats(result);
      } catch (e) {
        debugPrint('[ADMIN] Dashboard RPC failed: $e');
        _dashboardStats = {
          'total_users': 0,
          'active_users': 0,
          'total_orders': 0,
          'pending_applications': 0,
        };
      }

      // Fix: Query actual online drivers count from drivers table
      // The RPC may return stale data; the driver toggle writes is_online
      // directly to the drivers table, so we read from there.
      try {
        final onlineResult = await _client
            .from('drivers')
            .select('id')
            .eq('is_online', true);
        final onlineCount = (onlineResult as List).length;
        _dashboardStats ??= {};
        _dashboardStats!['online_drivers'] = onlineCount;
        debugPrint('[ADMIN] Online drivers (live query): $onlineCount');
      } catch (e) {
        debugPrint('[ADMIN] Online drivers query failed: $e');
      }

      // SESSION 28: Load accurate revenue with full breakdown
      await _loadAdminRevenue();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading dashboard: $e');
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // ============================================================
  // SESSION 28 FIX: Admin revenue calculation
  //
  // Revenue model:
  //   - Delivery fee is EARNED when an order is confirmed (not just delivered).
  //   - Cancelled orders are EXCLUDED (deducted automatically by not counting them).
  //   - Formula: SUM(delivery_fee) WHERE status NOT IN ('cancelled')
  //
  // Breakdown: today / this month / this year / all-time
  // All figures are derived from live DB — zero hardcoding.
  // ============================================================
  Future<void> _loadAdminRevenue() async {
    try {
      final now = DateTime.now();
      final startOfDay   = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfYear  = DateTime(now.year, 1, 1);

      // Fetch ALL non-cancelled orders with delivery_fee in one query.
      // We filter out 'cancelled' status — this naturally handles the
      // "cancellation deduction" requirement: cancelled orders are never
      // included in any revenue figure.
      final rows = await _client
          .from('orders')
          .select('delivery_fee, created_at')
          .neq('status', 'cancelled');

      double today     = 0.0;
      double thisMonth = 0.0;
      double thisYear  = 0.0;
      double allTime   = 0.0;

      for (final row in (rows as List)) {
        final fee = (row['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        if (fee <= 0) continue;

        allTime += fee;

        final raw = row['created_at'];
        if (raw == null) continue;
        final dt = DateTime.tryParse(raw.toString());
        if (dt == null) continue;

        if (!dt.isBefore(startOfYear))  thisYear  += fee;
        if (!dt.isBefore(startOfMonth)) thisMonth += fee;
        if (!dt.isBefore(startOfDay))   today     += fee;
      }

      _revenueBreakdown = {
        'today':      today,
        'this_month': thisMonth,
        'this_year':  thisYear,
        'all_time':   allTime,
      };

      // Keep dashboardStats total_revenue in sync for metric cards
      _dashboardStats ??= {};
      _dashboardStats!['total_revenue'] = allTime;

      debugPrint(
        '[ADMIN] Revenue — today: \$${today.toStringAsFixed(2)}, '
        'month: \$${thisMonth.toStringAsFixed(2)}, '
        'year: \$${thisYear.toStringAsFixed(2)}, '
        'all-time: \$${allTime.toStringAsFixed(2)} '
        '(non-cancelled delivery fees only)',
      );
    } catch (e) {
      debugPrint('[ADMIN] Error loading admin revenue: $e');
      // Non-fatal: keep existing values
    }
  }

  Future<void> loadRecentOrders({int limit = 5}) async {
    _setLoading(true);

    try {
      if (!await _ensureAdmin()) {
        _recentOrders = [];
        _setLoading(false);
        return;
      }

      final result = await _client
          .from('orders')
          .select('*, stores(name, image_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      _recentOrders = _normalizeList(result);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading recent orders: $e');
      _recentOrders = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // ============================================================
  // USERS MANAGEMENT
  // SESSION 27 FIX: Now fetches order counts per user
  // ============================================================

  Future<void> loadUsers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,
  }) async {
    debugPrint('[ADMIN] Loading users...');
    _setLoading(true);
    _setError(null);

    try {
      if (!await _ensureAdmin()) {
        _users = [];
        _setLoading(false);
        _setError('Access denied');
        return;
      }

      var query = _client.from('users').select();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final s = searchQuery.trim();
        query = query.or('email.ilike.%$s%,full_name.ilike.%$s%');
      }

      if (filterRole != null && filterRole.trim().isNotEmpty) {
        query = query.eq('role', filterRole.trim());
      }

      if (filterStatus != null) {
        query = query.eq('is_active', filterStatus);
      }

      final result = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      _users = _normalizeList(result);

      await _loadUserOrderCounts();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading users: $e');
      _users = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> _loadUserOrderCounts() async {
    if (_users.isEmpty) return;

    try {
      final userIds = _users
          .map((u) => u['id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (userIds.isEmpty) return;

      final orders = await _client
          .from('orders')
          .select('user_id')
          .inFilter('user_id', userIds);

      final countMap = <String, int>{};
      for (var order in (orders as List)) {
        final uid = order['user_id'] as String?;
        if (uid != null) {
          countMap[uid] = (countMap[uid] ?? 0) + 1;
        }
      }

      for (var i = 0; i < _users.length; i++) {
        final uid = _users[i]['id'] as String?;
        _users[i]['order_count'] = countMap[uid] ?? 0;
      }

      debugPrint('[ADMIN] Order counts loaded for ${userIds.length} users');
    } catch (e) {
      debugPrint('[ADMIN] Error loading order counts: $e');
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      if (!await _ensureAdmin()) return false;

      await _client
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);

      _patchLocalUser(userId, {'is_active': isActive});
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error updating user status: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      if (!await _ensureAdmin()) return false;

      await _client.from('users').update({'role': role}).eq('id', userId);

      _patchLocalUser(userId, {'role': role});
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error updating user role: $e');
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // MERCHANT APPLICATIONS
  // ============================================================

  Future<void> loadPendingMerchants() async {
    debugPrint('[ADMIN] Loading pending merchants...');
    _setLoading(true);

    try {
      if (!await _ensureAdmin()) {
        _pendingMerchants = [];
        _setLoading(false);
        return;
      }

      final result = await _client
          .from('merchants')
          .select('*, users(email, full_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _pendingMerchants = (result as List)
          .map((m) => Merchant.fromMap(m as Map<String, dynamic>))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading pending merchants: $e');
      _pendingMerchants = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> loadAllMerchants({String? statusFilter}) async {
    debugPrint('[ADMIN] Loading all merchants...');
    _setLoading(true);

    try {
      if (!await _ensureAdmin()) {
        _allMerchants = [];
        _setLoading(false);
        return;
      }

      var query = _client.from('merchants').select('*, users(email, full_name)');
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      final result = await query.order('created_at', ascending: false);

      _allMerchants = (result as List)
          .map((m) => Merchant.fromMap(m as Map<String, dynamic>))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading merchants: $e');
      _allMerchants = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<bool> approveMerchant(String merchantId) async {
    debugPrint('[ADMIN] Approving merchant: $merchantId');

    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied');
        return false;
      }

      final result = await _client.rpc(
        'admin_approve_merchant',
        params: {'p_merchant_id': merchantId},
      );

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        return false;
      }

      await loadPendingMerchants();
      await refreshRoles(reason: 'approveMerchant-postRefresh', force: true);
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error approving merchant: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> rejectMerchant(String merchantId, {String? reason}) async {
    debugPrint('[ADMIN] Rejecting merchant: $merchantId');

    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied');
        return false;
      }

      final result = await _client.rpc(
        'admin_reject_merchant',
        params: {
          'p_merchant_id': merchantId,
          'p_reason': reason,
        },
      );

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        return false;
      }

      await loadPendingMerchants();
      await refreshRoles(reason: 'rejectMerchant-postRefresh', force: true);
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error rejecting merchant: $e');
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // DRIVER APPLICATIONS
  // ============================================================

  Future<void> loadPendingDrivers() async {
    debugPrint('[ADMIN] Loading pending drivers...');
    _setLoading(true);

    try {
      if (!await _ensureAdmin()) {
        _pendingDrivers = [];
        _setLoading(false);
        return;
      }

      final result = await _client
          .from('drivers')
          .select('*, users(email, full_name)')
          .eq('is_active', true)
          .eq('is_verified', false)
          .order('created_at', ascending: false);

      _pendingDrivers = (result as List)
          .map((d) => Driver.fromMap(d as Map<String, dynamic>))
          .toList();

      debugPrint('[ADMIN] Loaded ${_pendingDrivers.length} pending drivers');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading pending drivers: $e');
      _pendingDrivers = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> loadAllDrivers({bool? isVerified}) async {
    debugPrint('[ADMIN] Loading all drivers...');
    _setLoading(true);

    try {
      if (!await _ensureAdmin()) {
        _allDrivers = [];
        _setLoading(false);
        return;
      }

      var query = _client.from('drivers').select('*, users(email, full_name)');

      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }

      final result = await query.order('created_at', ascending: false);

      _allDrivers = (result as List)
          .map((d) => Driver.fromMap(d as Map<String, dynamic>))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading drivers: $e');
      _allDrivers = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<bool> approveDriver(String driverId) async {
    debugPrint('[ADMIN] Approving driver: $driverId');

    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied');
        return false;
      }

      try {
        final result = await _client.rpc(
          'admin_approve_driver',
          params: {'p_driver_id': driverId},
        );

        if (result is Map && result['error'] != null) {
          throw Exception(result['error']);
        }
      } catch (rpcError) {
        debugPrint('[ADMIN] RPC admin_approve_driver not available, using direct update: $rpcError');

        await _client
            .from('drivers')
            .update({
              'is_verified': true,
              'is_active': true,
            })
            .eq('id', driverId);

        final driver = await _client
            .from('drivers')
            .select('user_id')
            .eq('id', driverId)
            .single();

        if (driver['user_id'] != null) {
          await _client
              .from('users')
              .update({'role': 'driver'})
              .eq('id', driver['user_id']);
        }
      }

      await loadPendingDrivers();
      await refreshRoles(reason: 'approveDriver-postRefresh', force: true);
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error approving driver: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> rejectDriver(String driverId, {String? reason}) async {
    debugPrint('[ADMIN] Rejecting driver: $driverId');

    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied');
        return false;
      }

      try {
        final result = await _client.rpc(
          'admin_reject_driver',
          params: {
            'p_driver_id': driverId,
            'p_reason': reason,
          },
        );

        if (result is Map && result['error'] != null) {
          throw Exception(result['error']);
        }
      } catch (rpcError) {
        debugPrint('[ADMIN] RPC admin_reject_driver not available, using direct update: $rpcError');

        final updateData = <String, dynamic>{
          'is_verified': false,
          'is_active': false,
          'rejected_at': DateTime.now().toIso8601String(),
        };

        if (reason != null && reason.isNotEmpty) {
          updateData['rejection_reason'] = reason;
        }

        await _client
            .from('drivers')
            .update(updateData)
            .eq('id', driverId);
      }

      await loadPendingDrivers();
      await refreshRoles(reason: 'rejectDriver-postRefresh', force: true);
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error rejecting driver: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeDriver(String driverId) async {
    debugPrint('[ADMIN] Removing driver: $driverId');
    try {
      if (!await _ensureAdmin()) {
        _setError('Access denied');
        return false;
      }
      final driver = await _client
          .from('drivers')
          .select('user_id')
          .eq('id', driverId)
          .single();
      await _client.from('drivers').delete().eq('id', driverId);
      if (driver['user_id'] != null) {
        await _client
            .from('users')
            .update({'role': 'customer'})
            .eq('id', driver['user_id']);
      }
      debugPrint('[ADMIN] Driver removed successfully');
      await loadPendingDrivers();
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error removing driver: $e');
      _setError(e.toString());
      return false;
    }
  }

  Future<void> loadPendingApplications() async {
    await Future.wait([loadPendingMerchants(), loadPendingDrivers()]);
  }

  // ============================================================
  // EDIT MODE
  // ============================================================

  void setEditMode(bool value) {
    _isEditMode = value;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _patchLocalUser(String userId, Map<String, dynamic> patch) {
    final idx = _users.indexWhere((u) => u['id'] == userId);
    if (idx != -1) {
      _users[idx] = {..._users[idx], ...patch};
      notifyListeners();
    }
  }

  Map<String, dynamic>? _normalizeStats(dynamic res) {
    if (res == null) return null;
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    if (res is List && res.isNotEmpty) {
      final first = res.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return <String, dynamic>{};
  }

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
}