import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/marketplace_category_model.dart';
import '../../models/user_address_model.dart';
import '../../services/marketplace_category_service.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';
import '../map_location_picker/map_location_picker_screen.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String _selectedCondition = 'used';
  bool _isNegotiable = true;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  // Location from universal map picker
  UserAddress? _pickedLocation;

  List<MarketplaceCategoryModel> _categories = [];
  final List<XFile> _selectedImages = [];
  final _imagePicker = ImagePicker();
  final _marketplaceService = MarketplaceService();

  static const List<Map<String, String>> _conditions = [
    {'id': 'new', 'name': 'New'},
    {'id': 'like_new', 'name': 'Like New'},
    {'id': 'used', 'name': 'Used'},
    {'id': 'good', 'name': 'Good'},
    {'id': 'fair', 'name': 'Fair'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats =
          await MarketplaceCategoryService().getCategories(activeOnly: true);
      if (mounted) {
        setState(() {
          _categories = cats;
          if (cats.isNotEmpty) _selectedCategory = cats.first.id;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1200, maxHeight: 1200, imageQuality: 80,
      );
      if (picked.isNotEmpty) setState(() => _selectedImages.addAll(picked));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalMapPickerScreen(
          mode: MapPickerMode.marketplace,
          initialLat: _pickedLocation?.lat,
          initialLng: _pickedLocation?.lng,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _pickedLocation = result);
  }

  Future<List<String>> _uploadImages() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final urls = <String>[];
    for (final xFile in _selectedImages) {
      final bytes = await xFile.readAsBytes();
      final ext = xFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';

      await client.storage.from('marketplace-images').uploadBinary(
            fileName, bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
      urls.add(client.storage.from('marketplace-images').getPublicUrl(fileName));
    }
    return urls;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a listing')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imageUrls = await _uploadImages();
      await _marketplaceService.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory!,
        condition: _selectedCondition,
        imageUrls: imageUrls,
        locationText: _pickedLocation?.address,
        locationLat: _pickedLocation?.lat,
        locationLng: _pickedLocation?.lng,
        isNegotiable: _isNegotiable,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to create listing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = AppTheme.kjRed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: theme.iconTheme.color), onPressed: () => Navigator.pop(context)),
        title: Text('Create Listing', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  // Photos
                  _buildLabel('Photos', theme),
                  SizedBox(height: 1.h),
                  SizedBox(
                    height: 25.w,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 25.w, height: 25.w, margin: EdgeInsets.only(right: 2.w),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey[100],
                            borderRadius: BorderRadius.circular(3.w),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo, size: 8.w, color: theme.colorScheme.onSurfaceVariant),
                            SizedBox(height: 0.5.h),
                            Text('Add', style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                      ..._selectedImages.asMap().entries.map((entry) {
                        return FutureBuilder<Uint8List>(
                          future: entry.value.readAsBytes(),
                          builder: (context, snapshot) => Container(
                            width: 25.w, height: 25.w, margin: EdgeInsets.only(right: 2.w),
                            child: Stack(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(3.w),
                                child: snapshot.hasData
                                    ? Image.memory(snapshot.data!, width: 25.w, height: 25.w, fit: BoxFit.cover)
                                    : Container(width: 25.w, height: 25.w, color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
                              Positioned(top: 1.w, right: 1.w, child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(padding: EdgeInsets.all(1.w),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Icon(Icons.close, size: 4.w, color: Colors.white)),
                              )),
                            ]),
                          ),
                        );
                      }),
                    ]),
                  ),
                  SizedBox(height: 1.h),
                  Text('${_selectedImages.length} / 10 photos', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant)),

                  SizedBox(height: 3.h),
                  _buildLabel('Title', theme), SizedBox(height: 0.5.h),
                  TextFormField(controller: _titleController, style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: _inputDeco('What are you selling?', theme, isDark),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null),

                  SizedBox(height: 2.h),
                  _buildLabel('Description', theme), SizedBox(height: 0.5.h),
                  TextFormField(controller: _descriptionController, style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    maxLines: 4, decoration: _inputDeco('Describe your item in detail...', theme, isDark),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null),

                  SizedBox(height: 2.h),
                  _buildLabel('Price (USD)', theme), SizedBox(height: 0.5.h),
                  TextFormField(controller: _priceController, style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDeco('0.00', theme, isDark),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Price is required';
                      final price = double.tryParse(v.trim());
                      if (price == null || price < 0) return 'Enter a valid price';
                      return null;
                    }),

                  SizedBox(height: 2.h),
                  _buildLabel('Category', theme), SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(initialValue: _selectedCategory, dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color), decoration: _inputDeco('', theme, isDark),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); }),

                  SizedBox(height: 2.h),
                  _buildLabel('Condition', theme), SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(initialValue: _selectedCondition, dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color), decoration: _inputDeco('', theme, isDark),
                    items: _conditions.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedCondition = v); }),

                  SizedBox(height: 2.h),
                  // ── Location (Universal Map Picker) ──
                  _buildLabel('Location', theme), SizedBox(height: 0.5.h),
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey[100],
                        borderRadius: BorderRadius.circular(2.w)),
                      child: Row(children: [
                        Icon(_pickedLocation != null ? Icons.location_on : Icons.add_location_alt,
                            color: _pickedLocation != null ? primaryRed : theme.colorScheme.onSurfaceVariant, size: 6.w),
                        SizedBox(width: 3.w),
                        Expanded(child: Text(
                          _pickedLocation?.address ?? 'Tap to pick location on map',
                          style: TextStyle(fontSize: 13.sp,
                              color: _pickedLocation != null ? theme.textTheme.bodyLarge?.color : theme.colorScheme.onSurfaceVariant),
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 6.w),
                      ]),
                    ),
                  ),
                  if (_pickedLocation != null) ...[
                    SizedBox(height: 0.5.h),
                    GestureDetector(
                      onTap: () => setState(() => _pickedLocation = null),
                      child: Text('Clear location', style: TextStyle(fontSize: 11.sp, color: Colors.red)),
                    ),
                  ],

                  SizedBox(height: 2.h),
                  SwitchListTile(title: Text('Price is negotiable', style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color)),
                    value: _isNegotiable, activeThumbColor: primaryRed, onChanged: (v) => setState(() => _isNegotiable = v)),

                  SizedBox(height: 3.h),
                  SizedBox(width: double.infinity, height: 6.h, child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitListing,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w))),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Post Listing', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  )),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) => Text(text,
      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color));

  InputDecoration _inputDeco(String hint, ThemeData theme, bool isDark) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    filled: true, fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(2.w), borderSide: BorderSide.none),
    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h));
}