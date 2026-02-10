import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/store_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/store_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/animated_press_button.dart';

/// Top Stores section on home screen.
///
/// UPDATED:
/// - Shows ALL active stores (not just featured) so newly created stores appear
/// - Featured stores appear first, then the rest sorted by rating
/// - Horizontal scrollable ListView carousel
/// - Admin edit mode (three dots) on all store cards
class TopStoresWidget extends StatefulWidget {
  const TopStoresWidget({super.key});

  @override
  State<TopStoresWidget> createState() => _TopStoresWidgetState();
}

class _TopStoresWidgetState extends State<TopStoresWidget> {
  bool _isLoading = false;
  String? _error;
  List<Store> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch ALL active stores (not just featured)
      final stores = await StoreService.getAllStores(
        activeOnly: true,
        excludeDemo: true,
      );

      // Sort: featured first, then by rating descending
      stores.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.rating.compareTo(a.rating);
      });

      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[TOP_STORES_WIDGET] Error loading stores: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Stores',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isEditMode)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use the Create button in Admin bar to add stores'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => AppRoutes.switchToTab(context, 3),
                  child: Text(
                    'See All',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadStores,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh stores',
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState(theme)
          else if (_stores.isEmpty)
            _buildEmptyState(theme)
          else
            _buildStoresCarousel(theme, isEditMode),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Failed to load stores',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadStores,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 10.w, color: theme.colorScheme.outline),
            SizedBox(height: 1.h),
            Text(
              'No stores yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Stores will appear here once created',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal scrollable ListView carousel
  Widget _buildStoresCarousel(ThemeData theme, bool isEditMode) {
    return SizedBox(
      height: 22.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _stores.length,
        separatorBuilder: (_, __) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final store = _stores[index];
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
    );
  }

  Widget _buildStoreCard(Store store, ThemeData theme) {
    return AnimatedPressButton(
      onPressed: () => _navigateToStore(store),
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: store.imageUrl ??
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                      fit: BoxFit.cover,
                      semanticLabel: 'Store front of ${store.name}',
                    ),
                    // Closed overlay
                    if (!store.isActive || !store.isAcceptingOrders)
                      Container(
                        color: theme.colorScheme.surface.withOpacity(0.8),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Closed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Featured badge
                    if (store.isFeatured)
                      Positioned(
                        top: 1.h,
                        left: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            color: AppTheme.kjRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '★ Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Rating badge
                    if (store.rating > 0)
                      Positioned(
                        top: 1.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 3.w),
                              SizedBox(width: 1.w),
                              Text(
                                store.ratingDisplay,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Store Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.3.h),
                    if (store.category != null)
                      Text(
                        store.category!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 3.w, color: theme.colorScheme.primary),
                        SizedBox(width: 1.w),
                        Text(
                          store.prepTimeDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}