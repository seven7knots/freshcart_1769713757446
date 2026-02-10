import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/category_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/category_service.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/custom_image_widget.dart';

class CategoriesWidget extends StatefulWidget {
  const CategoriesWidget({super.key});

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];
  String? _marketplaceImageUrl;

  @override
  void initState() {
    super.initState();
    _loadRootCategories();
    _loadMarketplaceImage();
  }

  Future<void> _loadRootCategories() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final categories = await CategoryService.getTopLevelCategories();
      if (mounted) setState(() { _categories = categories; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  /// Load marketplace cover image from Supabase storage or app_config table
  Future<void> _loadMarketplaceImage() async {
    try {
      // Strategy 1: Check app_config table for marketplace_image_url
      final configRow = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'marketplace_image_url')
          .maybeSingle();
      if (configRow != null && configRow['value'] != null) {
        if (mounted) setState(() => _marketplaceImageUrl = configRow['value'] as String);
        return;
      }
    } catch (_) {
      // app_config table may not exist — that's ok
    }

    try {
      // Strategy 2: Check if a known file exists in storage
      final url = SupabaseService.client.storage
          .from('uploads')
          .getPublicUrl('marketplace/cover.jpg');
      if (url.isNotEmpty) {
        if (mounted) setState(() => _marketplaceImageUrl = url);
      }
    } catch (_) {}
  }

  /// Save marketplace image URL to app_config (or just storage)
  Future<void> _saveMarketplaceImageUrl(String url) async {
    try {
      await SupabaseService.client.from('app_config').upsert({
        'key': 'marketplace_image_url',
        'value': url,
      }, onConflict: 'key');
    } catch (_) {
      // app_config may not exist — image still works from storage URL
    }
  }

  Future<void> _onCategoryTap(Category category) async {
    final hasSubcats = await CategoryService.hasSubcategories(category.id);
    if (!mounted) return;
    if (hasSubcats) {
      Navigator.pushNamed(context, AppRoutes.subcategoriesScreen, arguments: {
        'parentCategoryId': category.id, 'parentCategoryName': category.name,
      });
    } else {
      Navigator.pushNamed(context, AppRoutes.categoryStoresScreen, arguments: {
        'categoryId': category.id, 'categoryName': category.name,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
          child: Row(children: [
            Expanded(child: Text('Categories', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            if (isEditMode) _adminButton('Manage', Icons.settings, () => Navigator.pushNamed(context, AppRoutes.adminCategories)),
            IconButton(onPressed: _loadRootCategories, icon: const Icon(Icons.refresh, size: 20)),
          ]),
        ),
        if (_isLoading)
          Padding(padding: EdgeInsets.all(4.w), child: const Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Padding(padding: EdgeInsets.symmetric(horizontal: 4.w), child: Row(children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
            SizedBox(width: 2.w),
            Expanded(child: Text('Failed to load', style: theme.textTheme.bodySmall)),
            IconButton(onPressed: _loadRootCategories, icon: const Icon(Icons.refresh, size: 18)),
          ]))
        else if (_categories.isEmpty)
          Padding(padding: EdgeInsets.all(4.w), child: Center(child: Text('No categories yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))))
        else
          _buildCarousel(theme, isEditMode),
      ]),
    );
  }

  Widget _adminButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 14), SizedBox(width: 1.w),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildCarousel(ThemeData theme, bool isEditMode) {
    return SizedBox(
      height: 14.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _categories.length + 1, // +1 for marketplace
        itemBuilder: (context, index) {
          if (index == 0) return Padding(padding: EdgeInsets.only(right: 2.5.w), child: _buildMarketplaceCard(theme, isEditMode));
          final cat = _categories[index - 1];
          final card = _buildCategoryCard(cat, theme);
          final padded = Padding(padding: EdgeInsets.only(right: 2.5.w), child: card);
          if (isEditMode) {
            return Padding(
              padding: EdgeInsets.only(right: 2.5.w),
              child: AdminEditableItemWrapper(
                contentType: 'category', contentId: cat.id, contentData: cat.toMap(),
                onDeleted: _loadRootCategories, onUpdated: _loadRootCategories, child: card,
              ),
            );
          }
          return padded;
        },
      ),
    );
  }

  // ============================================================
  // MARKETPLACE CARD — supports full-bleed image + red binding box
  // Admin gets a direct "change image" button (no AdminEditableItemWrapper)
  // ============================================================

  Widget _buildMarketplaceCard(ThemeData theme, bool isEditMode) {
    final hasImage = _marketplaceImageUrl != null && _marketplaceImageUrl!.isNotEmpty;

    final card = GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.marketplaceScreen),
      child: Container(
        width: 22.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.kjRed, width: 2.5),
          boxShadow: [BoxShadow(color: AppTheme.kjRed.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                CustomImageWidget(imageUrl: _marketplaceImageUrl!, fit: BoxFit.cover, semanticLabel: 'Marketplace'),
                Positioned(bottom: 0, left: 0, right: 0, child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.kjRed.withOpacity(0.85)]),
                  ),
                  child: Text('Marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9.sp),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ])
            : Container(
                color: AppTheme.kjRed.withOpacity(0.08),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.storefront, color: AppTheme.kjRed, size: 8.w),
                  SizedBox(height: 0.8.h),
                  Text('Marketplace', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.kjRed, fontSize: 9.sp),
                    textAlign: TextAlign.center),
                ]),
              ),
      ),
    );

    // In admin edit mode, wrap with a camera button overlay for image upload
    if (isEditMode) {
      return Stack(clipBehavior: Clip.none, children: [
        card,
        Positioned(
          top: -4, right: -4,
          child: GestureDetector(
            onTap: _pickMarketplaceImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.kjRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ),
        ),
      ]);
    }
    return card;
  }

  /// Pick and upload marketplace cover image, save URL to app_config
  Future<void> _pickMarketplaceImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (img == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading marketplace image...'), duration: Duration(seconds: 2)),
      );

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final bytes = await img.readAsBytes();
      final ext = img.path.split('.').last.toLowerCase();
      String mimeType;
      switch (ext) {
        case 'jpg': case 'jpeg': mimeType = 'image/jpeg';
        case 'png': mimeType = 'image/png';
        case 'gif': mimeType = 'image/gif';
        case 'webp': mimeType = 'image/webp';
        default: mimeType = 'image/jpeg';
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = 'marketplace/cover_$ts.$ext';

      await SupabaseService.client.storage.from('uploads').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(upsert: true, contentType: mimeType),
      );

      final publicUrl = SupabaseService.client.storage.from('uploads').getPublicUrl(path);

      // Save to app_config
      await SupabaseService.client.from('app_config').upsert({
        'key': 'marketplace_image_url',
        'value': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');

      if (mounted) {
        setState(() => _marketplaceImageUrl = publicUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marketplace image updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // REGULAR CATEGORY CARD — full-bleed image or icon fallback
  // ============================================================

  Widget _buildCategoryCard(Category category, ThemeData theme) {
    final hasImage = category.imageUrl != null && category.imageUrl!.isNotEmpty;
    final color = _colorFor(category.type, theme);

    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        width: 22.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            // IMAGE FILLS ENTIRE CARD — name overlaid at bottom
            ? Stack(fit: StackFit.expand, children: [
                CustomImageWidget(imageUrl: category.imageUrl!, fit: BoxFit.cover, semanticLabel: category.name),
                Positioned(bottom: 0, left: 0, right: 0, child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
                  ),
                  child: Text(category.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9.sp),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                )),
              ])
            // FALLBACK: icon + name (no image uploaded)
            : Container(
                color: color.withOpacity(0.06),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_iconFor(category.icon), color: color, size: 7.w),
                  SizedBox(height: 0.8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: Text(category.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9.sp, color: theme.colorScheme.onSurface),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
      ),
    );
  }

  IconData _iconFor(String? n) {
    switch (n?.toLowerCase()) {
      case 'restaurant': case 'food': return Icons.restaurant;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'grocery': return Icons.local_grocery_store;
      case 'shopping': return Icons.shopping_bag;
      case 'coffee': return Icons.coffee;
      case 'electronics': return Icons.devices;
      case 'fashion': return Icons.checkroom;
      case 'services': return Icons.handyman;
      case 'beauty': return Icons.spa;
      case 'pets': return Icons.pets;
      default: return Icons.category;
    }
  }

  Color _colorFor(String? t, ThemeData theme) {
    switch (t?.toLowerCase()) {
      case 'food': case 'restaurant': return Colors.orange;
      case 'grocery': return Colors.green;
      case 'pharmacy': return Colors.red;
      case 'retail': return Colors.blue;
      case 'services': return Colors.purple;
      default: return theme.colorScheme.primary;
    }
  }
}