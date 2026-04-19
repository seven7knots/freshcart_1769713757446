// ============================================================
// FILE: lib/services/product_service.dart
// ============================================================
// Product service with CRUD operations
// SESSION 27 FIX: Search now includes category field so searching
// "Fruits", "Veggies", "Sandwiches" etc. returns matching products.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  static SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all products
  static Future<List<Product>> getAllProducts({
    bool availableOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[PRODUCT] Fetching all products...');

      var query = _client.from('products').select('*, stores(name)');

      if (availableOnly) {
        query = query.eq('is_available', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('created_at', ascending: false);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();

      debugPrint('[PRODUCT] Loaded ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching products: $e');
      rethrow;
    }
  }

  /// Get products by store
  static Future<List<Product>> getProductsByStore(
    String storeId, {
    bool availableOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[PRODUCT] Fetching products for store: $storeId');

      var query = _client
          .from('products')
          .select('*, stores(name)')
          .eq('store_id', storeId);

      if (availableOnly) {
        query = query.eq('is_available', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('created_at', ascending: false);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();

      debugPrint('[PRODUCT] Loaded ${products.length} products for store');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching store products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  static Future<Product?> getProductById(String id) async {
    try {
      debugPrint('[PRODUCT] Fetching product: $id');

      final response = await _client
          .from('products')
          .select('*, stores(name)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromMap(response);
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching product: $e');
      rethrow;
    }
  }

  /// Get featured products
  static Future<List<Product>> getFeaturedProducts({
    int limit = 20,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[PRODUCT] Fetching featured products...');

      var query = _client
          .from('products')
          .select('*, stores(name)')
          .eq('is_available', true)
          .eq('is_featured', true);

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();

      debugPrint('[PRODUCT] Loaded ${products.length} featured products');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching featured products: $e');
      rethrow;
    }
  }

  /// Get products on sale
  static Future<List<Product>> getProductsOnSale({
    int limit = 20,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[PRODUCT] Fetching products on sale...');

      var query = _client
          .from('products')
          .select('*, stores(name)')
          .eq('is_available', true)
          .not('sale_price', 'is', null);

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();

      debugPrint('[PRODUCT] Loaded ${products.length} sale products');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching sale products: $e');
      rethrow;
    }
  }

  // ============================================================
  // CREATE OPERATIONS
  // ============================================================

  /// Create a new product
  static Future<Product> createProduct({
    required String storeId,
    required String name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    required double price,
    double? salePrice,
    String currency = 'USD',
    String? category,
    String? subcategory,
    String? imageUrl,
    List<String>? images,
    int? stockQuantity,
    int? lowStockThreshold,
    String? sku,
    String? barcode,
    bool isAvailable = true,
    bool isFeatured = false,
  }) async {
    try {
      debugPrint('[PRODUCT] Creating product: $name');

      final data = {
        'store_id': storeId,
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'description_ar': descriptionAr,
        'price': price,
        'sale_price': salePrice,
        'currency': currency,
        'category': category,
        'subcategory': subcategory,
        'image_url': imageUrl,
        'images': images,
        'stock_quantity': stockQuantity,
        'low_stock_threshold': lowStockThreshold,
        'sku': sku,
        'barcode': barcode,
        'is_available': isAvailable,
        'is_featured': isFeatured,
        'is_demo': false,
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      final response = await _client
          .from('products')
          .insert(data)
          .select()
          .single();

      final product = Product.fromMap(response);
      debugPrint('[PRODUCT] Product created: ${product.id}');
      return product;
    } catch (e) {
      debugPrint('[PRODUCT] Error creating product: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE OPERATIONS
  // ============================================================

  /// Update a product
  static Future<Product> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('[PRODUCT] Updating product: $id');

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('products')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final product = Product.fromMap(response);
      debugPrint('[PRODUCT] Product updated: ${product.id}');
      return product;
    } catch (e) {
      debugPrint('[PRODUCT] Error updating product: $e');
      rethrow;
    }
  }

  /// Toggle product availability
  static Future<void> toggleAvailability(String id, bool isAvailable) async {
    await updateProduct(id, {'is_available': isAvailable});
  }

  /// Toggle featured status
  static Future<void> toggleFeatured(String id, bool isFeatured) async {
    await updateProduct(id, {'is_featured': isFeatured});
  }

  /// Update stock quantity
  static Future<void> updateStock(String id, int quantity) async {
    await updateProduct(id, {'stock_quantity': quantity});
  }

  /// Update price
  static Future<void> updatePrice(String id, double price,
      {double? salePrice}) async {
    final updates = <String, dynamic>{'price': price};
    if (salePrice != null) {
      updates['sale_price'] = salePrice;
    }
    await updateProduct(id, updates);
  }

  /// Remove sale price
  static Future<void> removeSalePrice(String id) async {
    await updateProduct(id, {'sale_price': null});
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  /// Delete a product
  static Future<void> deleteProduct(String id) async {
    try {
      debugPrint('[PRODUCT] Deleting product: $id');

      await _client.from('products').delete().eq('id', id);

      debugPrint('[PRODUCT] Product deleted: $id');
    } catch (e) {
      debugPrint('[PRODUCT] Error deleting product: $e');
      rethrow;
    }
  }

  /// Soft delete (set is_available to false)
  static Future<void> softDeleteProduct(String id) async {
    await toggleAvailability(id, false);
  }

  // ============================================================
  // SEARCH & UTILITY
  // ============================================================

  /// Search products by name, description, or category
  /// Note: PostgREST does not support filtering on joined table
  /// columns inside .or() — store name search is done client-side
  /// after fetching results via a separate store lookup if needed.
  static Future<List<Product>> searchProducts(
    String query, {
    String? storeId,
    bool availableOnly = true,
  }) async {
    try {
      debugPrint('[PRODUCT] Searching products: $query');

      // Search by product name, arabic name, description, category
      var dbQuery = _client
          .from('products')
          .select('*, stores(name)')
          .or('name.ilike.%$query%,name_ar.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');

      if (storeId != null) {
        dbQuery = dbQuery.eq('store_id', storeId);
      }

      if (availableOnly) {
        dbQuery = dbQuery.eq('is_available', true);
      }

      final response = await dbQuery.limit(50);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();

      debugPrint('[PRODUCT] Found ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error searching products: $e');
      rethrow;
    }
  }

  /// Get low stock products for a store
  static Future<List<Product>> getLowStockProducts(String storeId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('store_id', storeId)
          .not('stock_quantity', 'is', null)
          .not('low_stock_threshold', 'is', null);

      final products = (response as List)
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .where((p) => p.isLowStock)
          .toList();

      debugPrint('[PRODUCT] Found ${products.length} low stock products');
      return products;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching low stock products: $e');
      rethrow;
    }
  }

  /// Get product categories for a store (distinct values)
  static Future<List<String>> getProductCategories(String storeId) async {
    try {
      final response = await _client
          .from('products')
          .select('category')
          .eq('store_id', storeId)
          .not('category', 'is', null);

      final categories = (response as List)
          .map((p) => p['category'] as String)
          .toSet()
          .toList()
        ..sort();

      return categories;
    } catch (e) {
      debugPrint('[PRODUCT] Error fetching product categories: $e');
      rethrow;
    }
  }
}