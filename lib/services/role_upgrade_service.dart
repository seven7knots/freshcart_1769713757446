import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class RoleUpgradeService {
  final SupabaseClient _client = SupabaseService.client;

  // Create role upgrade request
  Future<Map<String, dynamic>> createRoleUpgradeRequest({
    required String requestedRole,
    String? requestNotes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user details
      final userResponse = await _client
          .from('users')
          .select('email, full_name, phone, role')
          .eq('id', userId)
          .single();

      // Check if user already has a pending request
      final existingRequest = await _client
          .from('role_upgrade_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        return {
          'success': false,
          'message': 'You already have a pending role upgrade request',
        };
      }

      // Create new request
      final response = await _client
          .from('role_upgrade_requests')
          .insert({
            'user_id': userId,
            'email': userResponse['email'],
            'full_name': userResponse['full_name'],
            'phone': userResponse['phone'],
            'user_current_role': userResponse['role'],
            'requested_role': requestedRole,
            'request_notes': requestNotes,
            'status': 'pending',
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'Role upgrade request submitted successfully',
        'data': response,
      };
    } catch (e) {
      throw Exception('Failed to create role upgrade request: $e');
    }
  }

  // Get user's role upgrade requests
  Future<List<Map<String, dynamic>>> getUserRoleUpgradeRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('role_upgrade_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get role upgrade requests: $e');
    }
  }

  // Get all pending role upgrade requests (admin only)
  Future<List<Map<String, dynamic>>> getPendingRoleUpgradeRequests() async {
    try {
      final response = await _client
          .from('role_upgrade_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  // Get all role upgrade requests with filters (admin only)
  Future<List<Map<String, dynamic>>> getAllRoleUpgradeRequests({
    String? statusFilter,
  }) async {
    try {
      var query = _client.from('role_upgrade_requests').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get role upgrade requests: $e');
    }
  }

  // Approve role upgrade request (admin only)
  Future<Map<String, dynamic>> approveRoleUpgradeRequest(
    String requestId,
  ) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.rpc(
        'approve_role_upgrade_request',
        params: {
          'request_id_param': requestId,
          'admin_id_param': adminId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to approve role upgrade request: $e');
    }
  }

  // Reject role upgrade request (admin only)
  Future<Map<String, dynamic>> rejectRoleUpgradeRequest(
    String requestId,
    String rejectionReason,
  ) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.rpc(
        'reject_role_upgrade_request',
        params: {
          'request_id_param': requestId,
          'admin_id_param': adminId,
          'rejection_reason_param': rejectionReason,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to reject role upgrade request: $e');
    }
  }

  // Check if user can request role upgrade
  Future<bool> canRequestRoleUpgrade() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if user is verified
      final userResponse = await _client
          .from('users')
          .select('email_verified, phone_verified, role')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return false;

      final emailVerified = userResponse['email_verified'] as bool? ?? false;
      final phoneVerified = userResponse['phone_verified'] as bool? ?? false;
      final role = userResponse['role'] as String?;

      // Must be verified and currently a customer
      if (!emailVerified || !phoneVerified || role != 'customer') {
        return false;
      }

      // Check if user has pending request
      final pendingRequest = await _client
          .from('role_upgrade_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      return pendingRequest == null;
    } catch (e) {
      return false;
    }
  }
}
