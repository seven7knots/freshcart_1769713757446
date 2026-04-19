// ============================================================
// FILE: lib/providers/cart_provider.dart
// ============================================================
// SESSION 27 FIXES:
// - cartItemCountProvider now DERIVES from cartNotifierProvider
//   so badge and cart screen always stay in sync (single source of truth)
// - Removed dead CartProvider ChangeNotifier class (was an in-memory
//   ghost that never synced to Supabase — caused badge/cart mismatch)
// - cartItemsProvider kept for backwards compat but also derives
//   from cartNotifierProvider
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';

final cartServiceProvider = Provider((ref) => DatabaseService.instance);

// SESSION 27 FIX: Derives from cartNotifierProvider instead of
// making a separate Supabase call. Single source of truth.
final cartItemsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(cartNotifierProvider);
});

// SESSION 27 FIX: Derives count from cartNotifierProvider state.
// Previously this was a separate FutureProvider calling getCartItemCount()
// which ran independently and got out of sync with the cart screen.
final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartNotifierProvider);
  return cartState.when(
    data: (items) =>
        items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 1)),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// State notifier for cart operations — SINGLE SOURCE OF TRUTH
class CartNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final DatabaseService _databaseService;

  CartNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    debugPrint('[CART] loadCart called, setting loading state...');
    state = const AsyncValue.loading();
    try {
      final items = await _databaseService.getCartItems();
      debugPrint('[CART] ✅ Loaded ${items.length} cart items');
      if (items.isNotEmpty) {
        for (final item in items) {
          final product = item['products'] as Map<String, dynamic>?;
          debugPrint('[CART]   - ${product?['name'] ?? 'unknown'} x${item['quantity']}');
        }
      }
      state = AsyncValue.data(items);
    } catch (e, stack) {
      debugPrint('[CART] ❌ Error loading cart: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
    List<Map<String, dynamic>>? optionsSelected,
    String? specialInstructions,
  }) async {
    try {
      debugPrint('[CART] Adding to cart: product=$productId, qty=$quantity');
      await _databaseService.addToCart(
        productId: productId,
        quantity: quantity,
        optionsSelected: optionsSelected,
        specialInstructions: specialInstructions,
      );
      debugPrint('[CART] ✅ Added to cart, reloading...');
      await loadCart();
    } catch (e) {
      debugPrint('[CART] ❌ Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      debugPrint('[CART] Updating quantity: item=$cartItemId, qty=$quantity');
      await _databaseService.updateCartItemQuantity(cartItemId, quantity);
      await loadCart();
    } catch (e) {
      debugPrint('[CART] ❌ Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> removeItem(String cartItemId) async {
    try {
      debugPrint('[CART] Removing item: $cartItemId');
      await _databaseService.removeCartItem(cartItemId);
      await loadCart();
    } catch (e) {
      debugPrint('[CART] ❌ Error removing item: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      debugPrint('[CART] Clearing cart...');
      await _databaseService.clearCart();
      await loadCart();
    } catch (e) {
      debugPrint('[CART] ❌ Error clearing cart: $e');
      rethrow;
    }
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => CartNotifier(DatabaseService.instance),
);