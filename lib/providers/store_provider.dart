// ============================================================
// FILE: lib/providers/store_provider.dart
// ============================================================
// SESSION 24 FIX — Issue B: Deduplicate store fetches
//
// CHANGES:
// 1. featuredStoresProvider now reads from allStoresProvider
//    instead of making its own independent StoreService.getAllStores()
//    call. This eliminates one duplicate Supabase query.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_model.dart';
import '../services/store_service.dart';

final storeServiceProvider = Provider((ref) => StoreService());

final allStoresProvider = FutureProvider<List<Store>>((ref) async {
  return await StoreService.getAllStores();
});

/// SESSION 24 FIX: Reuse allStoresProvider data instead of calling
/// StoreService.getAllStores() again. Previously both providers made
/// independent identical queries (logcat showed 2× "[STORE] Fetching
/// all stores..." within 1.5s).
final featuredStoresProvider = FutureProvider<List<Store>>((ref) async {
  final allStores = await ref.watch(allStoresProvider.future);
  return allStores;
});

final storeByIdProvider =
    FutureProvider.family<Store?, String>((ref, storeId) async {
  return await StoreService.getStoreById(storeId);
});

final storesByCategoryProvider =
    FutureProvider.family<List<Store>, String>((ref, category) async {
  return await StoreService.getStoresByCategory(category);
});