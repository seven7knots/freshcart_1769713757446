import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class AdminService {
  final SupabaseClient _client = SupabaseService.client;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('users')
          .select('role, is_active')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;
      return response['role'] == 'admin' && response['is_active'] == true;
    } catch (e) {
      return false;
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.rpc('get_admin_dashboard_stats');
      return response[0] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Get users list with filters
  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc('get_users_for_admin', params: {
        'search_query': searchQuery,
        'filter_role': filterRole,
        'filter_status': filterStatus,
        'limit_count': limit,
        'offset_count': offset,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Get user details by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();

      return response;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  // Get user transactions
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
      throw Exception('Failed to get user transactions: $e');
    }
  }

  // Get user orders
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
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Adjust user wallet balance
  Future<bool> adjustWalletBalance({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    try {
      final response =
          await _client.rpc('admin_adjust_wallet_balance', params: {
        'target_user_id': userId,
        'adjustment_amount': amount,
        'adjustment_reason': reason,
      });

      return response == true;
    } catch (e) {
      throw Exception('Failed to adjust wallet balance: $e');
    }
  }

  // Update user status (suspend/activate)
  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final response = await _client.rpc('admin_update_user_status', params: {
        'target_user_id': userId,
        'new_status': isActive,
      });

      return response == true;
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Get active orders count
  Future<int> getActiveOrdersCount() async {
    try {
      final response =
          await _client.from('orders').select('id').inFilter('status', [
        'pending',
        'confirmed',
        'preparing',
        'ready',
        'assigned',
        'picked_up',
        'in_transit'
      ]);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get online drivers count
  Future<int> getOnlineDriversCount() async {
    try {
      final response = await _client
          .from('drivers')
          .select('id')
          .eq('is_online', true)
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get recent orders for live dashboard
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
      throw Exception('Failed to get recent orders: $e');
    }
  }
}
