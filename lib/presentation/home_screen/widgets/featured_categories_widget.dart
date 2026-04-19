import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/category_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/category_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/shimmer_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

class FeaturedCategoriesWidget extends StatefulWidget {
  const FeaturedCategoriesWidget({super.key});

  @override
  State<FeaturedCategoriesWidget> createState() =>
      _FeaturedCategoriesWidgetState();
}

class _FeaturedCategoriesWidgetState extends State<FeaturedCategoriesWidget> {
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];

  static const List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1667988672217-10a31d5cca30',
    'https://images.unsplash.com/photo-1558475890-1ebfc06edcf5',
    'https://images.unsplash.com/photo-1580980906245-af3b357dcc84',
    'https://images.unsplash.com/photo-1596662850405-75dafe9a0338',
    'https://images.unsplash.com/photo-1570384182225-e00c5765cd01',
    'https://images.unsplash.com/photo-1676159434936-9c19c551d262',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await CategoryService.getTopLevelCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[FEATURED_CATEGORIES] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — FIX: wrap left column in Expanded, right buttons stay min-size
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.shopByCategory,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        AppLocalizations.of(context)!.findEverythingYouNeed,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isEditMode)
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.adminCategories),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.5.h),
                      margin: EdgeInsets.only(right: 1.w),
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
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.allCategoriesScreen,
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Horizontal scrolling cards
          SizedBox(
            height: 28.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final categoryCard =
                    _buildCategoryCard(context, category, index);

                if (isEditMode) {
                  return AdminEditableItemWrapper(
                    contentType: 'category',
                    contentId: category.id,
                    contentData: category.toMap(),
                    onDeleted: _loadCategories,
                    onUpdated: _loadCategories,
                    child: categoryCard,
                  );
                }

                return categoryCard;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: const ShimmerProductRow(),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, Category category, int index) {
    final theme = Theme.of(context);

    final imageUrl =
        category.imageUrl ?? _fallbackImages[index % _fallbackImages.length];

    final cardColor = _getColorForType(category.type);

    return GestureDetector(
      onTap: () => _handleCategoryTap(context, category),
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  semanticLabel: '${category.name} category image',
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 3.w,
                left: 3.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    (category.type ?? 'General').toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 4.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null &&
                        category.description!.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        category.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.surface.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (category.storeCount > 0) ...[
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Icon(
                            Icons.store,
                            color: Colors.white.withOpacity(0.8),
                            size: 3.5.w,
                          ),
                          SizedBox(width: 1.w),
                          Flexible(child: Text(
                            '${category.storeCount} stores',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCategoryTap(
      BuildContext context, Category category) async {
    final hasSubcats =
        await CategoryService.hasSubcategories(category.id);

    if (!mounted) return;

    if (hasSubcats) {
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': category.id,
          'parentCategoryName': category.name,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.categoryListingsScreen,
        arguments: category.id,
      );
    }
  }

  Color _getColorForType(String? type) {
    if (type == null || type.isEmpty) return Colors.blue;

    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Colors.orange;
      case 'grocery':
        return Colors.green;
      case 'pharmacy':
        return Colors.red;
      case 'retail':
      case 'shopping':
        return Colors.blue;
      case 'services':
        return Colors.purple;
      case 'marketplace':
        return Colors.teal;
      case 'bakery':
        return Colors.brown;
      case 'electronics':
        return Colors.indigo;
      case 'fashion':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }
}