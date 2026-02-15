import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import './widgets/delivery_stats_widget.dart';
import './widgets/earnings_card_widget.dart';
import './widgets/online_toggle_widget.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  bool _isLoading = true;
  String _driverName = 'Driver';
  double _todayEarnings = 0.0;
  int _completedDeliveries = 0;
  List<Map<String, dynamic>> _assignedOrders = [];
  bool _isUpdatingOrder = false;

  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
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

      if (driverData == null) {
        setState(() {
          _driverName = userData['full_name'] ?? 'Driver';
          _isLoading = false;
        });
        return;
      }

      final driverId = driverData['id'];
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final earningsData = await SupabaseService.client
          .from('deliveries')
          .select('driver_earnings')
          .eq('driver_id', driverId)
          .eq('status', 'delivered')
          .gte('delivery_time', startOfDay.toIso8601String());

      double totalEarnings = 0.0;
      for (var d in earningsData) {
        totalEarnings += (d['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }

      final completedCount = await SupabaseService.client
          .from('deliveries')
          .select('id')
          .eq('driver_id', driverId)
          .eq('status', 'delivered')
          .gte('delivery_time', startOfDay.toIso8601String());

      final assignedOrders =
          await SupabaseService.client.from('orders').select('''
            *, stores:store_id (name, address, phone, lat, lng),
            users:customer_id (full_name, email, phone)
          ''').eq('driver_id', userId).inFilter(
              'status', ['assigned', 'picked_up']).order('created_at',
              ascending: false);

      setState(() {
        _driverName = userData['full_name'] ?? 'Driver';
        _isOnline = driverData['is_online'] ?? false;
        _todayEarnings = totalEarnings;
        _completedDeliveries = completedCount.length;
        _assignedOrders = List<Map<String, dynamic>>.from(assignedOrders);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading driver data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.driverLogin);

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
            content:
                Text(newStatus ? 'You are now online' : 'You are now offline'),
            backgroundColor: newStatus ? Colors.green : Colors.grey));
      }
    } catch (_) {}
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
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Order ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green));
      }
      await _loadDriverData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isUpdatingOrder = false);
    }
  }

  /// Navigate to a location — uses real coordinates, falls back to geocoding address
  Future<void> _openNavigation(String address, double? lat, double? lng) async {
    double targetLat = lat ?? 0;
    double targetLng = lng ?? 0;

    // If no coordinates, try geocoding the address
    if (targetLat == 0 || targetLng == 0) {
      final coords = await _locationService.forwardGeocode(address);
      if (coords != null) {
        targetLat = coords['lat']!;
        targetLng = coords['lng']!;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not determine location coordinates')));
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')));
      return;
    }
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Logout')),
              ],
            ));
    if (confirm == true) {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.driverLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hello, $_driverName'),
        actions: [
          IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.driverPerformanceDashboard)),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: _handleLogout),
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
                      EarningsCardWidget(
                          todayEarnings: _todayEarnings,
                          completedDeliveries: _completedDeliveries),
                      SizedBox(height: 3.h),
                      DeliveryStatsWidget(
                          completedToday: _completedDeliveries,
                          activeHours: 0,
                          averagePerDelivery: _completedDeliveries > 0
                              ? _todayEarnings / _completedDeliveries
                              : 0.0),
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
            Text('Assigned Orders',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_assignedOrders.isNotEmpty)
              Text('${_assignedOrders.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
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
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(Icons.inbox_outlined,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(height: 2.h),
        Text('No Assigned Orders',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 0.5.h),
        Text('New orders will appear here when assigned to you',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildOrderCard(ThemeData theme, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderNumber =
        order['order_number'] as String? ?? orderId.substring(0, 8);
    final status = order['status'] as String;
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryAddress = order['delivery_address'] as String? ?? 'N/A';
    final deliveryLat = (order['delivery_lat'] as num?)?.toDouble();
    final deliveryLng = (order['delivery_lng'] as num?)?.toDouble();
    final paymentMethod = order['payment_method'] as String? ?? 'N/A';
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '');

    final store = order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? 'Store';
    final storeAddress = store?['address'] as String? ?? '';
    final storeLat = (store?['lat'] as num?)?.toDouble();
    final storeLng = (store?['lng'] as num?)?.toDouble();

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? 'Customer';
    final customerPhone = customer?['phone'] as String?;

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
            // Header
            Row(children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary)),
            ]),
            SizedBox(height: 1.5.h),

            Text('Order #$orderNumber',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 1.h),

            // Payment method
            Row(children: [
              Icon(Icons.payment,
                  size: 15, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                  paymentMethod == 'cash_on_delivery'
                      ? '💵 Cash on Delivery'
                      : paymentMethod == 'whish_money'
                          ? '📱 Whish Money'
                          : paymentMethod,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            SizedBox(height: 1.h),

            // Store info (pickup)
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.store, size: 16, color: Colors.blue),
                      SizedBox(width: 1.w),
                      Text('PICKUP',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue)),
                      const Spacer(),
                      if (storeLat != null)
                        Icon(Icons.gps_fixed,
                            size: 12, color: Colors.green),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(storeName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (storeAddress.isNotEmpty)
                      Text(storeAddress,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ]),
            ),
            SizedBox(height: 1.h),

            // Customer info (delivery)
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.green),
                      SizedBox(width: 1.w),
                      Text('DELIVER TO',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green)),
                      const Spacer(),
                      if (deliveryLat != null)
                        Icon(Icons.gps_fixed,
                            size: 12, color: Colors.green),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(customerName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(deliveryAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            SizedBox(height: 1.5.h),

            // Quick action buttons
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () {
                  if (isAssigned) {
                    // Navigate to store
                    _openNavigation(storeAddress, storeLat, storeLng);
                  } else {
                    // Navigate to customer
                    _openNavigation(
                        deliveryAddress, deliveryLat, deliveryLng);
                  }
                },
                icon: const Icon(Icons.navigation, size: 16),
                label: Text(
                    isAssigned
                        ? 'Navigate to Store'
                        : 'Navigate to Customer',
                    style: TextStyle(fontSize: 10.sp)),
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
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.phone,
                      color: Colors.green, size: 18),
                ),
              ),
            ]),
            SizedBox(height: 1.5.h),

            // Main action button
            if (isAssigned)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingOrder
                        ? null
                        : () => _updateOrderStatus(orderId, 'picked_up'),
                    icon: _isUpdatingOrder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: const Text('Mark Picked Up'),
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
                        : () => _confirmDelivery(
                            orderId, total, paymentMethod),
                    icon: _isUpdatingOrder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.done_all),
                    label: const Text('Mark Delivered'),
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
                  'Ordered: ${createdAt.day}/${createdAt.month} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ]),
    );
  }

  /// Confirm delivery — if COD, confirm cash collected first
  Future<void> _confirmDelivery(
      String orderId, double total, String paymentMethod) async {
    if (paymentMethod == 'cash_on_delivery') {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Cash on Delivery'),
                content: Text(
                    'Confirm you collected \$${total.toStringAsFixed(2)} in cash from the customer.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('Confirm Cash Collected'),
                  ),
                ],
              ));
      if (confirm != true) return;

      try {
        await SupabaseService.client.from('orders').update({
          'cash_collected_amount': total,
          'cash_collected_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      } catch (_) {}
    }

    await _updateOrderStatus(orderId, 'delivered');
  }
}