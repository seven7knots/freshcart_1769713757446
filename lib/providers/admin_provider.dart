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
  bool _isMerchant = false; // approved merchant for current user
  bool _isLoading = false;
  String? _error;
  bool _isEditMode = false;

  // Dashboard
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _recentOrders = [];

  // Users
  List<Map<String, dynamic>> _users = [];

  // Applications
  List<Merchant> _pendingMerchants = [];
  List<Driver> _pendingDrivers = []; // Changed to List<Driver>
  List<Merchant> _allMerchants = [];
  List<Driver> _allDrivers = []; // Changed to List<Driver>

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isAdmin => _isAdmin;
  bool get isMerchant => _isMerchant;

  /// Effective role (Model A): admin always wins.
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

  List<Merchant> get pendingMerchants => _pendingMerchants;
  List<Driver> get pendingDrivers => _pendingDrivers; // Changed type
  List<Merchant> get allMerchants => _allMerchants;
  List<Driver> get allDrivers => _allDrivers; // Changed type

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
  // ROLE RESOLUTION (Model A)
  // ============================================================

  Future<void> checkAdminStatus({String reason = 'unknown'}) async {
    await refreshRoles(reason: reason);
  }

  Future<void> refreshRoles({String reason = 'unknown'}) async {
    debugPrint('[ROLE] refreshRoles - reason: $reason');

    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('[ROLE] No user logged in -> admin=false merchant=false');
      _isAdmin = false;
      _isMerchant = false;
      notifyListeners();
      return;
    }

    bool admin = false;
    bool merchant = false;

    // ----------------------------
    // 1) ADMIN CHECK
    // ----------------------------
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

    // ----------------------------
    // 2) MERCHANT CHECK (by auth user id)
    // ----------------------------
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

    debugPrint(
      '[ROLE] resolved => isAdmin=$_isAdmin isMerchant=$_isMerchant effectiveRole=$effectiveRole',
    );
    notifyListeners();
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<void> loadDashboardStats() async {
    debugPrint('[ADMIN] Loading dashboard stats...');
    _setLoading(true);
    _setError(null);

    try {
      await refreshRoles(reason: 'loadDashboardStats');
      if (!_isAdmin) {
        _setError('Access denied: not an admin');
        _setLoading(false);
        return;
      }

      try {
        final result = await _client.rpc('get_admin_dashboard_stats');
        _dashboardStats = _normalizeStats(result);
      } catch (e) {
        debugPrint('[ADMIN] Dashboard RPC failed: $e');
        _dashboardStats = {
          'total_users': 0,
          'active_users': 0,
          'total_orders': 0,
          'total_revenue': 0.0,
          'pending_applications': 0,
        };
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading dashboard: $e');
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> loadRecentOrders({int limit = 5}) async {
    _setLoading(true);

    try {
      await refreshRoles(reason: 'loadRecentOrders');
      if (!_isAdmin) {
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
      await refreshRoles(reason: 'loadUsers');
      if (!_isAdmin) {
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
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ADMIN] Error loading users: $e');
      _users = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await refreshRoles(reason: 'updateUserStatus');
      if (!_isAdmin) return false;

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
      await refreshRoles(reason: 'updateUserRole');
      if (!_isAdmin) return false;

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
      await refreshRoles(reason: 'loadPendingMerchants');
      if (!_isAdmin) {
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
      await refreshRoles(reason: 'loadAllMerchants');
      if (!_isAdmin) {
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
      await refreshRoles(reason: 'approveMerchant');
      if (!_isAdmin) {
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
      await refreshRoles(reason: 'approveMerchant-postRefresh');
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
      await refreshRoles(reason: 'rejectMerchant');
      if (!_isAdmin) {
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
      await refreshRoles(reason: 'rejectMerchant-postRefresh');
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error rejecting merchant: $e');
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // DRIVER APPLICATIONS (CORRECTED)
  // ============================================================

  /// Load pending drivers (is_active=true AND is_verified=false)
  Future<void> loadPendingDrivers() async {
    debugPrint('[ADMIN] Loading pending drivers...');
    _setLoading(true);

    try {
      await refreshRoles(reason: 'loadPendingDrivers');
      if (!_isAdmin) {
        _pendingDrivers = [];
        _setLoading(false);
        return;
      }

      // Pending = active but not verified
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
      await refreshRoles(reason: 'loadAllDrivers');
      if (!_isAdmin) {
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

  /// Approve driver - sets is_verified=true and optionally updates user role
  Future<bool> approveDriver(String driverId) async {
    debugPrint('[ADMIN] Approving driver: $driverId');

    try {
      await refreshRoles(reason: 'approveDriver');
      if (!_isAdmin) {
        _setError('Access denied');
        return false;
      }

      // Try RPC first (if it exists)
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
        
        // Fallback: Direct database update
        // 1. Update driver record
        await _client
            .from('drivers')
            .update({
              'is_verified': true,
              'is_active': true,
              'verified_at': DateTime.now().toIso8601String(),
            })
            .eq('id', driverId);

        // 2. Get the driver's user_id and update user role
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
      await refreshRoles(reason: 'approveDriver-postRefresh');
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error approving driver: $e');
      _setError(e.toString());
      return false;
    }
  }

  /// Reject driver - sets is_active=false and stores reason
  Future<bool> rejectDriver(String driverId, {String? reason}) async {
    debugPrint('[ADMIN] Rejecting driver: $driverId');

    try {
      await refreshRoles(reason: 'rejectDriver');
      if (!_isAdmin) {
        _setError('Access denied');
        return false;
      }

      // Try RPC first (if it exists)
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
        
        // Fallback: Direct database update
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
      await refreshRoles(reason: 'rejectDriver-postRefresh');
      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error rejecting driver: $e');
      _setError(e.toString());
      return false;
    }
  }

  /// Load both pending merchants and drivers
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
  // WALLET ADJUSTMENT
  // ============================================================

  Future<bool> adjustWalletBalance({
    required String userId,
    required num amount,
    String? note,
    String? reason,
  }) async {
    try {
      await refreshRoles(reason: 'adjustWalletBalance');
      if (!_isAdmin) {
        _setError('Access denied');
        return false;
      }

      await _client.rpc('admin_adjust_wallet_balance', params: {
        'target_user_id': userId,
        'adjustment_amount': amount.toDouble(),
        'adjustment_reason': reason ?? note ?? 'Manual adjustment',
      });

      return true;
    } catch (e) {
      debugPrint('[ADMIN] Error adjusting wallet: $e');
      _setError(e.toString());
      return false;
    }
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