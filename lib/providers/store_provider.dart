import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_model.dart';
import '../services/store_service.dart';

final storeServiceProvider = Provider((ref) => StoreService());

final allStoresProvider = FutureProvider<List<Store>>((ref) async {
  return await StoreService.getAllStores();
});

final featuredStoresProvider = FutureProvider<List<Store>>((ref) async {
  return await StoreService.getAllStores();
});

final storeByIdProvider =
    FutureProvider.family<Store?, String>((ref, storeId) async {
  return await StoreService.getStoreById(storeId);
});

final storesByCategoryProvider =
    FutureProvider.family<List<Store>, String>((ref, category) async {
  return await StoreService.getStoresByCategory(category);
});