import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/push_notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_layout_wrapper.dart';
import '../../l10n/generated/app_localizations.dart';

class EnhancedOrderManagementScreen extends ConsumerStatefulWidget {
  const EnhancedOrderManagementScreen({super.key});

  @override
  ConsumerState<EnhancedOrderManagementScreen> createState() =>
      _EnhancedOrderManagementScreenState();
}

class _EnhancedOrderManagementScreenState
    extends ConsumerState<EnhancedOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _orders = [];
  String _filterStatus = 'all';

  final _statusFilters = [
    'all',
    'pending',
    'accepted',
    'assigned',
    'picked_up',
    'delivered',
    'rejected',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await SupabaseService.client.from('orders').select('''
            *,
            stores (name, address),
            users!orders_customer_id_fkey (email, full_name, phone)
          ''').eq('is_demo', false).order('created_at', ascending: false);

      final allOrders = List<Map<String, dynamic>>.from(response);

      // Sort: pending first, then by created_at desc
      allOrders.sort((a, b) {
        final aStatus = a['status'] as String? ?? '';
        final bStatus = b['status'] as String? ?? '';
        if (aStatus == 'pending' && bStatus != 'pending') return -1;
        if (aStatus != 'pending' && bStatus == 'pending') return 1;
        final aCreated =
            DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(2000);
        final bCreated =
            DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(2000);
        return bCreated.compareTo(aCreated);
      });

      setState(() {
        _orders = allOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o['status'] == _filterStatus).toList();
  }

  List<Map<String, dynamic>> get _activeOrders => _orders
      .where((o) =>
          ['pending', 'accepted', 'assigned', 'picked_up'].contains(o['status']))
      .toList();

  List<Map<String, dynamic>> get _completedOrders => _orders
      .where((o) =>
          ['delivered', 'rejected', 'cancelled'].contains(o['status']))
      .toList();

  // ============================================================
  // ORDER ACTIONS
  // ============================================================

  Future<void> _acceptOrder(String orderId) async {
    try {
      await SupabaseService.client.from('orders').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      final order = _orders.firstWhere((o) => o['id'] == orderId, orElse: () => {});
      if (order.isNotEmpty) {
        final customerId =
            order['user_id'] as String? ?? order['customer_id'] as String?;
        final storeName =
            (order['stores'] as Map<String, dynamic>?)?['name'] as String?;
        if (customerId != null) {
          PushNotificationService.notifyOrderStatus(
            customerId: customerId,
            orderId: orderId,
            status: 'confirmed',
            storeName: storeName,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.orderAccepted, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final reason =
        await _showReasonDialog(AppLocalizations.of(context)!.rejectOrder, 'Reason for rejection (optional)');
    if (reason == null) return;

    try {
      await SupabaseService.client.from('orders').update({
        'status': 'rejected',
        'cancellation_reason': reason.isNotEmpty ? reason : 'Rejected by admin',
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      final order =
          _orders.firstWhere((o) => o['id'] == orderId, orElse: () => {});
      if (order.isNotEmpty) {
        final customerId =
            order['user_id'] as String? ?? order['customer_id'] as String?;
        final storeName =
            (order['stores'] as Map<String, dynamic>?)?['name'] as String?;
        if (customerId != null) {
          PushNotificationService.notifyOrderStatus(
            customerId: customerId,
            orderId: orderId,
            status: 'cancelled',
            storeName: storeName,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.orderRejected, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              content: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: hint, border: const OutlineInputBorder()),
                  maxLines: 3),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    child: Text(AppLocalizations.of(context)!.confirm, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ));
  }

  // ============================================================
  // ASSIGN DRIVER — LAYER 1: DB query filters online+approved+active
  //                LAYER 2: Dart-side filter as safety net
  //                LAYER 3: Re-verify before DB write in _assignDriver
  // ============================================================

  Future<void> _showAssignDriverModal(String orderId) async {
    try {
      // LAYER 1: DB-level filter — online + approved + active
      final driversResponse = await SupabaseService.client
          .from('drivers')
          .select('id, user_id, full_name, phone, vehicle_type, is_online, is_active, status, rating')
          .eq('is_active', true)
          .eq('is_online', true)
          .eq('status', 'approved')
          .order('rating', ascending: false);

      // LAYER 2: Dart-side filter — guards against RLS bypasses or stale data
      // If a driver slipped through the DB filter with is_online=false, drop them here.
      final drivers = List<Map<String, dynamic>>.from(driversResponse)
          .where((d) =>
              d['is_online'] == true &&
              d['is_active'] == true &&
              (d['status'] as String?) == 'approved')
          .toList();

      if (!mounted) return;

      // Hard block: if nobody is genuinely online, show snackbar and bail out.
      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.noActiveDriversOnlineCannotAssign, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.orange));
        return;
      }

      String? selectedDriverUserId;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.all(4.w),
            height: 60.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 12.w,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Title
                Text(AppLocalizations.of(context)!.assignDriver,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),

                // Online count — now always equals total since we filtered
                Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 1.5.w),
                  Flexible(child: Text(
                    '${drivers.length} online, ${drivers.length} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                SizedBox(height: 2.h),

                // Driver list — all guaranteed online
                Expanded(
                  child: ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (ctx, i) {
                      final driver = drivers[i];
                      final driverUserId = driver['user_id'] as String;
                      final driverName =
                          driver['full_name'] as String? ?? 'Driver ${i + 1}';
                      final vehicle =
                          driver['vehicle_type'] as String? ?? AppLocalizations.of(context)!.nA;
                      final rating =
                          (driver['rating'] as num?)?.toDouble() ?? 0.0;
                      final isSelected = selectedDriverUserId == driverUserId;

                      return Card(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : null,
                        child: RadioListTile<String>(
                          value: driverUserId,
                          groupValue: selectedDriverUserId,
                          onChanged: (v) =>
                              setModalState(() => selectedDriverUserId = v),
                          title: Row(children: [
                            Flexible(child: Text(driverName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 2.w),
                            // Always green — offline drivers never reach this list
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle),
                            ),
                          ]),
                          subtitle: Text(
                            '$vehicle • ⭐ ${rating.toStringAsFixed(1)}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 2.h),

                // Assign button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedDriverUserId == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _assignDriver(orderId, selectedDriverUserId!);
                          },
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h)),
                    child: Text(AppLocalizations.of(context)!.assignDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load drivers: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _assignDriver(String orderId, String driverUserId) async {
    // LAYER 3: Re-verify from DB that driver is still online RIGHT NOW
    // before any write. Handles the race where driver went offline between
    // the modal opening and the assign button being tapped.
    try {
      final verifyResponse = await SupabaseService.client
          .from('drivers')
          .select('id, is_online, is_active, status')
          .eq('user_id', driverUserId)
          .maybeSingle();

      final isOnline = verifyResponse?['is_online'] as bool? ?? false;
      final isActive = verifyResponse?['is_active'] as bool? ?? false;
      final status = verifyResponse?['status'] as String? ?? '';

      if (!isOnline || !isActive || status != 'approved') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.assignmentBlockedDriverIsNoLonger2, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4)));
        }
        return; // Hard stop — do not write to orders table
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not verify driver status: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
      }
      return;
    }

    // All checks passed — safe to assign
    try {
      await SupabaseService.client.from('orders').update({
        'driver_id': driverUserId,
        'status': 'assigned',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      final order =
          _orders.firstWhere((o) => o['id'] == orderId, orElse: () => {});
      if (order.isNotEmpty) {
        final storeAddress =
            (order['stores'] as Map<String, dynamic>?)?['address'] as String? ??
                'Store';

        PushNotificationService.notifyDriverNewDelivery(
          driverUserId: driverUserId,
          orderId: orderId,
          pickupAddress: storeAddress,
        );

        final customerId =
            order['user_id'] as String? ?? order['customer_id'] as String?;
        if (customerId != null) {
          PushNotificationService.notifyOrderStatus(
            customerId: customerId,
            orderId: orderId,
            status: 'picked_up',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.driverAssignedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminLayoutWrapper(
      currentRoute: AppRoutes.enhancedOrderManagement,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.orderManagement,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
          ],
          bottom: TabBar(controller: _tabController, tabs: [
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'Completed (${_completedOrders.length})'),
            Tab(text: 'All (${_orders.length})'),
          ]),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.colorScheme.error),
                        SizedBox(height: 2.h),
                        Text(_errorMessage!,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        ElevatedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]))
                : TabBarView(controller: _tabController, children: [
                    _buildOrderList(theme, _activeOrders),
                    _buildOrderList(theme, _completedOrders),
                    _buildAllOrdersTab(theme),
                  ]),
      ),
    );
  }

  Widget _buildAllOrdersTab(ThemeData theme) {
    return Column(children: [
      SizedBox(
        height: 6.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          children: _statusFilters.map((s) {
            final isSelected = _filterStatus == s;
            final count = s == 'all'
                ? _orders.length
                : _orders.where((o) => o['status'] == s).length;
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: FilterChip(
                label: Text(
                    '${s == 'all' ? AppLocalizations.of(context)!.all2 : s.replaceAll('_', ' ').toUpperCase()} ($count)', maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: isSelected,
                onSelected: (_) => setState(() => _filterStatus = s),
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(child: _buildOrderList(theme, _filteredOrders)),
    ]);
  }

  Widget _buildOrderList(ThemeData theme, List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined,
            size: 60, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context)!.noOrders, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(theme, orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(ThemeData theme, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderNumber =
        order['order_number'] as String? ?? orderId.substring(0, 8);
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '');
    final paymentMethod = order['payment_method'] as String? ?? AppLocalizations.of(context)!.nA;
    final deliveryAddress = order['delivery_address'] as String? ?? AppLocalizations.of(context)!.nA;
    final customerPhone = order['customer_phone'] as String?;

    final store = order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? AppLocalizations.of(context)!.unknownStore;

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? AppLocalizations.of(context)!.unknownCustomer;

    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Flexible(child: Text('#$orderNumber',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Spacer(),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          Divider(height: 2.h),

          // Info rows
          _infoRow(theme, Icons.store, storeName),
          _infoRow(theme, Icons.person, customerName),
          _infoRow(theme, Icons.location_on, deliveryAddress),
          if (customerPhone != null)
            _infoRow(theme, Icons.phone, customerPhone),
          _infoRow(
              theme,
              Icons.payment,
              paymentMethod == 'cash_on_delivery'
                  ? 'Cash on Delivery'
                  : paymentMethod == 'whish_money'
                      ? AppLocalizations.of(context)!.whishMoney
                      : paymentMethod),
          Row(children: [
            Icon(Icons.attach_money,
                size: 15, color: Colors.grey),
            SizedBox(width: 1.w),
            Flexible(child: Text('\$${total.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Spacer(),
            if (createdAt != null)
              Text(
                  '${createdAt.toLocal().day}/${createdAt.toLocal().month} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),

          // Action buttons
          if (status == 'pending') ...[
            SizedBox(height: 2.h),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(orderId),
                icon: const Icon(Icons.check, size: 18),
                label: Text(AppLocalizations.of(context)!.accept, maxLines: 1, overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              )),
              SizedBox(width: 2.w),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () => _rejectOrder(orderId),
                icon: const Icon(Icons.close, size: 18),
                label: Text(AppLocalizations.of(context)!.reject, maxLines: 1, overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              )),
            ]),
          ],
          if (status == 'accepted') ...[
            SizedBox(height: 2.h),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignDriverModal(orderId),
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: Text(AppLocalizations.of(context)!.assignDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                )),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String value) {
    return Padding(
        padding: EdgeInsets.only(bottom: 0.5.h),
        child: Row(children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 2.w),
          Expanded(
              child: Text(value,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]));
  }

  Color _getStatusColor(String status) {
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
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}