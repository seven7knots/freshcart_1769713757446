import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import './widgets/online_toggle_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with WidgetsBindingObserver {
  bool _isOnline = false;
  bool _isLoading = true;
  String _driverName = 'Driver';
  List<Map<String, dynamic>> _assignedOrders = [];
  bool _isUpdatingOrder = false;

  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        _navigateToLogin();
        return;
      }

      final userData = await SupabaseService.client
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();

      final driverData = await SupabaseService.client
          .from('drivers')
          .select('id, is_online')
          .eq('user_id', userId)
          .maybeSingle();

      final assignedOrders = await SupabaseService.client
          .from('orders')
          .select('*, stores:store_id (name, address, lat, lng), users:customer_id (full_name, email, phone)')
          .eq('driver_id', userId)
          .inFilter('status', ['assigned', 'picked_up'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _driverName = userData['full_name'] ?? AppLocalizations.of(context)!.driver2;
          _isOnline = driverData?['is_online'] ?? false;
          _assignedOrders = List<Map<String, dynamic>>.from(assignedOrders);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      final uid = SupabaseService.client.auth.currentUser?.id;
      if (uid != null) {
        SupabaseService.client.from('drivers').update({'is_online': false}).eq('user_id', uid).then((_) {}).catchError((_) {});
      }
    }
  }

  void _navigateToLogin() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);

  Future<void> _toggleOnlineStatus() async {
    HapticFeedback.mediumImpact();
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;
      final newStatus = !_isOnline;
      await SupabaseService.client
          .from('drivers')
          .update({'is_online': newStatus}).eq('user_id', userId);
      setState(() => _isOnline = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(newStatus ? AppLocalizations.of(context)!.youAreNowOnline : AppLocalizations.of(context)!.youAreNowOffline, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: newStatus ? Colors.green : Colors.grey));
      }
    } catch (e) { debugPrint('[DRIVER_HOME_SCREEN] Silent error: $e'); }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    if (_isUpdatingOrder) return;
    setState(() => _isUpdatingOrder = true);
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus == 'delivered') {
        updates['actual_delivery_time'] = DateTime.now().toIso8601String();
      }
      await SupabaseService.client
          .from('orders')
          .update(updates)
          .eq('id', orderId);

      // Update deliveries table if exists
      try {
        if (newStatus == 'picked_up') {
          await SupabaseService.client.from('deliveries').update({
            'status': 'picked_up',
            'pickup_time': DateTime.now().toIso8601String()
          }).eq('order_id', orderId);
        } else if (newStatus == 'delivered') {
          await SupabaseService.client.from('deliveries').update({
            'status': 'delivered',
            'delivery_time': DateTime.now().toIso8601String()
          }).eq('order_id', orderId);
        }
      } catch (e) { debugPrint('[DRIVER_HOME_SCREEN] Silent error: $e'); }

      // SESSION 32 FIX: auto go online after delivery completes
      if (newStatus == 'delivered') {
        final uid = SupabaseService.client.auth.currentUser?.id;
        if (uid != null) {
          try {
            await SupabaseService.client
                .from('drivers')
                .update({'is_online': true}).eq('user_id', uid);
            if (mounted) setState(() => _isOnline = true);
          } catch (e) { debugPrint('[DRIVER_HOME_SCREEN] Silent error: $e'); }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Order $newStatus', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green));
      }
      await _loadDriverData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingOrder = false);
    }
  }

  Future<void> _openNavigation(String address, double? lat, double? lng) async {
    double targetLat = lat ?? 0;
    double targetLng = lng ?? 0;

    if (targetLat == 0 || targetLng == 0) {
      final coords = await _locationService.forwardGeocode(address);
      if (coords != null) {
        targetLat = coords['lat']!;
        targetLng = coords['lng']!;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotDetermineLocationCoordinates, maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
        return;
      }
    }

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noPhoneNumberAvailable, maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
      return;
    }
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _browseAsCustomer() {
    Navigator.pushNamed(context, '/main-layout');
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.logout, maxLines: 1, overflow: TextOverflow.ellipsis),
              content: Text(AppLocalizations.of(context)!.areYouSure, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(context)!.logout, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ));
    if (confirm == true) {
      final uid = SupabaseService.client.auth.currentUser?.id;
      if (uid != null) {
        try { await SupabaseService.client.from('drivers').update({'is_online': false}).eq('user_id', uid); } catch (e) { debugPrint('[DRIVER_HOME_SCREEN] Silent error: $e'); }
      }
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
      }
    }
  }

  Future<void> _confirmDelivery(
      String orderId, double total, String paymentMethod) async {
    if (paymentMethod == 'cash_on_delivery' || paymentMethod == 'cash') {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text('Cash on Delivery', maxLines: 1, overflow: TextOverflow.ellipsis),
                content: Text(
                    'Confirm you collected \$${total.toStringAsFixed(2)} in cash from the customer.', maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Confirm Cash Collected', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ));
      if (confirm != true) return;
      try {
        await SupabaseService.client.from('orders').update({
          'cash_collected_amount': total,
          'cash_collected_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      } catch (e) { debugPrint('[DRIVER_HOME_SCREEN] Silent error: $e'); }
    }
    await _updateOrderStatus(orderId, 'delivered');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hello, $_driverName', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: AppLocalizations.of(context)!.browseApp,
            onPressed: _browseAsCustomer,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDriverData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OnlineToggleWidget(
                          isOnline: _isOnline, onToggle: _toggleOnlineStatus),
                      SizedBox(height: 3.h),
                      _buildAssignedOrdersSection(theme),
                      SizedBox(height: 3.h),
                    ]),
              ),
            ),
    );
  }

  Widget _buildAssignedOrdersSection(ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(child: Text(AppLocalizations.of(context)!.assignedOrders,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Spacer(),
            if (_assignedOrders.isNotEmpty)
              Text('${_assignedOrders.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
          SizedBox(height: 2.h),
          if (_assignedOrders.isEmpty)
            _buildEmptyState(theme)
          else
            ..._assignedOrders.map((order) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildOrderCard(theme, order),
                )),
        ]);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(Icons.inbox_outlined,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context)!.noAssignedOrders,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 0.5.h),
        Text(AppLocalizations.of(context)!.newOrdersWillAppearHereWhen,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildOrderCard(ThemeData theme, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderNumber =
        order['order_number'] as String? ?? orderId.substring(0, 8);
    final status = order['status'] as String;
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryAddress = order['delivery_address'] as String? ?? AppLocalizations.of(context)!.nA;
    final deliveryLat = (order['delivery_lat'] as num?)?.toDouble();
    final deliveryLng = (order['delivery_lng'] as num?)?.toDouble();
    final paymentMethod = order['payment_method'] as String? ?? AppLocalizations.of(context)!.nA;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');

    final store = order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? AppLocalizations.of(context)!.store2;
    final storeAddress = store?['address'] as String? ?? '';
    final storeLat = (store?['lat'] as num?)?.toDouble();
    final storeLng = (store?['lng'] as num?)?.toDouble();

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? AppLocalizations.of(context)!.customer2;
    final customerPhone = customer?['phone'] as String?;

    // SESSION 39: Delivery instructions for driver
    final deliveryInstructions = order['delivery_instructions'] as String?
        ?? order['instructions'] as String?
        ?? '';
    final specialInstructions = order['special_instructions'] as String? ?? '';

    final isAssigned = status == 'assigned';
    final isPickedUp = status == 'picked_up';
    final statusColor = isAssigned ? Colors.blue : Colors.teal;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Spacer(),
              Flexible(child: Text('\$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            SizedBox(height: 1.5.h),
            Text('Order #$orderNumber',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Row(children: [
              Icon(Icons.payment,
                  size: 15, color: Colors.grey),
              SizedBox(width: 1.w),
              Flexible(child: Text(
                  paymentMethod == 'cash_on_delivery' || paymentMethod == 'cash'
                      ? AppLocalizations.of(context)!.cashOnDelivery2
                      : paymentMethod == 'whish_money'
                          ? AppLocalizations.of(context)!.whishMoney2
                          : paymentMethod,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.store, size: 16, color: Colors.blue),
                      SizedBox(width: 1.w),
                      Flexible(child: Text('PICKUP',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Spacer(),
                      if (storeLat != null)
                        const Icon(Icons.gps_fixed, size: 12, color: Colors.green),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(storeName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (storeAddress.isNotEmpty)
                      Text(storeAddress,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.green),
                      SizedBox(width: 1.w),
                      Flexible(child: Text(AppLocalizations.of(context)!.deliverTo,
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Spacer(),
                      if (deliveryLat != null)
                        const Icon(Icons.gps_fixed, size: 12, color: Colors.green),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(customerName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(deliveryAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            // SESSION 39: Show delivery instructions if present
            if (deliveryInstructions.isNotEmpty || specialInstructions.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.note_alt_outlined, size: 16, color: Colors.orange),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(AppLocalizations.of(context)!.deliveryInstructions2,
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      SizedBox(height: 0.5.h),
                      if (deliveryInstructions.isNotEmpty)
                        Text(deliveryInstructions,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis),
                      if (specialInstructions.isNotEmpty) ...[
                        SizedBox(height: 0.3.h),
                        Text('Handling: $specialInstructions',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ]),
              ),
            ],

            SizedBox(height: 1.5.h),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () {
                  if (isAssigned) {
                    _openNavigation(storeAddress, storeLat, storeLng);
                  } else {
                    _openNavigation(deliveryAddress, deliveryLat, deliveryLng);
                  }
                },
                icon: const Icon(Icons.navigation, size: 16),
                label: Text(
                    isAssigned ? AppLocalizations.of(context)!.navigateToStore : AppLocalizations.of(context)!.navigateToCustomer,
                    style: TextStyle(fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h)),
              )),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: () => _callCustomer(customerPhone),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.phone, color: Colors.green, size: 18),
                ),
              ),
            ]),
            SizedBox(height: 1.5.h),
            if (isAssigned)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingOrder
                        ? null
                        : () => _updateOrderStatus(orderId, 'picked_up'),
                    icon: _isUpdatingOrder
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: Text(AppLocalizations.of(context)!.markPickedUp, maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ))
            else if (isPickedUp)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingOrder
                        ? null
                        : () => _confirmDelivery(orderId, total, paymentMethod),
                    icon: _isUpdatingOrder
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.done_all),
                    label: Text(AppLocalizations.of(context)!.markDelivered, maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )),
            if (createdAt != null) ...[
              SizedBox(height: 1.h),
              Text(
                  'Ordered: ${createdAt.toLocal().day}/${createdAt.toLocal().month} at ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
    );
  }
}