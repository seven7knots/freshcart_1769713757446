import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/category_service.dart';
import './category_edit_dialog.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  // ✅ Removed unused: final CategoryService _service = CategoryService();

  bool _includeInactive = true;
  bool _loading = false;
  List<Category> _items = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _loading = v);
  }

  Future<void> _refresh() async {
    _setLoading(true);
    try {
      final rows = await CategoryService.getTopLevelCategories(
        activeOnly: !_includeInactive,
        excludeDemo: false,
      );
      setState(() => _items = rows);
    } catch (e) {
      _showError('Failed to load categories', e);
    } finally {
      _setLoading(false);
    }
  }

  void _showError(String title, Object e) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Category c, bool v) async {
    final idx = _items.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      setState(() {
        final copy = List<Category>.of(_items);
        copy[idx] = copy[idx].copyWith(isActive: v);
        _items = copy;
      });
    }

    try {
      await CategoryService.toggleCategoryStatus(c.id, v);
    } catch (e) {
      _showError('Failed to update active state', e);
      await _refresh();
    }
  }

  Future<void> _delete(Category c) async {
    _setLoading(true);
    try {
      final hasChildren = await CategoryService.getSubcategories(
        c.id,
        activeOnly: false,
        excludeDemo: false,
      );
      if (hasChildren.isNotEmpty) {
        _setLoading(false);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cannot delete'),
            content: const Text(
                'This category has subcategories. Delete subcategories first.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      _showError('Failed to validate delete', e);
      _setLoading(false);
      return;
    }

    _setLoading(false);

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${c.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _setLoading(true);
    try {
      await CategoryService.deleteCategory(c.id);
      await _refresh();
    } catch (e) {
      _showError('Failed to delete category', e);
      _setLoading(false);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final updated = List<Category>.of(_items);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    setState(() => _items = updated);

    try {
      for (int i = 0; i < updated.length; i++) {
        await CategoryService.updateSortOrder(updated[i].id, i);
      }
      await _refresh();
    } catch (e) {
      _showError('Failed to reorder categories', e);
      await _refresh();
    }
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => CategoryEditDialog(
        existingCategory: null,
        parentCategory: null,
        onSaved: _refresh,
      ),
    );
  }

  void _openEditDialog(Category c) {
    showDialog<void>(
      context: context,
      builder: (_) => CategoryEditDialog(
        existingCategory: c,
        parentCategory: null,
        onSaved: _refresh,
      ),
    );
  }

  void _openSubcategories(Category parent) {
    Navigator.pushNamed(
      context,
      AppRoutes.adminSubcategories,
      arguments: {
        'parentCategoryId': parent.id,
        'parentCategoryName': parent.name,
        'parentCategoryType': parent.type,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Categories'),
        actions: [
          Row(
            children: [
              const Text('Show inactive'),
              Switch(
                value: _includeInactive,
                onChanged: (v) {
                  setState(() => _includeInactive = v);
                  _refresh();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No categories yet')),
                    ],
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _items.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final c = _items[index];
                      return ListTile(
                        key: ValueKey(c.id),
                        title: Text(c.name),
                        subtitle: Text(
                            'type: ${c.type} • sort_order: ${c.sortOrder}'),
                        leading: IconButton(
                          tooltip: c.isActive ? 'Active' : 'Inactive',
                          icon: Icon(c.isActive
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: _loading
                              ? null
                              : () => _toggleActive(c, !c.isActive),
                        ),
                        onTap: () => _openSubcategories(c),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'sub') _openSubcategories(c);
                            if (v == 'edit') _openEditDialog(c);
                            if (v == 'delete') _delete(c);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'sub',
                              child: Text('Manage subcategories'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
