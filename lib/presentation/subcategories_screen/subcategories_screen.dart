import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import '../../widgets/admin_editable_item_wrapper.dart';
import '../../widgets/custom_image_widget.dart';

class SubcategoriesScreen extends StatefulWidget {
  final dynamic parentCategoryId;
  final String parentCategoryName;

  const SubcategoriesScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final parentId = widget.parentCategoryId.toString();
      if (parentId.isEmpty) { setState(() { _all = []; _filtered = []; _isLoading = false; }); return; }

      final rows = await CategoryService.getSubcategories(parentId);
      if (!mounted) return;

      final enriched = <Map<String, dynamic>>[];
      for (final cat in rows) {
        bool hasChildren = false;
        try {
          final children = await CategoryService.getSubcategories(cat.id);
          hasChildren = children.isNotEmpty;
        } catch (_) {}
        enriched.add({
          'id': cat.id, 'name': cat.name, 'description': cat.description ?? '',
          'type': cat.type ?? '', 'image_url': cat.imageUrl ?? '',
          'has_children': hasChildren, 'is_active': cat.isActive,
        });
      }
      if (!mounted) return;
      setState(() { _all = enriched; _applySearch(); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = q.isEmpty ? List.from(_all) : _all.where((c) =>
      (c['name'] ?? '').toString().toLowerCase().contains(q) ||
      (c['description'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  void _onTap(Map<String, dynamic> sub) {
    final id = sub['id']?.toString() ?? '';
    final name = (sub['name'] ?? 'Category').toString();
    if (id.isEmpty) return;

    if (sub['has_children'] == true) {
      Navigator.pushNamed(context, AppRoutes.subcategoriesScreen, arguments: {
        'parentCategoryId': id, 'parentCategoryName': name,
      });
    } else {
      Navigator.pushNamed(context, AppRoutes.categoryStoresScreen, arguments: {
        'categoryId': id, 'categoryName': name,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentCategoryName),
        actions: [
          if (isEditMode) IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminSubcategories, arguments: {
              'parentCategoryId': widget.parentCategoryId.toString(),
              'parentCategoryName': widget.parentCategoryName,
            }),
            icon: const Icon(Icons.settings, color: Colors.orange), tooltip: 'Manage',
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(children: [
        // Search
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() => _applySearch()),
            decoration: InputDecoration(
              hintText: 'Search...', prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _applySearch()); }) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _error != null ? _buildError(theme)
              : _filtered.isEmpty ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 3.w, mainAxisSpacing: 2.h, childAspectRatio: 0.85),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final sub = _filtered[index];
                      final card = _buildSubcategoryCard(sub, theme);
                      if (isEditMode) {
                        return AdminEditableItemWrapper(
                          contentType: 'category', contentId: sub['id']?.toString(),
                          contentData: sub, onDeleted: _load, onUpdated: _load, child: card,
                        );
                      }
                      return card;
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> sub, ThemeData theme) {
    final name = (sub['name'] ?? '').toString();
    final imageUrl = (sub['image_url'] ?? '').toString();
    final hasImage = imageUrl.isNotEmpty;
    final hasChildren = sub['has_children'] == true;

    return GestureDetector(
      onTap: () => _onTap(sub),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            // FULL-BLEED IMAGE — name overlaid at bottom
            ? Stack(fit: StackFit.expand, children: [
                CustomImageWidget(imageUrl: imageUrl, fit: BoxFit.cover, semanticLabel: name),
                // Gradient overlay
                Positioned(bottom: 0, left: 0, right: 0, child: Container(
                  padding: EdgeInsets.fromLTRB(3.w, 4.h, 3.w, 2.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (hasChildren) ...[
                      SizedBox(height: 0.3.h),
                      Row(children: [
                        Icon(Icons.subdirectory_arrow_right, size: 3.w, color: Colors.white70),
                        SizedBox(width: 0.5.w),
                        Text('Has subcategories', style: TextStyle(color: Colors.white70, fontSize: 8.sp)),
                      ]),
                    ],
                  ]),
                )),
              ])
            // NO IMAGE FALLBACK
            : Container(
                color: theme.colorScheme.surface,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      child: Icon(Icons.category_outlined, size: 10.w, color: theme.colorScheme.primary.withOpacity(0.4)),
                    ),
                  ),
                  Expanded(flex: 2, child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (hasChildren) ...[
                        SizedBox(height: 0.5.h),
                        Row(children: [
                          Icon(Icons.subdirectory_arrow_right, size: 3.5.w, color: theme.colorScheme.primary),
                          SizedBox(width: 1.w),
                          Text('Has subcategories', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        ]),
                      ],
                    ]),
                  )),
                ]),
              ),
      ),
    );
  }

  Widget _buildError(ThemeData t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 48, color: t.colorScheme.error), SizedBox(height: 2.h),
    Text('Something went wrong', style: t.textTheme.titleMedium), SizedBox(height: 2.h),
    ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ]));

  Widget _buildEmpty(ThemeData t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.category_outlined, size: 64, color: t.colorScheme.outline), SizedBox(height: 2.h),
    Text('No subcategories found', style: t.textTheme.titleMedium),
  ]));
}