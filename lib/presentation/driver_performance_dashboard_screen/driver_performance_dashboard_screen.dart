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

  // Daily metrics
  double _todayEarnings = 0.0;
  int _todayCompletedDeliveries = 0;
  int _todayTotalDeliveries = 0;
  double _acceptanceRate = 0.0;
  double _customerRating = 5.0;
  final int _totalRatings = 0;
  double _averageDeliveryTime = 0.0;

  // Weekly metrics
  double _weeklyEarnings = 0.0;
  int _weeklyCompletedDeliveries = 0;
  List<Map<String, dynamic>> _weeklyEarningsData = [];

  // Monthly metrics
  double _monthlyEarnings = 0.0;
  int _monthlyCompletedDeliveries = 0;
  List<Map<String, dynamic>> _monthlyEarningsData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPerformanceData();
    _subscribeToRealtimeUpdates();
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

      // Get driver data
      final driverData = await SupabaseService.client
          .from('drivers')
          .select('id, is_online, rating')
          .eq('user_id', userId)
          .single();

      _driverId = driverData['id'];
      _isOnline = driverData['is_online'] ?? false;
      _customerRating = (driverData['rating'] as num?)?.toDouble() ?? 5.0;

      final userData = await SupabaseService.client
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();

      _driverName = userData['full_name'] ?? 'Driver';

      // Calculate time periods
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Load daily metrics
      await _loadDailyMetrics(startOfDay);

      // Load weekly metrics
      await _loadWeeklyMetrics(startOfWeek);

      // Load monthly metrics
      await _loadMonthlyMetrics(startOfMonth);

      // Calculate active hours (simplified - based on deliveries)
      _activeHours = _todayCompletedDeliveries > 0
          ? (_todayCompletedDeliveries * 0.5).ceil()
          : 0;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading performance data: $e');
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

  Future<void> _loadDailyMetrics(DateTime startOfDay) async {
    // Get today's deliveries
    final deliveries = await SupabaseService.client
        .from('deliveries')
        .select('status, driver_earnings, delivery_time, pickup_time')
        .eq('driver_id', _driverId)
        .gte('created_at', startOfDay.toIso8601String());

    double totalEarnings = 0.0;
    int completedCount = 0;
    int assignedCount = 0;
    int acceptedCount = 0;
    double totalDeliveryTime = 0.0;
    int deliveryTimeCount = 0;

    for (var delivery in deliveries) {
      final status = delivery['status'] as String;

      if (status == 'delivered') {
        completedCount++;
        totalEarnings +=
            (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;

        // Calculate delivery time
        if (delivery['pickup_time'] != null &&
            delivery['delivery_time'] != null) {
          final pickupTime = DateTime.parse(delivery['pickup_time'] as String);
          final deliveryTime =
              DateTime.parse(delivery['delivery_time'] as String);
          final duration = deliveryTime.difference(pickupTime).inMinutes;
          totalDeliveryTime += duration;
          deliveryTimeCount++;
        }
      }

      if (status == 'assigned') assignedCount++;
      if (status == 'accepted' ||
          status == 'picked_up' ||
          status == 'in_transit' ||
          status == 'delivered') {
        acceptedCount++;
      }
    }

    _todayEarnings = totalEarnings;
    _todayCompletedDeliveries = completedCount;
    _todayTotalDeliveries = deliveries.length;
    _acceptanceRate = assignedCount > 0
        ? (acceptedCount / (assignedCount + acceptedCount)) * 100
        : 100.0;
    _averageDeliveryTime =
        deliveryTimeCount > 0 ? totalDeliveryTime / deliveryTimeCount : 0.0;
  }

  Future<void> _loadWeeklyMetrics(DateTime startOfWeek) async {
    final deliveries = await SupabaseService.client
        .from('deliveries')
        .select('status, driver_earnings, delivery_time')
        .eq('driver_id', _driverId)
        .eq('status', 'delivered')
        .gte('delivery_time', startOfWeek.toIso8601String())
        .order('delivery_time', ascending: true);

    double totalEarnings = 0.0;
    Map<String, double> dailyEarnings = {};

    for (var delivery in deliveries) {
      final earnings = (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      totalEarnings += earnings;

      if (delivery['delivery_time'] != null) {
        final date = DateTime.parse(delivery['delivery_time'] as String);
        final dayKey = '${date.year}-${date.month}-${date.day}';
        dailyEarnings[dayKey] = (dailyEarnings[dayKey] ?? 0.0) + earnings;
      }
    }

    _weeklyEarnings = totalEarnings;
    _weeklyCompletedDeliveries = deliveries.length;

    // Convert to chart data
    _weeklyEarningsData = dailyEarnings.entries
        .map((e) => {'date': e.key, 'earnings': e.value})
        .toList();
  }

  Future<void> _loadMonthlyMetrics(DateTime startOfMonth) async {
    final deliveries = await SupabaseService.client
        .from('deliveries')
        .select('status, driver_earnings, delivery_time')
        .eq('driver_id', _driverId)
        .eq('status', 'delivered')
        .gte('delivery_time', startOfMonth.toIso8601String())
        .order('delivery_time', ascending: true);

    double totalEarnings = 0.0;
    Map<String, double> weeklyEarnings = {};

    for (var delivery in deliveries) {
      final earnings = (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      totalEarnings += earnings;

      if (delivery['delivery_time'] != null) {
        final date = DateTime.parse(delivery['delivery_time'] as String);
        final weekNumber = ((date.day - 1) / 7).floor() + 1;
        final weekKey = 'Week $weekNumber';
        weeklyEarnings[weekKey] = (weeklyEarnings[weekKey] ?? 0.0) + earnings;
      }
    }

    _monthlyEarnings = totalEarnings;
    _monthlyCompletedDeliveries = deliveries.length;

    // Convert to chart data
    _monthlyEarningsData = weeklyEarnings.entries
        .map((e) => {'week': e.key, 'earnings': e.value})
        .toList();
  }

  void _subscribeToRealtimeUpdates() {
    if (_driverId.isEmpty) return;

    _performanceChannel = SupabaseService.client
        .channel('driver_performance_$_driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: _driverId,
          ),
          callback: (payload) {
            // Refresh metrics on any delivery update
            _loadPerformanceData();
            HapticFeedback.lightImpact();
          },
        )
        .subscribe();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.driverLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surfaceDark,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryDark,
              unselectedLabelColor: AppTheme.textSecondaryOf(context),
              indicatorColor: AppTheme.primaryDark,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyView(),
                  _buildWeeklyView(),
                  _buildMonthlyView(),
                ],
              ),
            ),
    );
  }

  Widget _buildDailyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PerformanceHeaderWidget(
            driverName: _driverName,
            isOnline: _isOnline,
            activeHours: _activeHours,
            todayEarnings: _todayEarnings,
          ),
          SizedBox(height: 2.h),
          PerformanceMetricsWidget(
            completedDeliveries: _todayCompletedDeliveries,
            totalDeliveries: _todayTotalDeliveries,
            acceptanceRate: _acceptanceRate,
            averageDeliveryTime: _averageDeliveryTime,
            earnings: _todayEarnings,
          ),
          SizedBox(height: 2.h),
          RatingDisplayWidget(
            rating: _customerRating,
            totalRatings: _totalRatings,
          ),
          SizedBox(height: 2.h),
          GoalTrackingWidget(
            currentEarnings: _todayEarnings,
            dailyGoal: 200.0,
            currentDeliveries: _todayCompletedDeliveries,
            deliveryGoal: 15,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(
            title: 'Weekly Summary',
            earnings: _weeklyEarnings,
            deliveries: _weeklyCompletedDeliveries,
          ),
          SizedBox(height: 2.h),
          EarningsChartWidget(
            title: 'Weekly Earnings Trend',
            data: _weeklyEarningsData,
            period: 'weekly',
          ),
          SizedBox(height: 2.h),
          RatingDisplayWidget(
            rating: _customerRating,
            totalRatings: _totalRatings,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(
            title: 'Monthly Summary',
            earnings: _monthlyEarnings,
            deliveries: _monthlyCompletedDeliveries,
          ),
          SizedBox(height: 2.h),
          EarningsChartWidget(
            title: 'Monthly Earnings Trend',
            data: _monthlyEarningsData,
            period: 'monthly',
          ),
          SizedBox(height: 2.h),
          RatingDisplayWidget(
            rating: _customerRating,
            totalRatings: _totalRatings,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double earnings,
    required int deliveries,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE10600), Color(0xFFFF3B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '\$${earnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$deliveries Deliveries Completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
