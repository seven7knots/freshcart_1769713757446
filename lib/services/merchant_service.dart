import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/merchant_model.dart';

class MerchantService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Get merchant by user_id
  static Future<Merchant?> getMyMerchant(String userId) async {
    try {
      debugPrint('[MERCHANT] Loading merchant for user_id=$userId');

      final response = await _client
          .from('merchants')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[MERCHANT] No merchant found for user_id=$userId');
        return null;
      }

      final merchant = Merchant.fromMap(response);
      debugPrint('[MERCHANT] load ok: merchant_id=${merchant.id}');
      return merchant;
    } on PostgrestException catch (e) {
      debugPrint(
          '[MERCHANT] error loading: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[MERCHANT] error loading: $e');
      rethrow;
    }
  }

  /// Create merchant for current user
  static Future<Merchant> createMyMerchant(
      String userId, Map<String, dynamic> payload) async {
    try {
      debugPrint('[MERCHANT] Creating merchant for user_id=$userId');

      // Add user_id to payload
      final data = {
        ...payload,
        'user_id': userId,
      };

      final response =
          await _client.from('merchants').insert(data).select().single();

      final merchant = Merchant.fromMap(response);
      debugPrint('[MERCHANT] create ok: merchant_id=${merchant.id}');
      return merchant;
    } on PostgrestException catch (e) {
      debugPrint(
          '[MERCHANT] error creating: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[MERCHANT] error creating: $e');
      rethrow;
    }
  }

  /// Update merchant by merchant_id
  static Future<Merchant> updateMyMerchant(
      String merchantId, Map<String, dynamic> updates) async {
    try {
      debugPrint('[MERCHANT] Updating merchant_id=$merchantId');

      // Add updated_at timestamp
      final data = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('merchants')
          .update(data)
          .eq('id', merchantId)
          .select()
          .single();

      final merchant = Merchant.fromMap(response);
      debugPrint('[MERCHANT] update ok: merchant_id=${merchant.id}');
      return merchant;
    } on PostgrestException catch (e) {
      debugPrint(
          '[MERCHANT] error updating: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[MERCHANT] error updating: $e');
      rethrow;
    }
  }
}
