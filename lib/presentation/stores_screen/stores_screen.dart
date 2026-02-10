import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/store_model.dart';
import '../../providers/admin_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/store_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_editable_item_wrapper.dart';
import '../../widgets/custom_image_widget.dart';

/// Stores screen — shown when pressing the Stores tab in the bottom bar.
/// Displays all active stores with search, category filter, and admin edit.
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  bool _isLoading = false;
  String? _error;
  List<Store> _stores = [];
  List<Store> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stores = await StoreService.getAllStores(activeOnly: false, excludeDemo: true);
      if (mounted) setState(() { _stores = stores; _applyFilters(); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilters() {
    var list = List<Store>.from(_stores);
    // Type filter
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      list = list.where((s) => s.category?.toLowerCase() == _selectedType!.toLowerCase()).toList();
    }
    // Search filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) =>
        s.name.toLowerCase().contains(q) ||
        (s.category?.toLowerCase().contains(q) ?? false) ||
        (s.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    _filtered = list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;
    final isAdmin = adminProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores'),
        automaticallyImplyLeading: false,
        actions: [
          if (isAdmin) ...[
            if (isEditMode)
              TextButton.icon(
                onPressed: () => adminProvider.setEditMode(false),
                icon: const Icon(Icons.check, color: Colors.green, size: 18),
                label: Text('Done', style: TextStyle(color: Colors.green, fontSize: 11.sp)),
              )
            else
              IconButton(
                onPressed: () => adminProvider.setEditMode(true),
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'Enable edit mode',
              ),
          ],
          IconButton(onPressed: _loadStores, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: Column(children: [
        // Search
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() => _applyFilters()),
            decoration: InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _applyFilters()); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        // Category type filter chips
        SizedBox(
          height: 5.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            children: [
              _buildFilterChip(theme, null, 'All'),
              ..._getAvailableTypes().map((t) => _buildFilterChip(theme, t, _capitalize(t))),
            ],
          ),
        ),
        // Store count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
          child: Row(children: [
            Text('${_filtered.length} stores', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            if (isEditMode)
              Text('Edit mode ON', style: TextStyle(color: Colors.orange, fontSize: 10.sp, fontWeight: FontWeight.w600)),
          ]),
        ),
        // Stores list
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _error != null ? _buildError(theme)
              : _filtered.isEmpty ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _loadStores,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 3.h),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final store = _filtered[index];
                      final card = _buildStoreCard(store, theme);
                      if (isEditMode) {
                        return AdminEditableItemWrapper(
                          contentType: 'store', contentId: store.id,
                          contentData: store.toMap(),
                          onDeleted: _loadStores, onUpdated: _loadStores, child: card,
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

  List<String> _getAvailableTypes() {
    final types = _stores.map((s) => s.category).where((c) => c != null && c.isNotEmpty).toSet().toList();
    types.sort();
    return types.cast<String>();
  }

  Widget _buildFilterChip(ThemeData theme, String? type, String label) {
    final selected = _selectedType == type;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() { _selectedType = type; _applyFilters(); }),
        selectedColor: theme.colorScheme.primary.withOpacity(0.15),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _buildStoreCard(Store store, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.storeDetail, arguments: {'storeId': store.id}),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 28.w, height: 14.h,
              child: Stack(children: [
                Positioned.fill(
                  child: CustomImageWidget(
                    imageUrl: store.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                    fit: BoxFit.cover, semanticLabel: store.name,
                  ),
                ),
                if (!store.isActive)
                  Positioned.fill(child: Container(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    child: Center(child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                      child: Text('Inactive', style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w600)),
                    )),
                  )),
                if (store.isFeatured)
                  Positioned(top: 4, left: 4, child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                    decoration: BoxDecoration(color: AppTheme.kjRed, borderRadius: BorderRadius.circular(6)),
                    child: Text('★', style: TextStyle(color: Colors.white, fontSize: 8.sp)),
                  )),
              ]),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                if (store.category != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(store.category!, style: TextStyle(color: theme.colorScheme.primary, fontSize: 9.sp, fontWeight: FontWeight.w500)),
                  ),
                SizedBox(height: 0.5.h),
                if (store.description != null)
                  Text(store.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Row(children: [
                  if (store.rating > 0) ...[
                    Icon(Icons.star, color: Colors.amber, size: 3.5.w),
                    SizedBox(width: 0.5.w),
                    Text(store.ratingDisplay, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600)),
                    SizedBox(width: 2.w),
                  ],
                  Icon(Icons.access_time, size: 3.w, color: theme.colorScheme.onSurfaceVariant),
                  SizedBox(width: 0.5.w),
                  Text(store.prepTimeDisplay, style: TextStyle(fontSize: 9.sp, color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ]),
            ),
          ),
          // Arrow
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }

  Widget _buildError(ThemeData t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 48, color: t.colorScheme.error), SizedBox(height: 2.h),
    Text('Failed to load stores', style: t.textTheme.titleMedium), SizedBox(height: 2.h),
    ElevatedButton.icon(onPressed: _loadStores, icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ]));

  Widget _buildEmpty(ThemeData t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.store_outlined, size: 64, color: t.colorScheme.outline), SizedBox(height: 2.h),
    Text('No stores found', style: t.textTheme.titleMedium), SizedBox(height: 1.h),
    Text('Stores will appear here once created', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
  ]));
}