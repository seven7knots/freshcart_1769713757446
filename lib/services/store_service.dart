import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store_model.dart';

class StoreService {
  final SupabaseClient _client = Supabase.instance.client;

  // -----------------------
  // Customer / Public reads
  // -----------------------

  Future<List<StoreModel>> getAllStores({
    String? category,
    bool? isFeatured,
    int limit = 20,
  }) async {
    try {
      var query = _client.from('stores').select().eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }
      if (isFeatured != null) {
        query = query.eq('is_featured', isFeatured);
      }

      final response =
          await query.order('rating', ascending: false).limit(limit);

      return (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load stores: $e');
    }
  }

  Future<StoreModel?> getStoreById(String storeId) async {
    try {
      final response =
          await _client.from('stores').select().eq('id', storeId).maybeSingle();

      if (response == null) return null;
      return StoreModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get store: $e');
    }
  }

  Future<List<StoreModel>> searchStores(String query) async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search stores: $e');
    }
  }

  Future<List<StoreModel>> getStoresByCategory(String category) async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load stores by category: $e');
    }
  }

  // -----------------------
  // Admin CRUD operations
  // -----------------------

  Future<StoreModel> createStore(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('stores').insert(data).select().single();
      return StoreModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  Future<StoreModel> updateStore(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('stores')
          .update(data)
          .eq('id', storeId)
          .select()
          .single();

      return StoreModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  Future<void> deleteStore(String storeId) async {
    try {
      await _client.from('stores').delete().eq('id', storeId);
    } catch (e) {
      throw Exception('Failed to delete store: $e');
    }
  }
}
