import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/product_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;
  final String? storeName;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const ProductInfoSection({
    super.key,
    required this.product,
    this.storeName,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Name + Wishlist
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (storeName != null && storeName!.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Text(storeName!, style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
          GestureDetector(
            onTap: onWishlistToggle,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isWishlisted ? theme.colorScheme.error.withOpacity(0.1) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isWishlisted ? theme.colorScheme.error : theme.colorScheme.outline),
              ),
              child: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant, size: 20),
            ),
          ),
        ]),
        SizedBox(height: 2.h),

        // Price row
        Row(children: [
          if (product.isOnSale) ...[
            Text(product.salePriceDisplay!, style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(width: 2.w),
            Text(product.priceDisplay, style: theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${product.discountPercent}% OFF', style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.red, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ] else
            Text(product.priceDisplay, style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        SizedBox(height: 2.h),

        // Stock status
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: product.canOrder
                ? Colors.green.withOpacity(0.1)
                : theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: product.canOrder ? Colors.green : theme.colorScheme.error,
            ),
          ),
          child: Row(children: [
            Icon(product.canOrder ? Icons.check_circle : Icons.error,
                color: product.canOrder ? Colors.green : theme.colorScheme.error, size: 20),
            SizedBox(width: 2.w),
            Flexible(child: Text(product.canOrder ? AppLocalizations.of(context)!.inStock : AppLocalizations.of(context)!.outOfStock2,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: product.canOrder ? Colors.green : theme.colorScheme.error,
                    fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (product.canOrder && product.stockQuantity != null) ...[
              SizedBox(width: 2.w),
              Text('• ${product.stockQuantity} left',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),

        // Category badge
        if (product.category != null && product.category!.isNotEmpty) ...[
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Text(product.category!, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ]),
    );
  }
}