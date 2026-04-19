#!/usr/bin/env python3
"""Fix the 4 pre-existing build errors."""

import os

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Fix 1: saved_addresses_sheet.dart wrong import path ──
path1 = os.path.join(PROJECT, 'lib', 'widgets', 'saved_addresses_sheet.dart')
with open(path1, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "import '../map_location_picker/map_location_picker_screen.dart';",
    "import '../presentation/map_location_picker/map_location_picker_screen.dart';",
)

with open(path1, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed: saved_addresses_sheet.dart import path')

# ── Fix 2: Add reorderCategories to CategoryService ──
path2 = os.path.join(PROJECT, 'lib', 'services', 'category_service.dart')
with open(path2, 'r', encoding='utf-8') as f:
    content = f.read()

# The widget calls it as an instance method on a CategoryService() instance,
# but CategoryService uses static methods everywhere. We add the method as
# a static method with an instance-method forwarder so both patterns work.
#
# The caller passes List<Map<String, dynamic>> where each map has 'id' and
# 'sort_order'. We batch-update each row.

stub = '''
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
'''

# Insert before the closing brace of the class
# Find the last '}' which closes the class
last_brace = content.rfind('}')
content = content[:last_brace] + stub + content[last_brace:]

with open(path2, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed: category_service.dart — added reorderCategories method')
