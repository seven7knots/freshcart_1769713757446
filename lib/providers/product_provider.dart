import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

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

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return await ProductService.getFeaturedProducts();
});
