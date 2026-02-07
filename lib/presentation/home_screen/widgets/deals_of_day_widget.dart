import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';

class DealsOfDayWidget extends ConsumerWidget {
  const DealsOfDayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredProductsAsync = ref.watch(featuredProductsProvider);
    final authProvider = provider.Provider.of<AuthProvider>(context);
    final adminProvider = provider.Provider.of<AdminProvider>(context);
    final isEditMode = adminProvider.isAdmin && adminProvider.isEditMode;

    return featuredProductsAsync.when(
      data: (products) {
        if (products.isEmpty && !isEditMode) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'local_fire_department',
                          color: Theme.of(context).colorScheme.error,
                          size: 6.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Deals of the Day',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isEditMode)
                          InkWell(
                            onTap: () => _addNewProduct(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 3.w, vertical: 0.5.h),
                              margin: EdgeInsets.only(right: 2.w),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 16),
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
                            AppRoutes.switchToTab(context, 1);
                          },
                          child: Text(
                            'View All',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              SizedBox(
                height: 28.h,
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'No deals yet. Add featured products.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: products.length > 10 ? 10 : products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final productCard =
                              _buildProductCard(context, product);

                          // Wrap with admin edit controls if in edit mode
                          if (isEditMode) {
                            return AdminEditableItemWrapper(
                              contentType: 'product',
                              contentId: product.id,
                              contentData: {
                                'id': product.id,
                                'name': product.name,
                                'description': product.description,
                                'price': product.price,
                                'sale_price': product.salePrice,
                                'image_url': product.imageUrl,
                                'is_available': product.isAvailable,
                                'is_featured': product.isFeatured,
                                'store_id': product.storeId,
                              },
                              onDeleted: () =>
                                  ref.invalidate(featuredProductsProvider),
                              onUpdated: () =>
                                  ref.invalidate(featuredProductsProvider),
                              child: productCard,
                            );
                          }

                          return productCard;
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _addNewProduct(BuildContext context) {
    // Navigate to product creation or show modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to product creation'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    final discount = product.salePrice != null
        ? (((product.price - product.salePrice!) / product.price) * 100).round()
        : 0;

    return Container(
      width: 40.w,
      margin: EdgeInsets.only(right: 3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: {'productId': product.id},
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  child: CustomImageWidget(
                    imageUrl: product.imageUrl ??
                        (product.images.isNotEmpty
                            ? product.images.first
                            : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'),
                    width: double.infinity,
                    height: 15.h,
                    fit: BoxFit.cover,
                    semanticLabel: '${product.name} product image',
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Text(
                        '\$${product.salePrice ?? product.price}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      if (product.salePrice != null) ...[
                        SizedBox(width: 1.w),
                        Text(
                          '\$${product.price}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: Theme.of(context).colorScheme.error,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Deals of the Day',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 28.h,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
