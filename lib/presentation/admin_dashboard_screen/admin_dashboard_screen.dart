// ============================================================
// FILE: lib/presentation/admin_dashboard_screen/admin_dashboard_screen.dart
// ============================================================
// MERGED Admin Dashboard — combines the profile admin dashboard
// and the landing admin dashboard into ONE unified interface.
// UPDATED: Added home icon + proper back button to navigate to main app.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../services/analytics_service.dart';
import '../admin_subscription_management_screen/admin_subscription_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAdminAndLoadData();
    AnalyticsService.logScreenView(screenName: 'admin_dashboard_screen');
  }

  Future<void> _verifyAdminAndLoadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    if (!adminProvider.isAdmin) {
      await adminProvider.checkAdminStatus();
    }

    if (!adminProvider.isAdmin && mounted) {
      Navigator.of(context).pop();
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
      adminProvider.loadDashboardStats(),
      adminProvider.loadPendingApplications(),
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

  /// Navigate back to the main app interface
  void _goToMainApp() {
    HapticFeedback.lightImpact();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.mainLayout,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _goToMainApp();
            }
          },
          tooltip: 'Back',
        ),
        title: const Text('Admin Dashboard'),
        actions: [
          // HOME BUTTON — takes admin back to main app
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: _goToMainApp,
            tooltip: 'Back to App',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.yellowAccent),
            onPressed: _showEmergencyControls,
            tooltip: 'Emergency Controls',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (_isLoading || adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!adminProvider.isAdmin) {
            return _buildAccessDenied(adminProvider);
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemStatusHeader(theme),
                  SizedBox(height: 2.h),
                  _buildMetricsCards(adminProvider, theme),
                  SizedBox(height: 2.h),
                  if (adminProvider.pendingApplicationsCount > 0) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _buildPendingApplicationsAlert(adminProvider, theme),
                    ),
                    SizedBox(height: 2.h),
                  ],
                  _buildManagementGrid(theme),
                  SizedBox(height: 2.h),
                  _buildQuickActions(adminProvider, theme),
                  SizedBox(height: 2.h),
                  _buildLiveActivityFeed(adminProvider, theme),
                  SizedBox(height: 2.h),
                  _buildPerformanceOverview(adminProvider, theme),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccessDenied(AdminProvider adminProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You do not have admin privileges.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _verifyAdminAndLoadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Admin Status'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _goToMainApp,
            icon: const Icon(Icons.home),
            label: const Text('Go to Main App'),
          ),
          if (adminProvider.error != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('Error: ${adminProvider.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemStatusHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kjRed, AppTheme.kjRed.withOpacity(0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
          SizedBox(width: 2.w),
          Text('System Operational', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
        SizedBox(height: 1.h),
        Text('All services running normally', style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8))),
      ]),
    );
  }

  Widget _buildMetricsCards(AdminProvider adminProvider, ThemeData theme) {
    final stats = adminProvider.dashboardStats;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(children: [
        Row(children: [
          Expanded(child: _buildMetricCard(icon: Icons.shopping_bag, title: 'Active Orders', value: stats?['active_orders']?.toString() ?? stats?['total_orders']?.toString() ?? '0', color: Colors.blue, onTap: () => Navigator.pushNamed(context, AppRoutes.enhancedOrderManagement), theme: theme)),
          SizedBox(width: 3.w),
          Expanded(child: _buildMetricCard(icon: Icons.local_shipping, title: 'Online Drivers', value: stats?['online_drivers']?.toString() ?? '0', color: Colors.green, onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsersManagement), theme: theme)),
        ]),
        SizedBox(height: 3.w),
        Row(children: [
          Expanded(child: _buildMetricCard(icon: Icons.attach_money, title: 'Revenue Today', value: '\$${stats?['revenue_today']?.toStringAsFixed(2) ?? stats?['total_revenue']?.toStringAsFixed(2) ?? '0.00'}', color: Colors.orange, onTap: () {}, theme: theme)),
          SizedBox(width: 3.w),
          Expanded(child: _buildMetricCard(icon: Icons.people, title: 'Total Users', value: stats?['total_users']?.toString() ?? '0', color: Colors.purple, onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsersManagement), theme: theme)),
        ]),
      ]),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String title, required String value, required Color color, required VoidCallback onTap, required ThemeData theme}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 1.h),
          Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          SizedBox(height: 0.5.h),
          Text(title, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildPendingApplicationsAlert(AdminProvider adminProvider, ThemeData theme) {
    final count = adminProvider.pendingApplicationsCount;
    final merchantCount = adminProvider.pendingMerchants.length;
    final driverCount = adminProvider.pendingDrivers.length;
    return Card(
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminApplications),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.pending_actions, color: Colors.white, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$count Pending Application${count > 1 ? 's' : ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$merchantCount merchant${merchantCount != 1 ? 's' : ''}, $driverCount driver${driverCount != 1 ? 's' : ''} waiting', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ]),
        ),
      ),
    );
  }

  Widget _buildManagementGrid(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Management', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 1.h),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0,
          children: [
            _buildMgmtTile(Icons.people, 'Users', Colors.blue, () => Navigator.pushNamed(context, AppRoutes.adminUsersManagement), theme),
            _buildMgmtTile(Icons.receipt_long, 'Orders', Colors.orange, () => Navigator.pushNamed(context, AppRoutes.enhancedOrderManagement), theme),
            _buildMgmtTile(Icons.pending_actions, 'Applications', Colors.deepOrange, () => Navigator.pushNamed(context, AppRoutes.adminApplications), theme),
            _buildMgmtTile(Icons.campaign, 'Ads', Colors.pink, () => Navigator.pushNamed(context, AppRoutes.adminAdsManagement), theme),
            _buildMgmtTile(Icons.local_shipping, 'Logistics', Colors.teal, () => Navigator.pushNamed(context, AppRoutes.adminLogisticsManagement), theme),
            _buildMgmtTile(Icons.category, 'Categories', Colors.indigo, () => Navigator.pushNamed(context, AppRoutes.adminCategories), theme),
            _buildMgmtTile(Icons.assignment_ind, 'Roles', Colors.brown, () => Navigator.pushNamed(context, AppRoutes.adminRoleUpgradeManagement), theme),
            _buildMgmtTile(Icons.card_membership, 'Subscriptions', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSubscriptionManagementScreen())), theme),
            _buildMgmtTile(Icons.edit, 'Edit System', Colors.grey, () => Navigator.pushNamed(context, AppRoutes.adminEditOverlaySystem), theme),
          ],
        ),
      ]),
    );
  }

  Widget _buildMgmtTile(IconData icon, String label, Color color, VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 24)),
          SizedBox(height: 1.h),
          Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(AdminProvider adminProvider, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Actions', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 1.h),
        Row(children: [
          Expanded(child: _buildQuickActionTile(icon: Icons.pending_actions, title: 'Pending Approvals', count: adminProvider.pendingApplicationsCount, onTap: () => Navigator.pushNamed(context, AppRoutes.adminApplications), theme: theme)),
          SizedBox(width: 3.w),
          Expanded(child: _buildQuickActionTile(icon: Icons.assignment_ind, title: 'Driver Assign', count: 0, onTap: () => Navigator.pushNamed(context, AppRoutes.adminLogisticsManagement), theme: theme)),
        ]),
        SizedBox(height: 3.w),
        Row(children: [
          Expanded(child: _buildQuickActionTile(icon: Icons.verified_user, title: 'Merchant Review', count: adminProvider.pendingMerchants.length, onTap: () => Navigator.pushNamed(context, AppRoutes.adminApplications), theme: theme)),
          SizedBox(width: 3.w),
          Expanded(child: _buildQuickActionTile(icon: Icons.card_membership, title: 'Subscriptions', count: 0, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSubscriptionManagementScreen())), theme: theme)),
        ]),
      ]),
    );
  }

  Widget _buildQuickActionTile({required IconData icon, required String title, required int count, required VoidCallback onTap, required ThemeData theme}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: AppTheme.kjRed),
          SizedBox(width: 2.w),
          Expanded(child: Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
          if (count > 0) Container(padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: Text(count.toString(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _buildLiveActivityFeed(AdminProvider adminProvider, ThemeData theme) {
    final orders = adminProvider.recentOrders;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Recent Activity', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
          child: orders.isEmpty
              ? Padding(padding: EdgeInsets.all(4.w), child: Center(child: Text('No recent activity', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))))
              : Column(children: orders.take(5).map((order) {
                  final status = order['status']?.toString() ?? 'unknown';
                  final storeName = order['stores']?['name'] ?? 'Unknown Store';
                  final total = (order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
                  return _buildActivityItem(icon: _getStatusIcon(status), title: 'Order - $storeName', subtitle: '\$$total - $status', time: _formatTime(order['created_at']), theme: theme);
                }).toList()),
        ),
      ]),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_top;
      case 'confirmed': return Icons.check_circle;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.local_shipping;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  Widget _buildActivityItem({required IconData icon, required String title, required String subtitle, required String time, required ThemeData theme}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: AppTheme.kjRed.withOpacity(0.1), child: Icon(icon, color: AppTheme.kjRed, size: 20)),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          SizedBox(height: 0.3.h),
          Text(subtitle, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant)),
        ])),
        Text(time, style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildPerformanceOverview(AdminProvider adminProvider, ThemeData theme) {
    final stats = adminProvider.dashboardStats;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Performance', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(children: [
            _buildPerformanceMetric(title: 'Total Orders', value: stats?['total_orders']?.toString() ?? '0', theme: theme),
            SizedBox(height: 2.h),
            _buildPerformanceMetric(title: 'Total Users', value: stats?['total_users']?.toString() ?? '0', theme: theme),
            SizedBox(height: 2.h),
            _buildPerformanceMetric(title: 'Active Users', value: stats?['active_users']?.toString() ?? '0', theme: theme),
            SizedBox(height: 2.h),
            _buildPerformanceMetric(title: 'Total Revenue', value: '\$${stats?['total_revenue']?.toStringAsFixed(2) ?? '0.00'}', theme: theme),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPerformanceMetric({required String title, required String value, required ThemeData theme}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurfaceVariant)),
      Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
    ]);
  }

  void _showEmergencyControls() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.emergency, color: theme.colorScheme.error), const SizedBox(width: 8), const Text('Emergency Controls')]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.warning, color: Colors.orange), title: const Text('System Alert'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text('Emergency Order Cancel'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.swap_horiz, color: Colors.blue), title: const Text('Reassign Driver'), onTap: () => Navigator.pop(context)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}