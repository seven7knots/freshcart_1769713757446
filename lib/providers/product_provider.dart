import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider((ref) => ProductService());

final productsByStoreProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, storeId) async {
  final productService = ref.watch(productServiceProvider);
  return await productService.getProductsByStore(storeId);
});

final productByIdProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) async {
  final productService = ref.watch(productServiceProvider);
  return await productService.getProductById(productId);
});

final featuredProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return await productService.getFeaturedProducts();
});
