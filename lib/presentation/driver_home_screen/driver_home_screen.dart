import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDriverData();

    // Track driver screen view
    AnalyticsService.logScreenView(screenName: 'driver_home_screen');
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
          .single();

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
      for (var delivery in earningsData) {
        totalEarnings +=
            (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }

      final completedCount = await SupabaseService.client
          .from('deliveries')
          .select('id')
          .eq('driver_id', driverId)
          .eq('status', 'delivered')
          .gte('delivery_time', startOfDay.toIso8601String());

      // Load assigned orders where driver_id = current user and status in ('assigned', 'picked_up')
      final assignedOrders = await SupabaseService.client
          .from('orders')
          .select('''
            *,
            stores:store_id (name, address, phone),
            users:customer_id (full_name, email, phone)
          ''')
          .eq('driver_id', userId)
          .inFilter('status', ['assigned', 'picked_up'])
          .order('created_at', ascending: false);

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
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.driverLogin);
  }

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

      // Track driver online status change
      await AnalyticsService.logDriverOnlineStatusChange(
        driverId: userId,
        isOnline: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(newStatus ? 'You are now online' : 'You are now offline'),
            backgroundColor: newStatus ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    if (_isUpdatingOrder) return;

    setState(() => _isUpdatingOrder = true);

    try {
      await SupabaseService.client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh orders list
      await _loadDriverData();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdatingOrder = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

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
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF616161);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hello, $_driverName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(AppRoutes.driverPerformanceDashboard);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
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
                      isOnline: _isOnline,
                      onToggle: _toggleOnlineStatus,
                    ),
                    SizedBox(height: 3.h),
                    EarningsCardWidget(
                      todayEarnings: _todayEarnings,
                      completedDeliveries: _completedDeliveries,
                    ),
                    SizedBox(height: 3.h),
                    DeliveryStatsWidget(
                      completedToday: _completedDeliveries,
                      activeHours: 0,
                      averagePerDelivery: _completedDeliveries > 0
                          ? _todayEarnings / _completedDeliveries
                          : 0.0,
                    ),
                    SizedBox(height: 3.h),
                    _buildAssignedOrdersSection(),
                    SizedBox(height: 3.h),
                    _buildAvailableOrdersButton(),
                    SizedBox(height: 3.h),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAssignedOrdersSection() {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Orders',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        if (_assignedOrders.isEmpty)
          _buildEmptyState()
        else
          ..._assignedOrders.map((order) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: _buildOrderCard(order),
              )),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF616161);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 15.w,
            color: textSecondary,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Assigned Orders',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'You currently have no orders assigned to you',
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF616161);

    final orderId = order['id'] as String;
    final orderNumber = order['order_number'] as String? ?? 'N/A';
    final status = order['status'] as String;
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = order['created_at'] as String?;
    final deliveryAddress = order['delivery_address'] as String? ?? 'N/A';

    final store = order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? 'Store';

    final customer = order['users'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] as String? ?? 'Customer';
    final customerPhone = customer?['phone'] as String?;

    DateTime? orderDate;
    if (createdAt != null) {
      try {
        orderDate = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: status == 'assigned' ? AppTheme.primaryLight : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: status == 'assigned'
                      ? AppTheme.primaryLight
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Order #$orderNumber',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 4.w,
                color: textSecondary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  storeName,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 4.w,
                color: textSecondary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (customerPhone != null) ...[
                SizedBox(width: 2.w),
                Text(
                  customerPhone,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 4.w,
                color: textSecondary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  deliveryAddress,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (orderDate != null) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 4.w,
                  color: textSecondary,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 2.h),
          if (status == 'assigned')
            ElevatedButton(
              onPressed: _isUpdatingOrder
                  ? null
                  : () => _updateOrderStatus(orderId, 'picked_up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isUpdatingOrder
                  ? SizedBox(
                      height: 2.h,
                      width: 2.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Mark Picked Up',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )
          else if (status == 'picked_up')
            ElevatedButton(
              onPressed: _isUpdatingOrder
                  ? null
                  : () => _updateOrderStatus(orderId, 'delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isUpdatingOrder
                  ? SizedBox(
                      height: 2.h,
                      width: 2.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Mark Delivered',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersButton() {
    return ElevatedButton(
      onPressed: _isOnline ? () {} : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        padding: EdgeInsets.symmetric(vertical: 2.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 6.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'View Available Orders',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.account_balance_wallet,
                label: 'Earnings',
                onTap: () {},
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.person,
                label: 'Profile',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryLight,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
