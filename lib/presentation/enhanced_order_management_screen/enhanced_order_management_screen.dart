import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_layout_wrapper.dart';

class EnhancedOrderManagementScreen extends ConsumerStatefulWidget {
  const EnhancedOrderManagementScreen({super.key});

  @override
  ConsumerState<EnhancedOrderManagementScreen> createState() =>
      _EnhancedOrderManagementScreenState();
}

class _EnhancedOrderManagementScreenState
    extends ConsumerState<EnhancedOrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _orders = [];
  String _filterStatus = 'all';

  final _statusFilters = ['all', 'pending', 'accepted', 'assigned', 'picked_up', 'delivered', 'rejected', 'cancelled'];

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
    setState(() { _isLoading = true; _errorMessage = null; });
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
        final aCreated = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(2000);
        final bCreated = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(2000);
        return bCreated.compareTo(aCreated);
      });

      setState(() { _orders = allOrders; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o['status'] == _filterStatus).toList();
  }

  List<Map<String, dynamic>> get _activeOrders =>
      _orders.where((o) => ['pending', 'accepted', 'assigned', 'picked_up'].contains(o['status'])).toList();

  List<Map<String, dynamic>> get _completedOrders =>
      _orders.where((o) => ['delivered', 'rejected', 'cancelled'].contains(o['status'])).toList();

  // ============================================================
  // ORDER ACTIONS
  // ============================================================

  Future<void> _acceptOrder(String orderId) async {
    try {
      await SupabaseService.client.from('orders').update({
        'status': 'accepted', 'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted'), backgroundColor: Colors.green));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final reason = await _showReasonDialog('Reject Order', 'Reason for rejection (optional)');
    if (reason == null) return; // cancelled dialog

    try {
      await SupabaseService.client.from('orders').update({
        'status': 'rejected',
        'cancellation_reason': reason.isNotEmpty ? reason : 'Rejected by admin',
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected'), backgroundColor: Colors.orange));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Confirm')),
      ],
    ));
  }

  Future<void> _showAssignDriverModal(String orderId) async {
    try {
      // Fetch active, verified drivers
      final driversResponse = await SupabaseService.client
          .from('drivers')
          .select('id, user_id, full_name, phone, vehicle_type, is_online, rating')
          .eq('is_active', true)
          .eq('is_verified', true)
          .order('is_online', ascending: false);

      final drivers = List<Map<String, dynamic>>.from(driversResponse);

      if (!mounted) return;
      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active drivers available'), backgroundColor: Colors.orange));
        return;
      }

      String? selectedDriverUserId;

      await showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.all(4.w), height: 60.h,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 12.w, height: 4, margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            Text('Assign Driver', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 1.h),
            Text('${drivers.where((d) => d['is_online'] == true).length} online, ${drivers.length} total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 2.h),
            Expanded(child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (ctx, i) {
                final driver = drivers[i];
                final driverUserId = driver['user_id'] as String;
                final driverName = driver['full_name'] as String? ?? 'Driver ${i + 1}';
                final isOnline = driver['is_online'] as bool? ?? false;
                final vehicle = driver['vehicle_type'] as String? ?? 'N/A';
                final rating = (driver['rating'] as num?)?.toDouble() ?? 0.0;
                final isSelected = selectedDriverUserId == driverUserId;

                return Card(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                  child: RadioListTile<String>(
                    value: driverUserId,
                    groupValue: selectedDriverUserId,
                    onChanged: (v) => setModalState(() => selectedDriverUserId = v),
                    title: Row(children: [
                      Text(driverName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                      SizedBox(width: 2.w),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle),
                      ),
                    ]),
                    subtitle: Text('$vehicle • ⭐ ${rating.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 11.sp, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                );
              },
            )),
            SizedBox(height: 2.h),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: selectedDriverUserId == null ? null : () async {
                Navigator.pop(ctx);
                await _assignDriver(orderId, selectedDriverUserId!);
              },
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h)),
              child: const Text('Assign Driver'),
            )),
          ]),
        )),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load drivers: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _assignDriver(String orderId, String driverUserId) async {
    try {
      await SupabaseService.client.from('orders').update({
        'driver_id': driverUserId,
        'status': 'assigned',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assigned successfully'), backgroundColor: Colors.green));
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
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
          title: Text('Order Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    SizedBox(height: 2.h),
                    Text(_errorMessage!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    SizedBox(height: 2.h),
                    ElevatedButton.icon(onPressed: _loadOrders, icon: const Icon(Icons.refresh), label: const Text('Retry')),
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
      // Status filter chips
      SizedBox(height: 6.h, child: ListView(scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        children: _statusFilters.map((s) {
          final isSelected = _filterStatus == s;
          final count = s == 'all' ? _orders.length : _orders.where((o) => o['status'] == s).length;
          return Padding(padding: EdgeInsets.only(right: 2.w), child: FilterChip(
            label: Text('${s == 'all' ? 'All' : s.replaceAll('_', ' ').toUpperCase()} ($count)'),
            selected: isSelected,
            onSelected: (_) => setState(() => _filterStatus = s),
            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
          ));
        }).toList(),
      )),
      Expanded(child: _buildOrderList(theme, _filteredOrders)),
    ]);
  }

  Widget _buildOrderList(ThemeData theme, List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(height: 2.h),
        Text('No orders', style: theme.textTheme.titleMedium),
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
    final orderNumber = order['order_number'] as String? ?? orderId.substring(0, 8);
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final paymentMethod = order['payment_method'] as String? ?? 'N/A';
    final deliveryAddress = order['delivery_address'] as String? ?? 'N/A';
    final customerPhone = order['customer_phone'] as String?;

    final store = order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? 'Unknown Store';

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? 'Unknown Customer';

    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Text('#$orderNumber', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ]),
          Divider(height: 2.h),

          // Info rows
          _infoRow(theme, Icons.store, storeName),
          _infoRow(theme, Icons.person, customerName),
          _infoRow(theme, Icons.location_on, deliveryAddress),
          if (customerPhone != null) _infoRow(theme, Icons.phone, customerPhone),
          _infoRow(theme, Icons.payment, paymentMethod == 'cash_on_delivery' ? 'Cash on Delivery' :
              paymentMethod == 'whish_money' ? 'Whish Money' : paymentMethod),
          Row(children: [
            Icon(Icons.attach_money, size: 15, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 1.w),
            Text('\$${total.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            const Spacer(),
            if (createdAt != null)
              Text('${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),

          // Action buttons
          if (status == 'pending') ...[
            SizedBox(height: 2.h),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(orderId),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )),
              SizedBox(width: 2.w),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _rejectOrder(orderId),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )),
            ]),
          ],
          if (status == 'accepted') ...[
            SizedBox(height: 2.h),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _showAssignDriverModal(orderId),
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Assign Driver'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String value) {
    return Padding(padding: EdgeInsets.only(bottom: 0.5.h), child: Row(children: [
      Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
      SizedBox(width: 2.w),
      Expanded(child: Text(value, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'assigned': return Colors.purple;
      case 'picked_up': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'rejected': case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}