import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response =
          await _client.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;
      return UserModel(
        id: response['id'] as String,
        email: response['email'] as String,
        fullName: response['full_name'] as String?,
        phone: response['phone'] as String?,
        profileImageUrl: response['profile_image_url'] as String?,
        defaultAddress: response['default_address'] as String?,
        locationLat: response['location_lat'] as double?,
        locationLng: response['location_lng'] as double?,
        fcmToken: response['fcm_token'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;
      return UserModel(
        id: response['id'] as String,
        email: response['email'] as String,
        fullName: response['full_name'] as String?,
        phone: response['phone'] as String?,
        profileImageUrl: response['profile_image_url'] as String?,
        defaultAddress: response['default_address'] as String?,
        locationLat: response['location_lat'] as double?,
        locationLng: response['location_lng'] as double?,
        fcmToken: response['fcm_token'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
    String? defaultAddress,
    double? locationLat,
    double? locationLng,
    String? fcmToken,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) {
        updates['profile_image_url'] = profileImageUrl;
      }
      if (defaultAddress != null) updates['default_address'] = defaultAddress;
      if (locationLat != null) updates['location_lat'] = locationLat;
      if (locationLng != null) updates['location_lng'] = locationLng;
      if (fcmToken != null) updates['fcm_token'] = fcmToken;

      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel(
        id: response['id'] as String,
        email: response['email'] as String,
        fullName: response['full_name'] as String?,
        phone: response['phone'] as String?,
        profileImageUrl: response['profile_image_url'] as String?,
        defaultAddress: response['default_address'] as String?,
        locationLat: response['location_lat'] as double?,
        locationLng: response['location_lng'] as double?,
        fcmToken: response['fcm_token'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user wallet balance
  Future<double> getWalletBalance() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await _client
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return 0.0;
      return (response['balance'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }
}
