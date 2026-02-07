import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/category_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/category_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';

class FeaturedCategoriesWidget extends StatefulWidget {
  const FeaturedCategoriesWidget({super.key});

  @override
  State<FeaturedCategoriesWidget> createState() => _FeaturedCategoriesWidgetState();
}

class _FeaturedCategoriesWidgetState extends State<FeaturedCategoriesWidget> {
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];

  // Fallback images for categories without images
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
      // Get all active top-level categories
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

    // Don't show section if loading or no categories
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _categories.isEmpty) {
      // Show nothing or minimal state - don't clutter the home page
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop by Category',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Find everything you need',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isEditMode)
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.adminCategories),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                          margin: EdgeInsets.only(right: 2.w),
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
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.allCategoriesScreen,
                        );
                      },
                      child: Text(
                        'See All',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                final categoryCard = _buildCategoryCard(context, category, index);

                // Wrap with admin edit controls if in edit mode
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
      height: 28.h,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, int index) {
    final theme = Theme.of(context);
    
    // Get image URL or use fallback
    final imageUrl = category.imageUrl ?? _fallbackImages[index % _fallbackImages.length];
    
    // Get color based on category type
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
              // Background image
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  semanticLabel: '${category.name} category image',
                ),
              ),
              
              // Gradient overlay
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
              
              // Category type badge
              Positioned(
                top: 3.w,
                left: 3.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (category.type ?? 'General').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Category info
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null && category.description!.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        category.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
                          Text(
                            '${category.storeCount} stores',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
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

  Future<void> _handleCategoryTap(BuildContext context, Category category) async {
    // Check if this category has subcategories
    final hasSubcats = await CategoryService.hasSubcategories(category.id);
    
    if (!mounted) return;

    if (hasSubcats) {
      // Navigate to subcategories screen
      Navigator.pushNamed(
        context,
        AppRoutes.subcategoriesScreen,
        arguments: {
          'parentCategoryId': category.id,
          'parentCategoryName': category.name,
        },
      );
    } else {
      // Navigate to category listings
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