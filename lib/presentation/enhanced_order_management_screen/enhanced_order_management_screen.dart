import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/admin_layout_wrapper.dart';

class EnhancedOrderManagementScreen extends ConsumerStatefulWidget {
  const EnhancedOrderManagementScreen({super.key});

  @override
  ConsumerState<EnhancedOrderManagementScreen> createState() =>
      _EnhancedOrderManagementScreenState();
}

class _EnhancedOrderManagementScreenState
    extends ConsumerState<EnhancedOrderManagementScreen> {
  bool _isLoading = true;
  String? _userRole;
  String? _userId;
  String? _errorMessage;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      _userId = user.id;

      final userData = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      setState(() {
        _userRole = userData['role'] as String?;
        _isLoading = false;
      });

      if (_userRole == 'admin') {
        _loadOrders();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user role: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService.client
          .from('orders')
          .select('''
            *,
            stores (name, name_ar, address),
            users!orders_customer_id_fkey (email, full_name)
          ''')
          .order('status', ascending: true)
          .order('created_at', ascending: false);

      final allOrders = List<Map<String, dynamic>>.from(response);

      allOrders.sort((a, b) {
        final aStatus = a['status'] as String;
        final bStatus = b['status'] as String;

        if (aStatus == 'pending' && bStatus != 'pending') return -1;
        if (aStatus != 'pending' && bStatus == 'pending') return 1;

        final aCreated = DateTime.parse(a['created_at'] as String);
        final bCreated = DateTime.parse(b['created_at'] as String);
        return bCreated.compareTo(aCreated);
      });

      setState(() {
        _orders = allOrders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final orderService = OrderService();
      await orderService.updateOrderStatus(orderId, 'accepted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully')),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept order: $e')));
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      final orderService = OrderService();
      await orderService.updateOrderStatus(
        orderId,
        'rejected',
        reason: 'Order rejected by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected successfully')),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject order: $e')));
      }
    }
  }

  Future<void> _showAssignDriverModal(String orderId) async {
    try {
      final driversResponse = await SupabaseService.client
          .from('users')
          .select('id, email, full_name')
          .eq('role', 'driver')
          .eq('is_active', true);

      final drivers = List<Map<String, dynamic>>.from(driversResponse);

      if (!mounted) return;

      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active drivers available')),
        );
        return;
      }

      String? selectedDriverId;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.all(4.w),
            height: 60.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Assign Driver',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Expanded(
                  child: ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final driverId = driver['id'] as String;
                      final driverName = driver['full_name'] as String? ??
                          driver['email'] as String;
                      final driverEmail = driver['email'] as String;

                      return RadioListTile<String>(
                        value: driverId,
                        groupValue: selectedDriverId,
                        onChanged: (value) {
                          setModalState(() {
                            selectedDriverId = value;
                          });
                        },
                        title: Text(
                          driverName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          driverEmail,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedDriverId == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _assignDriver(orderId, selectedDriverId!);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Assign Driver',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load drivers: $e')));
      }
    }
  }

  Future<void> _assignDriver(String orderId, String driverId) async {
    try {
      await SupabaseService.client.from('orders').update(
          {'driver_id': driverId, 'status': 'assigned'}).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assigned successfully')),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign driver: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWrapper(
      currentRoute: AppRoutes.enhancedOrderManagement,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          title: Text(
            'Order Management',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 2.h),
                    Text(
                      'Loading orders...',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 15.w, color: Colors.red),
                        SizedBox(height: 2.h),
                        Text(
                          'Error',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            _errorMessage!,
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
                          onPressed: _loadUserRole,
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
                : _userRole != 'admin'
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 15.w,
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Access Denied',
                              style: AppTheme.lightTheme.textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Admin access required',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
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
                                  'No Orders',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'No orders to manage',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(3.w),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              final orderId = order['id'] as String;
                              final orderNumber =
                                  order['order_number'] as String? ??
                                      orderId.substring(0, 8);
                              final status = order['status'] as String;
                              final total =
                                  (order['total'] as num?)?.toDouble() ?? 0.0;
                              final createdAt = DateTime.parse(
                                order['created_at'] as String,
                              );

                              final store =
                                  order['stores'] as Map<String, dynamic>?;
                              final storeName =
                                  store?['name'] as String? ?? 'Unknown Store';

                              final customer =
                                  order['users'] as Map<String, dynamic>?;
                              final customerName =
                                  customer?['full_name'] as String? ??
                                      'Unknown Customer';
                              final customerEmail =
                                  customer?['email'] as String? ?? '';

                              return Card(
                                margin: EdgeInsets.only(bottom: 2.h),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #$orderNumber',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 2.w,
                                              vertical: 0.5.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status)
                                                  .withAlpha(26),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 1.h),
                                      Divider(height: 1),
                                      SizedBox(height: 1.h),
                                      _buildInfoRow(
                                          Icons.store, 'Store', storeName),
                                      SizedBox(height: 0.5.h),
                                      _buildInfoRow(Icons.person, 'Customer',
                                          customerName),
                                      if (customerEmail.isNotEmpty) ...[
                                        SizedBox(height: 0.5.h),
                                        _buildInfoRow(Icons.email, 'Email',
                                            customerEmail),
                                      ],
                                      SizedBox(height: 0.5.h),
                                      _buildInfoRow(
                                        Icons.attach_money,
                                        'Total',
                                        '\$${total.toStringAsFixed(2)}',
                                      ),
                                      SizedBox(height: 0.5.h),
                                      _buildInfoRow(
                                        Icons.access_time,
                                        'Created',
                                        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                                      ),
                                      if (_userRole == 'admin' &&
                                          (status == 'pending' ||
                                              status == 'accepted')) ...[
                                        SizedBox(height: 2.h),
                                        Row(
                                          children: [
                                            if (status == 'pending') ...[
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _acceptOrder(orderId),
                                                  icon: Icon(Icons.check,
                                                      size: 16.sp),
                                                  label: Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                        fontSize: 12.sp),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 1.h,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 2.w),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _rejectOrder(orderId),
                                                  icon: Icon(Icons.close,
                                                      size: 16.sp),
                                                  label: Text(
                                                    'Reject',
                                                    style: TextStyle(
                                                        fontSize: 12.sp),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 1.h,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (status == 'accepted') ...[
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _showAssignDriverModal(
                                                          orderId),
                                                  icon: Icon(
                                                    Icons.local_shipping,
                                                    size: 16.sp,
                                                  ),
                                                  label: Text(
                                                    'Assign Driver',
                                                    style: TextStyle(
                                                        fontSize: 12.sp),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 1.h,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
      ),
    );
  }

  Widget _buildRoleBasedView() {
    switch (_userRole) {
      case 'admin':
        return _buildAdminOrderView();
      case 'driver':
        return Center(
          child: Text('Driver Order View', style: TextStyle(fontSize: 16.sp)),
        );
      case 'customer':
      case 'merchant':
      default:
        return Center(
          child: Text('Customer Order View', style: TextStyle(fontSize: 16.sp)),
        );
    }
  }

  Widget _buildAdminOrderView() {
    final adminProvider = provider.Provider.of<AdminProvider>(
      context,
      listen: false,
    );
    final isAdmin = adminProvider.isAdmin;

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Orders will appear here once placed',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final orderId = order['id'] as String;
          final orderNumber =
              order['order_number'] as String? ?? orderId.substring(0, 8);
          final status = order['status'] as String;
          final total = (order['total'] as num?)?.toDouble() ?? 0.0;
          final createdAt = DateTime.parse(order['created_at'] as String);

          final store = order['stores'] as Map<String, dynamic>?;
          final storeName = store?['name'] as String? ?? 'Unknown Store';

          final customer = order['users'] as Map<String, dynamic>?;
          final customerName =
              customer?['full_name'] as String? ?? 'Unknown Customer';
          final customerEmail = customer?['email'] as String? ?? '';

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$orderNumber',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Divider(height: 1),
                  SizedBox(height: 1.h),
                  _buildInfoRow(Icons.store, 'Store', storeName),
                  SizedBox(height: 0.5.h),
                  _buildInfoRow(Icons.person, 'Customer', customerName),
                  if (customerEmail.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    _buildInfoRow(Icons.email, 'Email', customerEmail),
                  ],
                  SizedBox(height: 0.5.h),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 0.5.h),
                  _buildInfoRow(
                    Icons.access_time,
                    'Created',
                    '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                  if (isAdmin &&
                      (status == 'pending' || status == 'accepted')) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (status == 'pending') ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptOrder(orderId),
                              icon: Icon(Icons.check, size: 16.sp),
                              label: Text(
                                'Accept',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rejectOrder(orderId),
                              icon: Icon(Icons.close, size: 16.sp),
                              label: Text(
                                'Reject',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (status == 'accepted') ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAssignDriverModal(orderId),
                              icon: Icon(Icons.local_shipping, size: 16.sp),
                              label: Text(
                                'Assign Driver',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
