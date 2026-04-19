import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/earnings_chart_widget.dart';
import './widgets/goal_tracking_widget.dart';
import './widgets/performance_header_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/rating_display_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class DriverPerformanceDashboardScreen extends StatefulWidget {
  const DriverPerformanceDashboardScreen({super.key});

  @override
  State<DriverPerformanceDashboardScreen> createState() =>
      _DriverPerformanceDashboardScreenState();
}

class _DriverPerformanceDashboardScreenState
    extends State<DriverPerformanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RealtimeChannel? _performanceChannel;

  bool _isLoading = true;
  String _driverId = '';
  String _driverName = 'Driver';
  bool _isOnline = false;
  int _activeHours = 0;

  double _todayEarnings = 0.0;
  int _todayCompletedDeliveries = 0;
  int _todayTotalDeliveries = 0;
  double _acceptanceRate = 0.0;
  double _customerRating = 5.0;
  int _totalRatings = 0;
  double _averageDeliveryTime = 0.0;

  double _weeklyEarnings = 0.0;
  int _weeklyCompletedDeliveries = 0;
  List<Map<String, dynamic>> _weeklyEarningsData = [];

  double _monthlyEarnings = 0.0;
  int _monthlyCompletedDeliveries = 0;
  List<Map<String, dynamic>> _monthlyEarningsData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        _navigateToLogin();
        return;
      }

      final driverData = await SupabaseService.client
          .from('drivers')
          .select('id, is_online, rating, total_deliveries')
          .eq('user_id', userId)
          .maybeSingle();

      if (driverData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noDriverProfileFoundApplyAs, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      _driverId = driverData['id'];
      _isOnline = driverData['is_online'] ?? false;
      _customerRating = (driverData['rating'] as num?)?.toDouble() ?? 5.0;
      _totalRatings = (driverData['total_deliveries'] as num?)?.toInt() ?? 0;

      final userData = await SupabaseService.client
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();

      _driverName = userData['full_name'] ?? AppLocalizations.of(context)!.driver2;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // SESSION 20 FIX: Query from 'orders' table (not empty 'deliveries' table)
      await _loadDailyMetrics(startOfDay);
      await _loadWeeklyMetrics(startOfWeek);
      await _loadMonthlyMetrics(startOfMonth);

      _activeHours = _todayCompletedDeliveries > 0
          ? (_todayCompletedDeliveries * 0.5).ceil()
          : 0;

      _subscribeToRealtimeUpdates();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[DRIVER_PERF] Error loading performance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // SESSION 20 FIX: All metrics now query 'orders' table
  // The old code queried 'deliveries' table which was empty.
  // Driver earnings = delivery_fee from each completed order.
  // ============================================================

  Future<void> _loadDailyMetrics(DateTime startOfDay) async {
    try {
      // Get ALL orders assigned to this driver today
      final orders = await SupabaseService.client
          .from('orders')
          .select('id, status, delivery_fee, total, created_at, updated_at')
          .eq('driver_id', _driverId)
          .gte('created_at', startOfDay.toIso8601String());

      double totalEarnings = 0.0;
      int completedCount = 0;
      int rejectedByDriverCount = 0;
      int acceptedCount = 0;

      for (var order in orders) {
        final status = order['status'] as String? ?? '';

        if (status == 'delivered') {
          completedCount++;
          // Driver earnings = delivery fee from the order
          final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
          totalEarnings += deliveryFee;
        }

        // Count accepted orders (any status past 'assigned' means driver accepted)
        if (['accepted', 'picked_up', 'in_transit', 'delivered'].contains(status)) {
          acceptedCount++;
        }

        // Orders that were assigned but driver didn't accept
        if (status == 'assigned') {
          rejectedByDriverCount++;
        }
      }

      _todayEarnings = totalEarnings;
      _todayCompletedDeliveries = completedCount;
      _todayTotalDeliveries = orders.length;

      // Acceptance rate: accepted / (accepted + still-assigned)
      final totalAssignments = acceptedCount + rejectedByDriverCount;
      _acceptanceRate = totalAssignments > 0
          ? (acceptedCount / totalAssignments) * 100
          : 100.0;

      // Average delivery time: estimate from completed orders
      // Use time between created_at and updated_at for delivered orders
      double totalMinutes = 0.0;
      int timeCount = 0;
      for (var order in orders) {
        if (order['status'] == 'delivered' &&
            order['created_at'] != null &&
            order['updated_at'] != null) {
          final created = DateTime.tryParse(order['created_at'] as String);
          final updated = DateTime.tryParse(order['updated_at'] as String);
          if (created != null && updated != null) {
            final mins = updated.difference(created).inMinutes;
            if (mins > 0 && mins < 180) {
              // Sanity check: < 3 hours
              totalMinutes += mins;
              timeCount++;
            }
          }
        }
      }
      _averageDeliveryTime = timeCount > 0 ? totalMinutes / timeCount : 0.0;

      debugPrint('[DRIVER_PERF] Daily: $completedCount deliveries, \$$totalEarnings earnings');
    } catch (e) {
      debugPrint('[DRIVER_PERF] Error loading daily metrics: $e');
    }
  }

  Future<void> _loadWeeklyMetrics(DateTime startOfWeek) async {
    try {
      final orders = await SupabaseService.client
          .from('orders')
          .select('id, status, delivery_fee, updated_at')
          .eq('driver_id', _driverId)
          .eq('status', 'delivered')
          .gte('updated_at', startOfWeek.toIso8601String())
          .order('updated_at', ascending: true);

      double totalEarnings = 0.0;
      Map<String, double> dailyEarnings = {};

      for (var order in orders) {
        final earnings = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        totalEarnings += earnings;

        if (order['updated_at'] != null) {
          final date = DateTime.parse(order['updated_at'] as String);
          final dayKey = '${date.year}-${date.month}-${date.day}';
          dailyEarnings[dayKey] = (dailyEarnings[dayKey] ?? 0.0) + earnings;
        }
      }

      _weeklyEarnings = totalEarnings;
      _weeklyCompletedDeliveries = orders.length;
      _weeklyEarningsData = dailyEarnings.entries
          .map((e) => {'date': e.key, 'earnings': e.value})
          .toList();

      debugPrint('[DRIVER_PERF] Weekly: ${orders.length} deliveries, \$$totalEarnings earnings');
    } catch (e) {
      debugPrint('[DRIVER_PERF] Error loading weekly metrics: $e');
    }
  }

  Future<void> _loadMonthlyMetrics(DateTime startOfMonth) async {
    try {
      final orders = await SupabaseService.client
          .from('orders')
          .select('id, status, delivery_fee, updated_at')
          .eq('driver_id', _driverId)
          .eq('status', 'delivered')
          .gte('updated_at', startOfMonth.toIso8601String())
          .order('updated_at', ascending: true);

      double totalEarnings = 0.0;
      Map<String, double> weeklyEarnings = {};

      for (var order in orders) {
        final earnings = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        totalEarnings += earnings;

        if (order['updated_at'] != null) {
          final date = DateTime.parse(order['updated_at'] as String);
          final weekNumber = ((date.day - 1) / 7).floor() + 1;
          final weekKey = 'Week $weekNumber';
          weeklyEarnings[weekKey] = (weeklyEarnings[weekKey] ?? 0.0) + earnings;
        }
      }

      _monthlyEarnings = totalEarnings;
      _monthlyCompletedDeliveries = orders.length;
      _monthlyEarningsData = weeklyEarnings.entries
          .map((e) => {'week': e.key, 'earnings': e.value})
          .toList();

      debugPrint('[DRIVER_PERF] Monthly: ${orders.length} deliveries, \$$totalEarnings earnings');
    } catch (e) {
      debugPrint('[DRIVER_PERF] Error loading monthly metrics: $e');
    }
  }

  // SESSION 20 FIX: Subscribe to orders table (not deliveries)
  void _subscribeToRealtimeUpdates() {
    if (_driverId.isEmpty) return;
    _performanceChannel?.unsubscribe();
    _performanceChannel = SupabaseService.client
        .channel('driver_performance_$_driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: _driverId,
          ),
          callback: (payload) {
            _loadPerformanceData();
            HapticFeedback.lightImpact();
          },
        )
        .subscribe();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.performanceDashboard, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPerformanceData),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.daily),
              Tab(text: AppLocalizations.of(context)!.weekly),
              Tab(text: AppLocalizations.of(context)!.monthly),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              child: TabBarView(
                controller: _tabController,
                children: [_buildDailyView(), _buildWeeklyView(), _buildMonthlyView()],
              ),
            ),
    );
  }

  Widget _buildDailyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PerformanceHeaderWidget(
            driverName: _driverName, isOnline: _isOnline,
            activeHours: _activeHours, todayEarnings: _todayEarnings),
        SizedBox(height: 2.h),
        PerformanceMetricsWidget(
            completedDeliveries: _todayCompletedDeliveries, totalDeliveries: _todayTotalDeliveries,
            acceptanceRate: _acceptanceRate, averageDeliveryTime: _averageDeliveryTime,
            earnings: _todayEarnings),
        SizedBox(height: 2.h),
        RatingDisplayWidget(rating: _customerRating, totalRatings: _totalRatings),
        SizedBox(height: 2.h),
        GoalTrackingWidget(
            currentEarnings: _todayEarnings, dailyGoal: 200.0,
            currentDeliveries: _todayCompletedDeliveries, deliveryGoal: 15),
      ]),
    );
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildSummaryCard(title: AppLocalizations.of(context)!.weeklySummary, earnings: _weeklyEarnings, deliveries: _weeklyCompletedDeliveries),
        SizedBox(height: 2.h),
        EarningsChartWidget(title: AppLocalizations.of(context)!.weeklyEarningsTrend, data: _weeklyEarningsData, period: 'weekly'),
        SizedBox(height: 2.h),
        RatingDisplayWidget(rating: _customerRating, totalRatings: _totalRatings),
      ]),
    );
  }

  Widget _buildMonthlyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildSummaryCard(title: AppLocalizations.of(context)!.monthlySummary, earnings: _monthlyEarnings, deliveries: _monthlyCompletedDeliveries),
        SizedBox(height: 2.h),
        EarningsChartWidget(title: AppLocalizations.of(context)!.monthlyEarningsTrend, data: _monthlyEarningsData, period: 'monthly'),
        SizedBox(height: 2.h),
        RatingDisplayWidget(rating: _customerRating, totalRatings: _totalRatings),
      ]),
    );
  }

  Widget _buildSummaryCard({required String title, required double earnings, required int deliveries}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kjRed, AppTheme.kjRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 2.h),
        Text('\$${earnings.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Text('$deliveries Deliveries Completed',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}