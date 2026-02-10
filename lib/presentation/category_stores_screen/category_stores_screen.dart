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

/// Shows stores belonging to a specific category or subcategory.
///
/// This is the correct destination when a user taps:
///   Category → Subcategory → [this screen shows stores]
///   Tapping a store → StoreDetailScreen (with products)
///
/// Accepts arguments:
///   - String categoryId (required)
///   - String? categoryName (optional, for AppBar title)
class CategoryStoresScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryStoresScreen({
    super.key,
    required this.categoryId,
    this.categoryName = 'Stores',
  });

  @override
  State<CategoryStoresScreen> createState() => _CategoryStoresScreenState();
}

class _CategoryStoresScreenState extends State<CategoryStoresScreen> {
  bool _isLoading = false;
  String? _error;
  List<Store> _stores = [];
  final TextEditingController _searchCtrl = TextEditingController();
  List<Store> _filtered = [];

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
      List<Store> stores;

      if (widget.categoryId == 'all' || widget.categoryId.isEmpty) {
        // Load all stores
        stores = await StoreService.getAllStores(activeOnly: true, excludeDemo: true);
      } else {
        // Try category_id FK first
        stores = await StoreService.getStoresByCategoryId(
          widget.categoryId,
          activeOnly: true,
          excludeDemo: true,
        );

        // If no results, also try subcategory_id
        if (stores.isEmpty) {
          try {
            final response = await StoreService.getStoresBySubcategoryId(
              widget.categoryId,
              activeOnly: true,
              excludeDemo: true,
            );
            stores = response;
          } catch (_) {
            // subcategory query not supported, ignore
          }
        }

        // If still no results, try legacy category string match
        if (stores.isEmpty) {
          try {
            stores = await StoreService.getStoresByCategory(
              widget.categoryId,
              activeOnly: true,
              excludeDemo: true,
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _stores = stores;
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CATEGORY_STORES] Error: $e');
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_stores);
    } else {
      _filtered = _stores.where((s) {
        return s.name.toLowerCase().contains(q) ||
            (s.category?.toLowerCase().contains(q) ?? false) ||
            (s.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  void _navigateToStore(Store store) {
    Navigator.pushNamed(
      context,
      AppRoutes.storeDetail,
      arguments: {'storeId': store.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            onPressed: _loadStores,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() => _applySearch()),
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _applySearch());
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(theme)
                    : _filtered.isEmpty
                        ? _buildEmpty(theme)
                        : RefreshIndicator(
                            onRefresh: _loadStores,
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => SizedBox(height: 2.h),
                              itemBuilder: (context, index) {
                                final store = _filtered[index];
                                final card = _buildStoreCard(store, theme);
                                if (isEditMode) {
                                  return AdminEditableItemWrapper(
                                    contentType: 'store',
                                    contentId: store.id,
                                    contentData: store.toMap(),
                                    onDeleted: _loadStores,
                                    onUpdated: _loadStores,
                                    child: card,
                                  );
                                }
                                return card;
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Store store, ThemeData theme) {
    return GestureDetector(
      onTap: () => _navigateToStore(store),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  CustomImageWidget(
                    imageUrl: store.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                    width: double.infinity,
                    height: 18.h,
                    fit: BoxFit.cover,
                    semanticLabel: 'Store: ${store.name}',
                  ),
                  // Status overlays
                  if (!store.isActive || !store.isAcceptingOrders)
                    Positioned.fill(
                      child: Container(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
                            child: Text('Closed', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onError, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  // Rating
                  if (store.rating > 0)
                    Positioned(
                      top: 1.h, right: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star, color: Colors.amber, size: 4.w),
                          SizedBox(width: 1.w),
                          Text(store.ratingDisplay, style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  // Featured
                  if (store.isFeatured)
                    Positioned(
                      top: 1.h, left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(color: AppTheme.kjRed, borderRadius: BorderRadius.circular(8)),
                        child: Text('★ Featured', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  if (store.description != null && store.description!.isNotEmpty)
                    Text(store.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      if (store.category != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(store.category!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      Icon(Icons.access_time, size: 3.5.w, color: theme.colorScheme.onSurfaceVariant),
                      SizedBox(width: 1.w),
                      Text(store.prepTimeDisplay, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if ((store.minimumOrder ?? 0) > 0) ...[
                        SizedBox(width: 3.w),
                        Icon(Icons.shopping_bag_outlined, size: 3.5.w, color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: 1.w),
                        Text('Min \$${(store.minimumOrder ?? 0).toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(child: Padding(padding: EdgeInsets.all(4.w), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        SizedBox(height: 2.h),
        Text('Failed to load stores', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 1.h),
        Text(_error ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 3),
        SizedBox(height: 2.h),
        ElevatedButton.icon(onPressed: _loadStores, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    )));
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(child: Padding(padding: EdgeInsets.all(4.w), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.store_outlined, size: 64, color: theme.colorScheme.outline),
        SizedBox(height: 2.h),
        Text('No stores in this category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 1.h),
        Text('Stores assigned to this category will appear here.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        SizedBox(height: 2.h),
        OutlinedButton.icon(onPressed: _loadStores, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
      ],
    )));
  }
}