// ============================================================
// FILE: lib/services/favorites_service.dart
// ============================================================
// Handles all Supabase operations for the user_favorites table.
// Supports both delivery (product) and marketplace (listing) favorites.
// ============================================================

import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class FavoritesService {
  static get _client => SupabaseService.client;

  // ============================================================
  // READ
  // ============================================================

  /// Get all favorite product IDs for the current user (delivery type)
  static Future<Set<String>> getDeliveryFavoriteIds() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final result = await _client
          .from('user_favorites')
          .select('product_id')
          .eq('user_id', userId)
          .eq('favorite_type', 'delivery')
          .not('product_id', 'is', null);

      return (result as List)
          .map((r) => r['product_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error loading delivery favorite IDs: $e');
      return {};
    }
  }

  /// Get all favorite listing IDs for the current user (marketplace type)
  static Future<Set<String>> getMarketplaceFavoriteIds() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final result = await _client
          .from('user_favorites')
          .select('listing_id')
          .eq('user_id', userId)
          .eq('favorite_type', 'marketplace')
          .not('listing_id', 'is', null);

      return (result as List)
          .map((r) => r['listing_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error loading marketplace favorite IDs: $e');
      return {};
    }
  }

  /// Get full delivery favorites with product details
  static Future<List<Map<String, dynamic>>> getDeliveryFavorites() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final result = await _client
          .from('user_favorites')
          .select('id, product_id, created_at, products(id, name, price, sale_price, currency, image_url, store_id, is_available, category, stores(name))')
          .eq('user_id', userId)
          .eq('favorite_type', 'delivery')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error loading delivery favorites: $e');
      return [];
    }
  }

  /// Get full marketplace favorites with listing details
  static Future<List<Map<String, dynamic>>> getMarketplaceFavorites() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final result = await _client
          .from('user_favorites')
          .select('id, listing_id, created_at, marketplace_listings(id, title, price, image_url, seller_name, category, status)')
          .eq('user_id', userId)
          .eq('favorite_type', 'marketplace')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error loading marketplace favorites: $e');
      return [];
    }
  }

  // ============================================================
  // ADD / REMOVE
  // ============================================================

  /// Add a delivery product to favorites
  static Future<bool> addDeliveryFavorite(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('user_favorites').insert({
        'user_id': userId,
        'favorite_type': 'delivery',
        'product_id': productId,
      });

      debugPrint('[FAVORITES_SVC] Added delivery favorite: $productId');
      return true;
    } catch (e) {
      // Unique constraint violation = already favorited, treat as success
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        debugPrint('[FAVORITES_SVC] Already favorited: $productId');
        return true;
      }
      debugPrint('[FAVORITES_SVC] Error adding delivery favorite: $e');
      return false;
    }
  }

  /// Remove a delivery product from favorites
  static Future<bool> removeDeliveryFavorite(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('favorite_type', 'delivery');

      debugPrint('[FAVORITES_SVC] Removed delivery favorite: $productId');
      return true;
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error removing delivery favorite: $e');
      return false;
    }
  }

  /// Add a marketplace listing to favorites
  static Future<bool> addMarketplaceFavorite(String listingId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('user_favorites').insert({
        'user_id': userId,
        'favorite_type': 'marketplace',
        'listing_id': listingId,
      });

      debugPrint('[FAVORITES_SVC] Added marketplace favorite: $listingId');
      return true;
    } catch (e) {
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return true;
      }
      debugPrint('[FAVORITES_SVC] Error adding marketplace favorite: $e');
      return false;
    }
  }

  /// Remove a marketplace listing from favorites
  static Future<bool> removeMarketplaceFavorite(String listingId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .eq('favorite_type', 'marketplace');

      debugPrint('[FAVORITES_SVC] Removed marketplace favorite: $listingId');
      return true;
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error removing marketplace favorite: $e');
      return false;
    }
  }

  /// Remove a favorite by its row ID (used from favorites screen)
  static Future<bool> removeFavoriteById(String favoriteRowId) async {
    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('id', favoriteRowId);

      debugPrint('[FAVORITES_SVC] Removed favorite row: $favoriteRowId');
      return true;
    } catch (e) {
      debugPrint('[FAVORITES_SVC] Error removing favorite by ID: $e');
      return false;
    }
  }

  // ============================================================
  // TOGGLE (convenience)
  // ============================================================

  /// Toggle delivery favorite — returns true if now favorited, false if removed
  static Future<bool> toggleDeliveryFavorite(String productId) async {
    final ids = await getDeliveryFavoriteIds();
    if (ids.contains(productId)) {
      await removeDeliveryFavorite(productId);
      return false;
    } else {
      await addDeliveryFavorite(productId);
      return true;
    }
  }
}