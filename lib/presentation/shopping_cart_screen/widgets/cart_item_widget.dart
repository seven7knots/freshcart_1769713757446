import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class CartItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onRemove;
  final Function(int)? onQuantityChanged;
  final VoidCallback? onMoveToWishlist;

  const CartItemWidget({
    super.key,
    required this.item,
    this.onRemove,
    this.onQuantityChanged,
    this.onMoveToWishlist,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late int _quantity;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item['quantity'] ?? 1;
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      _quantity = newQuantity;
    });

    HapticFeedback.lightImpact();
    widget.onQuantityChanged?.call(newQuantity);
  }

  void _handleRemove() {
    setState(() {
      _isRemoving = true;
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onRemove?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = widget.item['isOutOfStock'] ?? false;
    final price = widget.item['price'] ?? 0.0;
    final originalPrice = widget.item['originalPrice'];
    final discount = widget.item['discount'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.translationValues(_isRemoving ? -100.w : 0, 0, 0),
      child: Dismissible(
        key: Key(widget.item['id'].toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _handleRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'delete',
                color: theme.colorScheme.onError,
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                AppLocalizations.of(context)!.remove,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOutOfStock
                  ? theme.colorScheme.error.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.surface,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CustomImageWidget(
                        imageUrl: widget.item['image'] ?? '',
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.cover,
                        semanticLabel:
                            widget.item['semanticLabel'] ?? AppLocalizations.of(context)!.productImage,
                      ),
                    ),
                    if (isOutOfStock)
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            'Out of\nStock',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(width: 3.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Brand
                    Text(
                      widget.item['name'] ?? AppLocalizations.of(context)!.productName2,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? Colors.black87.withValues(alpha: 0.6)
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (widget.item['brand'] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.item['brand'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],

                    if (widget.item['weight'] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.item['weight'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],

                    SizedBox(height: 1.h),

                    // Price and Discount
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (originalPrice != null && discount != null) ...[
                          SizedBox(width: 2.w),
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondary,
                                fontWeight: FontWeight.w600,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 1.5.h),

                    // Quantity Controls and Actions
                    Row(
                      children: [
                        // Quantity Stepper
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade400
                                  .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: isOutOfStock
                                    ? null
                                    : () => _updateQuantity(_quantity - 1),
                                child: Container(
                                  padding: EdgeInsets.all(2.w),
                                  child: CustomIconWidget(
                                    iconName: 'remove',
                                    size: 16,
                                    color: isOutOfStock
                                        ? Colors.black87
                                            .withValues(alpha: 0.3)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: Text(
                                  _quantity.toString(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock
                                        ? Colors.black87
                                            .withValues(alpha: 0.6)
                                        : Colors.black87,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              GestureDetector(
                                onTap: isOutOfStock
                                    ? null
                                    : () => _updateQuantity(_quantity + 1),
                                child: Container(
                                  padding: EdgeInsets.all(2.w),
                                  child: CustomIconWidget(
                                    iconName: 'add',
                                    size: 16,
                                    color: isOutOfStock
                                        ? Colors.black87
                                            .withValues(alpha: 0.3)
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Move to Wishlist
                        GestureDetector(
                          onTap: widget.onMoveToWishlist,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'favorite_border',
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  AppLocalizations.of(context)!.save2,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Out of Stock Warning
                    if (isOutOfStock) ...[
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'warning',
                              size: 14,
                              color: theme.colorScheme.error,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.thisItemIsCurrentlyOutOf,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
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
}
