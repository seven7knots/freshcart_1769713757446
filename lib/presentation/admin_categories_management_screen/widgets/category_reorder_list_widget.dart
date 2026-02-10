import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/category_service.dart';

class CategoryReorderListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback onReorderComplete;

  const CategoryReorderListWidget({
    super.key,
    required this.categories,
    required this.onReorderComplete,
  });

  @override
  State<CategoryReorderListWidget> createState() =>
      _CategoryReorderListWidgetState();
}

class _CategoryReorderListWidgetState extends State<CategoryReorderListWidget> {
  final CategoryService _categoryService = CategoryService();

  late List<Map<String, dynamic>> _items;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.categories)
      ..sort((a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);

    try {
      final updates = <Map<String, dynamic>>[];

      for (int i = 0; i < _items.length; i++) {
        updates.add({
          'id': _items[i]['id'],
          'sort_order': i,
        });
      }

      // Changed from updateCategorySortOrders to reorderCategories
      await _categoryService.updateCategorySortOrders(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category order updated')),
        );
        widget.onReorderComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _header(theme),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                  _hasChanges = true;
                });
              },
              itemBuilder: (_, index) {
                final category = _items[index];
                return _row(theme, category, index);
              },
            ),
          ),
          _footer(theme),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Reorder Categories',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Drag and drop to change order',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (!_hasChanges || _isSaving) ? null : _saveOrder,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Order'),
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    Map<String, dynamic> category,
    int index,
  ) {
    final String name = category['name'] ?? 'Unnamed';
    final bool isActive = category['is_active'] == true;

    return Container(
      key: ValueKey(category['id']),
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          name,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Position ${index + 1}'),
        trailing: Text(
          isActive ? 'ACTIVE' : 'INACTIVE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}