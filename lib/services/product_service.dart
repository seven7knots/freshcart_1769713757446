import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  // -----------------------
  // Customer / Public reads
  // -----------------------

  Future<List<ProductModel>> getProductsByStore(
    String storeId, {
    String? category,
    bool? isFeatured,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('products')
          .select()
          .eq('store_id', storeId)
          .eq('is_available', true);

      if (category != null) {
        query = query.eq('category', category);
      }
      if (isFeatured != null) {
        query = query.eq('is_featured', isFeatured);
      }

      final response = await query.order('name', ascending: true).limit(limit);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;
      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<List<ProductModel>> searchProducts(
    String query, {
    String? storeId,
    String? category,
  }) async {
    try {
      var queryBuilder = _client
          .from('products')
          .select()
          .eq('is_available', true)
          .or('name.ilike.%$query%,description.ilike.%$query%');

      if (storeId != null) {
        queryBuilder = queryBuilder.eq('store_id', storeId);
      }
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      final response =
          await queryBuilder.order('name', ascending: true).limit(50);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_available', true)
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load featured products: $e');
    }
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .eq('is_available', true)
          .maybeSingle();

      if (response == null) return null;
      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get product by barcode: $e');
    }
  }

  // -----------------------
  // Admin CRUD operations
  // -----------------------

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('products').insert(data).select().single();
      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<ProductModel> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('products')
          .update(data)
          .eq('id', productId)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
