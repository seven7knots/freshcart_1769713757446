import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/category_service.dart';

class CategoryFormModalWidget extends StatefulWidget {
  final Map<String, dynamic>? existingCategory;
  final VoidCallback onCategoryCreated;

  const CategoryFormModalWidget({
    super.key,
    this.existingCategory,
    required this.onCategoryCreated,
  });

  @override
  State<CategoryFormModalWidget> createState() =>
      _CategoryFormModalWidgetState();
}

class _CategoryFormModalWidgetState extends State<CategoryFormModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  /// category type: product | marketplace | service
  String _type = 'product';

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      final c = widget.existingCategory!;
      _nameController.text = c['name'] ?? '';
      _descriptionController.text = c['description'] ?? '';
      _sortOrderController.text = (c['sort_order'] ?? 0).toString();
      _isActive = c['is_active'] ?? true;
      _type = c['type'] ?? 'product';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sortOrder = int.tryParse(_sortOrderController.text) ?? 0;

      if (widget.existingCategory == null) {
        await _categoryService.createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          sortOrder: sortOrder,
          isActive: _isActive,
          type: _type,
        );
      } else {
        await _categoryService.updateCategory(
          widget.existingCategory!['id'],
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          sortOrder: sortOrder,
          isActive: _isActive,
        );
      }

      widget.onCategoryCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          // Header
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.existingCategory == null
                        ? 'Create Category'
                        : 'Edit Category',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Category Name *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 2.h),

                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration:
                          const InputDecoration(labelText: 'Category Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'product', child: Text('Product')),
                        DropdownMenuItem(
                            value: 'marketplace',
                            child: Text('Marketplace')),
                        DropdownMenuItem(
                            value: 'service', child: Text('Service')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 2.h),

                    TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Sort Order'),
                    ),
                    SizedBox(height: 2.h),

                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 3.h),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(widget.existingCategory == null
                                ? 'Create'
                                : 'Update'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}