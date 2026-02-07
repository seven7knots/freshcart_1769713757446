import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class AdminService {
  final SupabaseClient _client = SupabaseService.client;

  Future<bool> isAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      debugPrint('[AdminService] Checking admin status for user: $userId');

      if (userId == null) {
        debugPrint('[AdminService] No user ID found - not logged in');
        return false;
      }

      // Try RPC first (bypasses RLS)
      try {
        final rpcResult = await _client.rpc('is_admin');
        debugPrint('[AdminService] RPC is_admin() returned: $rpcResult');
        return rpcResult == true;
      } catch (rpcError) {
        debugPrint('[AdminService] RPC failed: $rpcError');
      }

      // Fallback: direct table query
      debugPrint('[AdminService] Trying direct table query...');
      final response = await _client
          .from('users')
          .select('role, is_active')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('[AdminService] Direct query response: $response');

      if (response == null) {
        debugPrint('[AdminService] No user record found in database');
        return false;
      }

      final isAdmin =
          response['role'] == 'admin' && response['is_active'] == true;

      debugPrint(
        '[AdminService] isAdmin result: $isAdmin (role: ${response['role']}, is_active: ${response['is_active']})',
      );

      return isAdmin;
    } catch (e, stackTrace) {
      debugPrint('[AdminService] ERROR checking admin status: $e');
      debugPrint('[AdminService] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> isApprovedMerchant() async {
    try {
      final userId = _client.auth.currentUser?.id;
      debugPrint('[AdminService] Checking merchant status for user: $userId');

      if (userId == null) return false;

      final m = await _client
          .from('merchants')
          .select('id, status')
          .eq('user_id', userId)
          .maybeSingle();

      final isMerchant = (m != null && (m['status']?.toString() == 'approved'));
      debugPrint('[AdminService] isMerchant result: $isMerchant (row: $m)');
      return isMerchant;
    } catch (e) {
      debugPrint('[AdminService] Error checking merchant status: $e');
      return false;
    }
  }

  /// Model A: admin > merchant > user
  Future<String> getEffectiveRole() async {
    final admin = await isAdmin();
    if (admin) return 'admin';

    final merchant = await isApprovedMerchant();
    if (merchant) return 'merchant';

    return 'user';
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    return getDashboardStats();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      debugPrint('[AdminService] Fetching dashboard stats...');
      final response = await _client.rpc('get_admin_dashboard_stats');
      debugPrint('[AdminService] Dashboard stats response: $response');

      if (response == null || response.isEmpty) {
        return {
          'total_users': 0,
          'active_users': 0,
          'total_orders': 0,
          'total_revenue': 0.0,
        };
      }

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[AdminService] Error getting dashboard stats: $e');
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentOrders({int limit = 10}) async {
    return getRecentOrders(limit: limit);
  }

  Future<List<Map<String, dynamic>>> fetchUsers({
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    return getUsers(
      searchQuery: searchQuery,
      filterRole: filterRole,
      filterStatus: filterStatus,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('[AdminService] Fetching users with filters...');
      final response = await _client.rpc('get_users_for_admin', params: {
        'search_query': searchQuery,
        'filter_role': filterRole,
        'filter_status': filterStatus,
        'limit_count': limit,
        'offset_count': offset,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[AdminService] Error getting users: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();

      return response;
    } catch (e) {
      debugPrint('[AdminService] Error getting user by ID: $e');
      throw Exception('Failed to get user details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    try {
      final walletResponse = await _client
          .from('wallets')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (walletResponse == null) return [];

      final response = await _client
          .from('transactions')
          .select()
          .eq('wallet_id', walletResponse['id'])
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[AdminService] Error getting user transactions: $e');
      throw Exception('Failed to get user transactions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            stores (name, name_ar, image_url)
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[AdminService] Error getting user orders: $e');
      throw Exception('Failed to get user orders: $e');
    }
  }

  Future<bool> adjustWalletBalance({
    required String userId,
    required num amount,
    String? note,
    String? reason,
  }) async {
    try {
      debugPrint(
          '[AdminService] Adjusting wallet balance for user $userId by $amount');
      final response =
          await _client.rpc('admin_adjust_wallet_balance', params: {
        'target_user_id': userId,
        'adjustment_amount': amount.toDouble(),
        'adjustment_reason': reason ?? note ?? 'Manual adjustment',
      });

      return response == true;
    } catch (e) {
      debugPrint('[AdminService] Error adjusting wallet balance: $e');
      throw Exception('Failed to adjust wallet balance: $e');
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      debugPrint(
          '[AdminService] Updating user status for $userId to ${isActive ? "active" : "inactive"}');
      final response = await _client.rpc('admin_update_user_status', params: {
        'target_user_id': userId,
        'new_status': isActive,
      });

      return response == true;
    } catch (e) {
      debugPrint('[AdminService] Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<int> getActiveOrdersCount() async {
    try {
      final response = await _client.from('orders').select('id').inFilter(
        'status',
        [
          'pending',
          'confirmed',
          'preparing',
          'ready',
          'assigned',
          'picked_up',
          'in_transit'
        ],
      );

      return response.length;
    } catch (e) {
      debugPrint('[AdminService] Error getting active orders count: $e');
      return 0;
    }
  }

  Future<int> getOnlineDriversCount() async {
    try {
      final response = await _client
          .from('drivers')
          .select('id')
          .eq('is_online', true)
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      debugPrint('[AdminService] Error getting online drivers count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 10}) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            stores (name, name_ar, address),
            users!orders_driver_id_fkey (id, full_name, phone)
          ''')
          .inFilter('status', [
            'pending',
            'confirmed',
            'preparing',
            'ready',
            'assigned',
            'picked_up',
            'in_transit'
          ])
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[AdminService] Error getting recent orders: $e');
      throw Exception('Failed to get recent orders: $e');
    }
  }
}
