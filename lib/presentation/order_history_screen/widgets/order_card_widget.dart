import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class OrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onReorderAll;
  final Function(Map<String, dynamic>)? onAddToCart;
  final VoidCallback? onDownloadReceipt;
  final VoidCallback? onRateOrder;
  final VoidCallback? onReportIssue;
  final VoidCallback? onShareOrder;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onReorderAll,
    this.onAddToCart,
    this.onDownloadReceipt,
    this.onRateOrder,
    this.onReportIssue,
    this.onShareOrder,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget>
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
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showContextMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              _buildContextMenuItem(
                icon: 'download',
                title: AppLocalizations.of(context)!.downloadReceipt,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDownloadReceipt?.call();
                },
              ),
              _buildContextMenuItem(
                icon: 'star',
                title: AppLocalizations.of(context)!.rateOrder,
                onTap: () {
                  Navigator.pop(context);
                  widget.onRateOrder?.call();
                },
              ),
              _buildContextMenuItem(
                icon: 'report',
                title: AppLocalizations.of(context)!.reportIssue,
                onTap: () {
                  Navigator.pop(context);
                  widget.onReportIssue?.call();
                },
              ),
              _buildContextMenuItem(
                icon: 'share',
                title: AppLocalizations.of(context)!.shareOrder,
                onTap: () {
                  Navigator.pop(context);
                  widget.onShareOrder?.call();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: Theme.of(context).colorScheme.onSurface,
        size: 24,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Theme.of(context).colorScheme.secondary;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      case 'processing':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: all casts are null-safe — real Supabase data may be missing mock fields
    final orderDateStr = widget.order['orderDate'] as String?
        ?? DateTime.now().toIso8601String();
    final orderDate = DateTime.tryParse(orderDateStr) ?? DateTime.now();
    final items = (widget.order['items'] as List<dynamic>?) ?? [];
    final totalAmount = (widget.order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = widget.order['status'] as String? ?? 'pending';
    final itemCount = widget.order['itemCount'] as int? ?? items.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleExpansion,
            onLongPress: _showContextMenu,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${widget.order['orderId'] ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                              style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w600,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '$itemCount item${itemCount != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      // FIX: item image thumbnails — gracefully skip if no image
                      Row(
                        children: [
                          if (items.isNotEmpty)
                            ...items.take(3).map((item) {
                              final imageUrl =
                                  (item as Map<String, dynamic>)['image']
                                      as String?;
                              return Container(
                                margin: EdgeInsets.only(left: 1.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? CustomImageWidget(
                                          imageUrl: imageUrl,
                                          width: 12.w,
                                          height: 12.w,
                                          fit: BoxFit.cover,
                                          semanticLabel: item['product_name']
                                                  as String? ??
                                              'Product',
                                        )
                                      : Container(
                                          width: 12.w,
                                          height: 12.w,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 5.w,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          if (items.length > 3)
                            Container(
                              margin: EdgeInsets.only(left: 1.w),
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '+${items.length - 3}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onReorderAll,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.reorderAll,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      GestureDetector(
                        onTap: _toggleExpansion,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: CustomIconWidget(
                              iconName: 'keyboard_arrow_down',
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                children: [
                  Divider(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    thickness: 1,
                  ),
                  SizedBox(height: 2.h),
                  ...items.map((item) =>
                      _buildOrderItem(item as Map<String, dynamic>)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // FIX: all fields null-safe — map real Supabase order_items columns
    final isAvailable = item['isAvailable'] as bool? ?? true;
    final imageUrl = item['image'] as String?; // may be null from real data
    // Real Supabase columns: product_name, unit_price, quantity
    final name = item['name'] as String?
        ?? item['product_name'] as String?
        ?? AppLocalizations.of(context)!.unknownItem;
    final price = (item['price'] as num?)?.toDouble()
        ?? (item['unit_price'] as num?)?.toDouble()
        ?? 0.0;
    final quantity = item['quantity'] as int? ?? 1;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // FIX: show placeholder icon when no image URL
                imageUrl != null && imageUrl.isNotEmpty
                    ? CustomImageWidget(
                        imageUrl: imageUrl,
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                        semanticLabel: name,
                      )
                    : Container(
                        width: 15.w,
                        height: 15.w,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 6.w,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                if (!isAvailable)
                  Container(
                    width: 15.w,
                    height: 15.w,
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isAvailable
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      'Qty: $quantity',
                      style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(width: 3.w),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                if (!isAvailable) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    AppLocalizations.of(context)!.outOfStock3,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          SizedBox(width: 2.w),
          isAvailable
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onAddToCart?.call(item);
                  },
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CustomIconWidget(
                      iconName: 'add_shopping_cart',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomIconWidget(
                    iconName: 'block',
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
                  ),
                ),
        ],
      ),
    );
  }
}