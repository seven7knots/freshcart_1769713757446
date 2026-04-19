import 'package:flutter/material.dart';

import '../../../services/category_service.dart';
import '../../../models/category_model.dart';
import './category_edit_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';

class AdminSubcategoriesScreen extends StatefulWidget {
  final String parentCategoryId;
  final String parentCategoryName;
  final String parentCategoryType;

  const AdminSubcategoriesScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
    required this.parentCategoryType,
  });

  @override
  State<AdminSubcategoriesScreen> createState() =>
      _AdminSubcategoriesScreenState();
}

class _AdminSubcategoriesScreenState extends State<AdminSubcategoriesScreen> {
  bool _includeInactive = true;
  bool _loading = false;
  List<Map<String, dynamic>> _items = const [];

  static const String _fallbackType = 'product';

  String get _safeParentType {
    final t = widget.parentCategoryType.trim();
    return t.isNotEmpty ? t : _fallbackType;
  }

  Category get _parentCategory => Category(
        id: widget.parentCategoryId,
        name: widget.parentCategoryName,
        type: _safeParentType,
        parentId: null,
        sortOrder: 0,
        isActive: true,
      );

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _setLoading(bool v) {
    setState(() => _loading = v);
  }

  Future<void> _refresh() async {
    _setLoading(true);
    try {
      final rows = await CategoryService.getSubcategories(
        widget.parentCategoryId,
        activeOnly: !_includeInactive,
        excludeDemo: false,
      );

      final list = rows.map((c) => c.toMap()).toList();
      setState(() => _items = list);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToLoadSubcategories, e);
    } finally {
      _setLoading(false);
    }
  }

  void _showError(String title, Object e) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(e.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok2, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> c, bool v) async {
    final idx = _items.indexWhere((x) => x['id'] == c['id']);
    if (idx >= 0) {
      setState(() {
        final copy = List<Map<String, dynamic>>.of(_items);
        copy[idx] = {...copy[idx], 'is_active': v};
        _items = copy;
      });
    }

    try {
      await CategoryService.toggleCategoryStatus(c['id'] as String, v);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToUpdateActiveState, e);
      await _refresh();
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    _setLoading(true);
    try {
      final hasChildren = await CategoryService.getSubcategories(
        c['id'] as String,
        activeOnly: false,
        excludeDemo: false,
      );
      if (hasChildren.isNotEmpty) {
        _setLoading(false);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.cannotDelete, maxLines: 1, overflow: TextOverflow.ellipsis),
            content: Text(
              AppLocalizations.of(context)!.thisSubcategoryHasNestedChildrenDelete, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.ok2, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToValidateDelete, e);
      _setLoading(false);
      return;
    }

    _setLoading(false);

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSubcategory, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text('Delete "${c['name']}"? This cannot be undone.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _setLoading(true);
    try {
      await CategoryService.deleteCategory(c['id'] as String);
      await _refresh();
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToDeleteSubcategory, e);
      _setLoading(false);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final updated = List<Map<String, dynamic>>.of(_items);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    setState(() => _items = updated);

    try {
      for (int i = 0; i < updated.length; i++) {
        await CategoryService.updateSortOrder(updated[i]['id'] as String, i);
      }
      await _refresh();
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToReorderSubcategories, e);
      await _refresh();
    }
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => CategoryEditDialog(
        existingCategory: null,
        parentCategory: _parentCategory,
        onSaved: _refresh,
      ),
    );
  }

  void _openEditDialog(Map<String, dynamic> c) {
    showDialog<void>(
      context: context,
      builder: (_) => CategoryEditDialog(
        existingCategory: Category.fromMap(c),
        parentCategory: _parentCategory,
        onSaved: _refresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subcategories • ${widget.parentCategoryName}', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Row(
            children: [
              Flexible(child: Text(AppLocalizations.of(context)!.showInactive, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        label: Text(AppLocalizations.of(context)!.addSubcategory, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text(AppLocalizations.of(context)!.noSubcategoriesYet, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _items.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final c = _items[index];
                      final isActive = (c['is_active'] as bool?) ?? true;

                      return ListTile(
                        key: ValueKey(c['id']),
                        title: Text((c['name'] as String?) ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('sort_order: ${c['sort_order']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        leading: IconButton(
                          tooltip: isActive ? AppLocalizations.of(context)!.active2 : AppLocalizations.of(context)!.inactive2,
                          icon: Icon(
                            isActive ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: _loading
                              ? null
                              : () => _toggleActive(c, !isActive),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _openEditDialog(c);
                            if (v == 'delete') _delete(c);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.delete, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
