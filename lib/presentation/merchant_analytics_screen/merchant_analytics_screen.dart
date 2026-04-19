import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/merchant_provider.dart';
import '../../services/supabase_service.dart';
import '../../l10n/generated/app_localizations.dart';

enum _AnalyticsPeriod { weekly, monthly, yearly }

class MerchantAnalyticsScreen extends StatefulWidget {
  final String? storeId;

  const MerchantAnalyticsScreen({super.key, this.storeId});

  @override
  State<MerchantAnalyticsScreen> createState() =>
      _MerchantAnalyticsScreenState();
}

class _MerchantAnalyticsScreenState extends State<MerchantAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  _AnalyticsPeriod _period = _AnalyticsPeriod.weekly;
  String? _resolvedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalytics());
  }

  String? _effectiveStoreId() {
    if (widget.storeId != null) return widget.storeId;
    final merchantProvider =
        Provider.of<MerchantProvider>(context, listen: false);
    return merchantProvider.selectedStoreId ??
        (merchantProvider.stores.isNotEmpty
            ? merchantProvider.stores.first['id'] as String?
            : null);
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final storeId = _effectiveStoreId();
      _resolvedStoreId = storeId;

      if (storeId == null) {
        setState(() {
          _isLoading = false;
          _orders = [];
        });
        return;
      }

      // Load up to 1 year of orders for the selected store
      final oneYearAgo = DateTime.now()
          .subtract(const Duration(days: 365))
          .toIso8601String();

      final response = await SupabaseService.client
          .from('orders')
          .select('id, status, total, subtotal, delivery_fee, created_at, customer_id')
          .eq('store_id', storeId)
          .gte('created_at', oneYearAgo)
          .order('created_at', ascending: false)
          .limit(2000);

      if (!mounted) return;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[MERCHANT_ANALYTICS] Error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Period filtering
  // ============================================================
  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_period) {
      case _AnalyticsPeriod.weekly:
        return DateTime(now.year, now.month, now.day - 6);
      case _AnalyticsPeriod.monthly:
        return DateTime(now.year, now.month, now.day - 29);
      case _AnalyticsPeriod.yearly:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  List<Map<String, dynamic>> _filteredOrders() {
    final start = _periodStart();
    return _orders.where((o) {
      final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
      if (createdAt == null) return false;
      return createdAt.isAfter(start) ||
          createdAt.isAtSameMomentAs(start);
    }).toList();
  }

  double _revenueFor(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    if (status == 'cancelled' || status == 'rejected') return 0;
    final subtotal = order['subtotal'];
    if (subtotal != null) return (subtotal as num).toDouble();
    final total = order['total'];
    if (total == null) return 0;
    final totalAmount = (total as num).toDouble();
    final fee = order['delivery_fee'] != null
        ? (order['delivery_fee'] as num).toDouble()
        : 0.0;
    return totalAmount - fee;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.analytics,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 15.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp),
              ),
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_resolvedStoreId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined,
                  size: 15.w, color: theme.colorScheme.outline),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.noStoreSelected,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredOrders();
    final totalOrders = filtered.length;
    final totalRevenue = filtered.fold<double>(
        0, (prev, o) => prev + _revenueFor(o));
    final avgOrderValue =
        totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodToggle(theme),
            SizedBox(height: 3.h),
            if (totalOrders == 0)
              _buildEmptyState(theme)
            else ...[
              _buildSummaryCards(theme, totalOrders, totalRevenue, avgOrderValue),
              SizedBox(height: 3.h),
              Text(
                _chartTitle(),
                style:
                    TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              _buildChart(theme, filtered),
            ],
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Period toggle
  // ============================================================
  Widget _buildPeriodToggle(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_AnalyticsPeriod>(
      segments: <ButtonSegment<_AnalyticsPeriod>>[
        ButtonSegment(
          value: _AnalyticsPeriod.weekly,
          label: Text(l10n.weekly,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.view_week),
        ),
        ButtonSegment(
          value: _AnalyticsPeriod.monthly,
          label: Text(l10n.monthly,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.calendar_month),
        ),
        ButtonSegment(
          value: _AnalyticsPeriod.yearly,
          label: const Text('Yearly',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.calendar_today),
        ),
      ],
      selected: <_AnalyticsPeriod>{_period},
      onSelectionChanged: (set) {
        setState(() => _period = set.first);
      },
    );
  }

  String _chartTitle() {
    switch (_period) {
      case _AnalyticsPeriod.weekly:
        return 'Last 7 Days';
      case _AnalyticsPeriod.monthly:
        return 'Last 30 Days';
      case _AnalyticsPeriod.yearly:
        return 'Last 12 Months';
    }
  }

  // ============================================================
  // Summary cards
  // ============================================================
  Widget _buildSummaryCards(
    ThemeData theme,
    int totalOrders,
    double totalRevenue,
    double avgOrderValue,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _summaryCard(
          theme,
          label: AppLocalizations.of(context)!.totalOrders,
          value: '$totalOrders',
          icon: Icons.shopping_bag,
          color: Colors.blue,
        ),
        _summaryCard(
          theme,
          label: 'Total Revenue',
          value: '\$${totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _summaryCard(
          theme,
          label: AppLocalizations.of(context)!.avgOrderValue,
          value: '\$${avgOrderValue.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
        _summaryCard(
          theme,
          label: 'Period',
          value: _chartTitle(),
          icon: Icons.date_range,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 7.w),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Chart — bucketed by period
  // ============================================================
  Widget _buildChart(ThemeData theme, List<Map<String, dynamic>> filtered) {
    final buckets = _bucketize(filtered);
    final maxRevenue = buckets.fold<double>(
        0, (prev, b) => b.revenue > prev ? b.revenue : prev);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: SizedBox(
          height: 24.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((b) {
              final ratio = maxRevenue > 0 ? b.revenue / maxRevenue : 0.0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (b.revenue > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '\$${b.revenue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: (16.h * ratio).clamp(0.5.h, 16.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        b.label,
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_Bucket> _bucketize(List<Map<String, dynamic>> filtered) {
    final now = DateTime.now();
    final buckets = <_Bucket>[];

    if (_period == _AnalyticsPeriod.weekly) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day - i);
        final orders = filtered.where((o) {
          final c = DateTime.tryParse(o['created_at'] as String? ?? '');
          return c != null &&
              c.year == d.year &&
              c.month == d.month &&
              c.day == d.day;
        });
        final revenue =
            orders.fold<double>(0, (p, o) => p + _revenueFor(o));
        buckets.add(_Bucket(
          label: dayNames[d.weekday - 1],
          revenue: revenue,
          orderCount: orders.length,
        ));
      }
    } else if (_period == _AnalyticsPeriod.monthly) {
      // Group into 6 buckets of 5 days each (last 30 days)
      for (int i = 5; i >= 0; i--) {
        final end = DateTime(now.year, now.month, now.day - (i * 5));
        final start = DateTime(now.year, now.month, end.day - 4);
        final orders = filtered.where((o) {
          final c = DateTime.tryParse(o['created_at'] as String? ?? '');
          if (c == null) return false;
          final d = DateTime(c.year, c.month, c.day);
          return !d.isBefore(start) && !d.isAfter(end);
        });
        final revenue =
            orders.fold<double>(0, (p, o) => p + _revenueFor(o));
        buckets.add(_Bucket(
          label: '${start.day}-${end.day}',
          revenue: revenue,
          orderCount: orders.length,
        ));
      }
    } else {
      // Yearly: 12 monthly buckets
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      for (int i = 11; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final orders = filtered.where((o) {
          final c = DateTime.tryParse(o['created_at'] as String? ?? '');
          return c != null && c.year == m.year && c.month == m.month;
        });
        final revenue =
            orders.fold<double>(0, (p, o) => p + _revenueFor(o));
        buckets.add(_Bucket(
          label: monthNames[m.month - 1],
          revenue: revenue,
          orderCount: orders.length,
        ));
      }
    }
    return buckets;
  }

  // ============================================================
  // Empty state
  // ============================================================
  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(Icons.bar_chart,
                size: 16.w, color: theme.colorScheme.outline),
            SizedBox(height: 2.h),
            Text(
              AppLocalizations.of(context)!.noOrdersYet,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Text(
              'Analytics will appear here once you receive orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bucket {
  final String label;
  final double revenue;
  final int orderCount;

  _Bucket({
    required this.label,
    required this.revenue,
    required this.orderCount,
  });
}
