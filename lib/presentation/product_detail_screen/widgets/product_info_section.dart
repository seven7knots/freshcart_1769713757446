import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ProductInfoSection extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      product['brand'] as String,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onWishlistToggle,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isWishlisted
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWishlisted
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: isWishlisted ? 'favorite' : 'favorite_border',
                    color: isWishlisted
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                product['price'] as String,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              if (product['originalPrice'] != null)
                Text(
                  product['originalPrice'] as String,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              SizedBox(width: 2.w),
              if (product['discount'] != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product['discount']}% OFF',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return CustomIconWidget(
                    iconName: index < (product['rating'] as double).floor()
                        ? 'star'
                        : index < (product['rating'] as double)
                            ? 'star_half'
                            : 'star_border',
                    color: theme.colorScheme.tertiary,
                    size: 16,
                  );
                }),
              ),
              SizedBox(width: 2.w),
              Text(
                '${product['rating']} (${product['reviewCount']} reviews)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: product['inStock'] as bool
                  ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                  : theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: product['inStock'] as bool
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.error,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName:
                      product['inStock'] as bool ? 'check_circle' : 'error',
                  color: product['inStock'] as bool
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.error,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  product['inStock'] as bool ? 'In Stock' : 'Out of Stock',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: product['inStock'] as bool
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product['inStock'] as bool) ...[
                  SizedBox(width: 2.w),
                  Text(
                    '• ${product['stockCount']} left',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
