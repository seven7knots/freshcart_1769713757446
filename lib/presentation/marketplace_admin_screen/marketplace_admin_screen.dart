
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/marketplace_category_model.dart';
import '../../services/marketplace_category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class MarketplaceAdminScreen extends StatefulWidget {
  const MarketplaceAdminScreen({super.key});

  @override
  State<MarketplaceAdminScreen> createState() => _MarketplaceAdminScreenState();
}

class _MarketplaceAdminScreenState extends State<MarketplaceAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.marketplaceAdmin,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.kjRed,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.kjRed,
          tabs: [
            Tab(icon: Icon(Icons.campaign), text: AppLocalizations.of(context)!.adBanner),
            Tab(icon: Icon(Icons.category), text: AppLocalizations.of(context)!.categories),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdBannerManagementTab(),
          _CategoriesCrudTab(),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: Ad Banner Management (unchanged from before)
// ============================================================

class _AdBannerManagementTab extends StatefulWidget {
  const _AdBannerManagementTab();

  @override
  State<_AdBannerManagementTab> createState() => _AdBannerManagementTabState();
}

class _AdBannerManagementTabState extends State<_AdBannerManagementTab> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('app_config')
          .select('key, value')
          .inFilter('key', [
        'marketplace_ad_image_url',
        'marketplace_ad_title',
        'marketplace_ad_subtitle',
      ]);

      final configs = Map<String, String>.fromEntries(
        (response as List).map((row) =>
            MapEntry(row['key'] as String, row['value'] as String? ?? '')),
      );

      if (mounted) {
        setState(() {
          _currentImageUrl = configs['marketplace_ad_image_url']?.isNotEmpty == true
              ? configs['marketplace_ad_image_url']
              : null;
          if (configs['marketplace_ad_title']?.isNotEmpty == true) {
            _titleController.text = configs['marketplace_ad_title']!;
          }
          if (configs['marketplace_ad_subtitle']?.isNotEmpty == true) {
            _subtitleController.text = configs['marketplace_ad_subtitle']!;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final client = Supabase.instance.client;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          'marketplace_ad/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('uploads').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      final publicUrl = client.storage.from('uploads').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _currentImageUrl = publicUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      final now = DateTime.now().toIso8601String();

      final entries = {
        'marketplace_ad_image_url': _currentImageUrl ?? '',
        'marketplace_ad_title': _titleController.text.trim(),
        'marketplace_ad_subtitle': _subtitleController.text.trim(),
      };

      for (final entry in entries.entries) {
        await client.from('app_config').upsert({
          'key': entry.key,
          'value': entry.value,
          'updated_at': now,
        }, onConflict: 'key');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.marketplaceAdUpdated, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = AppTheme.kjRed;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(AppLocalizations.of(context)!.adBannerPreview,
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Container(
          height: 18.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.w),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.w),
            child: Stack(
              children: [
                if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                  CustomImageWidget(
                      imageUrl: _currentImageUrl!,
                      width: double.infinity,
                      height: 18.h,
                      fit: BoxFit.cover,
                      semanticLabel: AppLocalizations.of(context)!.adPreview)
                else
                  Container(
                      width: double.infinity,
                      height: 18.h,
                      color: theme.colorScheme.outlineVariant,
                      child: Icon(Icons.image, size: 12.w, color: theme.colorScheme.onSurfaceVariant)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2.h,
                  left: 4.w,
                  right: 4.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _titleController.text.isNotEmpty
                              ? _titleController.text
                              : 'Ad Title',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.surface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Text(
                          _subtitleController.text.isNotEmpty
                              ? _subtitleController.text
                              : AppLocalizations.of(context)!.adSubtitle,
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: _isUploadingImage ? null : _pickAndUploadImage,
          icon: _isUploadingImage
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.image),
          label: Text(_isUploadingImage ? AppLocalizations.of(context)!.uploading : AppLocalizations.of(context)!.changeImage, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryRed,
            side: BorderSide(color: primaryRed),
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
          ),
        ),
        SizedBox(height: 3.h),
        _buildField(AppLocalizations.of(context)!.adTitle, _titleController, AppLocalizations.of(context)!.specialOffersThisWeek,
            theme, isDark),
        SizedBox(height: 2.h),
        _buildField(AppLocalizations.of(context)!.adSubtitle2, _subtitleController,
            'Up to 50% off on selected items', theme, isDark),
        SizedBox(height: 3.h),
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w)),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.surface))
                : Text(AppLocalizations.of(context)!.saveAdBanner,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 0.5.h),
        TextField(
          controller: controller,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TAB 2: Categories CRUD
// ============================================================

class _CategoriesCrudTab extends StatefulWidget {
  const _CategoriesCrudTab();

  @override
  State<_CategoriesCrudTab> createState() => _CategoriesCrudTabState();
}

class _CategoriesCrudTabState extends State<_CategoriesCrudTab> {
  final _service = MarketplaceCategoryService();
  List<MarketplaceCategoryModel> _categories = [];
  bool _isLoading = true;
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await _service.getCategories(activeOnly: false);
      if (mounted) setState(() { _categories = cats; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _isSavingOrder = true);
    try {
      await _service.reorderCategories(_categories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.orderSaved, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving order: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    } finally {
      if (mounted) setState(() => _isSavingOrder = false);
    }
  }

  Future<void> _toggleActive(MarketplaceCategoryModel cat) async {
    try {
      await _service.toggleActive(cat.id, !cat.isActive);
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    }
  }

  Future<void> _togglePrimary(MarketplaceCategoryModel cat) async {
    try {
      await _service.updateCategory(cat.id, {'is_primary': !cat.isPrimary});
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    }
  }

  Future<void> _deleteCategory(MarketplaceCategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
            'Delete "${cat.name}"? Existing listings with this category will NOT be removed, but users won\'t be able to filter by it.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteCategory(cat.id);
        await _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      }
    }
  }

  Future<void> _showAddEditDialog({MarketplaceCategoryModel? existing}) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final iconController =
        TextEditingController(text: existing?.icon ?? 'category');
    bool isPrimary = existing?.isPrimary ?? false;
    final isNew = existing == null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: Text(isNew ? AppLocalizations.of(context)!.addCategory2 : AppLocalizations.of(context)!.editCategory2, maxLines: 1, overflow: TextOverflow.ellipsis),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew) ...[
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.idLowercaseNoSpaces,
                          hintText: AppLocalizations.of(context)!.eGGardenTools2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                    ],
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.displayName,
                        hintText: AppLocalizations.of(context)!.eGGardenTools,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: iconController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.iconName,
                        hintText: AppLocalizations.of(context)!.eGYardBuildPalette,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.primaryShowOnHomeRow, maxLines: 1, overflow: TextOverflow.ellipsis),
                      value: isPrimary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) =>
                          setDialogState(() => isPrimary = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kjRed,
                      foregroundColor: Colors.white),
                  child: Text(isNew ? AppLocalizations.of(context)!.add2 : AppLocalizations.of(context)!.save2, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        if (isNew) {
          final id = idController.text.trim().toLowerCase().replaceAll(' ', '_');
          if (id.isEmpty || nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.idAndNameAreRequired, maxLines: 1, overflow: TextOverflow.ellipsis)));
            return;
          }
          await _service.addCategory(
            id: id,
            name: nameController.text.trim(),
            icon: iconController.text.trim(),
            sortOrder: _categories.length + 1,
            isPrimary: isPrimary,
          );
        } else {
          await _service.updateCategory(existing.id, {
            'name': nameController.text.trim(),
            'icon': iconController.text.trim(),
            'is_primary': isPrimary,
          });
        }
        await _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      }
    }
  }

  /// Map icon name string to IconData
  IconData _getIconData(String iconName) {
    const map = <String, IconData>{
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'phone_android': Icons.phone_android,
      'tv': Icons.tv,
      'chair': Icons.chair,
      'business_center': Icons.business_center,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'sports_soccer': Icons.sports_soccer,
      'palette': Icons.palette,
      'work': Icons.work,
      'checkroom': Icons.checkroom,
      'handyman': Icons.handyman,
      'category': Icons.category,
      'yard': Icons.yard,
      'build': Icons.build,
      'spa': Icons.spa,
      'restaurant': Icons.restaurant,
      'local_grocery_store': Icons.local_grocery_store,
      'local_pharmacy': Icons.local_pharmacy,
      'devices': Icons.devices,
      'apartment': Icons.apartment,
      'shopping_bag': Icons.shopping_bag,
      'fastfood': Icons.fastfood,
      'coffee': Icons.coffee,
      'cake': Icons.cake,
      'sports': Icons.sports,
      'fitness_center': Icons.fitness_center,
      'music_note': Icons.music_note,
      'book': Icons.book,
      'camera': Icons.camera,
      'car_repair': Icons.car_repair,
      'construction': Icons.construction,
      'electrical_services': Icons.electrical_services,
      'plumbing': Icons.plumbing,
      'cleaning_services': Icons.cleaning_services,
    };
    return map[iconName.toLowerCase()] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryRed = AppTheme.kjRed;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Action bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Flexible(child: Text(
                '${_categories.length} categories',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Spacer(),
              if (_isSavingOrder)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                TextButton.icon(
                  onPressed: _saveOrder,
                  icon: Icon(Icons.save, size: 5.w, color: primaryRed),
                  label: Text(AppLocalizations.of(context)!.saveOrder,
                      style: TextStyle(color: primaryRed, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              SizedBox(width: 2.w),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.add, style: TextStyle(fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
            ],
          ),
        ),

        // Info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              children: [
                Icon(Icons.drag_handle, size: 5.w, color: primaryRed),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Long-press and drag to reorder. Tap "Save Order" to persist.',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1.h),

        // Reorderable list
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _categories.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _categories.removeAt(oldIndex);
                _categories.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildCategoryRow(cat, index, theme, primaryRed);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    MarketplaceCategoryModel cat,
    int index,
    ThemeData theme,
    Color primaryRed,
  ) {
    return Container(
      key: ValueKey(cat.id),
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.w),
      decoration: BoxDecoration(
        color: cat.isActive
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cat.isActive
              ? theme.colorScheme.outline.withOpacity(0.1)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(Icons.drag_handle,
              size: 5.w, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 2.w),

          // Icon circle
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: cat.isActive
                  ? primaryRed.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(cat.icon),
              size: 5.w,
              color: cat.isActive ? primaryRed : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 3.w),

          // Name + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: cat.isActive
                        ? theme.textTheme.bodyLarge?.color
                        : Colors.grey,
                    decoration:
                        cat.isActive ? null : TextDecoration.lineThrough,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text('ID: ${cat.id}',
                        style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(width: 2.w),
                    if (cat.isPrimary)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w, vertical: 0.2.h),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Primary',
                            style: TextStyle(
                                fontSize: 8.sp,
                                color: primaryRed,
                                fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 5.w, color: Colors.grey),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showAddEditDialog(existing: cat);
                  break;
                case 'toggle_active':
                  _toggleActive(cat);
                  break;
                case 'toggle_primary':
                  _togglePrimary(cat);
                  break;
                case 'delete':
                  _deleteCategory(cat);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_active',
                child: Row(
                  children: [
                    Icon(
                        cat.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(cat.isActive ? 'Deactivate' : 'Activate', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_primary',
                child: Row(
                  children: [
                    Icon(cat.isPrimary ? Icons.star_border : Icons.star,
                        size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(cat.isPrimary
                        ? 'Remove from Home'
                        : 'Show on Home', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}