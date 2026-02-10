import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/product_model.dart';
import '../../../widgets/custom_image_widget.dart';

class RelatedProductsSection extends StatelessWidget {
  final List<Product> products;

  const RelatedProductsSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Text('You might also like', style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      ),
      SizedBox(height: 2.h),
      SizedBox(
        height: 28.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildCard(context, products[index], theme),
        ),
      ),
      SizedBox(height: 2.h),
    ]);
  }

  Widget _buildCard(BuildContext context, Product product, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(), // Will be replaced by proper navigation
      )),
      child: Container(
        width: 40.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Expanded(flex: 3, child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? CustomImageWidget(imageUrl: product.imageUrl!, fit: BoxFit.cover,
                    width: double.infinity, height: double.infinity)
                : Container(color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(child: Icon(Icons.shopping_bag, size: 30, color: theme.colorScheme.onSurfaceVariant))),
          )),
          // Info
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.all(2.5.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (product.storeName != null) ...[
                SizedBox(height: 0.3.h),
                Text(product.storeName!, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const Spacer(),
              Row(children: [
                Expanded(child: product.isOnSale
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(product.salePriceDisplay!, style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                        Text(product.priceDisplay, style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant, fontSize: 9.sp)),
                      ])
                    : Text(product.priceDisplay, style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} added to cart'), backgroundColor: Colors.green));
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 16),
                  ),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}