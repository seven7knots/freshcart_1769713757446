import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';

final cartServiceProvider = Provider((ref) => DatabaseService.instance);

final cartItemsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final cartService = ref.watch(cartServiceProvider);
  return await cartService.getCartItems();
});

final cartItemCountProvider = FutureProvider<int>((ref) async {
  final cartService = ref.watch(cartServiceProvider);
  return await cartService.getCartItemCount();
});

// State notifier for cart operations
class CartNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final DatabaseService _databaseService;

  CartNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await _databaseService.getCartItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
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
      await _databaseService.addToCart(
        productId: productId,
        quantity: quantity,
        optionsSelected: optionsSelected,
        specialInstructions: specialInstructions,
      );
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _databaseService.updateCartItemQuantity(cartItemId, quantity);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String cartItemId) async {
    try {
      await _databaseService.removeCartItem(cartItemId);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _databaseService.clearCart();
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => CartNotifier(DatabaseService.instance),
);

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  void addItem({
    required String productId,
    required String productName,
    required double price,
    required String imageUrl,
    String? storeId,
    String? storeName,
    int quantity = 1,
  }) {
    final existingIndex = _items.indexWhere(
      (item) => item['productId'] == productId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = {
        ..._items[existingIndex],
        'quantity': (_items[existingIndex]['quantity'] as int) + quantity,
      };
    } else {
      _items.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'imageUrl': imageUrl,
        'storeId': storeId,
        'storeName': storeName,
      });
    }

    // Track add to cart
    AnalyticsService.logAddToCart(
      itemId: productId,
      itemName: productName,
      category: storeName ?? 'general',
      price: price,
      quantity: quantity,
    );

    notifyListeners();
  }

  void removeItem(String productId) {
    final itemIndex =
        _items.indexWhere((item) => item['productId'] == productId);

    if (itemIndex >= 0) {
      final item = _items[itemIndex];

      // Track remove from cart
      AnalyticsService.logRemoveFromCart(
        itemId: item['productId'] as String,
        itemName: item['productName'] as String,
        price: item['price'] as double,
      );

      _items.removeAt(itemIndex);
      notifyListeners();
    }
  }
}
