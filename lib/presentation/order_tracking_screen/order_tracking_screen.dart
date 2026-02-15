import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/supabase_service.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  String? _orderId;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    String? orderId;

    if (args is Map<String, dynamic>) {
      // Could be {'orderId': '...'} OR the full order response from checkout
      orderId = args['orderId'] as String? ?? args['id'] as String?;
    } else if (args is String) {
      // Direct order ID string
      orderId = args;
    }

    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      _subscribeToOrder();
    }
  }

  Future<void> _subscribeToOrder() async {
    if (_orderId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(orderTrackingProvider.notifier)
          .subscribeToOrderUpdates(_orderId!);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    ref.read(orderTrackingProvider.notifier).unsubscribe();
    super.dispose();
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  static const _statusOrder = [
    'pending',
    'accepted',
    'assigned',
    'picked_up',
    'delivered',
  ];

  int _statusIndex(String status) {
    final idx = _statusOrder.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'accepted':
        return 'Order Accepted';
      case 'assigned':
        return 'Driver Assigned';
      case 'picked_up':
        return 'Order Picked Up';
      case 'delivered':
        return 'Order Delivered';
      case 'rejected':
        return 'Order Rejected';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Processing';
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your order is being reviewed by the store';
      case 'accepted':
        return 'Store accepted your order, assigning a driver';
      case 'assigned':
        return 'A driver has been assigned and is heading to the store';
      case 'picked_up':
        return 'Your order is on the way to you!';
      case 'delivered':
        return 'Your order has been delivered. Enjoy!';
      case 'rejected':
        return 'Unfortunately, your order was rejected';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return 'Processing your order...';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.receipt_long;
      case 'accepted':
        return Icons.check_circle;
      case 'assigned':
        return Icons.local_shipping;
      case 'picked_up':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderState = ref.watch(orderTrackingProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Order Tracking',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _subscribeToOrder),
          IconButton(
              icon: const Icon(Icons.support_agent),
              onPressed: () => _showSupportSheet(theme)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : orderState.currentOrder == null
                  ? _buildNotFound(theme)
                  : _buildOrderContent(theme, orderState.currentOrder!, orderState.driverLocation),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
        child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                SizedBox(height: 2.h),
                Text('Error Loading Order',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 1.h),
                Text(_error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                    onPressed: _subscribeToOrder,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry')),
              ],
            )));
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: 2.h),
          Text('Order Not Found',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]));
  }

  Widget _buildOrderContent(ThemeData theme, OrderModel order, Map<String, dynamic>? driverLocation) {
    final status = order.status;
    final currentIdx = _statusIndex(status);
    final isTerminal =
        status == 'delivered' || status == 'rejected' || status == 'cancelled';
    final showMap = status == 'assigned' || status == 'picked_up';

    return RefreshIndicator(
      onRefresh: () async => _subscribeToOrder(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeroCard(theme, order, status),
              SizedBox(height: 3.h),
              if (showMap) ...[
                _buildMapSection(theme, order, driverLocation),
                SizedBox(height: 3.h),
              ],
              if (order.driverId != null && !isTerminal) ...[
                _buildDriverCard(theme, order),
                SizedBox(height: 3.h),
              ],
              _buildStatusTimeline(theme, status, currentIdx),
              SizedBox(height: 3.h),
              _buildOrderDetailsCard(theme, order),
              SizedBox(height: 3.h),
              if (status == 'pending')
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelOrder(order.id),
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red),
                      label: const Text('Cancel Order',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    )),
              if (status == 'delivered')
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.mainLayout, (r) => false),
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Home'),
                    )),
              SizedBox(height: 4.h),
            ]),
      ),
    );
  }

  // ============================================================
  // STATUS HERO CARD
  // ============================================================

  Widget _buildStatusHeroCard(
      ThemeData theme, OrderModel order, String status) {
    final color = _statusColor(status, theme);
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_statusIcon(status), color: color, size: 28),
              ),
              SizedBox(width: 3.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_statusTitle(status),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: color)),
                    SizedBox(height: 0.3.h),
                    Text(_statusDescription(status),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ])),
            ]),
            SizedBox(height: 2.h),
            Row(children: [
              Icon(Icons.receipt,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                  'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('\$${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary)),
            ]),
            SizedBox(height: 0.5.h),
            Row(children: [
              Icon(Icons.payment,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                  order.paymentMethod == 'cash_on_delivery'
                      ? 'Cash on Delivery'
                      : order.paymentMethod == 'whish_money'
                          ? 'Whish Money'
                          : order.paymentMethod ?? 'N/A',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ]),
    );
  }

  // ============================================================
  // MAP SECTION — Embedded Google Map
  // ============================================================

  Widget _buildMapSection(
      ThemeData theme, OrderModel order, Map<String, dynamic>? driverLocation) {
    final deliveryLat = order.deliveryLat ?? 33.8886;
    final deliveryLng = order.deliveryLng ?? 35.4955;
    final deliveryLatLng = LatLng(deliveryLat, deliveryLng);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryLatLng,
        infoWindow:
            InfoWindow(title: 'Delivery', snippet: order.deliveryAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    LatLng? driverLatLng;
    if (driverLocation != null) {
      final dLat =
          (driverLocation['latitude'] ?? driverLocation['lat']) as num?;
      final dLng =
          (driverLocation['longitude'] ?? driverLocation['lng']) as num?;
      if (dLat != null && dLng != null) {
        driverLatLng = LatLng(dLat.toDouble(), dLng.toDouble());
        markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          infoWindow: const InfoWindow(title: 'Driver'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 25.h,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: deliveryLatLng, zoom: 14),
              markers: markers,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: true,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(children: [
            Row(children: [
              Icon(Icons.location_on,
                  size: 16, color: theme.colorScheme.error),
              SizedBox(width: 1.w),
              Expanded(
                  child: Text(order.deliveryAddress,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            SizedBox(height: 1.h),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openGoogleMaps(order, driverLocation),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Track on Google Maps'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                )),
          ]),
        ),
      ]),
    );
  }

  Future<void> _openGoogleMaps(
      OrderModel order, Map<String, dynamic>? driverLocation) async {
    final lat = order.deliveryLat ?? 33.8886;
    final lng = order.deliveryLng ?? 35.4955;

    if (driverLocation != null) {
      final dLat = driverLocation['latitude'] ?? driverLocation['lat'];
      final dLng = driverLocation['longitude'] ?? driverLocation['lng'];
      if (dLat != null && dLng != null) {
        final url = Uri.parse(
            'https://www.google.com/maps/dir/$dLat,$dLng/$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        return;
      }
    }

    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ============================================================
  // DRIVER CARD
  // ============================================================

  Widget _buildDriverCard(ThemeData theme, OrderModel order) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Driver',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 1.5.h),
            Row(children: [
              CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person,
                      color: theme.colorScheme.primary)),
              SizedBox(width: 3.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Driver Assigned',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('On the way',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ])),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling driver...')));
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.phone,
                      color: Colors.green, size: 20),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening chat...')));
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chat,
                      color: Colors.blue, size: 20),
                ),
              ),
            ]),
          ]),
    );
  }

  // ============================================================
  // STATUS TIMELINE
  // ============================================================

  Widget _buildStatusTimeline(
      ThemeData theme, String currentStatus, int currentIdx) {
    final isRejected =
        currentStatus == 'rejected' || currentStatus == 'cancelled';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Progress',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 2.h),
            ...List.generate(_statusOrder.length, (i) {
              final status = _statusOrder[i];
              final isComplete = i < currentIdx;
              final isCurrent = i == currentIdx;
              final isFuture = i > currentIdx;

              Color dotColor;
              if (isRejected && isCurrent) {
                dotColor = theme.colorScheme.error;
              } else if (isComplete) {
                dotColor = Colors.green;
              } else if (isCurrent) {
                dotColor = _statusColor(currentStatus, theme);
              } else {
                dotColor = theme.colorScheme.outline.withOpacity(0.3);
              }

              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 30,
                        child: Column(children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                color: dotColor, shape: BoxShape.circle),
                            child: isComplete
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : isCurrent
                                    ? Container(
                                        margin: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle))
                                    : null,
                          ),
                          if (i < _statusOrder.length - 1)
                            Container(
                                width: 2,
                                height: 40,
                                color: isComplete
                                    ? Colors.green
                                    : theme.colorScheme.outline
                                        .withOpacity(0.2)),
                        ])),
                    SizedBox(width: 3.w),
                    Expanded(
                        child: Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_statusTitle(status),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: (isComplete || isCurrent)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isFuture
                                        ? theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.5)
                                        : theme.colorScheme.onSurface)),
                            Text(_statusDescription(status),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: isFuture
                                        ? theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.3)
                                        : theme
                                            .colorScheme.onSurfaceVariant)),
                          ]),
                    )),
                  ]);
            }),
            if (isRejected) ...[
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 30,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        )),
                    SizedBox(width: 3.w),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_statusTitle(currentStatus),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error)),
                          Text(_statusDescription(currentStatus),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error)),
                        ])),
                  ]),
            ],
          ]),
    );
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  Widget _buildOrderDetailsCard(ThemeData theme, OrderModel order) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 1.5.h),
            _detailRow(
                theme, 'Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
            _detailRow(theme, 'Delivery Fee',
                '\$${order.deliveryFee.toStringAsFixed(2)}'),
            _detailRow(
                theme, 'Tax', '\$${order.tax.toStringAsFixed(2)}'),
            if (order.discount > 0)
              _detailRow(theme, 'Discount',
                  '-\$${order.discount.toStringAsFixed(2)}',
                  isDiscount: true),
            Divider(height: 2.h),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('\$${order.total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary)),
                ]),
            SizedBox(height: 1.h),
            Divider(height: 2.h),
            Row(children: [
              Icon(Icons.location_on,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Expanded(
                  child: Text(order.deliveryAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
            ]),
          ]),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value,
      {bool isDiscount = false}) {
    return Padding(
        padding: EdgeInsets.only(bottom: 0.8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDiscount ? Colors.green : null)),
          ],
        ));
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Cancel Order?'),
              content:
                  const Text('Are you sure you want to cancel this order?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('No')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Yes, Cancel',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirm != true) return;

    try {
      await SupabaseService.client.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': 'Cancelled by customer',
      }).eq('id', orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: Colors.orange));
        _subscribeToOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _showSupportSheet(ThemeData theme) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
              padding: EdgeInsets.all(6.w),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Need Help?',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2.h),
                    Text(
                        'Contact our support team for any delivery issues.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    SizedBox(height: 3.h),
                    ListTile(
                        leading:
                            const Icon(Icons.chat, color: Colors.blue),
                        title: const Text('Live Chat'),
                        subtitle: const Text('Chat with support'),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Opening chat...')));
                        }),
                    ListTile(
                        leading:
                            const Icon(Icons.phone, color: Colors.green),
                        title: const Text('Call Support'),
                        subtitle: const Text('+961 XX XXX XXX'),
                        onTap: () {
                          Navigator.pop(ctx);
                        }),
                    SizedBox(height: 2.h),
                  ]),
            ));
  }
}