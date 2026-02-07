import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store_model.dart';
import './supabase_service.dart';

class StoreService {
  static SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  static Future<List<Store>> getAllStores({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching all stores...');

      var query = _client.from('stores').select();

      if (activeOnly) query = query.eq('is_active', true);
      if (excludeDemo) query = query.eq('is_demo', false);

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching stores: $e');
      rethrow;
    }
  }

  /// Legacy category string filter (kept for backward compatibility)
  static Future<List<Store>> getStoresByCategory(
    String category, {
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching stores for legacy category: $category');

      var query = _client.from('stores').select().eq('category', category);

      if (activeOnly) query = query.eq('is_active', true);
      if (excludeDemo) query = query.eq('is_demo', false);

      final response = await query.order('rating', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching stores by category: $e');
      rethrow;
    }
  }

  /// Preferred: filter by category_id (UUID FK)
  static Future<List<Store>> getStoresByCategoryId(
    String categoryId, {
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching stores for category_id: $categoryId');

      var query = _client.from('stores').select().eq('category_id', categoryId);

      if (activeOnly) query = query.eq('is_active', true);
      if (excludeDemo) query = query.eq('is_demo', false);

      final response = await query.order('rating', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching stores by category_id: $e');
      rethrow;
    }
  }

  static Future<List<Store>> getFeaturedStores({
    int limit = 10,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching featured stores...');

      var query = _client
          .from('stores')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true);

      if (excludeDemo) query = query.eq('is_demo', false);

      final response = await query.order('rating', ascending: false).limit(limit);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching featured stores: $e');
      rethrow;
    }
  }

  static Future<List<Store>> getTopRatedStores({
    int limit = 10,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching top rated stores...');

      var query = _client.from('stores').select().eq('is_active', true);
      if (excludeDemo) query = query.eq('is_demo', false);

      final response = await query.order('rating', ascending: false).limit(limit);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching top rated stores: $e');
      rethrow;
    }
  }

  static Future<Store?> getStoreById(String id) async {
    try {
      debugPrint('[STORE] Fetching store: $id');

      final response =
          await _client.from('stores').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return Store.fromMap(response);
    } catch (e) {
      debugPrint('[STORE] Error fetching store: $e');
      rethrow;
    }
  }

  /// Stores for a merchant row id
  static Future<List<Store>> getStoresByMerchant(String merchantId) async {
    try {
      debugPrint('[STORE] Fetching stores for merchant_id: $merchantId');

      final response = await _client
          .from('stores')
          .select()
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching merchant stores: $e');
      rethrow;
    }
  }

  /// Stores for an owner user id (auth uid)
  static Future<List<Store>> getStoresByOwner(String ownerUserId) async {
    try {
      debugPrint('[STORE] Fetching stores for owner_user_id: $ownerUserId');

      final response = await _client
          .from('stores')
          .select()
          .eq('owner_user_id', ownerUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching owner stores: $e');
      rethrow;
    }
  }

  // ============================================================
  // CREATE OPERATIONS
  // ============================================================

  /// Create a new store
  ///
  /// Ownership rules:
  /// - owner_user_id must be the auth user id (auth.uid()).
  /// - merchant_id is optional but recommended; if omitted, we attempt to resolve it
  ///   from merchants where merchants.user_id == owner_user_id AND status == 'approved'.
  ///
  /// Category rules:
  /// - Prefer categoryId (UUID FK) if your DB has category_id.
  /// - category (string) is legacy and optional.
  static Future<Store> createStore({
    String? merchantId,
    String? ownerUserId,

    required String name,
    String? nameAr,

    String? categoryId, // preferred
    String? category, // legacy

    String? description,
    String? descriptionAr,
    String? imageUrl,
    String? bannerUrl,
    String? address,
    double? locationLat,
    double? locationLng,
    double? minimumOrder,
    int? averagePrepTimeMinutes,
    bool isActive = true,
    bool isFeatured = false,
  }) async {
    try {
      debugPrint('[STORE] Creating store: $name');

      final uid = ownerUserId ?? _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated (owner_user_id missing)');
      }

      // Resolve merchant id if not provided (best-effort)
      String? resolvedMerchantId = merchantId;
      if (resolvedMerchantId == null) {
        try {
          final m = await _client
              .from('merchants')
              .select('id, status')
              .eq('user_id', uid)
              .maybeSingle();

          final status = (m?['status']?.toString() ?? '').trim().toLowerCase();
          if (m != null && status == 'approved') {
            resolvedMerchantId = m['id']?.toString();
            debugPrint('[STORE] Resolved merchant_id=$resolvedMerchantId');
          }
        } catch (e) {
          debugPrint('[STORE] merchant resolve skipped: $e');
        }
      }

      final data = <String, dynamic>{
        // Ownership
        'owner_user_id': uid,
        'merchant_id': resolvedMerchantId,

        // Basic
        'name': name,
        'name_ar': nameAr,

        // Category (support both)
        'category_id': categoryId,
        'category': category,

        'description': description,
        'description_ar': descriptionAr,
        'image_url': imageUrl,
        'banner_url': bannerUrl,
        'address': address,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'minimum_order': minimumOrder,
        'average_prep_time_minutes': averagePrepTimeMinutes,

        // Flags
        'is_active': isActive,
        'is_featured': isFeatured,
        'is_accepting_orders': true,
        'is_demo': false,

        // Defaults
        'rating': 0.0,
        'total_reviews': 0,
      };

      // Remove nulls to avoid overwriting defaults / violating constraints
      data.removeWhere((key, value) => value == null);

      final response = await _client.from('stores').insert(data).select().single();

      final store = Store.fromMap(response);
      debugPrint('[STORE] Store created: ${store.id}');
      return store;
    } catch (e) {
      debugPrint('[STORE] Error creating store: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE OPERATIONS
  // ============================================================

  static Future<Store> updateStore(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('[STORE] Updating store: $id');

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('stores')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final store = Store.fromMap(response);
      debugPrint('[STORE] Store updated: ${store.id}');
      return store;
    } catch (e) {
      debugPrint('[STORE] Error updating store: $e');
      rethrow;
    }
  }

  static Future<void> toggleStoreStatus(String id, bool isActive) async {
    await updateStore(id, {'is_active': isActive});
  }

  static Future<void> toggleAcceptingOrders(String id, bool isAccepting) async {
    await updateStore(id, {'is_accepting_orders': isAccepting});
  }

  static Future<void> toggleFeatured(String id, bool isFeatured) async {
    await updateStore(id, {'is_featured': isFeatured});
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  static Future<void> deleteStore(String id) async {
    try {
      debugPrint('[STORE] Deleting store: $id');
      await _client.from('stores').delete().eq('id', id);
      debugPrint('[STORE] Store deleted: $id');
    } catch (e) {
      debugPrint('[STORE] Error deleting store: $e');
      rethrow;
    }
  }

  static Future<void> softDeleteStore(String id) async {
    await toggleStoreStatus(id, false);
  }

  // ============================================================
  // SEARCH & UTILITY
  // ============================================================

  static Future<List<Store>> searchStores(
    String query, {
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[STORE] Searching stores: $query');

      var dbQuery = _client
          .from('stores')
          .select()
          .or('name.ilike.%$query%,name_ar.ilike.%$query%');

      if (activeOnly) dbQuery = dbQuery.eq('is_active', true);

      final response = await dbQuery.order('rating', ascending: false);

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error searching stores: $e');
      rethrow;
    }
  }

  static Future<List<Store>> getNearbyStores({
    required double lat,
    required double lng,
    double radiusKm = 10,
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[STORE] Fetching nearby stores...');

      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));

      var query = _client
          .from('stores')
          .select()
          .gte('location_lat', lat - latDelta)
          .lte('location_lat', lat + latDelta)
          .gte('location_lng', lng - lngDelta)
          .lte('location_lng', lng + lngDelta);

      if (activeOnly) query = query.eq('is_active', true);

      final response = await query;

      return (response as List)
          .map((s) => Store.fromMap(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[STORE] Error fetching nearby stores: $e');
      rethrow;
    }
  }
}
