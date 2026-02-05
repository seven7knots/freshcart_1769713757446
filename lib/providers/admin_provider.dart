import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;
  SupabaseClient get _client => Supabase.instance.client;

  // ---- Auth/Admin state ----
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ---- Dashboard data ----
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> get recentOrders => _recentOrders;

  // ---- Users management ----
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  // ---- Global edit overlay ----
  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  AdminProvider({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  // ============================================================
  // ADMIN CHECK - CRITICAL FOR ACCESS CONTROL
  // ============================================================

  Future<void> checkAdminStatus({String reason = 'unknown'}) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[AdminProvider] checkAdminStatus START');
    print('[AdminProvider] Reason: $reason');
    print('[AdminProvider] Current isAdmin state: $_isAdmin');

    try {
      final user = _client.auth.currentUser;
      
      print('[AdminProvider] ┌─ Current User Info:');
      print('[AdminProvider] │  user == null: ${user == null}');
      print('[AdminProvider] │  id: ${user?.id}');
      print('[AdminProvider] │  email: ${user?.email}');
      print('[AdminProvider] │  role (JWT): ${user?.role}');
      print('[AdminProvider] │  app_metadata: ${user?.appMetadata}');
      print('[AdminProvider] │  user_metadata: ${user?.userMetadata}');
      print('[AdminProvider] └─');

      if (user == null) {
        print('[AdminProvider] ❌ NO USER -> Setting isAdmin=false');
        _isAdmin = false;
        _setError(null);
        notifyListeners();
        print('[AdminProvider] checkAdminStatus COMPLETE (no user)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      print('[AdminProvider] ┌─ Calling AdminService.isAdmin()...');
      final res = await _adminService.isAdmin();
      
      print('[AdminProvider] │  Raw response: $res');
      print('[AdminProvider] │  Response type: ${res.runtimeType}');
      print('[AdminProvider] │  Response == true: ${res == true}');
      print('[AdminProvider] │  Response is bool: ${res is bool}');
      print('[AdminProvider] └─');

      final oldIsAdmin = _isAdmin;
      _isAdmin = res;

      if (oldIsAdmin != _isAdmin) {
        print('[AdminProvider] ⚠️  isAdmin CHANGED: $oldIsAdmin → $_isAdmin');
      } else {
        print('[AdminProvider] ℹ️  isAdmin unchanged: $_isAdmin');
      }

      _setError(null);
      notifyListeners();
      print('[AdminProvider] ✅ notifyListeners() called');

      print('[AdminProvider] checkAdminStatus COMPLETE');
      print('[AdminProvider] Final state: isAdmin=$_isAdmin, error=$_error');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR in checkAdminStatus');
      print('[AdminProvider] Error: $e');
      print('[AdminProvider] Error type: ${e.runtimeType}');
      print('[AdminProvider] Stack trace:');
      print(st);
      
      _isAdmin = false;
      _setError(e.toString());
      notifyListeners();
      
      print('[AdminProvider] Set isAdmin=false due to error');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // ============================================================
  // DASHBOARD STATS & RECENT ORDERS
  // ============================================================

  Future<void> loadDashboardStats() async {
    print('[AdminProvider] loadDashboardStats START');
    _setLoading(true);
    _setError(null);

    try {
      await checkAdminStatus(reason: 'loadDashboardStats');
      if (!_isAdmin) {
        _dashboardStats = null;
        _setLoading(false);
        _setError('Access denied: not an admin');
        print('[AdminProvider] loadDashboardStats ABORT - not admin');
        return;
      }

      Map<String, dynamic>? stats;

      // Try service method if exists, otherwise fallback to RPC
      try {
        final res = await _adminService.fetchDashboardStats();
        stats = _normalizeStats(res);
        print('[AdminProvider] loadDashboardStats via service: OK (${stats?.keys.length ?? 0} keys)');
      } catch (serviceError) {
        print('[AdminProvider] Service method failed: $serviceError');
        print('[AdminProvider] Falling back to RPC: admin_dashboard_stats');
        
        const rpcName = 'admin_dashboard_stats';
        final res = await _client.rpc(rpcName);
        stats = _normalizeStats(res);
        print('[AdminProvider] RPC response type: ${res.runtimeType}');
        print('[AdminProvider] Normalized stats: ${stats?.keys.length ?? 0} keys');
      }

      _dashboardStats = stats ?? <String, dynamic>{};
      _setLoading(false);
      notifyListeners();
      
      print('[AdminProvider] loadDashboardStats COMPLETE: ${_dashboardStats?.keys.join(', ')}');
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR loadDashboardStats: $e');
      print('[AdminProvider] Stack: $st');
      
      _dashboardStats = null;
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<void> loadRecentOrders({int limit = 5}) async {
    print('[AdminProvider] loadRecentOrders START (limit=$limit)');
    _setLoading(true);
    _setError(null);

    try {
      await checkAdminStatus(reason: 'loadRecentOrders');
      if (!_isAdmin) {
        _recentOrders = [];
        _setLoading(false);
        _setError('Access denied: not an admin');
        print('[AdminProvider] loadRecentOrders ABORT - not admin');
        return;
      }

      List<Map<String, dynamic>> orders = [];

      try {
        final res = await _adminService.fetchRecentOrders(limit: limit);
        orders = _normalizeListOfMap(res);
        print('[AdminProvider] loadRecentOrders via service: OK (${orders.length} orders)');
      } catch (serviceError) {
        print('[AdminProvider] Service method failed: $serviceError');
        print('[AdminProvider] Falling back to direct orders table query');
        
        final res = await _client
            .from('orders')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        orders = _normalizeListOfMap(res);
        print('[AdminProvider] Direct query: OK (${orders.length} orders)');
      }

      _recentOrders = orders;
      _setLoading(false);
      notifyListeners();

      print('[AdminProvider] loadRecentOrders COMPLETE');
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR loadRecentOrders: $e');
      print('[AdminProvider] Stack: $st');
      
      _recentOrders = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // ============================================================
  // USERS MANAGEMENT
  // NOTE: filterStatus is bool? (active/inactive), not String
  // ============================================================

  Future<void> loadUsers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,  // ← bool? to match UI calls
  }) async {
    print('[AdminProvider] loadUsers START');
    print('[AdminProvider]   search: $searchQuery');
    print('[AdminProvider]   role: $filterRole');
    print('[AdminProvider]   status: $filterStatus (bool?)');
    print('[AdminProvider]   limit: $limit, offset: $offset');

    _setLoading(true);
    _setError(null);

    try {
      await checkAdminStatus(reason: 'loadUsers');
      if (!_isAdmin) {
        _users = [];
        _setLoading(false);
        _setError('Access denied: not an admin');
        print('[AdminProvider] loadUsers ABORT - not admin');
        return;
      }

      List<Map<String, dynamic>> rows = [];

      // Try service if available
      try {
        final res = await _adminService.fetchUsers(
          limit: limit,
          offset: offset,
          searchQuery: searchQuery,
          filterRole: filterRole,
          filterStatus: filterStatus,
        );
        rows = _normalizeListOfMap(res);
        print('[AdminProvider] loadUsers via service: OK (${rows.length} users)');
      } catch (serviceError) {
        print('[AdminProvider] Service method failed: $serviceError');
        print('[AdminProvider] Falling back to direct users table query');
        
        PostgrestFilterBuilder q = _client.from('users').select();

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final s = searchQuery.trim();
          q = q.or('email.ilike.%$s%,full_name.ilike.%$s%');
          print('[AdminProvider]   Applied search filter: $s');
        }

        if (filterRole != null && filterRole.trim().isNotEmpty) {
          q = q.eq('role', filterRole.trim());
          print('[AdminProvider]   Applied role filter: $filterRole');
        }

        if (filterStatus != null) {
          q = q.eq('is_active', filterStatus);
          print('[AdminProvider]   Applied status filter: $filterStatus');
        }

        final res = await q
            .range(offset, offset + limit - 1)
            .order('created_at', ascending: false);

        rows = _normalizeListOfMap(res);
        print('[AdminProvider] Direct query: OK (${rows.length} users)');
      }

      _users = rows;
      _setLoading(false);
      notifyListeners();

      print('[AdminProvider] loadUsers COMPLETE (${_users.length} users in state)');
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR loadUsers: $e');
      print('[AdminProvider] Stack: $st');
      
      _users = [];
      _setLoading(false);
      _setError(e.toString());
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    print('[AdminProvider] updateUserStatus START');
    print('[AdminProvider]   userId: $userId');
    print('[AdminProvider]   isActive: $isActive');
    
    _setError(null);

    try {
      await checkAdminStatus(reason: 'updateUserStatus');
      if (!_isAdmin) {
        _setError('Access denied: not an admin');
        print('[AdminProvider] updateUserStatus ABORT - not admin');
        return false;
      }

      try {
        final success = await _adminService.updateUserStatus(
          userId: userId,
          isActive: isActive,
        );
        
        if (success == true) {
          _patchLocalUser(userId, {'is_active': isActive});
          print('[AdminProvider] updateUserStatus via service: OK');
          return true;
        }
      } catch (serviceError) {
        print('[AdminProvider] Service method failed: $serviceError');
        print('[AdminProvider] Falling back to direct update');
        
        await _client
            .from('users')
            .update({'is_active': isActive})
            .eq('id', userId);
      }

      _patchLocalUser(userId, {'is_active': isActive});
      print('[AdminProvider] updateUserStatus COMPLETE');
      return true;
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR updateUserStatus: $e');
      print('[AdminProvider] Stack: $st');
      
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> adjustWalletBalance({
    required String userId,
    required num amount,
    String? note,
    String? reason,  // ← Matches UI signature
  }) async {
    print('[AdminProvider] adjustWalletBalance START');
    print('[AdminProvider]   userId: $userId');
    print('[AdminProvider]   amount: $amount');
    print('[AdminProvider]   reason: $reason');
    print('[AdminProvider]   note: $note');
    
    _setError(null);

    try {
      await checkAdminStatus(reason: 'adjustWalletBalance');
      if (!_isAdmin) {
        _setError('Access denied: not an admin');
        print('[AdminProvider] adjustWalletBalance ABORT - not admin');
        return false;
      }

      try {
        final success = await _adminService.adjustWalletBalance(
          userId: userId,
          amount: amount,
          note: note,
          reason: reason,
        );
        
        if (success == true) {
          print('[AdminProvider] adjustWalletBalance via service: OK');
          return true;
        }
      } catch (serviceError) {
        print('[AdminProvider] Service method failed: $serviceError');
        print('[AdminProvider] Falling back to RPC: admin_adjust_wallet_balance');
        
        const rpcName = 'admin_adjust_wallet_balance';
        final res = await _client.rpc(rpcName, params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_note': note ?? '',
          'p_reason': reason ?? '',
        });
        
        print('[AdminProvider] RPC response: $res (type: ${res.runtimeType})');
      }

      print('[AdminProvider] adjustWalletBalance COMPLETE');
      return true;
    } catch (e, st) {
      print('[AdminProvider] ❌ ERROR adjustWalletBalance: $e');
      print('[AdminProvider] Stack: $st');
      
      _setError(e.toString());
      return false;
    }
  }

  // ============================================================
  // EDIT MODE
  // ============================================================

  void setEditMode(bool value) {
    _isEditMode = value;
    notifyListeners();
    print('[AdminProvider] setEditMode: $_isEditMode');
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
    print('[AdminProvider] toggleEditMode: $_isEditMode');
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  void _patchLocalUser(String userId, Map<String, dynamic> patch) {
    final idx = _users.indexWhere((u) => (u['id']?.toString() ?? '') == userId);
    if (idx == -1) {
      print('[AdminProvider] _patchLocalUser: userId $userId not found in local cache');
      return;
    }
    
    _users[idx] = {..._users[idx], ...patch};
    notifyListeners();
    print('[AdminProvider] _patchLocalUser: Updated user $userId with $patch');
  }

  // ============================================================
  // NORMALIZERS - Handle various RPC/query response shapes
  // ============================================================

  Map<String, dynamic>? _normalizeStats(dynamic res) {
    if (res == null) return null;

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);

    if (res is List) {
      if (res.isEmpty) return <String, dynamic>{};
      final first = res.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }

    return <String, dynamic>{'value': res};
  }

  List<Map<String, dynamic>> _normalizeListOfMap(dynamic res) {
    if (res == null) return <Map<String, dynamic>>[];

    if (res is List) {
      return res
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (res is Map) {
      final data = res['data'];
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }

    return <Map<String, dynamic>>[];
  }
}
