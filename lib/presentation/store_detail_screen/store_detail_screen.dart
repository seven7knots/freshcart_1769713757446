import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../services/supabase_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_editable_item_wrapper.dart';
import '../../widgets/animated_press_button.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingStore = false;
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  String? _errorStore;

  Store? _store;
  List<Category> _storeCategories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Check if current user can manage this store (admin or store owner/merchant).
  /// Inside StoreDetailScreen, if you have permission, edit controls always show.
  /// The global pencil toggle (isEditMode) controls overlays on Home/Browse screens,
  /// but once you're inside your store, you're there to manage it.
  bool _canManageStore(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (adminProvider.isAdmin) return true;
    if (_store == null) return false;
    final uid = authProvider.userId;
    if (uid == null) return false;
    return _store!.ownerUserId == uid || _store!.merchantId == uid;
  }

  Future<void> _loadStoreData() async {
    await Future.wait([_loadStore(), _loadStoreCategories(), _loadProducts()]);
  }

  Future<void> _loadStore() async {
    setState(() { _isLoadingStore = true; _errorStore = null; });
    try {
      final store = await StoreService.getStoreById(widget.storeId);
      if (mounted) setState(() { _store = store; _isLoadingStore = false; });
    } catch (e) {
      if (mounted) setState(() { _errorStore = e.toString(); _isLoadingStore = false; });
    }
  }

  Future<void> _loadStoreCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getStoreCategories(widget.storeId, activeOnly: false);
      if (mounted) setState(() { _storeCategories = categories; _isLoadingCategories = false; });
    } catch (e) {
      debugPrint('[STORE_DETAIL] Error loading store categories: $e');
      if (mounted) setState(() { _storeCategories = []; _isLoadingCategories = false; });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await ProductService.getProductsByStore(widget.storeId, availableOnly: false, excludeDemo: true);
      if (mounted) setState(() { _allProducts = products; _filterProducts(); _isLoadingProducts = false; });
    } catch (e) {
      if (mounted) setState(() { _allProducts = []; _filteredProducts = []; _isLoadingProducts = false; });
    }
  }

  void _filterProducts() {
    if (_selectedCategoryId == null) {
      _filteredProducts = _allProducts;
    } else if (_selectedCategoryId == '__uncategorized__') {
      _filteredProducts = _allProducts.where((p) => p.category == null || p.category!.isEmpty).toList();
    } else {
      final catName = _storeCategories.where((c) => c.id == _selectedCategoryId).firstOrNull?.name;
      _filteredProducts = _allProducts.where((p) => p.category == catName || p.category == _selectedCategoryId).toList();
    }
  }

  void _selectCategory(String? catId) {
    setState(() { _selectedCategoryId = catId; _filterProducts(); });
  }

  void _addToCart(Product product) async {
    HapticFeedback.mediumImpact();
    try {
      await DatabaseService.instance.addToCart(
        productId: product.id,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} added to cart'), duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'View Cart', textColor: Colors.white, onPressed: () => AppRoutes.openCart(context)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add to cart: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ============================================================
  // IN-STORE CATEGORY MANAGEMENT (with image upload)
  // ============================================================

  void _showCreateCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    XFile? pickedImage;

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Create Store Category'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Image picker
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
                if (img != null) setDialogState(() => pickedImage = img);
              },
              child: Container(
                width: double.infinity, height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                ),
                child: pickedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: pickedImage!.readAsBytes(),
                                builder: (_, s) => s.hasData
                                    ? Image.memory(s.data!, fit: BoxFit.cover, width: double.infinity, height: 100)
                                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : Image.file(File(pickedImage!.path), fit: BoxFit.cover, width: double.infinity, height: 100))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text('Add thumbnail (optional)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  // Upload image if picked
                  String? imageUrl;
                  if (pickedImage != null) {
                    imageUrl = await _uploadCategoryImage(pickedImage!);
                  }

                  await CategoryService.createCategory(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    type: 'store_category',
                    storeId: widget.storeId,
                    isActive: true,
                    imageUrl: imageUrl,
                  );
                  _loadStoreCategories();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      });
    });
  }

  void _showEditCategoryDialog(Category cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description ?? '');
    XFile? pickedImage;
    String? existingImageUrl = cat.imageUrl;

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Image picker / existing image
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
                if (img != null) setDialogState(() => pickedImage = img);
              },
              child: Container(
                width: double.infinity, height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                ),
                child: pickedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: pickedImage!.readAsBytes(),
                                builder: (_, s) => s.hasData
                                    ? Image.memory(s.data!, fit: BoxFit.cover, width: double.infinity, height: 100)
                                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : Image.file(File(pickedImage!.path), fit: BoxFit.cover, width: double.infinity, height: 100))
                    : existingImageUrl != null && existingImageUrl!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: Image.network(existingImageUrl!, fit: BoxFit.cover, width: double.infinity, height: 100,
                              errorBuilder: (_, __, ___) => _dialogImagePlaceholder(context, 'Tap to change image')))
                        : _dialogImagePlaceholder(context, 'Add thumbnail (optional)'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
          ])),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await CategoryService.deleteCategory(cat.id);
                  _loadStoreCategories();
                  _loadProducts();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted'), backgroundColor: Colors.red));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  String? imageUrl = existingImageUrl;
                  if (pickedImage != null) {
                    imageUrl = await _uploadCategoryImage(pickedImage!);
                  }

                  await CategoryService.updateCategory(cat.id, {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    if (imageUrl != null) 'image_url': imageUrl,
                  });
                  _loadStoreCategories();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      });
    });
  }

  Widget _dialogImagePlaceholder(BuildContext context, String text) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.add_photo_alternate_outlined, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(height: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }

  /// Upload a category image and return the public URL
  Future<String?> _uploadCategoryImage(XFile image) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return null;

      final uid = user.id;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = image.path.split('.').last.toLowerCase();
      final bytes = await image.readAsBytes();

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

      await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: mimeType));

      return SupabaseService.client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('[UPLOAD] Category image failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red));
      }
      return null;
    }
  }

  // ============================================================
  // IN-STORE PRODUCT MANAGEMENT
  // ============================================================

  void _showCreateProductModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => ContentEditModalWidget(
        contentType: 'product',
        contentData: {
          'store_id': widget.storeId,
          'store_name': _store?.name ?? '',
        },
        onSaved: () { Navigator.pop(ctx); _loadProducts();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product created'), backgroundColor: Colors.green)); },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingStore && _store == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorStore != null || _store == null) {
      return Scaffold(appBar: AppBar(title: const Text('Store Not Found')), body: _buildError(theme, _errorStore ?? 'Store not found'));
    }

    final canManage = _canManageStore(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(theme, canManage),
          SliverPersistentHeader(pinned: true, delegate: _StickyTabBarDelegate(
            TabBar(controller: _tabController, labelColor: theme.colorScheme.primary, unselectedLabelColor: theme.colorScheme.onSurfaceVariant, indicatorColor: theme.colorScheme.primary,
              tabs: const [Tab(text: 'Products'), Tab(text: 'About')]),
          )),
        ],
        body: TabBarView(controller: _tabController, children: [
          _buildProductsTab(theme, canManage),
          _buildAboutTab(theme),
        ]),
      ),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: _showCreateProductModal,
        icon: const Icon(Icons.add), label: const Text('Add Product'),
        backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
      ) : null,
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool canManage) {
    return SliverAppBar(
      expandedHeight: 28.h, pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_store!.name, style: const TextStyle(fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 4)])),
        background: Stack(fit: StackFit.expand, children: [
          _store!.imageUrl != null && _store!.imageUrl!.isNotEmpty
              ? Image.network(_store!.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.primaryContainer, child: Icon(Icons.store, size: 60, color: theme.colorScheme.onPrimaryContainer)))
              : Container(color: theme.colorScheme.primaryContainer, child: Icon(Icons.store, size: 60, color: theme.colorScheme.onPrimaryContainer)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]))),
          if (!_store!.isActive || !_store!.isAcceptingOrders)
            Container(color: Colors.black54, child: Center(child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
              child: Text('Currently Closed', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onError, fontWeight: FontWeight.w600)),
            ))),
        ]),
      ),
      actions: [
        if (canManage) IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          tooltip: 'Edit Store',
          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (ctx) => ContentEditModalWidget(contentType: 'store', contentId: _store!.id, contentData: _store!.toMap(),
              onSaved: () { Navigator.pop(ctx); _loadStore(); })),
        ),
        IconButton(icon: const Icon(Icons.share), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing ${_store!.name}')))),
      ],
    );
  }

  Widget _buildProductsTab(ThemeData theme, bool canManage) {
    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildStoreInfoCard(theme)),
        SliverToBoxAdapter(child: _buildCategoriesSection(theme, canManage)),
        if (_isLoadingProducts)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (_filteredProducts.isEmpty)
          SliverFillRemaining(child: _buildEmptyProducts(theme, canManage))
        else
          SliverPadding(
            padding: EdgeInsets.all(4.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 3.w, mainAxisSpacing: 3.w, childAspectRatio: 0.72),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _filteredProducts[index];
                final card = _buildProductCard(product, theme);
                if (canManage) {
                  return AdminEditableItemWrapper(
                    contentType: 'product', contentId: product.id, contentData: product.toMap(),
                    onDeleted: _loadProducts, onUpdated: _loadProducts, child: card,
                  );
                }
                return card;
              }, childCount: _filteredProducts.length),
            ),
          ),
      ]),
    );
  }

  // ============================================================
  // CATEGORIES SECTION — Thumbnail Carousel
  // ============================================================

  Widget _buildCategoriesSection(ThemeData theme, bool canManage) {
    final hasUncategorized = _allProducts.any((p) => p.category == null || p.category!.isEmpty);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row
      Padding(
        padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
        child: Row(children: [
          Text('Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (canManage) InkWell(
            onTap: _showCreateCategoryDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: Colors.white, size: 14), SizedBox(width: 0.5.w),
                Text('Add', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),

      // Thumbnail carousel
      SizedBox(
        height: 12.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          children: [
            // "All" thumbnail
            _buildCategoryThumbnail(
              theme: theme,
              catId: null,
              label: 'All',
              count: _allProducts.length,
              icon: Icons.grid_view_rounded,
              canManage: false,
            ),

            // "Uncategorized" thumbnail
            if (hasUncategorized)
              _buildCategoryThumbnail(
                theme: theme,
                catId: '__uncategorized__',
                label: 'Other',
                count: _allProducts.where((p) => p.category == null || p.category!.isEmpty).length,
                icon: Icons.inventory_2_outlined,
                canManage: false,
              ),

            // Store category thumbnails (wrapped with admin edit wrapper)
            ..._storeCategories.map((cat) {
              final count = _allProducts.where((p) => p.category == cat.name || p.category == cat.id).length;
              final thumbnail = _buildCategoryThumbnail(
                theme: theme,
                catId: cat.id,
                label: cat.name,
                count: count,
                imageUrl: cat.imageUrl,
                icon: Icons.category_outlined,
                category: cat,
                canManage: canManage,
              );
              if (canManage) {
                return AdminEditableItemWrapper(
                  contentType: 'category',
                  contentId: cat.id,
                  contentData: {
                    'name': cat.name,
                    'description': cat.description,
                    'image_url': cat.imageUrl,
                    'is_active': cat.isActive,
                    'store_id': widget.storeId,
                    'type': 'store_category',
                  },
                  onDeleted: () { _loadStoreCategories(); _loadProducts(); },
                  onUpdated: _loadStoreCategories,
                  menuAlignment: Alignment.topRight,
                  menuPadding: const EdgeInsets.all(0),
                  showBorder: false,
                  child: thumbnail,
                );
              }
              return thumbnail;
            }),
          ],
        ),
      ),
      SizedBox(height: 1.h),
    ]);
  }

  Widget _buildCategoryThumbnail({
    required ThemeData theme,
    required String? catId,
    required String label,
    required int count,
    String? imageUrl,
    required IconData icon,
    Category? category,
    required bool canManage,
  }) {
    final isSelected = _selectedCategoryId == catId;
    final thumbWidth = 22.w;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(right: 2.5.w),
      child: GestureDetector(
        onTap: () => _selectCategory(catId),
        onLongPress: canManage && category != null ? () => _showEditCategoryDialog(category) : null,
        child: SizedBox(
          width: thumbWidth,
          child: Column(children: [
            // Thumbnail — image fills entire box, or icon fallback
            Expanded(child: Container(
              width: thumbWidth,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.transparent
                    : isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.15),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: hasImage
                  ? Stack(fit: StackFit.expand, children: [
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(icon, size: 24,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      // Selected overlay tint
                      if (isSelected)
                        Container(color: theme.colorScheme.primary.withOpacity(0.35)),
                      // Gradient at bottom for readability
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ])
                  : Center(child: Icon(icon, size: 24,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
            )),
            SizedBox(height: 0.5.h),
            // Label
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontSize: 9.sp,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
            // Count (only for non-image thumbnails — image ones show count in overlay)
            if (!hasImage)
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontSize: 8.sp,
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // STORE INFO, PRODUCT CARDS, ABOUT TAB
  // ============================================================

  Widget _buildStoreInfoCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(4.w), padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (_store!.rating > 0) ...[
            Icon(Icons.star, color: Colors.amber, size: 5.w), SizedBox(width: 1.w),
            Text(_store!.ratingDisplay, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(width: 1.w),
            Text('(${_store!.totalReviews})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
          ],
          Icon(Icons.access_time, size: 4.w, color: theme.colorScheme.primary), SizedBox(width: 1.w),
          Text(_store!.prepTimeDisplay, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ]),
        if (_store!.category != null) ...[
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(_store!.category!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
          ),
        ],
        SizedBox(height: 1.h),
        Text('${_allProducts.length} products${_storeCategories.isNotEmpty ? ' · ${_storeCategories.length} categories' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product),
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(fit: StackFit.expand, children: [
              product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant)))
                  : Container(color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.shopping_bag, size: 40, color: theme.colorScheme.onSurfaceVariant)),
              if (product.isOnSale) Positioned(top: 1.h, left: 1.h, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                child: Text('-${product.discountPercent}%', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
              )),
              if (!product.canOrder) Positioned.fill(child: Container(color: Colors.black54, child: Center(child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
                child: Text('Out of Stock', style: TextStyle(color: theme.colorScheme.onError, fontSize: 10.sp, fontWeight: FontWeight.w600)),
              )))),
              if (product.category != null && product.category!.isNotEmpty) Positioned(bottom: 4, left: 4, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Text(product.category!, style: TextStyle(color: Colors.white, fontSize: 8.sp)),
              )),
            ]),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.all(2.5.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: product.isOnSale
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(product.priceDisplay, style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant)),
                        Text(product.salePriceDisplay!, style: theme.textTheme.titleSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.w700)),
                      ])
                    : Text(product.priceDisplay, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                ),
                if (product.canOrder) GestureDetector(
                  onTap: () => _addToCart(product),
                  child: Container(padding: EdgeInsets.all(2.w), decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 18)),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildAboutTab(ThemeData theme) {
    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_store!.description != null) ...[
        Text('About', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),
        Text(_store!.description!, style: theme.textTheme.bodyMedium),
        SizedBox(height: 3.h),
      ],
      _infoRow(theme, Icons.category, 'Category', _store!.category ?? 'Not specified'),
      _infoRow(theme, Icons.access_time, 'Preparation Time', _store!.prepTimeDisplay),
      if (_store!.rating > 0) _infoRow(theme, Icons.star, 'Rating', '${_store!.ratingDisplay} (${_store!.totalReviews} reviews)'),
      _infoRow(theme, Icons.store, 'Status', (_store!.isActive && _store!.isAcceptingOrders) ? 'Open' : 'Closed'),
      if (_store!.address != null) _infoRow(theme, Icons.location_on, 'Address', _store!.address!),
      if (_store!.minimumOrder != null && _store!.minimumOrder! > 0) _infoRow(theme, Icons.shopping_bag, 'Minimum Order', '\$${_store!.minimumOrder!.toStringAsFixed(2)}'),
    ]));
  }

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(padding: EdgeInsets.only(bottom: 2.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 6.w, color: theme.colorScheme.primary), SizedBox(width: 3.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: 0.5.h),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ])),
    ]));
  }

  Widget _buildEmptyProducts(ThemeData theme, bool canManage) {
    return Center(child: Padding(padding: EdgeInsets.all(8.w), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_bag_outlined, size: 80, color: theme.colorScheme.outline),
      SizedBox(height: 3.h),
      Text('No products available', style: theme.textTheme.headlineSmall),
      SizedBox(height: 1.h),
      Text(_selectedCategoryId != null ? 'No products in this category' : 'This store hasn\'t added any products yet',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      if (canManage) ...[
        SizedBox(height: 3.h),
        ElevatedButton.icon(onPressed: _showCreateProductModal, icon: const Icon(Icons.add), label: const Text('Add Product')),
      ],
    ])));
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(child: Padding(padding: EdgeInsets.all(8.w), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
      SizedBox(height: 2.h),
      Text('Something went wrong', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error)),
      SizedBox(height: 1.h),
      Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      SizedBox(height: 3.h),
      ElevatedButton.icon(onPressed: _loadStoreData, icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ])));
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;
  _StickyTabBarDelegate(this.child);
  @override double get minExtent => child.preferredSize.height;
  @override double get maxExtent => child.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
    Container(color: Theme.of(context).scaffoldBackgroundColor, child: child);
  @override bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) => false;
}