import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class EmptyCartWidget extends StatelessWidget {
  final VoidCallback? onStartShopping;
  final List<Map<String, dynamic>>? recentlyViewedProducts;

  const EmptyCartWidget({
    super.key,
    this.onStartShopping,
    this.recentlyViewedProducts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),

          // Empty Cart Illustration
          Container(
            width: 60.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'shopping_cart_outlined',
                  size: 80,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                SizedBox(height: 3.h),
                Text(
                  AppLocalizations.of(context)!.yourCartIsEmpty,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    'Looks like you haven\'t added anything to your cart yet. Start shopping to fill it up!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Start Shopping Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onStartShopping?.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'shopping_bag',
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  SizedBox(width: 2.w),
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.startShopping,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Recently Viewed Products
          if (recentlyViewedProducts != null &&
              recentlyViewedProducts!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.recentlyViewed,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentlyViewedProducts!.length > 5
                    ? 5
                    : recentlyViewedProducts!.length,
                separatorBuilder: (context, index) => SizedBox(width: 3.w),
                itemBuilder: (context, index) {
                  final product = recentlyViewedProducts![index];
                  return _buildRecentlyViewedItem(context, product);
                },
              ),
            ),
          ],

          SizedBox(height: 4.h),

          // Quick Actions
          _buildQuickActions(context),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedItem(
      BuildContext context, Map<String, dynamic> product) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/product-detail-screen');
      },
      child: Container(
        width: 35.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                color: theme.colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CustomImageWidget(
                  imageUrl: product['image'] ?? '',
                  width: double.infinity,
                  height: 15.h,
                  fit: BoxFit.cover,
                  semanticLabel:
                      product['semanticLabel'] ?? 'Recently viewed product',
                ),
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product Name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '\$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    final quickActions = [
      {
        'icon': 'category',
        'title': AppLocalizations.of(context)!.browseCategories,
        'subtitle': AppLocalizations.of(context)!.exploreAllProductCategories,
        'route': '/home-screen',
      },
      {
        'icon': 'local_offer',
        'title': 'Today\'s Deals',
        'subtitle': AppLocalizations.of(context)!.checkOutSpecialOffers,
        'route': '/home-screen',
      },
      {
        'icon': 'search',
        'title': AppLocalizations.of(context)!.searchProducts2,
        'subtitle': 'Find what you\'re looking for',
        'route': '/search-screen',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        ...quickActions.map((action) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, action['route'] as String);
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CustomIconWidget(
                      iconName: action['icon'] as String,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 0.5.h),
                        Text(
                          action['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
