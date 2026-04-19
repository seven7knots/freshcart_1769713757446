import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer;
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_editable_item_wrapper.dart';
import '../admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/generated/app_localizations.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> with SingleTickerProviderStateMixin {
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
      await ref.read(cartNotifierProvider.notifier).addToCart(
        productId: product.id,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} added to cart', maxLines: 1, overflow: TextOverflow.ellipsis), duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: AppLocalizations.of(context)!.viewCart, textColor: Colors.white, onPressed: () => AppRoutes.openCart(context)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add to cart: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
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
          title: Text(AppLocalizations.of(context)!.createStoreCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                        Text(AppLocalizations.of(context)!.addThumbnailOptional, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.categoryName, border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionOptional, border: OutlineInputBorder()), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
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
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.categoryCreated, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocalizations.of(context)!.create, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          title: Text(AppLocalizations.of(context)!.editCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                    : existingImageUrl != null && existingImageUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(imageUrl: existingImageUrl, fit: BoxFit.cover, width: double.infinity, height: 100,
                              errorWidget: (_, __, ___) => _dialogImagePlaceholder(context, AppLocalizations.of(context)!.tapToChangeImage)))
                        : _dialogImagePlaceholder(context, 'Add thumbnail (optional)'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.categoryName, border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description, border: OutlineInputBorder()), maxLines: 2),
          ])),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await CategoryService.deleteCategory(cat.id);
                  _loadStoreCategories();
                  _loadProducts();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.categoryDeleted, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.categoryUpdated, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocalizations.of(context)!.save, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.productCreated, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green)); },
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
      return Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context)!.storeNotFound, maxLines: 1, overflow: TextOverflow.ellipsis)), body: _buildError(theme, _errorStore ?? AppLocalizations.of(context)!.storeNotFound2));
    }

    final canManage = _canManageStore(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(theme, canManage),
          SliverPersistentHeader(pinned: true, delegate: _StickyTabBarDelegate(
            TabBar(controller: _tabController, labelColor: theme.colorScheme.primary, unselectedLabelColor: theme.colorScheme.onSurfaceVariant, indicatorColor: theme.colorScheme.primary,
              tabs: [Tab(text: AppLocalizations.of(context)!.products), Tab(text: AppLocalizations.of(context)!.about)]),
          )),
        ],
        body: TabBarView(controller: _tabController, children: [
          _buildProductsTab(theme, canManage),
          _buildAboutTab(theme),
        ]),
      ),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: _showCreateProductModal,
        icon: Icon(Icons.add), label: Text(AppLocalizations.of(context)!.addProduct2, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
      ) : null,
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool canManage) {
    return SliverAppBar(
      expandedHeight: 28.h, pinned: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 12, end: 56),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.5),
                child: _store!.imageUrl != null && _store!.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: _store!.imageUrl!, fit: BoxFit.cover, memCacheWidth: 64,
                        errorWidget: (_, __, ___) => Container(color: Colors.white24,
                          child: const Icon(Icons.store, size: 14, color: Colors.white70)))
                    : Container(color: Colors.white24,
                        child: const Icon(Icons.store, size: 14, color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _store!.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black.withAlpha(45), offset: Offset(0, 1), blurRadius: 4)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        background: Stack(fit: StackFit.expand, children: [
          _store!.imageUrl != null && _store!.imageUrl!.isNotEmpty
              ? CachedNetworkImage(imageUrl: _store!.imageUrl!, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: theme.colorScheme.primaryContainer, child: Icon(Icons.store, size: 60, color: theme.colorScheme.onPrimaryContainer)))
              : Container(color: theme.colorScheme.primaryContainer, child: Icon(Icons.store, size: 60, color: theme.colorScheme.onPrimaryContainer)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]))),
          if (!_store!.isActive || !_store!.isAcceptingOrders)
            Container(color: Colors.black54, child: Center(child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
              child: Text(AppLocalizations.of(context)!.currentlyClosed, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onError, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ))),
        ]),
      ),
      actions: [
        if (canManage) IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          tooltip: AppLocalizations.of(context)!.editStore,
          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (ctx) => ContentEditModalWidget(contentType: 'store', contentId: _store!.id, contentData: _store!.toMap(),
              onSaved: () { Navigator.pop(ctx); _loadStore(); })),
        ),
        IconButton(icon: const Icon(Icons.share), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing ${_store!.name}', maxLines: 1, overflow: TextOverflow.ellipsis)))),
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
      Padding(
        padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
        child: Row(children: [
          Flexible(child: Text(AppLocalizations.of(context)!.categories, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Spacer(),
          if (canManage) InkWell(
            onTap: _showCreateCategoryDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: Colors.white, size: 14), SizedBox(width: 0.5.w),
                Text(AppLocalizations.of(context)!.add, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ]),
      ),
      SizedBox(
        height: 12.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          children: [
            _buildCategoryThumbnail(theme: theme, catId: null, label: AppLocalizations.of(context)!.all, count: _allProducts.length, icon: Icons.grid_view_rounded, canManage: false),
            if (hasUncategorized)
              _buildCategoryThumbnail(theme: theme, catId: '__uncategorized__', label: AppLocalizations.of(context)!.other,
                count: _allProducts.where((p) => p.category == null || p.category!.isEmpty).length, icon: Icons.inventory_2_outlined, canManage: false),
            ..._storeCategories.map((cat) {
              final count = _allProducts.where((p) => p.category == cat.name || p.category == cat.id).length;
              final thumbnail = _buildCategoryThumbnail(theme: theme, catId: cat.id, label: cat.name, count: count, imageUrl: cat.imageUrl, icon: Icons.category_outlined, category: cat, canManage: canManage);
              if (canManage) {
                return AdminEditableItemWrapper(
                  contentType: 'category', contentId: cat.id,
                  contentData: {'name': cat.name, 'description': cat.description, 'image_url': cat.imageUrl, 'is_active': cat.isActive, 'store_id': widget.storeId, 'type': 'store_category'},
                  onDeleted: () { _loadStoreCategories(); _loadProducts(); }, onUpdated: _loadStoreCategories,
                  menuAlignment: Alignment.topRight, menuPadding: const EdgeInsets.all(0), showBorder: false, child: thumbnail,
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
    required ThemeData theme, required String? catId, required String label, required int count,
    String? imageUrl, required IconData icon, Category? category, required bool canManage,
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
            Expanded(child: Container(
              width: thumbWidth, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: hasImage ? Colors.transparent : isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.15), width: isSelected ? 2.5 : 1),
              ),
              child: hasImage
                  ? Stack(fit: StackFit.expand, children: [
                      CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(child: Icon(icon, size: 24, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant))),
                      if (isSelected) Container(color: theme.colorScheme.primary.withOpacity(0.35)),
                      Positioned(bottom: 0, left: 0, right: 0, child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                        ),
                        child: Text('$count', style: TextStyle(color: theme.colorScheme.surface, fontSize: 8.sp, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                    ])
                  : Center(child: Icon(icon, size: 24, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
            )),
            SizedBox(height: 0.5.h),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface, fontSize: 9.sp),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            if (!hasImage) Text('$count', style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, fontSize: 8.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Flexible(child: Text(_store!.ratingDisplay, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 1.w),
            Flexible(child: Text('(${_store!.totalReviews})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Spacer(),
          ],
          Icon(Icons.access_time, size: 4.w, color: theme.colorScheme.primary), SizedBox(width: 1.w),
          Text(_store!.prepTimeDisplay, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        if (_store!.category != null) ...[
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Text(_store!.category!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
        SizedBox(height: 1.h),
        Text(
          _storeCategories.isNotEmpty
              ? '${_allProducts.length} ${AppLocalizations.of(context)!.products} · ${_storeCategories.length} ${AppLocalizations.of(context)!.categories}'
              : '${_allProducts.length} ${AppLocalizations.of(context)!.products}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  ? CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant)))
                  : Container(color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.shopping_bag, size: 40, color: theme.colorScheme.onSurfaceVariant)),
              if (product.isOnSale) Positioned(top: 1.h, left: 1.h, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
                child: Text('-${product.discountPercent}%', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (!product.canOrder) Positioned.fill(child: Container(color: Colors.black54, child: Center(child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
                child: Text(AppLocalizations.of(context)!.outOfStock, style: TextStyle(color: theme.colorScheme.onError, fontSize: 10.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              )))),
              if (product.category != null && product.category!.isNotEmpty) Positioned(bottom: 4, left: 4, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                decoration: BoxDecoration(color: Colors.black.withAlpha(54), borderRadius: BorderRadius.circular(16)),
                child: Text(product.category!, style: TextStyle(color: theme.colorScheme.surface, fontSize: 8.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        Text(product.priceDisplay, style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(product.salePriceDisplay!, style: theme.textTheme.titleSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])
                    : Text(product.priceDisplay, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (product.canOrder) GestureDetector(
                  onTap: () => _addToCart(product),
                  child: Container(padding: EdgeInsets.all(2.w), decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 18)),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  // ============================================================
  // SESSION 20 FIX: ABOUT TAB — Now shows operating hours,
  // delivery fee, accepting orders status, and phone
  // ============================================================

  Widget _buildAboutTab(ThemeData theme) {
    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Description
      if (_store!.description != null && _store!.description!.isNotEmpty) ...[
        Text(AppLocalizations.of(context)!.about, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        Text(_store!.description!, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 3.h),
      ],

      // Store Info
      Text(AppLocalizations.of(context)!.storeInformation, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: 2.h),
      _infoRow(theme, Icons.category, AppLocalizations.of(context)!.category2, _store!.category ?? AppLocalizations.of(context)!.notSpecified),
      _infoRow(theme, Icons.access_time, AppLocalizations.of(context)!.preparationTime, _store!.prepTimeDisplay),
      if (_store!.rating > 0) _infoRow(theme, Icons.star, AppLocalizations.of(context)!.rating, '${_store!.ratingDisplay} (${_store!.totalReviews} reviews)'),

      // SESSION 20: Accepting orders status
      _infoRow(theme, Icons.storefront,  'Status',
        (_store!.isActive && _store!.isAcceptingOrders)
            ? AppLocalizations.of(context)!.openAcceptingOrders
            : !_store!.isActive
                ? AppLocalizations.of(context)!.storeClosed
                : AppLocalizations.of(context)!.notAcceptingOrders),

      if (_store!.address != null && _store!.address!.isNotEmpty)
        _infoRow(theme, Icons.location_on, AppLocalizations.of(context)!.address, _store!.address!),
      if (_store!.minimumOrder != null && _store!.minimumOrder! > 0)
        _infoRow(theme, Icons.shopping_bag, AppLocalizations.of(context)!.minimumOrder, '\$${_store!.minimumOrder!.toStringAsFixed(2)}'),


      // SESSION 20 FIX: Operating Hours Section
      if (_store!.operatingHours != null && _store!.operatingHours!.isNotEmpty) ...[
        SizedBox(height: 1.h),
        Text(AppLocalizations.of(context)!.operatingHours, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.5.h),
        _buildOperatingHoursCard(theme),
        SizedBox(height: 2.h),
      ],
    ]));
  }

  // SESSION 20 FIX: Operating hours card for customer-facing About tab
  Widget _buildOperatingHoursCard(ThemeData theme) {
    final hours = _store!.operatingHours!;
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // Determine current day to highlight
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // Monday = 0

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        children: List.generate(dayNames.length, (i) {
          final dayKey = dayNames[i];
          final dayData = hours[dayKey];
          final isToday = i == todayIndex;

          String hoursText;
          bool isOpen = false;
          if (dayData is Map) {
            final open = dayData['open']?.toString() ?? '';
            final close = dayData['close']?.toString() ?? '';
            if (open.isNotEmpty && close.isNotEmpty) {
              hoursText = '$open – $close';
              isOpen = true;
            } else {
              hoursText = 'Closed';
            }
          } else {
            hoursText = 'Closed';
          }

          return Container(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: isToday ? theme.colorScheme.primary.withOpacity(0.06) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24.w,
                  child: Text(
                    dayLabels[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? theme.colorScheme.primary : null,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (isToday)
                  Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('TODAY', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 8.sp, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                const Spacer(),
                Flexible(child: Text(
                  hoursText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isOpen
                        ? (isToday ? theme.colorScheme.primary : Colors.black87)
                        : Colors.red,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(padding: EdgeInsets.only(bottom: 2.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 6.w, color: theme.colorScheme.primary), SizedBox(width: 3.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 0.5.h),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]));
  }

  Widget _buildEmptyProducts(ThemeData theme, bool canManage) {
    return Center(child: Padding(padding: EdgeInsets.fromLTRB(8.w, 8.w, 8.w, 12.h), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_bag_outlined, size: 80, color: theme.colorScheme.outline),
      SizedBox(height: 3.h),
      Text(AppLocalizations.of(context)!.noProductsAvailable, style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: 1.h),
      Text(_selectedCategoryId != null ? AppLocalizations.of(context)!.noProductsInThisCategory : 'This store hasn\'t added any products yet',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      if (canManage) ...[
        SizedBox(height: 3.h),
        ElevatedButton.icon(onPressed: _showCreateProductModal, icon: Icon(Icons.add), label: Text(AppLocalizations.of(context)!.addProduct2, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    ])));
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(child: Padding(padding: EdgeInsets.all(8.w), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
      SizedBox(height: 2.h),
      Text(AppLocalizations.of(context)!.somethingWentWrong, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error), maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: 1.h),
      Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      SizedBox(height: 3.h),
      ElevatedButton.icon(onPressed: _loadStoreData, icon: Icon(Icons.refresh), label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis)),
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