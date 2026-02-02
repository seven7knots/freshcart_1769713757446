import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/delivery_map_widget.dart';
import './widgets/delivery_rider_info_widget.dart';
import './widgets/order_status_timeline_widget.dart';
import './widgets/order_summary_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _orderId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get order ID from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final orderId = args?['orderId'] as String?;

    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      _isLoading = true;
      _error = null;
      // Subscribe to real-time updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _subscribeToOrder();
      });
    }
  }

  Future<void> _subscribeToOrder() async {
    if (_orderId == null) return;

    try {
      final provider = ref.read(orderTrackingProvider.notifier);
      await provider.subscribeToOrderUpdates(_orderId!);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load order: $e';
        });
      }
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Unsubscribe from real-time updates
    ref.read(orderTrackingProvider.notifier).unsubscribe();
    super.dispose();
  }

  void _handleCallRider() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling driver...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMessageRider() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat with driver...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleReorder() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/shopping-cart-screen');
  }

  void _handleSupportContact() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSupportBottomSheet(),
    );
  }

  Widget _buildSupportBottomSheet() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Need Help?',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Our customer support team is here to help you with any delivery issues.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          _buildSupportOption(
            icon: 'chat',
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening live chat...')),
              );
            },
          ),
          SizedBox(height: 2.h),
          _buildSupportOption(
            icon: 'phone',
            title: 'Call Support',
            subtitle: '1-800-FRESH-CART',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling support...')),
              );
            },
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.2,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 6.w,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current tab index from MainLayoutWrapper
    final parentState = MainLayoutWrapper.of(context);
    final currentTabIndex =
        parentState?.currentIndex ?? 1; // Default to Orders tab

    // Watch order tracking state
    final orderState = ref.watch(orderTrackingProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading order details...',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 15.w, color: Colors.red),
                      SizedBox(height: 2.h),
                      Text(
                        'Error Loading Order',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _subscribeToOrder();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 1.5.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : orderState.currentOrder == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 15.w,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Order Not Found',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Unable to find order details',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (BuildContext context) {
                        final currentOrder = orderState.currentOrder!;
                        final driverLocation = orderState.driverLocation;
                        final isLoading = orderState.isLoading;
                        final error = orderState.error;

                        // Build order statuses from current order
                        final orderStatuses =
                            _buildOrderStatuses(currentOrder.status);
                        final currentStatusIndex = _getCurrentStatusIndex(
                          currentOrder.status,
                        );

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // Delivery Map with real-time driver location
                                  Padding(
                                    padding: EdgeInsets.all(4.w),
                                    child: DeliveryMapWidget(
                                      orderData: {
                                        'deliveryAddress':
                                            currentOrder.deliveryAddress,
                                        'deliveryLat': currentOrder.deliveryLat,
                                        'deliveryLng': currentOrder.deliveryLng,
                                        'driverLocation': driverLocation,
                                      },
                                    ),
                                  ),

                                  // Order Status with Animation
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 4.w),
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: AppTheme
                                            .lightTheme.colorScheme.outline
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: _pulseAnimation.value,
                                                  child: Container(
                                                    width: 3.w,
                                                    height: 3.w,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .lightTheme
                                                          .colorScheme
                                                          .secondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(width: 3.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    orderStatuses[
                                                            currentStatusIndex]
                                                        ['title'] as String,
                                                    style: AppTheme.lightTheme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppTheme
                                                          .lightTheme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    orderStatuses[
                                                            currentStatusIndex][
                                                        'description'] as String,
                                                    style: AppTheme.lightTheme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: AppTheme
                                                          .lightTheme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (currentOrder
                                                    .estimatedDeliveryTime !=
                                                null)
                                              Text(
                                                _formatEstimatedTime(
                                                  currentOrder
                                                      .estimatedDeliveryTime!,
                                                ),
                                                style: AppTheme.lightTheme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.lightTheme
                                                      .colorScheme.secondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          'Delivering to: ${currentOrder.deliveryAddress}',
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 3.h),

                                  // Delivery Rider Info (if driver assigned)
                                  if (currentOrder.driverId != null)
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4.w),
                                      child: DeliveryRiderInfoWidget(
                                        riderInfo: {
                                          'name': 'Driver',
                                          'rating': 4.8,
                                          'totalDeliveries': 0,
                                          'vehicleInfo': 'Vehicle',
                                          'avatar': '',
                                          'avatarSemanticLabel':
                                              'Driver avatar',
                                        },
                                        onCallPressed: _handleCallRider,
                                        onMessagePressed: _handleMessageRider,
                                      ),
                                    ),

                                  SizedBox(height: 3.h),

                                  // Order Status Timeline
                                  OrderStatusTimelineWidget(
                                    orderStatuses: orderStatuses,
                                    currentStatusIndex: currentStatusIndex,
                                  ),

                                  SizedBox(height: 3.h),

                                  // Order Summary
                                  OrderSummaryWidget(
                                    orderData: {
                                      'orderId': currentOrder.orderNumber ??
                                          currentOrder.id,
                                      'subtotal':
                                          '\$${currentOrder.subtotal.toStringAsFixed(2)}',
                                      'deliveryFee':
                                          '\$${currentOrder.deliveryFee.toStringAsFixed(2)}',
                                      'tax':
                                          '\$${currentOrder.tax.toStringAsFixed(2)}',
                                      'total':
                                          '\$${currentOrder.total.toStringAsFixed(2)}',
                                      'items': [],
                                    },
                                    onReorderPressed: _handleReorder,
                                  ),

                                  SizedBox(height: 4.h),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          // Update parent tab index and pop detail screen
          parentState?.updateTabIndex(index);
          if (index != currentTabIndex) {
            Navigator.pop(context);
          }
        },
        variant: BottomBarVariant.primary,
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home-screen';
      case 1:
        return '/search-screen';
      case 2:
        return '/shopping-cart-screen';
      case 3:
        return '/order-history-screen';
      case 4:
        return '/profile-screen';
      default:
        return '/home-screen';
    }
  }

  List<Map<String, dynamic>> _buildOrderStatuses(String currentStatus) {
    return [
      {
        'title': 'Order Confirmed',
        'description': 'Your order has been received and confirmed',
        'timestamp': '',
      },
      {
        'title': 'Being Prepared',
        'description': 'Your items are being picked and packed',
        'timestamp': '',
      },
      {
        'title': 'Out for Delivery',
        'description': 'Your order is on the way to you',
        'timestamp': '',
      },
      {
        'title': 'Delivered',
        'description': 'Your order has been delivered successfully',
        'timestamp': null,
      },
    ];
  }

  int _getCurrentStatusIndex(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 0;
      case 'preparing':
      case 'ready':
        return 1;
      case 'picked_up':
      case 'in_transit':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  String _formatEstimatedTime(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  void _showAssignDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a driver for order #${_orderId ?? "N/A"}'),
            SizedBox(height: 2.h),
            // Driver selection would go here
            const Text('Driver selection UI'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver assigned successfully')),
              );
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
