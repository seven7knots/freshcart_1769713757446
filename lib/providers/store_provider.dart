import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';

final storeServiceProvider = Provider((ref) => StoreService());

final allStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final storeService = ref.watch(storeServiceProvider);
  return await storeService.getAllStores();
});

final featuredStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final storeService = ref.watch(storeServiceProvider);
  return await storeService.getAllStores(isFeatured: true, limit: 10);
});

final storeByIdProvider =
    FutureProvider.family<StoreModel?, String>((ref, storeId) async {
  final storeService = ref.watch(storeServiceProvider);
  return await storeService.getStoreById(storeId);
});

final storesByCategoryProvider =
    FutureProvider.family<List<StoreModel>, String>((ref, category) async {
  final storeService = ref.watch(storeServiceProvider);
  return await storeService.getStoresByCategory(category);
});
