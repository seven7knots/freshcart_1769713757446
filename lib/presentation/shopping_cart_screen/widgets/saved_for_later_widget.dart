import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class SavedForLaterWidget extends StatefulWidget {
  final List<Map<String, dynamic>> savedItems;
  final Function(Map<String, dynamic>)? onMoveToCart;
  final Function(Map<String, dynamic>)? onRemoveFromSaved;

  const SavedForLaterWidget({
    super.key,
    required this.savedItems,
    this.onMoveToCart,
    this.onRemoveFromSaved,
  });

  @override
  State<SavedForLaterWidget> createState() => _SavedForLaterWidgetState();
}

class _SavedForLaterWidgetState extends State<SavedForLaterWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    HapticFeedback.lightImpact();

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.savedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
        children: [
          // Header
          GestureDetector(
            onTap: _toggleExpansion,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'bookmark_border',
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Saved for Later (${widget.savedItems.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),

                // Saved Items List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  itemCount: widget.savedItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final item = widget.savedItems[index];
                    return _buildSavedItem(context, item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isOutOfStock = item['isOutOfStock'] ?? false;
    final price = item['price'] ?? 0.0;
    final originalPrice = item['originalPrice'];
    final discount = item['discount'];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomImageWidget(
                    imageUrl: item['image'] ?? '',
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                    semanticLabel:
                        item['semanticLabel'] ?? AppLocalizations.of(context)!.savedProductImage,
                  ),
                ),
                if (isOutOfStock)
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        'Out of\nStock',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 8.sp,
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
                // Product Name
                Text(
                  item['name'] ?? AppLocalizations.of(context)!.productName2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isOutOfStock
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (item['weight'] != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    item['weight'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],

                SizedBox(height: 1.h),

                // Price
                Row(
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
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
                    ],
                  ],
                ),

                SizedBox(height: 1.h),

                // Action Buttons
                Row(
                  children: [
                    // Move to Cart Button
                    Expanded(
                      child: GestureDetector(
                        onTap: isOutOfStock
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                widget.onMoveToCart?.call(item);
                              },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? Colors.grey.shade400
                                    .withValues(alpha: 0.1)
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isOutOfStock ? AppLocalizations.of(context)!.outOfStock2 : AppLocalizations.of(context)!.moveToCart,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isOutOfStock
                                  ? Colors.black87
                                      .withValues(alpha: 0.6)
                                  : theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),

                    SizedBox(width: 2.w),

                    // Remove Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onRemoveFromSaved?.call(item);
                      },
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CustomIconWidget(
                          iconName: 'delete_outline',
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
