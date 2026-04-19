import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/store_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/store_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/animated_press_button.dart';
import '../../../widgets/shimmer_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Top Stores section on home screen.
///
/// UPDATED:
/// - Shows ALL active stores (not just featured) so newly created stores appear
/// - Featured stores appear first, then the rest sorted by rating
/// - Horizontal scrollable ListView carousel
/// - Admin edit mode (three dots) on all store cards
/// - FIX: Header row overflow resolved with Expanded wrapper
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
      final stores = await StoreService.getAllStores(
        activeOnly: true,
        excludeDemo: true,
      );

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
          // Header — FIX: Expanded on title to prevent overflow
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.topStores,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEditMode)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.useTheCreateButtonInAdmin, maxLines: 1, overflow: TextOverflow.ellipsis),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              color: theme.colorScheme.surface, size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            AppLocalizations.of(context)!.add2,
                            style: TextStyle(
                              color: theme.colorScheme.surface,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => AppRoutes.switchToTab(context, 3),
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  onPressed: _loadStores,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: AppLocalizations.of(context)!.refreshStores,
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: ShimmerProductRow(),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
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
                    AppLocalizations.of(context)!.failedToLoadStores,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          color:
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.store_outlined,
                size: 10.w, color: theme.colorScheme.outline),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.noStoresYet2,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Text(
              AppLocalizations.of(context)!.storesWillAppearHereOnceCreated,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresCarousel(ThemeData theme, bool isEditMode) {
    return SizedBox(
      height: 24.h,
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
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: store.imageUrl ??
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
                      fit: BoxFit.cover,
                      semanticLabel: 'Store front of ${store.name}',
                    ),
                    if (!store.isActive || !store.isAcceptingOrders)
                      Container(
                        color:
                            theme.colorScheme.surface.withOpacity(0.8),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.closedStatus,
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    if (store.isFeatured)
                      Positioned(
                        top: 1.h,
                        left: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            color: AppTheme.kjRed,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '\u2605 Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    if (store.rating > 0)
                      Positioned(
                        top: 1.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber, size: 3.w),
                              SizedBox(width: 1.w),
                              Flexible(child: Text(
                                store.ratingDisplay,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (store.category != null)
                      Text(
                        store.category!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 9.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 0.2.h),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 3.w,
                            color: theme.colorScheme.primary),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(
                            store.prepTimeDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 9.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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