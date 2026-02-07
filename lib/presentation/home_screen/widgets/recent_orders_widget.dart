import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/order_service.dart';
import '../../../widgets/animated_press_button.dart';

// Riverpod provider for recent orders
final recentOrdersProvider = riverpod.FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final orderService = OrderService();
  return await orderService.getUserOrders(limit: 5);
});

class RecentOrdersWidget extends riverpod.ConsumerWidget {
  const RecentOrdersWidget({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final ordersAsync = ref.watch(recentOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        // Hide widget if no orders
        if (orders.isEmpty) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Orders',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Reorder your favorites with one tap',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full order history
                        // Since we removed orders from bottom nav, this could go to profile
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                      child: Text(
                        'View All',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                height: 25.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: orders.length > 3 ? 3 : orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order, ref);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) {
        // Don't show error state - just hide the widget
        debugPrint('[RECENT_ORDERS] Error loading: $error');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      height: 25.h,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    riverpod.WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final items = order["order_items"] as List<dynamic>? ?? [];
    final orderNumber = order["order_number"] as String? ?? '#N/A';
    final status = order["status"] as String? ?? 'pending';
    final totalAmount = order["total_amount"] as num? ?? 0;
    
    // Parse date
    final createdAt = order["created_at"] as String?;
    String displayDate = 'Today';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        final now = DateTime.now();
        final difference = now.difference(date);
        if (difference.inDays == 0) {
          displayDate = 'Today';
        } else if (difference.inDays == 1) {
          displayDate = 'Yesterday';
        } else if (difference.inDays < 7) {
          displayDate = '${difference.inDays} days ago';
        } else {
          displayDate = '${date.month}/${date.day}/${date.year}';
        }
      }
    }

    // Get store info
    final storeData = order["stores"] as Map<String, dynamic>?;
    final storeName = storeData?["name"] as String? ?? 'Unknown Store';

    return AnimatedPressButton(
      onPressed: () => _handleOrderTap(context, order),
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          storeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                displayDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              
              // Order Items Preview
              if (items.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 8.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length > 3 ? 3 : items.length,
                          itemBuilder: (context, index) {
                            final item = items[index] as Map<String, dynamic>;
                            final productName = item["product_name"] as String? ?? 'Product';
                            return Container(
                              width: 12.w,
                              height: 12.w,
                              margin: EdgeInsets.only(right: 2.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  productName.substring(0, 1).toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (items.length > 3)
                      Container(
                        width: 12.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+${items.length - 3}',
                            style:
                                theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              
              const Spacer(),
              
              // Order Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (status == 'delivered')
                    AnimatedPressButton(
                      onPressed: () => _reorderItems(context, order, ref),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: theme.colorScheme.onPrimary,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Reorder',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'preparing':
        return Colors.blue;
      case 'in_transit':
      case 'picked_up':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      default:
        return status.toUpperCase();
    }
  }

  void _handleOrderTap(BuildContext context, Map<String, dynamic> order) {
    // Navigate to order detail screen
    Navigator.pushNamed(
      context,
      AppRoutes.orderTracking,
      arguments: {'orderId': order['id']},
    );
  }

  void _reorderItems(
    BuildContext context,
    Map<String, dynamic> order,
    riverpod.WidgetRef ref,
  ) {
    final items = order["order_items"] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reorder Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        content: Text(
          'Add all ${items.length} items from this order to your cart?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // TODO: Implement actual cart add logic
              // For now, just show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${items.length} items added to cart'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'View Cart',
                    onPressed: () => AppRoutes.switchToTab(context, 2),
                  ),
                ),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}