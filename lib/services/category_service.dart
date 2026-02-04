import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class CategoryService {
  final SupabaseClient _client = SupabaseService.client;

  static const String _defaultType = 'product';

  String _normalizeType(String? t) {
    final v = (t ?? '').trim();
    return v.isEmpty ? _defaultType : v;
  }

  // -----------------------
  // Customer / Public reads
  // -----------------------

  /// Get all categories (optionally filtered). Defaults to ACTIVE only.
  Future<List<Map<String, dynamic>>> getAllCategories({
    String? type,
    String? parentId,
    bool activeOnly = true,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('categories').select();

      if (activeOnly) query = query.eq('is_active', true);
      if (type != null && type.trim().isNotEmpty) query = query.eq('type', type.trim());
      if (parentId != null && parentId.trim().isNotEmpty) query = query.eq('parent_id', parentId.trim());

      final data = await query
          .order('sort_order', ascending: true)
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get a single category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final data = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .maybeSingle();

      return data == null ? null : Map<String, dynamic>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get category: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  /// Get root categories (no parent_id)
  Future<List<Map<String, dynamic>>> getRootCategories({
    String? type,
    bool activeOnly = true,
  }) async {
    try {
      var query = _client
          .from('categories')
          .select()
          .isFilter('parent_id', null);

      if (activeOnly) query = query.eq('is_active', true);
      if (type != null && type.trim().isNotEmpty) query = query.eq('type', type.trim());

      final data = await query
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load root categories: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load root categories: $e');
    }
  }

  /// Get subcategories for a parent category
  Future<List<Map<String, dynamic>>> getSubcategories(
    String parentId, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _client
          .from('categories')
          .select()
          .eq('parent_id', parentId);

      if (activeOnly) query = query.eq('is_active', true);

      final data = await query
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load subcategories: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load subcategories: $e');
    }
  }

  // -----------------------
  // Admin CRUD operations
  // -----------------------

  /// Create a category (Admin)
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String type,
    String? description,
    String? nameAr,
    String? descriptionAr,
    String? icon,
    String? imageUrl,
    String? parentId,
    int sortOrder = 0,
    bool isActive = true,
    bool isMarketplace = false,
  }) async {
    try {
      final safeName = name.trim();
      final safeType = _normalizeType(type);

      if (safeName.isEmpty) throw Exception('Category name is required');

      final insertData = <String, dynamic>{
        'name': safeName,
        'type': safeType,
        'description': description,
        'name_ar': nameAr,
        'description_ar': descriptionAr,
        'icon': icon,
        'image_url': imageUrl,
        'parent_id': (parentId != null && parentId.trim().isNotEmpty) ? parentId.trim() : null,
        'sort_order': sortOrder,
        'is_active': isActive,
        'is_marketplace': isMarketplace,
      };

      insertData.removeWhere((k, v) => v == null);

      final data = await _client
          .from('categories')
          .insert(insertData)
          .select()
          .single();

      return Map<String, dynamic>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create category: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update a category (Admin)
  Future<Map<String, dynamic>> updateCategory(
    dynamic categoryId, {
    String? name,
    String? type,
    String? description,
    String? nameAr,
    String? descriptionAr,
    String? icon,
    String? imageUrl,
    String? parentId,
    int? sortOrder,
    bool? isActive,
    bool? isMarketplace,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) {
        final n = name.trim();
        if (n.isEmpty) throw Exception('Category name cannot be empty');
        updates['name'] = n;
      }

      if (type != null) updates['type'] = _normalizeType(type);
      if (description != null) updates['description'] = description;
      if (nameAr != null) updates['name_ar'] = nameAr;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (icon != null) updates['icon'] = icon;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (parentId != null) updates['parent_id'] = parentId.trim().isEmpty ? null : parentId.trim();
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (isActive != null) updates['is_active'] = isActive;
      if (isMarketplace != null) updates['is_marketplace'] = isMarketplace;

      if (updates.isEmpty) throw Exception('No fields to update');

      final data = await _client
          .from('categories')
          .update(updates)
          .eq('id', categoryId)
          .select()
          .single();

      return Map<String, dynamic>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update category: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category (Admin) - hard delete
  Future<void> deleteCategory(dynamic categoryId) async {
    try {
      await _client.from('categories').delete().eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete category: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Activate/Deactivate (Admin)
  Future<Map<String, dynamic>> setCategoryActive(
    dynamic categoryId,
    bool isActive,
  ) async {
    try {
      final data = await _client
          .from('categories')
          .update({'is_active': isActive})
          .eq('id', categoryId)
          .select()
          .single();

      return Map<String, dynamic>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update category status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update category status: $e');
    }
  }

  /// Reorder categories by list of ids (Admin).
  Future<void> reorderCategories(List<dynamic> orderedIds) async {
    try {
      for (int i = 0; i < orderedIds.length; i++) {
        await _client
            .from('categories')
            .update({'sort_order': i})
            .eq('id', orderedIds[i]);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to reorder categories: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reorder categories: $e');
    }
  }
}