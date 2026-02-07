import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/admin_layout_wrapper.dart';

class AdminLandingDashboardScreen extends StatefulWidget {
  const AdminLandingDashboardScreen({super.key});

  @override
  State<AdminLandingDashboardScreen> createState() =>
      _AdminLandingDashboardScreenState();
}

class _AdminLandingDashboardScreenState
    extends State<AdminLandingDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAdminAndLoadData();
    AnalyticsService.logScreenView(
        screenName: 'admin_landing_dashboard_screen');
  }

  Future<void> _verifyAdminAndLoadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    if (!adminProvider.isAdmin) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.wait([
      adminProvider.checkAdminStatus(),
      adminProvider.loadDashboardStats(),
      adminProvider.loadRecentOrders(limit: 5),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _verifyAdminAndLoadData();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWrapper(
      currentRoute: AppRoutes.adminLandingDashboard,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.emergency, color: Colors.red),
              onPressed: () {
                _showEmergencyControls();
              },
              tooltip: 'Emergency Controls',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSystemStatusHeader(),
                      SizedBox(height: 2.h),
                      _buildMetricsCards(),
                      SizedBox(height: 2.h),
                      _buildQuickActions(),
                      SizedBox(height: 2.h),
                      _buildLiveActivityFeed(),
                      SizedBox(height: 2.h),
                      _buildPerformanceCharts(),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSystemStatusHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'System Operational',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'All services running normally',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final stats = adminProvider.dashboardStats;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.shopping_bag,
                      title: 'Active Orders',
                      value: stats?['active_orders']?.toString() ?? '0',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.enhancedOrderManagement,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.local_shipping,
                      title: 'Online Drivers',
                      value: stats?['online_drivers']?.toString() ?? '0',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminUsersManagement,
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.w),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.attach_money,
                      title: 'Revenue Today',
                      value:
                          '\$${stats?['revenue_today']?.toStringAsFixed(2) ?? '0.00'}',
                      color: Colors.orange,
                      onTap: () {},
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.people,
                      title: 'Total Users',
                      value: stats?['total_users']?.toString() ?? '0',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminUsersManagement,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.pending_actions,
                  title: 'Pending Approvals',
                  count: 5,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.assignment_ind,
                  title: 'Driver Assignments',
                  count: 3,
                  onTap: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.verified_user,
                  title: 'Merchant Verifications',
                  count: 2,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.flag,
                  title: 'Content Moderation',
                  count: 8,
                  onTap: () {},
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .pushNamed(AppRoutes.adminRoleUpgradeManagement);
            },
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_ind_outlined,
                      color: AppTheme.lightTheme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role Requests',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Manage upgrade requests',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.lightTheme.colorScheme.primary),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveActivityFeed() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Activity Feed',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.person_add,
                  title: 'New user registration',
                  subtitle: 'john.doe@example.com',
                  time: '2 min ago',
                ),
                Divider(height: 2.h),
                _buildActivityItem(
                  icon: Icons.shopping_cart,
                  title: 'Order placed',
                  subtitle: '\$45.99 - 3 items',
                  time: '5 min ago',
                ),
                Divider(height: 2.h),
                _buildActivityItem(
                  icon: Icons.check_circle,
                  title: 'Order completed',
                  subtitle: 'Delivered successfully',
                  time: '12 min ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCharts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPerformanceMetric(
                  title: 'Order Volume',
                  value: '245',
                  change: '+12%',
                  isPositive: true,
                ),
                SizedBox(height: 2.h),
                _buildPerformanceMetric(
                  title: 'Delivery Efficiency',
                  value: '94%',
                  change: '+3%',
                  isPositive: true,
                ),
                SizedBox(height: 2.h),
                _buildPerformanceMetric(
                  title: 'Customer Satisfaction',
                  value: '4.8/5',
                  change: '+0.2',
                  isPositive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[700],
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                change,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEmergencyControls() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Controls'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('System Alert'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Emergency Order Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('Reassign Driver'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
