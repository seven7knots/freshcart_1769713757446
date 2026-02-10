import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/category_model.dart';
import '../../../models/store_model.dart';
import '../../../services/ads_service.dart';
import '../../../services/category_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/product_service.dart';
import '../../../services/store_service.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class ContentEditModalWidget extends StatefulWidget {
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback onSaved;

  const ContentEditModalWidget({
    super.key,
    required this.contentType,
    this.contentId,
    this.contentData,
    required this.onSaved,
  });

  @override
  State<ContentEditModalWidget> createState() => _ContentEditModalWidgetState();
}

class _ContentEditModalWidgetState extends State<ContentEditModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _storeSearchCtrl = TextEditingController();
  final _catSearchCtrl = TextEditingController();
  final _subSearchCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  bool get _isCreate => widget.contentId == null;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  String? _existingImageUrl;

  Store? _selectedStore;
  Category? _selectedCategory;
  Category? _selectedSubcategory;
  String _storeCategoryType = 'retail';
  List<Store> _storeResults = [];
  List<Category> _catResults = [];
  List<Category> _subResults = [];
  bool _searchingStores = false;
  bool _searchingCats = false;
  bool _searchingSubs = false;

  // ── Product-in-store: auto-assigned store + store category picker ──
  bool _storePreAssigned = false;
  String? _preAssignedStoreId;
  String? _preAssignedStoreName;
  List<Category> _storeCategoriesForProduct = [];
  bool _loadingStoreCategories = false;
  String? _selectedStoreCategoryId;

  @override
  void initState() {
    super.initState();
    _loadExisting();
    _checkPreAssignedStore();
  }

  void _loadExisting() {
    final d = widget.contentData;
    if (d == null) return;
    _titleCtrl.text = (d['title'] ?? d['name'] ?? '').toString();
    _descCtrl.text = (d['description'] ?? '').toString();
    if (d['price'] != null) _priceCtrl.text = d['price'].toString();

    // FIX: For marketplace listings, extract first image from 'images' jsonb array
    if (widget.contentType == 'marketplace') {
      final images = d['images'];
      if (images is List && images.isNotEmpty) {
        _existingImageUrl = images.first.toString();
      }
    }
    // For all other content types, use the standard image_url field
    _existingImageUrl ??= (d['image_url'] ?? d['imageUrl'] ?? d['cover_image_url'] ?? '').toString();
    if (_existingImageUrl?.isEmpty == true) _existingImageUrl = null;

    _linkCtrl.text = (d['target_route'] ?? d['link_target'] ?? d['deeplink'] ?? '').toString();
    _isActive = _parseActive(widget.contentType, d);

    if (widget.contentType == 'product' && d['category'] != null) {
      _selectedStoreCategoryId = d['category'].toString();
    }
  }

  void _checkPreAssignedStore() {
    if (widget.contentType != 'product') return;
    final storeId = widget.contentData?['store_id']?.toString().trim();
    if (storeId == null || storeId.isEmpty) return;
    _storePreAssigned = true;
    _preAssignedStoreId = storeId;
    _preAssignedStoreName = widget.contentData?['store_name']?.toString();
    if (_preAssignedStoreName == null || _preAssignedStoreName!.isEmpty) {
      _loadStoreName(storeId);
    }
    _loadStoreCategoriesForProduct(storeId);
  }

  Future<void> _loadStoreName(String storeId) async {
    try {
      final store = await StoreService.getStoreById(storeId);
      if (mounted && store != null) {
        setState(() => _preAssignedStoreName = store.name);
      }
    } catch (_) {}
  }

  Future<void> _loadStoreCategoriesForProduct(String storeId) async {
    setState(() => _loadingStoreCategories = true);
    try {
      final cats = await CategoryService.getStoreCategories(storeId, activeOnly: true);
      if (mounted) {
        setState(() {
          _storeCategoriesForProduct = cats;
          _loadingStoreCategories = false;
        });
      }
    } catch (e) {
      debugPrint('[MODAL] Error loading store categories: $e');
      if (mounted) setState(() => _loadingStoreCategories = false);
    }
  }

  bool _parseActive(String t, Map<String, dynamic> d) {
    if (t == 'ad') {
      final s = (d['status'] ?? '').toString().toLowerCase();
      return s.isNotEmpty ? s == 'active' : (d['is_active'] ?? true) == true;
    }
    if (t == 'product') return (d['is_available'] ?? d['is_active'] ?? true) == true;
    return (d['is_active'] ?? true) == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _linkCtrl.dispose();
    _storeSearchCtrl.dispose();
    _catSearchCtrl.dispose();
    _subSearchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE PICK + UPLOAD
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (img != null) setState(() => _pickedImage = img);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pick failed: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return _existingImageUrl;
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You must be logged in to upload images'),
            backgroundColor: Colors.red,
          ));
        }
        return _existingImageUrl;
      }

      final uid = user.id;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _pickedImage!.path.split('.').last.toLowerCase();
      final bytes = await _pickedImage!.readAsBytes();

      String mimeType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
        case 'png':
          mimeType = 'image/png';
        case 'gif':
          mimeType = 'image/gif';
        case 'webp':
          mimeType = 'image/webp';
        default:
          mimeType = 'image/jpeg';
      }

      const bucket = 'uploads';
      final path = '${widget.contentType}/$uid/$ts.$ext';

      debugPrint('[UPLOAD] Bucket: $bucket, Path: $path, Size: ${bytes.length}, MIME: $mimeType');

      await SupabaseService.client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: mimeType),
      );

      final publicUrl = SupabaseService.client.storage.from(bucket).getPublicUrl(path);
      debugPrint('[UPLOAD] ✅ Success: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[UPLOAD] ❌ Failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ));
      }
    }
    return _existingImageUrl;
  }

  // ============================================================
  // SEARCH HELPERS
  // ============================================================

  Future<void> _searchStores(String q) async {
    if (q.trim().length < 2) {
      setState(() => _storeResults = []);
      return;
    }
    setState(() => _searchingStores = true);
    try {
      final r = await StoreService.searchStores(q.trim());
      if (mounted) setState(() { _storeResults = r; _searchingStores = false; });
    } catch (_) {
      if (mounted) setState(() => _searchingStores = false);
    }
  }

  Future<void> _searchCats(String q) async {
    setState(() => _searchingCats = true);
    try {
      final all = q.trim().length < 2
          ? await CategoryService.getTopLevelCategories()
          : (await CategoryService.searchCategories(q.trim()))
              .where((c) => c.isTopLevel)
              .toList();
      if (mounted) setState(() { _catResults = all; _searchingCats = false; });
    } catch (_) {
      if (mounted) setState(() => _searchingCats = false);
    }
  }

  Future<void> _searchSubs(String q) async {
    if (_selectedCategory == null) {
      setState(() => _subResults = []);
      return;
    }
    setState(() => _searchingSubs = true);
    try {
      final subs = await CategoryService.getSubcategories(_selectedCategory!.id);
      final filtered = q.trim().isEmpty
          ? subs
          : subs.where((s) => s.name.toLowerCase().contains(q.trim().toLowerCase())).toList();
      if (mounted) setState(() { _subResults = filtered; _searchingSubs = false; });
    } catch (_) {
      if (mounted) setState(() => _searchingSubs = false);
    }
  }

  // ============================================================
  // SAVE DISPATCHER
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCreate && widget.contentType == 'product' && !_storePreAssigned && _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a store'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imgUrl = await _uploadImage();
      switch (widget.contentType) {
        case 'ad':
          await _saveAd(imgUrl);
        case 'product':
          await _saveProduct(imgUrl);
        case 'store':
          await _saveStore(imgUrl);
        case 'marketplace':
          await _saveMarketplace(imgUrl);
        case 'category':
          await _saveCategory(imgUrl);
        default:
          throw Exception('Unsupported: ${widget.contentType}');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // SAVE: AD
  // ============================================================

  Future<void> _saveAd(String? img) async {
    final svc = AdsService();
    if (_isCreate) {
      await svc.createAd(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        format: 'banner',
        imageUrl: img ?? '',
        linkType: 'external',
        externalUrl: _linkCtrl.text.trim().isNotEmpty ? _linkCtrl.text.trim() : null,
      );
    } else {
      await svc.updateAd(widget.contentId!, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': _isActive ? 'active' : 'paused',
        if (img != null) 'image_url': img,
        if (_linkCtrl.text.trim().isNotEmpty) 'target_route': _linkCtrl.text.trim(),
      });
    }
  }

  // ============================================================
  // SAVE: PRODUCT
  // ============================================================

  Future<void> _saveProduct(String? img) async {
    if (_isCreate) {
      final sid = _storePreAssigned
          ? _preAssignedStoreId!
          : (_selectedStore?.id ?? (widget.contentData?['store_id'] ?? '').toString().trim());
      if (sid.isEmpty) throw Exception('Select a store first');

      String? categoryName;
      if (_selectedStoreCategoryId != null && _selectedStoreCategoryId!.isNotEmpty) {
        final match = _storeCategoriesForProduct
            .where((c) => c.id == _selectedStoreCategoryId)
            .firstOrNull;
        categoryName = match?.name ?? _selectedStoreCategoryId;
      }

      await ProductService.createProduct(
        storeId: sid,
        name: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        isAvailable: _isActive,
        imageUrl: img,
        category: categoryName,
      );
    } else {
      String? categoryName;
      if (_selectedStoreCategoryId != null && _selectedStoreCategoryId!.isNotEmpty) {
        final match = _storeCategoriesForProduct
            .where((c) => c.id == _selectedStoreCategoryId)
            .firstOrNull;
        categoryName = match?.name ?? _selectedStoreCategoryId;
      }

      await ProductService.updateProduct(widget.contentId!, {
        'name': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'is_available': _isActive,
        if (img != null) 'image_url': img,
        if (categoryName != null) 'category': categoryName,
      });
    }
  }

  // ============================================================
  // SAVE: STORE
  // ============================================================

  Future<void> _saveStore(String? img) async {
    if (_isCreate) {
      await StoreService.createStore(
        name: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        isActive: _isActive,
        imageUrl: img,
        categoryId: _selectedSubcategory?.id ?? _selectedCategory?.id,
        subcategoryId: _selectedSubcategory?.id,
        category: _storeCategoryType,
      );
    } else {
      await StoreService.updateStore(widget.contentId!, {
        'name': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'is_active': _isActive,
        if (img != null) 'image_url': img,
        if (_selectedCategory != null)
          'category_id': _selectedSubcategory?.id ?? _selectedCategory!.id,
        if (_selectedSubcategory != null) 'subcategory_id': _selectedSubcategory!.id,
        'category': _storeCategoryType,
      });
    }
  }

  // ============================================================
  // SAVE: MARKETPLACE — FIX: uses 'images' jsonb array, NOT 'image_url'
  // ============================================================

  Future<void> _saveMarketplace(String? img) async {
    if (_isCreate) throw Exception('Use listing flow');

    final updates = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()),
      'is_active': _isActive,
    };

    // marketplace_listings uses 'images' (jsonb array), NOT 'image_url'
    if (img != null) {
      List<String> existingImages = [];
      final currentImages = widget.contentData?['images'];
      if (currentImages is List) {
        existingImages = currentImages.map((e) => e.toString()).toList();
      }
      // Replace cover image (first) or add as new
      if (existingImages.isNotEmpty) {
        existingImages[0] = img;
      } else {
        existingImages.add(img);
      }
      updates['images'] = existingImages;
    }

    await MarketplaceService().updateListing(widget.contentId!, updates);
  }

  // ============================================================
  // SAVE: CATEGORY
  // ============================================================

  Future<void> _saveCategory(String? img) async {
    final p = <String, dynamic>{
      'name': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'is_active': _isActive,
      if (img != null) 'image_url': img,
      if (_selectedCategory != null) 'parent_id': _selectedCategory!.id,
    };
    if (_isCreate) {
      if (!p.containsKey('type')) p['type'] = 'product';
      await SupabaseService.client.from('categories').insert(p);
    } else {
      await SupabaseService.client.from('categories').update(p).eq('id', widget.contentId!);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrice = widget.contentType == 'product' || widget.contentType == 'marketplace';
    final hasLink = widget.contentType == 'ad';
    final needsStoreSearch = widget.contentType == 'product' && _isCreate && !_storePreAssigned;
    final showStoreCategoryPicker = widget.contentType == 'product' && (_storePreAssigned || _selectedStore != null);
    final needsCat = (widget.contentType == 'store' || widget.contentType == 'category') && _isCreate;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${_isCreate ? "Create" : "Edit"} ${widget.contentType.toUpperCase()}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),
          SizedBox(height: 1.h),
          // Form
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _imgPicker(theme),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title / Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  if (hasPrice) ...[
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  // Store assignment
                  if (_storePreAssigned) ...[
                    SizedBox(height: 2.5.h),
                    _buildPreAssignedStoreInfo(theme),
                  ] else if (needsStoreSearch) ...[
                    SizedBox(height: 2.5.h),
                    _storeSearch(theme),
                  ],
                  // Store category picker
                  if (showStoreCategoryPicker) ...[
                    SizedBox(height: 2.h),
                    _buildStoreCategoryPicker(theme),
                  ],
                  // Global category search
                  if (needsCat) ...[
                    SizedBox(height: 2.5.h),
                    _catSearch(theme),
                  ],
                  if (widget.contentType == 'store' && _isCreate) ...[
                    SizedBox(height: 2.h),
                    _buildStoreCategoryTypeDropdown(theme),
                  ],
                  if (widget.contentType == 'store' && _isCreate && _selectedCategory != null) ...[
                    SizedBox(height: 2.h),
                    _subSearch(theme),
                  ],
                  if (hasLink) ...[
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link Target',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: Text(_isActive ? 'Visible' : 'Hidden'),
                    value: _isActive,
                    activeColor: theme.colorScheme.primary,
                    onChanged: _isLoading ? null : (v) => setState(() => _isActive = v),
                  ),
                  SizedBox(height: 3.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(_isCreate ? Icons.add : Icons.save),
                      label: Text(_isCreate ? 'Create' : 'Save Changes'),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ============================================================
  // PRE-ASSIGNED STORE INFO
  // ============================================================

  Widget _buildPreAssignedStoreInfo(ThemeData t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Store', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.store, color: Colors.green, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _preAssignedStoreName ?? 'Loading...',
              style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ]),
      ),
    ]);
  }

  // ============================================================
  // STORE CATEGORY PICKER
  // ============================================================

  Widget _buildStoreCategoryPicker(ThemeData t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Category (optional)', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 0.5.h),
      Text('Assign to a store category or leave empty',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      SizedBox(height: 1.h),
      if (_loadingStoreCategories)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Center(
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        )
      else if (_storeCategoriesForProduct.isEmpty)
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: t.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'No categories in this store yet. Product will be added without a category.',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
            ),
          ]),
        )
      else
        DropdownButtonFormField<String?>(
          value: _selectedStoreCategoryId,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.category_outlined),
            hintText: 'No category (direct to store)',
            hintStyle: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('No category (direct to store)')),
            ..._storeCategoriesForProduct.map((cat) => DropdownMenuItem<String?>(
                  value: cat.id,
                  child: Row(children: [
                    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          cat.imageUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.category, size: 20, color: t.colorScheme.primary),
                        ),
                      ),
                      SizedBox(width: 2.w),
                    ] else ...[
                      Icon(Icons.category, size: 20, color: t.colorScheme.primary),
                      SizedBox(width: 2.w),
                    ],
                    Flexible(child: Text(cat.name)),
                  ]),
                )),
          ],
          onChanged: (v) => setState(() => _selectedStoreCategoryId = v),
        ),
    ]);
  }

  // ============================================================
  // IMAGE PICKER WIDGET
  // ============================================================

  Widget _imgPicker(ThemeData t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Image', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 18.h,
          decoration: BoxDecoration(
            color: t.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.colorScheme.outline.withOpacity(0.4), width: 1.5),
          ),
          child: _pickedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? FutureBuilder<Uint8List>(
                          future: _pickedImage!.readAsBytes(),
                          builder: (_, s) => s.hasData
                              ? Image.memory(s.data!, fit: BoxFit.cover, width: double.infinity)
                              : const Center(child: CircularProgressIndicator()),
                        )
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: double.infinity),
                )
              : _existingImageUrl != null
                  ? Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder(t),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ])
                  : _imgPlaceholder(t),
        ),
      ),
    ]);
  }

  Widget _imgPlaceholder(ThemeData t) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 10.w, color: t.colorScheme.onSurfaceVariant),
          SizedBox(height: 1.h),
          Text('Tap to select from gallery',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      );

  // ============================================================
  // SEARCH SECTIONS
  // ============================================================

  Widget _storeSearch(ThemeData t) => _searchSection(
        t,
        label: 'Assign to Store *',
        selected: _selectedStore?.name,
        selectedIcon: Icons.store,
        selectedColor: Colors.green,
        onClear: () => setState(() {
          _selectedStore = null;
          _storeSearchCtrl.clear();
          _storeResults = [];
          _storeCategoriesForProduct = [];
          _selectedStoreCategoryId = null;
        }),
        controller: _storeSearchCtrl,
        searching: _searchingStores,
        onSearch: _searchStores,
        hint: 'Search store by name',
        results: _storeResults
            .map((s) => _SearchItem(
                  id: s.id,
                  title: s.name,
                  subtitle: s.category,
                  icon: Icons.store,
                  onTap: () {
                    setState(() {
                      _selectedStore = s;
                      _storeSearchCtrl.clear();
                      _storeResults = [];
                      _selectedStoreCategoryId = null;
                    });
                    _loadStoreCategoriesForProduct(s.id);
                  },
                ))
            .toList(),
      );

  Widget _catSearch(ThemeData t) => _searchSection(
        t,
        label: widget.contentType == 'category' ? 'Parent Category (optional)' : 'Assign to Category',
        selected: _selectedCategory?.name,
        selectedIcon: Icons.category,
        selectedColor: Colors.blue,
        onClear: () => setState(() {
          _selectedCategory = null;
          _selectedSubcategory = null;
          _catSearchCtrl.clear();
          _catResults = [];
          _subResults = [];
        }),
        controller: _catSearchCtrl,
        searching: _searchingCats,
        onSearch: _searchCats,
        hint: 'Search category',
        onTapField: () {
          if (_catResults.isEmpty) _searchCats('');
        },
        results: _catResults
            .map((c) => _SearchItem(
                  id: c.id,
                  title: c.name,
                  subtitle: c.type,
                  icon: Icons.category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = c;
                      _selectedSubcategory = null;
                      _catSearchCtrl.clear();
                      _catResults = [];
                    });
                    _searchSubs('');
                  },
                ))
            .toList(),
      );

  Widget _subSearch(ThemeData t) => _searchSection(
        t,
        label: 'Subcategory (optional)',
        selected: _selectedSubcategory?.name,
        selectedIcon: Icons.subdirectory_arrow_right,
        selectedColor: Colors.purple,
        onClear: () => setState(() {
          _selectedSubcategory = null;
          _subSearchCtrl.clear();
        }),
        controller: _subSearchCtrl,
        searching: _searchingSubs,
        onSearch: _searchSubs,
        hint: 'Search subcategory',
        onTapField: () {
          if (_subResults.isEmpty) _searchSubs('');
        },
        results: _subResults
            .map((c) => _SearchItem(
                  id: c.id,
                  title: c.name,
                  subtitle: c.type,
                  icon: Icons.subdirectory_arrow_right,
                  onTap: () => setState(() {
                    _selectedSubcategory = c;
                    _subSearchCtrl.clear();
                    _subResults = [];
                  }),
                ))
            .toList(),
      );

  Widget _buildStoreCategoryTypeDropdown(ThemeData t) {
    const types = <String, String>{
      'food': 'Food',
      'grocery': 'Grocery',
      'pharmacy': 'Pharmacy',
      'retail': 'Retail',
      'restaurant': 'Restaurant',
      'marketplace': 'Marketplace',
      'services': 'Services',
      'electronics': 'Electronics',
      'fashion': 'Fashion',
      'beauty': 'Beauty',
      'sports': 'Sports',
      'pets': 'Pets',
      'home': 'Home',
      'bakery': 'Bakery',
      'coffee': 'Coffee',
      'other': 'Other',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Store Type *', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      DropdownButtonFormField<String>(
        value: _storeCategoryType,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.label_outline),
        ),
        items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _storeCategoryType = v);
        },
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    ]);
  }

  // ============================================================
  // GENERIC SEARCH SECTION BUILDER
  // ============================================================

  Widget _searchSection(
    ThemeData t, {
    required String label,
    String? selected,
    required IconData selectedIcon,
    required Color selectedColor,
    required VoidCallback onClear,
    required TextEditingController controller,
    required bool searching,
    required ValueChanged<String> onSearch,
    required String hint,
    VoidCallback? onTapField,
    required List<_SearchItem> results,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      if (selected != null) ...[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: selectedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selectedColor.withOpacity(0.4)),
          ),
          child: Row(children: [
            Icon(selectedIcon, color: selectedColor, size: 20),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(selected, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
          ]),
        ),
        SizedBox(height: 1.h),
      ],
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
        ),
        onChanged: onSearch,
        onTap: onTapField,
      ),
      if (results.isNotEmpty)
        Container(
          constraints: BoxConstraints(maxHeight: 20.h),
          margin: EdgeInsets.only(top: 0.5.h),
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.colorScheme.outline.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: t.colorScheme.shadow.withOpacity(0.1), blurRadius: 4)],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: t.colorScheme.outline.withOpacity(0.2)),
            itemBuilder: (_, i) => ListTile(
              dense: true,
              leading: Icon(results[i].icon, size: 20),
              title: Text(results[i].title),
              subtitle: results[i].subtitle != null
                  ? Text(results[i].subtitle!, style: t.textTheme.bodySmall)
                  : null,
              onTap: results[i].onTap,
            ),
          ),
        ),
    ]);
  }
}

class _SearchItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  _SearchItem({required this.id, required this.title, this.subtitle, required this.icon, required this.onTap});
}