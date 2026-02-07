import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/store_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/store_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/animated_press_button.dart';

class TopStoresWidget extends StatefulWidget {
  const TopStoresWidget({super.key});

  @override
  State<TopStoresWidget> createState() => _TopStoresWidgetState();
}

class _TopStoresWidgetState extends State<TopStoresWidget> {
  bool _isLoading = false;
  String? _error;
  List<Store> _stores = [];
  final PageController _pageController = PageController(viewportFraction: 0.33);
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTopStores();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTopStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stores = await StoreService.getFeaturedStores(limit: 20);
      
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
      AppRoutes.merchantStore,
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
                          content: Text('Navigate to store creation'),
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
                IconButton(
                  onPressed: _loadTopStores,
                  icon: const Icon(Icons.refresh),
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
              onPressed: _loadTopStores,
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
            Icon(
              Icons.store_outlined,
              size: 10.w,
              color: theme.colorScheme.outline,
            ),
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

  Widget _buildStoresCarousel(ThemeData theme, bool isEditMode) {
    return SizedBox(
      height: 22.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _stores.length,
        itemBuilder: (context, index) {
          final store = _stores[index];
          final storeCard = _buildStoreCard(store, theme, index);

          if (isEditMode) {
            return AdminEditableItemWrapper(
              contentType: 'store',
              contentId: store.id,
              contentData: store.toMap(),
              onDeleted: _loadTopStores,
              onUpdated: _loadTopStores,
              child: storeCard,
            );
          }

          return storeCard;
        },
      ),
    );
  }

  Widget _buildStoreCard(Store store, ThemeData theme, int index) {
    // Calculate scale based on position
    final double distanceFromCenter = (_currentPage - index).abs();
    final double scale = 1.0 - (distanceFromCenter * 0.15).clamp(0.0, 0.15);

    return AnimatedPressButton(
      onPressed: () => _navigateToStore(store),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: scale, end: scale),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
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
                      if (!store.isActive || !store.isAcceptingOrders)
                        Container(
                          color: theme.colorScheme.surface.withOpacity(0.8),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
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
                      // Rating badge
                      if (store.rating > 0)
                        Positioned(
                          top: 1.h,
                          right: 2.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 3.w,
                                ),
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
                  padding: EdgeInsets.all(3.w),
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
                      SizedBox(height: 0.5.h),
                      if (store.category != null)
                        Text(
                          store.category!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 3.w,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            store.prepTimeDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}