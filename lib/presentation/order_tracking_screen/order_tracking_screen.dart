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
import '../../widgets/driver_rating_dialog.dart';
import '../../widgets/store_rating_dialog.dart';
import '../../l10n/generated/app_localizations.dart';

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
  bool _hasRated = false;      // SESSION 20: Track if user already rated driver
  bool _hasRatedStore = false; // SESSION 34: Track if user already rated store

  // SESSION 44: Cache notifier ref so dispose() doesn't crash
  // (ref.read() is illegal after widget unmount)
  dynamic _orderTrackingNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    String? orderId;

    if (args is Map<String, dynamic>) {
      orderId = args['orderId'] as String? ?? args['id'] as String?;
    } else if (args is String) {
      orderId = args;
    }

    if (orderId != null && orderId != _orderId) {
      _orderId = orderId;
      // SESSION 44: Cache notifier for safe dispose
      _orderTrackingNotifier = ref.read(orderTrackingProvider.notifier);
      // SESSION 44: Defer to avoid "modify provider during build" crash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _subscribeToOrder();
      });
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
      // SESSION 20: Check if already rated driver
      await _checkIfRated();
      // SESSION 34: Check if already rated store
      await _checkIfRatedStore();
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

  // SESSION 20: Check if user already rated this order's driver
  Future<void> _checkIfRated() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null || _orderId == null) return;

      final existing = await SupabaseService.client
          .from('driver_ratings')
          .select('id')
          .eq('order_id', _orderId!)
          .eq('customer_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() => _hasRated = existing != null);
      }
    } catch (e) {
      debugPrint('[RATING] Error checking rating: $e');
    }
  }

  // SESSION 20: Show driver rating dialog
  Future<void> _showRatingDialog(OrderModel order) async {
    if (order.driverId == null) return;

    // Get driver's internal ID (not user_id)
    String driverId = order.driverId!;
    String? driverName;

    try {
      // The order.driverId might be the user_id, get the driver record
      final driverData = await SupabaseService.client
          .from('drivers')
          .select('id, full_name')
          .eq('user_id', order.driverId!)
          .maybeSingle();

      if (driverData != null) {
        driverId = driverData['id'] as String;
        driverName = driverData['full_name'] as String?;
      }
    } catch (e) { debugPrint('[ORDER_TRACKING_SCREEN] Silent error: $e'); }

    if (!mounted) return;

    final rated = await DriverRatingDialog.show(
      context,
      orderId: order.id,
      driverId: driverId,
      driverName: driverName,
    );

    if (rated == true && mounted) {
      setState(() => _hasRated = true);
    }
  }

  // SESSION 34: Check if user already rated the store for this order
  Future<void> _checkIfRatedStore() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null || _orderId == null) return;

      final existing = await SupabaseService.client
          .from('store_ratings')
          .select('id')
          .eq('order_id', _orderId!)
          .eq('customer_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() => _hasRatedStore = existing != null);
      }
    } catch (e) {
      debugPrint('[STORE_RATING] Error checking rating: $e');
    }
  }

  // SESSION 34: Show store rating dialog
  Future<void> _showStoreRatingDialog(OrderModel order) async {
    final storeId = order.storeId;
    if (storeId == null || storeId.isEmpty) return;

    // Fetch store name for the dialog
    String? storeName;
    try {
      final storeData = await SupabaseService.client
          .from('stores')
          .select('name')
          .eq('id', storeId)
          .maybeSingle();
      storeName = storeData?['name'] as String?;
    } catch (e) { debugPrint('[ORDER_TRACKING_SCREEN] Silent error: $e'); }

    if (!mounted) return;

    final rated = await StoreRatingDialog.show(
      context,
      orderId: order.id,
      storeId: storeId,
      storeName: storeName,
    );

    if (rated == true && mounted) {
      setState(() => _hasRatedStore = true);
    }
  }

  @override
  void dispose() {
    // SESSION 44: Use cached notifier — ref.read() crashes after unmount
    try {
      _orderTrackingNotifier?.unsubscribe();
    } catch (_) {
      // Swallow — widget is being torn down, nothing to do
    }
    super.dispose();
  }

  // ============================================================
  // NAVIGATE TO AI MATE (Support)
  // ============================================================

  void _navigateToAiMate() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.mainLayout,
      (route) => false,
      arguments: {'initialIndex': 2},
    );
  }

  // ============================================================
  // CALL / WHATSAPP SUPPORT
  // ============================================================

  Future<void> _callSupport() async {
    final url = Uri.parse('tel:+96181483570');
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenDialerCall961, maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  Future<void> _whatsappSupport() async {
    final whatsappUrl = Uri.parse('whatsapp://send?phone=96181483570');
    final webUrl = Uri.parse('https://wa.me/96181483570');
    try {
      final launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webUrl, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsappPleaseContact, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
      }
    }
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
        return AppLocalizations.of(context)!.orderPlaced;
      case 'accepted':
        return AppLocalizations.of(context)!.orderAccepted2;
      case 'assigned':
        return AppLocalizations.of(context)!.driverAssigned2;
      case 'picked_up':
        return AppLocalizations.of(context)!.orderPickedUp;
      case 'delivered':
        return AppLocalizations.of(context)!.orderDelivered;
      case 'rejected':
        return AppLocalizations.of(context)!.orderRejected2;
      case 'cancelled':
        return AppLocalizations.of(context)!.orderCancelled2;
      default:
        return AppLocalizations.of(context)!.processing;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending':
        return AppLocalizations.of(context)!.yourOrderIsBeingReviewedBy;
      case 'accepted':
        return AppLocalizations.of(context)!.storeAcceptedYourOrderAssigningA;
      case 'assigned':
        return AppLocalizations.of(context)!.aDriverHasBeenAssignedAnd;
      case 'picked_up':
        return AppLocalizations.of(context)!.yourOrderIsOnTheWay;
      case 'delivered':
        return AppLocalizations.of(context)!.yourOrderHasBeenDeliveredEnjoy;
      case 'rejected':
        return AppLocalizations.of(context)!.unfortunatelyYourOrderWasRejected;
      case 'cancelled':
        return AppLocalizations.of(context)!.thisOrderHasBeenCancelled;
      default:
        return AppLocalizations.of(context)!.processingYourOrder;
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
        title: Text(AppLocalizations.of(context)!.orderTracking,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                Text(AppLocalizations.of(context)!.errorLoadingOrder,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                Text(_error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                    onPressed: _subscribeToOrder,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          Text(AppLocalizations.of(context)!.orderNotFound,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      label: Text(AppLocalizations.of(context)!.cancelOrder,
                          style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    )),
              // SESSION 20: Rate Driver + Back to Home when delivered
              if (status == 'delivered') ...[
                // Rate driver button (only if not yet rated and has a driver)
                if (!_hasRated && order.driverId != null) ...[
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(order),
                        icon: const Icon(Icons.star_rounded),
                        label: Text(AppLocalizations.of(context)!.rateYourDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
                  SizedBox(height: 1.5.h),
                ],
                // Already rated indicator
                if (_hasRated) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 2.w),
                        Flexible(child: Text(AppLocalizations.of(context)!.driverRated,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                ],
                // SESSION 34: Rate store button
                if (!_hasRatedStore) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStoreRatingDialog(order),
                      icon: const Icon(Icons.store_rounded),
                      label: Text(AppLocalizations.of(context)!.rateThisStore, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                ],
                // Store already rated indicator
                if (_hasRatedStore) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary, size: 20),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.storeRated,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                ],
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.mainLayout, (r) => false),
                      icon: const Icon(Icons.home),
                      label: Text(AppLocalizations.of(context)!.backToHome, maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
              ],
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
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(_statusIcon(status), color: color, size: 28),
              ),
              SizedBox(width: 3.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_statusTitle(status),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 0.3.h),
                    Text(_statusDescription(status),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
            ]),
            SizedBox(height: 2.h),
            Row(children: [
              Icon(Icons.receipt,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Flexible(child: Text(
                  'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Spacer(),
              Flexible(child: Text('\$${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            SizedBox(height: 0.5.h),
            Row(children: [
              Icon(Icons.payment,
                  size: 14, color: Colors.grey),
              SizedBox(width: 1.w),
              Flexible(child: Text(
                  order.paymentMethod == 'cash_on_delivery'
                      ? 'Cash on Delivery'
                      : order.paymentMethod == 'whish_money'
                          ? 'Whish Money'
                          : order.paymentMethod ?? 'N/A',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ]),
    );
  }

  // ============================================================
  // MAP SECTION
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
          infoWindow: InfoWindow(title: 'Driver'),
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
            color: Colors.white,
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
                  label: Text('Track on Google Maps', maxLines: 1, overflow: TextOverflow.ellipsis),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.yourDriver,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    Text(AppLocalizations.of(context)!.driverAssigned,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(AppLocalizations.of(context)!.onTheWay,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _callSupport();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.phone,
                      color: Colors.green, size: 20),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _navigateToAiMate();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Progress',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                ? Icon(Icons.check,
                                    size: 12, color: theme.colorScheme.surface)
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
                                    : Colors.grey.shade400
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
                                        ? Colors.grey
                                            .withOpacity(0.5)
                                        : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(_statusDescription(status),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: isFuture
                                        ? Colors.grey
                                            .withOpacity(0.3)
                                        : theme
                                            .colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  color: theme.colorScheme.error), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_statusDescription(currentStatus),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.orderDetails,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.5.h),
            _detailRow(
                theme, AppLocalizations.of(context)!.subtotal, '\$${order.subtotal.toStringAsFixed(2)}'),
            _detailRow(theme, AppLocalizations.of(context)!.deliveryFee,
                '\$${order.deliveryFee.toStringAsFixed(2)}'),
            _detailRow(
                theme, AppLocalizations.of(context)!.tax, '\$${order.tax.toStringAsFixed(2)}'),
            if (order.discount > 0)
              _detailRow(theme, AppLocalizations.of(context)!.discount,
                  '-\$${order.discount.toStringAsFixed(2)}',
                  isDiscount: true),
            Divider(height: 2.h),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(AppLocalizations.of(context)!.total,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Flexible(child: Text('\$${order.total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                          color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
            Flexible(child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Flexible(child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDiscount ? Colors.green : null), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
              title: Text(AppLocalizations.of(context)!.cancelOrder2, maxLines: 1, overflow: TextOverflow.ellipsis),
              content:
                  Text(AppLocalizations.of(context)!.areYouSureYouWantTo2, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.no2, maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(context)!.yesCancel,
                        style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.orderCancelled, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.orange));
        _subscribeToOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to cancel: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
      }
    }
  }

  // ============================================================
  // SUPPORT BOTTOM SHEET
  // ============================================================

  void _showSupportSheet(ThemeData theme) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Container(
              padding: EdgeInsets.all(6.w),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.needHelp,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(
                        AppLocalizations.of(context)!.getInstantHelpFromOurAi,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 3.h),
                    ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.smart_toy, color: Colors.blue),
                        ),
                        title: Text(AppLocalizations.of(context)!.aiMate, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(AppLocalizations.of(context)!.chatWithOurAiAssistant, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToAiMate();
                        }),
                    ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.phone, color: Colors.green),
                        ),
                        title: Text(AppLocalizations.of(context)!.callSupport, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: const Text('+961 81-483570'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          _callSupport();
                        }),
                    ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.message, color: Color(0xFF25D366)),
                        ),
                        title: Text(AppLocalizations.of(context)!.whatsapp, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(AppLocalizations.of(context)!.n247Support, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          _whatsappSupport();
                        }),
                    SizedBox(height: 2.h),
                  ]),
            ));
  }
}