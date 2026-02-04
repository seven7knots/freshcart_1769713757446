import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/category_service.dart';
import './admin_category_model.dart';

class CategoryEditDialog extends StatefulWidget {
  final AdminCategoryModel? existingCategory;
  final AdminCategoryModel? parentCategory;
  final VoidCallback onSaved;

  const CategoryEditDialog({
    super.key,
    this.existingCategory,
    this.parentCategory,
    required this.onSaved,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _sortOrderController = TextEditingController();

  bool _isActive = true;
  bool _isMarketplace = false;
  bool _isLoading = false;

  bool get _isEdit => widget.existingCategory != null;
  bool get _isSubcategory => widget.parentCategory != null;

  // Safety default if user leaves type empty (prevents DB NULL)
  static const String _defaultType = 'product';

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final c = widget.existingCategory!;
      _nameController.text = c.name;
      _typeController.text = c.type; // may be '' if legacy row
      _sortOrderController.text = c.sortOrder.toString();
      _isActive = c.isActive;
      _isMarketplace = c.isMarketplace;
    } else {
      _nameController.text = '';
      _sortOrderController.text = '0';
      _isActive = true;
      _isMarketplace = false;

      if (_isSubcategory) {
        // inherit type from parent
        _typeController.text = widget.parentCategory!.type;
      } else {
        _typeController.text = _defaultType; // give a valid default immediately
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _dialogTitle() {
    if (_isEdit) return _isSubcategory ? 'Edit Subcategory' : 'Edit Category';
    return _isSubcategory ? 'Add Subcategory' : 'Add Category';
  }

  String _effectiveType() {
    final raw = _typeController.text.trim();

    // If subcategory, ALWAYS use parent's type (source of truth)
    if (_isSubcategory) {
      final parentType = widget.parentCategory?.type.trim() ?? '';
      if (parentType.isNotEmpty) return parentType;
      // parent type missing (legacy bad data) -> force safe default
      return _defaultType;
    }

    // root category: use entered type, else fallback
    return raw.isNotEmpty ? raw : _defaultType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final type = _effectiveType(); // never empty
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    if (name.isEmpty) {
      _snack('Name is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isEdit) {
        await _categoryService.createCategory(
          name: name,
          type: type,
          parentId: widget.parentCategory?.id,
          sortOrder: sortOrder,
          isActive: _isActive,
          isMarketplace: _isMarketplace,
        );
      } else {
        await _categoryService.updateCategory(
          widget.existingCategory!.id,
          name: name,
          type: type,
          sortOrder: sortOrder,
          isActive: _isActive,
          isMarketplace: _isMarketplace,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _dialogTitle();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: SizedBox(
        width: 90.w,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 78.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isSubcategory) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              'Parent: ${widget.parentCategory!.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _isSubcategory
                                ? 'Subcategory Name *'
                                : 'Category Name *',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            if (v.trim().length < 2) return 'Name must be at least 2 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 2.h),

                        // Type field:
                        // - Root: editable, defaults to 'product'
                        // - Subcategory: locked, inherited from parent (or fallback)
                        TextFormField(
                          controller: _typeController,
                          enabled: !_isSubcategory,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Type *',
                            helperText: _isSubcategory
                                ? 'Inherited from parent category'
                                : 'Required (default: $_defaultType)',
                          ),
                        ),
                        SizedBox(height: 2.h),

                        TextFormField(
                          controller: _sortOrderController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _isLoading ? null : _save(),
                          decoration: const InputDecoration(
                            labelText: 'Sort Order',
                            hintText: '0',
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final n = int.tryParse(s);
                            if (n == null) return 'Must be a valid number';
                            if (n < 0) return 'Must be 0 or higher';
                            return null;
                          },
                        ),
                        SizedBox(height: 2.h),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          value: _isActive,
                          onChanged: _isLoading ? null : (v) => setState(() => _isActive = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Marketplace'),
                          value: _isMarketplace,
                          onChanged: _isLoading ? null : (v) => setState(() => _isMarketplace = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(_isEdit ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
