import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import './supabase_service.dart';

class CategoryService {
  static SupabaseClient get _client => SupabaseService.client;

  static const String _defaultType = 'product';

  static String _normalizeType(String? type) {
    final t = (type ?? '').trim();
    return t.isNotEmpty ? t : _defaultType;
  }

  // ============================================================
  // SESSION 24 FIX: In-memory cache with TTL
  // SESSION 26 FIX (Bug #2): Added Completer-based in-flight dedup.
  //
  // SESSION 24 PROBLEM: getTopLevelCategories() was called 3× within
  // 1.5s. Each call fired an independent Supabase query.
  //
  // SESSION 24 FIX: Static cache with 2-minute TTL. But this only
  // helps when the first call has ALREADY RETURNED. If two calls
  // fire 73ms apart, the first one hasn't returned yet, so the
  // cache is empty for both → both hit Supabase.
  //
  // SESSION 26 FIX: Added Completer. If a fetch is already in-flight,
  // subsequent callers await the SAME future instead of firing a new
  // query. This mirrors the auth_provider dedup pattern.
  //
  // Flow:
  //   Call 1 → cache miss → creates Completer → fires Supabase query
  //   Call 2 (73ms later) → cache miss → sees Completer → awaits it
  //   Query returns → Completer completes → both calls get same result
  //   Call 3 (2 min later) → cache hit → returns instantly
  // ============================================================

  static List<Category>? _topLevelCache;
  static DateTime? _topLevelCacheTime;
  static List<Category>? _allCategoriesCache;
  static DateTime? _allCategoriesCacheTime;
  static const _cacheTTL = Duration(minutes: 2);

  // SESSION 26 FIX (Bug #2): In-flight dedup Completers
  static Completer<List<Category>>? _topLevelFetchCompleter;
  static Completer<List<Category>>? _allCategoriesFetchCompleter;

  static bool _isCacheValid(DateTime? cacheTime) {
    return cacheTime != null &&
        DateTime.now().difference(cacheTime) < _cacheTTL;
  }

  /// Clear all caches. Call on pull-to-refresh or after admin edits.
  static void clearCache() {
    _topLevelCache = null;
    _topLevelCacheTime = null;
    _allCategoriesCache = null;
    _allCategoriesCacheTime = null;
    // NOTE: Do NOT null out the Completers here. If a fetch is in-flight
    // when the user pulls to refresh, let it finish. The next call after
    // it completes will see the cleared cache and fetch fresh data.
    debugPrint('[CATEGORY] Cache cleared');
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  static Future<List<Category>> getTopLevelCategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    // SESSION 24: Return cached data if valid
    if (_isCacheValid(_topLevelCacheTime) && _topLevelCache != null) {
      debugPrint('[CATEGORY] Returning ${_topLevelCache!.length} top-level categories from cache');
      return _topLevelCache!;
    }

    // SESSION 26 FIX (Bug #2): If a fetch is already in-flight, await it
    // instead of firing a duplicate Supabase query.
    if (_topLevelFetchCompleter != null && !_topLevelFetchCompleter!.isCompleted) {
      debugPrint('[CATEGORY] getTopLevelCategories DEDUPED (awaiting in-flight fetch)');
      return _topLevelFetchCompleter!.future;
    }

    // No cache, no in-flight fetch → start a new one
    _topLevelFetchCompleter = Completer<List<Category>>();

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

      query = query.isFilter('store_id', null);

      final response = await query.order('sort_order', ascending: true);

      final categories = (response as List)
          .map((c) => Category.fromMap(c as Map<String, dynamic>))
          .toList();

      // SESSION 24: Update cache
      _topLevelCache = categories;
      _topLevelCacheTime = DateTime.now();

      debugPrint('[CATEGORY] Loaded ${categories.length} top-level categories');

      // SESSION 26: Complete the Completer so deduped callers get the result
      _topLevelFetchCompleter!.complete(categories);
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching top-level categories: $e');
      _topLevelFetchCompleter!.completeError(e);
      rethrow;
    }
  }

  static Future<List<Category>> getAllCategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    // SESSION 24: Return cached data if valid
    if (_isCacheValid(_allCategoriesCacheTime) && _allCategoriesCache != null) {
      debugPrint('[CATEGORY] Returning ${_allCategoriesCache!.length} categories from cache');
      return _allCategoriesCache!;
    }

    // SESSION 26 FIX (Bug #2): In-flight dedup
    if (_allCategoriesFetchCompleter != null && !_allCategoriesFetchCompleter!.isCompleted) {
      debugPrint('[CATEGORY] getAllCategories DEDUPED (awaiting in-flight fetch)');
      return _allCategoriesFetchCompleter!.future;
    }

    _allCategoriesFetchCompleter = Completer<List<Category>>();

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

      // SESSION 24: Update cache
      _allCategoriesCache = categories;
      _allCategoriesCacheTime = DateTime.now();

      debugPrint('[CATEGORY] Loaded ${categories.length} total categories');

      // SESSION 26: Complete the Completer
      _allCategoriesFetchCompleter!.complete(categories);
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching all categories: $e');
      _allCategoriesFetchCompleter!.completeError(e);
      rethrow;
    }
  }

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

  static Future<List<Category>> getCategoriesWithSubcategories({
    bool activeOnly = true,
    bool excludeDemo = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching categories with subcategories...');

      final allCategories = await getAllCategories(
        activeOnly: activeOnly,
        excludeDemo: excludeDemo,
      );

      final topLevel = allCategories.where((c) => c.isTopLevel).toList();
      final subs = allCategories.where((c) => c.isSubcategory).toList();

      final result = topLevel.map((parent) {
        final children = subs.where((s) => s.parentId == parent.id).toList();
        return parent.copyWith(subcategories: children);
      }).toList();

      debugPrint('[CATEGORY] Loaded ${result.length} categories with subcategories');
      return result;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching categories with subcategories: $e');
      rethrow;
    }
  }

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

      debugPrint('[CATEGORY] Loaded ${categories.length} categories of type $type');
      return categories;
    } catch (e) {
      debugPrint('[CATEGORY] Error fetching categories by type: $e');
      rethrow;
    }
  }

  static Future<List<Category>> getStoreCategories(
    String storeId, {
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Fetching categories for store: $storeId');

      var query = _client.from('categories').select().eq('store_id', storeId);

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

      if (e.toString().contains('column') &&
          e.toString().contains('store_id')) {
        debugPrint('[CATEGORY] ⚠️ store_id column not found. Run migration first.');
        return [];
      }

      rethrow;
    }
  }

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

  static Future<Category> createCategory({
    required String name,
    String? nameAr,
    String? type,
    String? icon,
    String? imageUrl,
    String? description,
    String? descriptionAr,
    String? parentId,
    String? storeId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    try {
      debugPrint('[CATEGORY] Creating category: $name');

      final normalizedType = _normalizeType(type);

      final data = <String, dynamic>{
        'name': name,
        'name_ar': nameAr,
        'type': normalizedType,
        'icon': icon,
        'image_url': imageUrl,
        'description': description,
        'description_ar': descriptionAr,
        'parent_id': parentId,
        'sort_order': sortOrder,
        'is_active': isActive,
        'is_demo': false,
      };

      if (storeId != null && storeId.isNotEmpty) {
        data['store_id'] = storeId;
      }

      final response =
          await _client.from('categories').insert(data).select().single();

      final category = Category.fromMap(response);

      // SESSION 24: Invalidate cache after create
      clearCache();

      debugPrint('[CATEGORY] Category created: ${category.id}');
      return category;
    } catch (e) {
      debugPrint('[CATEGORY] Error creating category: $e');
      rethrow;
    }
  }

  static Future<Category> createSubcategory({
    required String parentId,
    required String name,
    String? nameAr,
    String? type,
    String? icon,
    String? imageUrl,
    String? description,
    String? descriptionAr,
    String? storeId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    return createCategory(
      name: name,
      nameAr: nameAr,
      type: type,
      icon: icon,
      imageUrl: imageUrl,
      description: description,
      descriptionAr: descriptionAr,
      parentId: parentId,
      storeId: storeId,
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  // ============================================================
  // UPDATE OPERATIONS
  // ============================================================

  static Future<Category> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('[CATEGORY] Updating category: $id');

      if (updates.containsKey('type')) {
        updates['type'] = _normalizeType(updates['type'] as String?);
      }

      updates.remove('is_marketplace');
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final category = Category.fromMap(response);

      // SESSION 24: Invalidate cache after update
      clearCache();

      debugPrint('[CATEGORY] Category updated: ${category.id}');
      return category;
    } catch (e) {
      debugPrint('[CATEGORY] Error updating category: $e');
      rethrow;
    }
  }

  static Future<void> toggleCategoryStatus(String id, bool isActive) async {
    await updateCategory(id, {'is_active': isActive});
  }

  static Future<void> updateSortOrder(String id, int sortOrder) async {
    await updateCategory(id, {'sort_order': sortOrder});
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  static Future<void> deleteCategory(String id) async {
    try {
      debugPrint('[CATEGORY] Deleting category: $id');

      await _client.from('categories').delete().eq('parent_id', id);
      await _client.from('categories').delete().eq('id', id);

      // SESSION 24: Invalidate cache after delete
      clearCache();

      debugPrint('[CATEGORY] Category deleted: $id');
    } catch (e) {
      debugPrint('[CATEGORY] Error deleting category: $e');
      rethrow;
    }
  }

  static Future<void> softDeleteCategory(String id) async {
    await toggleCategoryStatus(id, false);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

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

  // ============================================================
  // REORDER OPERATIONS
  // ============================================================

  /// Batch-update sort_order for a list of categories.
  /// [updates] is a list of maps with 'id' and 'sort_order' keys.
  static Future<void> reorderCategoriesStatic(
    List<Map<String, dynamic>> updates,
  ) async {
    try {
      debugPrint('[CATEGORY] Reordering ${updates.length} categories...');

      for (final entry in updates) {
        await _client
            .from('categories')
            .update({'sort_order': entry['sort_order']})
            .eq('id', entry['id'] as String);
      }

      clearCache();
      debugPrint('[CATEGORY] Reorder complete');
    } catch (e) {
      debugPrint('[CATEGORY] Error reordering categories: $e');
      rethrow;
    }
  }

  /// Instance-method forwarder so callers using `CategoryService().reorderCategories()`
  /// work without changing call-sites.
  Future<void> reorderCategories(List<Map<String, dynamic>> updates) {
    return reorderCategoriesStatic(updates);
  }
}