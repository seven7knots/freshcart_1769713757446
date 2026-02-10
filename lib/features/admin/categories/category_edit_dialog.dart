import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/category_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/category_model.dart';

class CategoryEditDialog extends StatefulWidget {
  final Category? existingCategory;
  final Category? parentCategory;
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
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _sortOrderController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  String? _existingImageUrl;

  bool get _isEdit => widget.existingCategory != null;
  bool get _isSubcategory => widget.parentCategory != null;

  static const String _defaultType = 'product';

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final c = widget.existingCategory!;
      _nameController.text = c.name;
      _typeController.text = (c.type ?? _defaultType);
      _sortOrderController.text = c.sortOrder.toString();
      _isActive = c.isActive;
      _existingImageUrl = c.imageUrl;
    } else {
      _nameController.text = '';
      _sortOrderController.text = '0';
      _isActive = true;
      if (_isSubcategory) {
        _typeController.text = (widget.parentCategory?.type ?? _defaultType);
      } else {
        _typeController.text = _defaultType;
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

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _dialogTitle() {
    if (_isEdit) return _isSubcategory ? 'Edit Subcategory' : 'Edit Category';
    return _isSubcategory ? 'Add Subcategory' : 'Add Category';
  }

  String _effectiveType() {
    final raw = _typeController.text.trim();
    if (_isSubcategory) {
      final parentType = widget.parentCategory?.type?.trim() ?? '';
      return parentType.isNotEmpty ? parentType : _defaultType;
    }
    return raw.isNotEmpty ? raw : _defaultType;
  }

  // ============================================================
  // IMAGE PICKER & UPLOAD
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (img != null && mounted) setState(() => _pickedImage = img);
    } catch (e) {
      _snack('Failed to pick image: $e', color: Colors.red);
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return _existingImageUrl;
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) { _snack('You must be logged in', color: Colors.red); return _existingImageUrl; }

      final uid = user.id;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _pickedImage!.path.split('.').last.toLowerCase();
      final bytes = await _pickedImage!.readAsBytes();

      String mimeType;
      switch (ext) {
        case 'jpg': case 'jpeg': mimeType = 'image/jpeg';
        case 'png': mimeType = 'image/png';
        case 'gif': mimeType = 'image/gif';
        case 'webp': mimeType = 'image/webp';
        default: mimeType = 'image/jpeg';
      }

      const bucket = 'uploads';
      final path = 'category/$uid/$ts.$ext';

      await SupabaseService.client.storage.from(bucket).uploadBinary(
        path, bytes, fileOptions: FileOptions(upsert: true, contentType: mimeType),
      );

      return SupabaseService.client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      _snack('Image upload failed: $e', color: Colors.red);
    }
    return _existingImageUrl;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final type = _effectiveType();
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    if (name.isEmpty) { _snack('Name is required'); return; }

    setState(() => _isLoading = true);

    try {
      // Upload image first
      final imageUrl = await _uploadImage();

      if (!_isEdit) {
        await CategoryService.createCategory(
          name: name,
          type: type,
          imageUrl: imageUrl,
          parentId: widget.parentCategory?.id,
          sortOrder: sortOrder,
          isActive: _isActive,
        );
      } else {
        final updates = <String, dynamic>{
          'name': name,
          'type': type,
          'sort_order': sortOrder,
          'is_active': _isActive,
        };
        if (imageUrl != null) updates['image_url'] = imageUrl;

        await CategoryService.updateCategory(widget.existingCategory!.id, updates);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      _snack('Failed to save: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _dialogTitle();

    // Determine what to show in image preview
    final hasPickedImage = _pickedImage != null;
    final hasExistingImage = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: SizedBox(
        width: 90.w,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 85.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  if (_isSubcategory) ...[
                    SizedBox(height: 0.5.h),
                    Text('Parent: ${widget.parentCategory!.name}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ])),
                IconButton(icon: const Icon(Icons.close), onPressed: _isLoading ? null : () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    // IMAGE PICKER — full width, tap to change
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasPickedImage
                            ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : hasExistingImage
                                ? Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                    errorBuilder: (_, __, ___) => _imagePlaceholder(theme))
                                : _imagePlaceholder(theme),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(hasPickedImage ? 'Tap to change photo' : 'Tap to add photo',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                    SizedBox(height: 2.h),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: _isSubcategory ? 'Subcategory Name *' : 'Category Name *'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 2) return 'Must be at least 2 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Type
                    TextFormField(
                      controller: _typeController,
                      enabled: !_isSubcategory,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Type *',
                        helperText: _isSubcategory ? 'Inherited from parent' : 'Default: $_defaultType',
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Sort Order
                    TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _save(),
                      decoration: const InputDecoration(labelText: 'Sort Order', hintText: '0'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null;
                        final n = int.tryParse(s);
                        if (n == null) return 'Must be a number';
                        if (n < 0) return 'Must be 0 or higher';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Active toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: _isLoading ? null : (v) => setState(() => _isActive = v),
                    ),
                  ]),
                ),
              ),
            ),

            const Divider(height: 1),
            // Actions
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
                SizedBox(width: 3.w),
                Expanded(child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                      : Text(_isEdit ? 'Update' : 'Create'),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.add_photo_alternate_outlined, size: 10.w, color: theme.colorScheme.outline),
      SizedBox(height: 1.h),
      Text('Add Photo', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
    ]);
  }
}