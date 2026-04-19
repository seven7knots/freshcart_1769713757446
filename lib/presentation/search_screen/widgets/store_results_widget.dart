import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/generated/app_localizations.dart';

// ============================================================
// SESSION 19+20: Store result card model
// SESSION 20 FIX (Bug 1): min_order → minimum_order
// ============================================================

class StoreResultCard {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final double? rating;
  final String? imageUrl;
  final double? deliveryFee;
  final double? minOrder;
  final bool isActive;

  StoreResultCard({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.rating,
    this.imageUrl,
    this.deliveryFee,
    this.minOrder,
    this.isActive = true,
  });

  factory StoreResultCard.fromMap(Map<String, dynamic> map) {
    return StoreResultCard(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Store',
      description: map['description'],
      category: map['category'],
      rating: (map['rating'] as num?)?.toDouble(),
      imageUrl: map['image_url'],
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble(),
      // SESSION 20 FIX: Read from minimum_order (actual DB column)
      minOrder: (map['minimum_order'] as num?)?.toDouble(),
      isActive: map['is_active'] ?? true,
    );
  }
}

// ============================================================
// SESSION 19: Category result card model
// ============================================================

class CategoryResultCard {
  final String id;
  final String name;
  final String? nameAr;
  final String? type;
  final String? icon;
  final String? imageUrl;
  final String? parentId;
  final bool hasChildren;

  CategoryResultCard({
    required this.id,
    required this.name,
    this.nameAr,
    this.type,
    this.icon,
    this.imageUrl,
    this.parentId,
    this.hasChildren = false,
  });

  factory CategoryResultCard.fromMap(Map<String, dynamic> map) {
    return CategoryResultCard(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      nameAr: map['name_ar'],
      type: map['type'],
      icon: map['icon'],
      imageUrl: map['image_url'],
      parentId: map['parent_id'],
    );
  }
}

// ============================================================
// SESSION 19: Horizontal store results widget
// ============================================================

class StoreResultsWidget extends StatelessWidget {
  final List<StoreResultCard> stores;
  final Function(StoreResultCard) onStoreTap;

  const StoreResultsWidget({
    super.key,
    required this.stores,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
          child: Row(
            children: [
              Icon(Icons.store_rounded, size: 18, color: cs.primary),
              SizedBox(width: 2.w),
              Flexible(child: Text(
                'Stores (${stores.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return _buildStoreCard(context, theme, cs, store);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    StoreResultCard store,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onStoreTap(store);
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: store.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(imageUrl: 
                              store.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.store_rounded,
                                color: cs.primary,
                                size: 18,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.store_rounded,
                            color: cs.primary,
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (store.category != null)
                Text(
                  store.category!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                children: [
                  if (store.rating != null) ...[
                    Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      store.rating!.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(width: 8),
                  ],

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SESSION 19: Horizontal category results widget
// ============================================================

class CategoryResultsWidget extends StatelessWidget {
  final List<CategoryResultCard> categories;
  final Function(CategoryResultCard) onCategoryTap;

  const CategoryResultsWidget({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
          child: Row(
            children: [
              Icon(Icons.category_rounded, size: 18, color: cs.primary),
              SizedBox(width: 2.w),
              Flexible(child: Text(
                'Categories (${categories.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryChip(context, theme, cs, cat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    CategoryResultCard cat,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onCategoryTap(cat);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cat.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(imageUrl: 
                  cat.imageUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.category_rounded,
                    color: cs.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Icon(Icons.category_rounded, color: cs.primary, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              cat.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: cs.primary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}