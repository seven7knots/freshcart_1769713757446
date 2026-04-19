// ============================================================
// FILE: lib/presentation/admin_dashboard_screen/admin_dashboard_screen.dart
// ============================================================
// MERGED Admin Dashboard — combines the profile admin dashboard
// and the landing admin dashboard into ONE unified interface.
// UPDATED Session 10: Fixed notification bell, revenue tap,
// emergency controls (System Alert, Emergency Cancel).
// SESSION 20 FIX: Revenue labels updated to "Delivery Revenue"
// SESSION 27 FIX: Revenue mismatch fixed, removed 'revenue_today' hardcode.
// SESSION 28 FIX:
// - Revenue now counts all non-cancelled orders (not just 'delivered')
// - Added Revenue Breakdown section: Today / This Month / This Year / All-Time
// - All revenue figures are live from DB — zero hardcoding
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import '../notifications_screen/notifications_screen.dart';
import '../../l10n/generated/app_localizations.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAdminAndLoadData();
      AnalyticsService.logScreenView(screenName: 'admin_dashboard_screen');
    });
  }

  Future<void> _verifyAdminAndLoadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    if (!adminProvider.isAdmin) {
      await adminProvider.checkAdminStatus();
    }

    if (!adminProvider.isAdmin && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.accessDeniedAdminPrivilegesRequired, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      backgroundColor: Color(0xFFF5F5F5),
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
          tooltip: AppLocalizations.of(context)!.back,
        ),
        title: Text(AppLocalizations.of(context)!.adminDashboard, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: _goToMainApp,
            tooltip: AppLocalizations.of(context)!.backToApp,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.notifications,
          ),
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.yellowAccent),
            onPressed: _showEmergencyControls,
            tooltip: AppLocalizations.of(context)!.emergencyControls,
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
                  // SESSION 28: Revenue breakdown replaces simple performance row
                  _buildRevenueBreakdown(adminProvider, theme),
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
          Icon(Icons.lock, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.youDoNotHaveAdminPrivileges,
              style: TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _verifyAdminAndLoadData,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.checkAdminStatus, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _goToMainApp,
            icon: const Icon(Icons.home),
            label: Text(AppLocalizations.of(context)!.goToMainApp, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (adminProvider.error != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('Error: ${adminProvider.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: Colors.greenAccent, shape: BoxShape.circle)),
            SizedBox(width: 2.w),
            Flexible(child: Text(AppLocalizations.of(context)!.systemOperational,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          SizedBox(height: 1.h),
          Text(AppLocalizations.of(context)!.allServicesRunningNormally,
              style: TextStyle(
                  fontSize: 12.sp, color: Colors.white.withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(AdminProvider adminProvider, ThemeData theme) {
    final stats = adminProvider.dashboardStats;
    final revenue = adminProvider.revenueBreakdown;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: _buildMetricCard(
                  icon: Icons.shopping_bag,
                  title: AppLocalizations.of(context)!.activeOrders,
                  value: stats?['active_orders']?.toString() ??
                      stats?['total_orders']?.toString() ??
                      '0',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.enhancedOrderManagement),
                  theme: theme)),
          SizedBox(width: 3.w),
          Expanded(
              child: _buildMetricCard(
                  icon: Icons.local_shipping,
                  title: AppLocalizations.of(context)!.onlineDrivers,
                  value: stats?['online_drivers']?.toString() ?? '0',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.adminUsersManagement),
                  theme: theme)),
        ]),
        SizedBox(height: 3.w),
        Row(children: [
          // SESSION 28: show all-time revenue from breakdown (live, no hardcode)
          Expanded(
              child: _buildMetricCard(
                  icon: Icons.delivery_dining,
                  title: AppLocalizations.of(context)!.deliveryRevenue,
                  value:
                      '\$${(revenue['all_time'] ?? 0.0).toStringAsFixed(2)}',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.enhancedOrderManagement),
                  theme: theme)),
          SizedBox(width: 3.w),
          Expanded(
              child: _buildMetricCard(
                  icon: Icons.people,
                  title: AppLocalizations.of(context)!.totalUsers,
                  value: stats?['total_users']?.toString() ?? '0',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.adminUsersManagement),
                  theme: theme)),
        ]),
      ]),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 1.h),
            Text(value,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Text(title,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApplicationsAlert(
      AdminProvider adminProvider, ThemeData theme) {
    final count = adminProvider.pendingApplicationsCount;
    final merchantCount = adminProvider.pendingMerchants.length;
    final driverCount = adminProvider.pendingDrivers.length;
    return Card(
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.adminApplications),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.pending_actions,
                    color: Colors.white, size: 28)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      '$count Pending Application${count > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                      '$merchantCount merchant${merchantCount != 1 ? 's' : ''}, $driverCount driver${driverCount != 1 ? 's' : ''} waiting',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.management,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildMgmtTile(
                  Icons.people, AppLocalizations.of(context)!.users, Colors.blue,
                  () => Navigator.pushNamed(context, AppRoutes.adminUsersManagement),
                  theme),
              _buildMgmtTile(
                  Icons.receipt_long, AppLocalizations.of(context)!.orders, Colors.orange,
                  () => Navigator.pushNamed(context, AppRoutes.enhancedOrderManagement),
                  theme),
              _buildMgmtTile(
                  Icons.pending_actions, AppLocalizations.of(context)!.applications, Colors.deepOrange,
                  () => Navigator.pushNamed(context, AppRoutes.adminApplications),
                  theme),
              _buildMgmtTile(
                  Icons.campaign, AppLocalizations.of(context)!.ads, Colors.pink,
                  () => Navigator.pushNamed(context, AppRoutes.adminAdsManagement),
                  theme),
              _buildMgmtTile(
                  Icons.local_shipping, AppLocalizations.of(context)!.logistics, Colors.teal,
                  () => Navigator.pushNamed(context, AppRoutes.adminLogisticsManagement),
                  theme),
              _buildMgmtTile(
                  Icons.category, AppLocalizations.of(context)!.categories, Colors.indigo,
                  () => Navigator.pushNamed(context, AppRoutes.adminCategories),
                  theme),
              _buildMgmtTile(
                  Icons.edit, AppLocalizations.of(context)!.editSystem, Colors.grey,
                  () => Navigator.pushNamed(context, AppRoutes.adminEditOverlaySystem),
                  theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMgmtTile(IconData icon, String label, Color color,
      VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24)),
            SizedBox(height: 1.h),
            Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AdminProvider adminProvider, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.quickActions,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Row(children: [
            Expanded(
                child: _buildQuickActionTile(
                    icon: Icons.pending_actions,
                    title: AppLocalizations.of(context)!.pendingApprovals,
                    count: adminProvider.pendingApplicationsCount,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.adminApplications),
                    theme: theme)),
            SizedBox(width: 3.w),
            Expanded(
                child: _buildQuickActionTile(
                    icon: Icons.assignment_ind,
                    title: AppLocalizations.of(context)!.driverAssign,
                    count: 0,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.adminLogisticsManagement),
                    theme: theme)),
          ]),
          SizedBox(height: 3.w),
          Row(children: [
            Expanded(
                child: _buildQuickActionTile(
                    icon: Icons.verified_user,
                    title: AppLocalizations.of(context)!.merchantReview,
                    count: adminProvider.pendingMerchants.length,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.adminApplications),
                    theme: theme)),
            SizedBox(width: 3.w),
            const Expanded(child: SizedBox()),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.grey.shade400.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: AppTheme.kjRed),
          SizedBox(width: 2.w),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis)),
          if (count > 0)
            Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(count.toString(),
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildLiveActivityFeed(AdminProvider adminProvider, ThemeData theme) {
    final orders = adminProvider.recentOrders;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.recentActivity,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: orders.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Center(
                        child: Text(AppLocalizations.of(context)!.noRecentActivity,
                            style: TextStyle(
                                color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)))
                : Column(
                    children: orders.take(5).map((order) {
                    final status =
                        order['status']?.toString() ?? 'unknown';
                    final storeName =
                        order['stores']?['name'] ?? AppLocalizations.of(context)!.unknownStore;
                    // Show delivery_fee (admin's cut). Fall back to total_amount.
                    final deliveryFee = order['delivery_fee'] as num?;
                    final totalAmount = order['total_amount'] as num?;
                    final displayAmount =
                        (deliveryFee ?? totalAmount ?? 0).toStringAsFixed(2);
                    return _buildActivityItem(
                        icon: _getStatusIcon(status),
                        title: 'Order - $storeName',
                        subtitle: '\$$displayAmount - $status',
                        time: _formatTime(order['created_at']),
                        theme: theme);
                  }).toList()),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SESSION 28: Revenue breakdown — Today / This Month / This Year / All-Time
  // All figures come live from DB via adminProvider.revenueBreakdown.
  // Cancelled orders are excluded automatically (not counted as revenue).
  // ============================================================
  Widget _buildRevenueBreakdown(AdminProvider adminProvider, ThemeData theme) {
    final rev = adminProvider.revenueBreakdown;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(AppLocalizations.of(context)!.revenueBreakdown,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            AppLocalizations.of(context)!.deliveryFeesFromAllActiveOrders,
            style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Column(
              children: [
                _buildRevenueRow(
                  icon: Icons.today,
                  label: AppLocalizations.of(context)!.today,
                  value: rev['today'] ?? 0.0,
                  color: Colors.blue,
                  theme: theme,
                  isFirst: true,
                ),
                _buildRevenueDivider(theme),
                _buildRevenueRow(
                  icon: Icons.calendar_month,
                  label: AppLocalizations.of(context)!.thisMonth,
                  value: rev['this_month'] ?? 0.0,
                  color: Colors.orange,
                  theme: theme,
                ),
                _buildRevenueDivider(theme),
                _buildRevenueRow(
                  icon: Icons.calendar_today,
                  label: AppLocalizations.of(context)!.thisYear,
                  value: rev['this_year'] ?? 0.0,
                  color: Colors.purple,
                  theme: theme,
                ),
                _buildRevenueDivider(theme),
                _buildRevenueRow(
                  icon: Icons.all_inclusive,
                  label: AppLocalizations.of(context)!.allTime,
                  value: rev['all_time'] ?? 0.0,
                  color: AppTheme.kjRed,
                  theme: theme,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ThemeData theme,
    bool isFirst = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Flexible(child: Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: isBold ? 17.sp : 15.sp,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? color : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildRevenueDivider(ThemeData theme) {
    return Divider(
      height: 1,
      color: Colors.grey.shade400.withOpacity(0.15),
    );
  }

  Widget _buildPerformanceOverview(
      AdminProvider adminProvider, ThemeData theme) {
    final stats = adminProvider.dashboardStats;
    final rev = adminProvider.revenueBreakdown;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Column(children: [
              _buildPerformanceMetric(
                  title: 'Total Orders',
                  value: stats?['total_orders']?.toString() ?? '0',
                  theme: theme),
              SizedBox(height: 2.h),
              _buildPerformanceMetric(
                  title: 'Total Users',
                  value: stats?['total_users']?.toString() ?? '0',
                  theme: theme),
              SizedBox(height: 2.h),
              _buildPerformanceMetric(
                  title: 'Active Users',
                  value: stats?['active_users']?.toString() ?? '0',
                  theme: theme),
              SizedBox(height: 2.h),
              // SESSION 28: Use live all_time from breakdown (not hardcoded)
              _buildPerformanceMetric(
                  title: 'Total Delivery Revenue',
                  value:
                      '\$${(rev['all_time'] ?? 0.0).toStringAsFixed(2)}',
                  theme: theme),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(title,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(value,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
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
    } catch (_) {
      return '';
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required ThemeData theme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(children: [
        CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.kjRed.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.kjRed, size: 20)),
        SizedBox(width: 3.w),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 0.3.h),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
        Flexible(child: Text(time,
            style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ============================================================
  // EMERGENCY CONTROLS
  // ============================================================

  void _showEmergencyControls() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          Icon(Icons.emergency, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Flexible(child: Text(AppLocalizations.of(context)!.emergencyControls, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(AppLocalizations.of(context)!.systemAlert, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppLocalizations.of(context)!.broadcastMessageToAllUsers, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(dialogContext);
                _showSystemAlertDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.emergencyOrderCancel, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppLocalizations.of(context)!.viewCancelActiveOrders, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(
                    context, AppRoutes.enhancedOrderManagement);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showSystemAlertDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.campaign, color: Colors.orange),
          const SizedBox(width: 8),
          Flexible(child: Text(AppLocalizations.of(context)!.sendSystemAlert, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.thisWillCreateAPlatformWide,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterAlertMessage,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: Text(AppLocalizations.of(context)!.sendAlert, maxLines: 1, overflow: TextOverflow.ellipsis),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterAMessage, maxLines: 1, overflow: TextOverflow.ellipsis)),
                );
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await SupabaseService.client
                    .from('notifications')
                    .insert({
                  'title': AppLocalizations.of(context)!.systemAlert,
                  'body': message,
                  'type': 'system_alert',
                  'is_global': true,
                  'created_at': DateTime.now().toIso8601String(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.systemAlertSentSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send alert: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}