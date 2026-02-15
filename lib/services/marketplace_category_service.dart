import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_category_model.dart';

class MarketplaceCategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all active categories ordered by sort_order
  Future<List<MarketplaceCategoryModel>> getCategories({
    bool activeOnly = true,
  }) async {
    try {
      var query = _client.from('marketplace_categories').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('sort_order', ascending: true);

      return (response as List)
          .map((json) => MarketplaceCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load marketplace categories: $e');
    }
  }

  /// Get only primary categories (shown on home screen row)
  Future<List<MarketplaceCategoryModel>> getPrimaryCategories() async {
    try {
      final response = await _client
          .from('marketplace_categories')
          .select()
          .eq('is_active', true)
          .eq('is_primary', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => MarketplaceCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load primary categories: $e');
    }
  }

  /// Add a new category
  Future<MarketplaceCategoryModel> addCategory({
    required String id,
    required String name,
    String? nameAr,
    required String icon,
    required int sortOrder,
    required bool isPrimary,
  }) async {
    try {
      final response = await _client
          .from('marketplace_categories')
          .insert({
            'id': id,
            'name': name,
            'name_ar': nameAr,
            'icon': icon,
            'sort_order': sortOrder,
            'is_primary': isPrimary,
            'is_active': true,
          })
          .select()
          .single();

      return MarketplaceCategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  /// Update a category
  Future<void> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('marketplace_categories').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category (hard delete)
  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('marketplace_categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Toggle active status
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _client.from('marketplace_categories').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle category: $e');
    }
  }

  /// Reorder categories — update sort_order for each
  Future<void> reorderCategories(List<MarketplaceCategoryModel> ordered) async {
    try {
      for (int i = 0; i < ordered.length; i++) {
        await _client.from('marketplace_categories').update({
          'sort_order': i + 1,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', ordered[i].id);
      }
    } catch (e) {
      throw Exception('Failed to reorder categories: $e');
    }
  }
}