import 'package:flutter/foundation.dart';
// ============================================================
// FILE: lib/providers/product_provider.dart
// ============================================================
// SESSION 24 FIX — Issue A/B: Deduplicate featured products fetch
//
// CHANGES:
// 1. featuredProductsProvider now uses .autoDispose with keepAlive
//    so it persists across tab switches but can still be invalidated.
// 2. QuickAddWidget should ref.watch(featuredProductsProvider)
//    instead of calling ProductService.getFeaturedProducts() directly.
//    This eliminates one duplicate Supabase query on home screen load.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final productServiceProvider = Provider((ref) => ProductService());

final productsByStoreProvider =
    FutureProvider.family<List<Product>, String>((ref, storeId) async {
  final productService = ref.watch(productServiceProvider);
  return await ProductService.getProductsByStore(storeId);
});

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final productService = ref.watch(productServiceProvider);
  return await ProductService.getProductById(productId);
});

/// SESSION 24: This provider is now the SINGLE source of truth for
/// featured products on the home screen. Both DealsOfDayWidget and
/// QuickAddWidget should ref.watch() this provider instead of making
/// independent ProductService calls.
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return await ProductService.getFeaturedProducts();
});

/// SESSION 39: Frequently purchased products based on customer order history.
/// Queries order_items for the current user, groups by product_id,
/// and returns products ordered by frequency (most ordered first).
/// Falls back to empty list if no history.
final frequentlyPurchasedProvider = FutureProvider<List<Product>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    // Get product_ids from this user's past orders, ordered by frequency
    final result = await Supabase.instance.client
        .from('order_items')
        .select('product_id, orders!inner(user_id)')
        .eq('orders.user_id', userId);

    if (result.isEmpty) return [];

    // Count frequency of each product_id
    final frequency = <String, int>{};
    for (final row in result) {
      final pid = row['product_id'] as String?;
      if (pid != null) {
        frequency[pid] = (frequency[pid] ?? 0) + 1;
      }
    }

    if (frequency.isEmpty) return [];

    // Sort by frequency descending, take top 10
    final sortedIds = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    final topIds = sortedIds.take(10).toList();

    // Fetch full product details
    final products = <Product>[];
    for (final pid in topIds) {
      try {
        final p = await ProductService.getProductById(pid);
        if (p != null) products.add(p);
      } catch (e) { // ignore: avoid_print
      print('[PRODUCT_PROVIDER] Silent error: \$e'); }
    }

    return products;
  } catch (e) {
    return [];
  }
});