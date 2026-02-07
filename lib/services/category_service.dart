import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import './supabase_service.dart';

class CategoryService {
  static SupabaseClient get _client => SupabaseService.client;

  // Safety default if callers pass null/empty (prevents DB NOT NULL)
  static const String _defaultType = 'product';

  static String _normalizeType(String? type) {
    final t = (type ?? '').trim();
    return t.isNotEmpty ? t : _defaultType;
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all top-level categories (parent_id is null)
  static Future<List<Category>> getTopLevelCategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching top-level categories...');

      var query =
          _client.from('categories').select().isFilter('parent_id', null);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('sort_order', ascending: true);

      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint('[CATEGORY] Loaded ${categories.length} top-level categories');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching top-level categories: $e');
      rethrow;
    }
  }

  /// Get all categories (both top-level and subcategories)
  static Future<List<Category>> getAllCategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching all categories...');

      var query = _client.from('categories').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('sort_order', ascending: true);

      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint('[CATEGORY] Loaded ${categories.length} total categories');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching all categories: $e');
      rethrow;
    }
  }

  /// Get subcategories for a parent category
  static Future<List<Category>> getSubcategories(
    String parentId, {
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching subcategories for parent: $parentId');

      var query = _client.from('categories').select().eq('parent_id', parentId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('sort_order', ascending: true);

      final subcategories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint('[CATEGORY] Loaded ${subcategories.length} subcategories');
      return subcategories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching subcategories: $e');
      rethrow;
    }
  }

  /// Get a single category by ID
  static Future<Category?> getCategoryById(String id) async {
    try {
      debugPrint('[CATEGORY] Fetching category: $id');

      final response =
          await _client.from('categories').select().eq('id', id).maybeSingle();

      if (response == null) {
        debugPrint('[CATEGORY] Category not found: $id');
        return null;
      }

      return Category.fromMap(response);
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching category: $e');
      rethrow;
    }
  }

  /// Get categories with their subcategories nested
  static Future<List<Category>> getCategoriesWithSubcategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching categories with subcategories...');

      // Get all categories
      final allCategories = await getAllCategories(
        activeOnly: activeOnly,
        excludeDemo: excludeDemo,
      );

      // Separate top-level and subcategories
      final topLevel = allCategories.where((c) => c.isTopLevel).toList();
      final subs = allCategories.where((c) => c.isSubcategory).toList();

      // Nest subcategories under their parents
      final result = topLevel.map((parent) {
        final children = subs.where((s) => s.parentId == parent.id).toList();
        return parent.copyWith(subcategories: children);
      }).toList();

      debugPrint(
          '[CATEGORY] Loaded ${result.length} categories with subcategories');
      return result;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching categories with subcategories: $e');
      rethrow;
    }
  }

  /// Get categories by type
  static Future<List<Category>> getCategoriesByType(
    String type, {
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching categories of type: $type');

      var query = _client.from('categories').select().eq('type', type);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (excludeDemo) {
        query = query.eq('is_demo', false);
      }

      final response = await query.order('sort_order', ascending: true);

      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint(
          '[CATEGORY] Loaded ${categories.length} categories of type $type');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching categories by type: $e');
      rethrow;
    }
  }

  /// Get categories specific to a store (merchant-created categories)
  /// These are categories that merchants create within their own stores
  static Future<List<Category>> getStoreCategories(
    String storeId, {
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching categories for store: $storeId');
      
      // Note: This assumes your categories table has a store_id column
      // If not, you'll need to add it with this SQL:
      // ALTER TABLE categories ADD COLUMN store_id UUID REFERENCES stores(id);
      // CREATE INDEX idx_categories_store_id ON categories(store_id);
      
      var query = _client
          .from('categories')
          .select()
          .eq('store_id', storeId);
      
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      
      final response = await query.order('sort_order', ascending: true);
      
      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();
      
      debugPrint('[CATEGORY] Loaded ${categories.length} store-specific categories');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching store categories: $e');
      
      // If store_id column doesn't exist yet, return empty list instead of crashing
      if (e.toString().contains('column') && e.toString().contains('store_id')) {
        debugPrint('[CATEGORY] ⚠️ store_id column not found in categories table');
        debugPrint('[CATEGORY] Run: ALTER TABLE categories ADD COLUMN store_id UUID REFERENCES stores(id);');
        return [];
      }
      
      rethrow;
    }
  }

  /// Check if a category has subcategories
  static Future<bool> hasSubcategories(String categoryId) async {
    try {
      final response = await _client
          .from('categories')
          .select('id')
          .eq('parent_id', categoryId)
          .eq('is_active', true)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('[CATEGORY] Error checking subcategories: $e');
      return false;
    }
  }

  // ============================================================
  // CREATE OPERATIONS
  // ============================================================

  /// Create a new category
  ///
  /// Fixes:
  /// - Ensures type is never null/empty (DB NOT NULL safe)
  /// - Saves is_marketplace when provided
  static Future<Category> createCategory({
    required String name,
    String? nameAr,
    String? type,
    String? icon,
    String? description,
    String? descriptionAr,
    String? parentId,
    String? storeId,
    int sortOrder = 0,
    bool isActive = true,
    bool isMarketplace = false,
  }) async {
    try {
      debugPrint('[CATEGORY] Creating category: $name');

      final normalizedType = _normalizeType(type);

      final data = {
        'name': name,
        'name_ar': nameAr,
        'type': normalizedType,
        'icon': icon,
        'description': description,
        'description_ar': descriptionAr,
        'parent_id': parentId,
        'store_id': storeId,
        'sort_order': sortOrder,
        'is_active': isActive,
        'is_marketplace': isMarketplace,
        'is_demo': false,
      };

      final response =
          await _client.from('categories').insert(data).select().single();

      final category = Category.fromMap(response);
      debugPrint('[CATEGORY] Category created: ${category.id}');
      return category;
    } catch (e) {
      debugPrint('[CATEGORY] Error creating category: $e');
      rethrow;
    }
  }

  /// Create a subcategory
  static Future<Category> createSubcategory({
    required String parentId,
    required String name,
    String? nameAr,
    String? type,
    String? icon,
    String? description,
    String? descriptionAr,
    String? storeId,
    int sortOrder = 0,
    bool isActive = true,
    bool isMarketplace = false,
  }) async {
    return createCategory(
      name: name,
      nameAr: nameAr,
      type: type,
      icon: icon,
      description: description,
      descriptionAr: descriptionAr,
      parentId: parentId,
      storeId: storeId,
      sortOrder: sortOrder,
      isActive: isActive,
      isMarketplace: isMarketplace,
    );
  }

  // ============================================================
  // UPDATE OPERATIONS
  // ============================================================

  /// Update a category
  ///
  /// Fixes:
  /// - If updates include 'type', normalize it (no empty -> DB safe)
  static Future<Category> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('[CATEGORY] Updating category: $id');

      if (updates.containsKey('type')) {
        updates['type'] = _normalizeType(updates['type'] as String?);
      }

      // Add updated_at timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final category = Category.fromMap(response);
      debugPrint('[CATEGORY] Category updated: ${category.id}');
      return category;
    } catch (e) {
      debugPrint('[CATEGORY] Error updating category: $e');
      rethrow;
    }
  }

  /// Toggle category active status
  static Future<void> toggleCategoryStatus(String id, bool isActive) async {
    await updateCategory(id, {'is_active': isActive});
  }

  /// Update category sort order
  static Future<void> updateSortOrder(String id, int sortOrder) async {
    await updateCategory(id, {'sort_order': sortOrder});
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  /// Delete a category (and its subcategories)
  static Future<void> deleteCategory(String id) async {
    try {
      debugPrint('[CATEGORY] Deleting category: $id');

      // First, delete all subcategories
      await _client.from('categories').delete().eq('parent_id', id);

      // Then delete the category itself
      await _client.from('categories').delete().eq('id', id);

      debugPrint('[CATEGORY] Category deleted: $id');
    } catch (e) {
      debugPrint('[CATEGORY] Error deleting category: $e');
      rethrow;
    }
  }

  /// Soft delete (set is_active to false)
  static Future<void> softDeleteCategory(String id) async {
    await toggleCategoryStatus(id, false);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Search categories by name
  static Future<List<Category>> searchCategories(
    String query, {
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Searching categories: $query');

      var dbQuery = _client
          .from('categories')
          .select()
          .or('name.ilike.%$query%,name_ar.ilike.%$query%');

      if (activeOnly) {
        dbQuery = dbQuery.eq('is_active', true);
      }

      final response = await dbQuery.order('sort_order', ascending: true);

      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      debugPrint('[CATEGORY] Found ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error searching categories: $e');
      rethrow;
    }
  }

  /// Get category path (for breadcrumbs)
  static Future<List<Category>> getCategoryPath(String categoryId) async {
    try {
      final path = <Category>[];
      String? currentId = categoryId;

      while (currentId != null) {
        final category = await getCategoryById(currentId);
        if (category == null) break;

        path.insert(0, category);
        currentId = category.parentId;
      }

      return path;
    } catch (e) {
      debugPrint('[CATEGORY] Error getting category path: $e');
      rethrow;
    }
  }
}