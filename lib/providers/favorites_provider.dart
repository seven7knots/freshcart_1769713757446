// ============================================================
// FILE: lib/providers/favorites_provider.dart
// ============================================================
// Provider (ChangeNotifier) for managing user favorites state.
// Holds in-memory Sets of favorited product/listing IDs.
// Syncs with Supabase via FavoritesService.
// ============================================================

import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  /// Set of delivery product IDs the user has favorited
  Set<String> _deliveryFavoriteIds = {};

  /// Set of marketplace listing IDs the user has favorited
  Set<String> _marketplaceFavoriteIds = {};

  bool _isLoaded = false;
  bool _isLoading = false;

  // ============================================================
  // GETTERS
  // ============================================================

  Set<String> get deliveryFavoriteIds => _deliveryFavoriteIds;
  Set<String> get marketplaceFavoriteIds => _marketplaceFavoriteIds;
  int get deliveryCount => _deliveryFavoriteIds.length;
  int get marketplaceCount => _marketplaceFavoriteIds.length;
  int get totalCount => _deliveryFavoriteIds.length + _marketplaceFavoriteIds.length;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  /// Check if a delivery product is favorited
  bool isDeliveryFavorite(String productId) => _deliveryFavoriteIds.contains(productId);

  /// Check if a marketplace listing is favorited
  bool isMarketplaceFavorite(String listingId) => _marketplaceFavoriteIds.contains(listingId);

  // ============================================================
  // LOAD FROM DB
  // ============================================================

  /// Load all favorite IDs from Supabase (call once on app startup / login)
  Future<void> loadFavorites() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final deliveryIds = await FavoritesService.getDeliveryFavoriteIds();
      final marketplaceIds = await FavoritesService.getMarketplaceFavoriteIds();

      _deliveryFavoriteIds = deliveryIds;
      _marketplaceFavoriteIds = marketplaceIds;
      _isLoaded = true;

      debugPrint('[FAV_PROVIDER] Loaded ${deliveryIds.length} delivery + ${marketplaceIds.length} marketplace favorites');
    } catch (e) {
      debugPrint('[FAV_PROVIDER] Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // TOGGLE DELIVERY FAVORITE
  // ============================================================

  /// Toggle a delivery product favorite. Returns true if now favorited.
  Future<bool> toggleDeliveryFavorite(String productId) async {
    final wasFavorited = _deliveryFavoriteIds.contains(productId);

    // Optimistic update
    if (wasFavorited) {
      _deliveryFavoriteIds.remove(productId);
    } else {
      _deliveryFavoriteIds.add(productId);
    }
    notifyListeners();

    // Sync with DB
    bool success;
    if (wasFavorited) {
      success = await FavoritesService.removeDeliveryFavorite(productId);
    } else {
      success = await FavoritesService.addDeliveryFavorite(productId);
    }

    // Rollback on failure
    if (!success) {
      if (wasFavorited) {
        _deliveryFavoriteIds.add(productId);
      } else {
        _deliveryFavoriteIds.remove(productId);
      }
      notifyListeners();
    }

    return !wasFavorited && success;
  }

  // ============================================================
  // TOGGLE MARKETPLACE FAVORITE
  // ============================================================

  /// Toggle a marketplace listing favorite. Returns true if now favorited.
  Future<bool> toggleMarketplaceFavorite(String listingId) async {
    final wasFavorited = _marketplaceFavoriteIds.contains(listingId);

    // Optimistic update
    if (wasFavorited) {
      _marketplaceFavoriteIds.remove(listingId);
    } else {
      _marketplaceFavoriteIds.add(listingId);
    }
    notifyListeners();

    // Sync with DB
    bool success;
    if (wasFavorited) {
      success = await FavoritesService.removeMarketplaceFavorite(listingId);
    } else {
      success = await FavoritesService.addMarketplaceFavorite(listingId);
    }

    // Rollback on failure
    if (!success) {
      if (wasFavorited) {
        _marketplaceFavoriteIds.add(listingId);
      } else {
        _marketplaceFavoriteIds.remove(listingId);
      }
      notifyListeners();
    }

    return !wasFavorited && success;
  }

  // ============================================================
  // CLEAR (on sign out)
  // ============================================================

  void clear() {
    _deliveryFavoriteIds = {};
    _marketplaceFavoriteIds = {};
    _isLoaded = false;
    notifyListeners();
  }
}