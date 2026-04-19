import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/order_model.dart';
import '../../../l10n/generated/app_localizations.dart';

// SESSION 39: Fixed Total Deliveries to query actual completed orders,
// added dark mode support, removed hardcoded colors.
class PerformanceMetricsSidebarWidget extends StatefulWidget {
  final List<dynamic> drivers;
  final List<OrderModel> orders;

  const PerformanceMetricsSidebarWidget({
    super.key,
    required this.drivers,
    required this.orders,
  });

  @override
  State<PerformanceMetricsSidebarWidget> createState() =>
      _PerformanceMetricsSidebarWidgetState();
}

class _PerformanceMetricsSidebarWidgetState
    extends State<PerformanceMetricsSidebarWidget> {
  int _totalDeliveries = 0;
  bool _loadingDeliveries = true;

  @override
  void initState() {
    super.initState();
    _loadTotalDeliveries();
  }

  Future<void> _loadTotalDeliveries() async {
    try {
      final result = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('status', 'delivered');
      if (mounted) {
        setState(() {
          _totalDeliveries = (result as List).length;
          _loadingDeliveries = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDeliveries = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final dividerColor = theme.dividerColor;

    final onlineDrivers =
        widget.drivers.where((d) => (d as dynamic).isOnline == true).length;
    final totalDrivers = widget.drivers.length;
    final utilizationRate =
        totalDrivers > 0 ? (onlineDrivers / totalDrivers * 100) : 0.0;

    final avgRating = widget.drivers.isNotEmpty
        ? widget.drivers
                .map((d) => ((d as dynamic).rating ?? 0.0) as double)
                .reduce((a, b) => a + b) /
            widget.drivers.length
        : 0.0;

    final pendingCount = widget.orders.length;
    final priorityCount = widget.orders.where((o) => o.isPriority).length;

    return Container(
      width: 70.w,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.performanceMetrics,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.analytics, color: Colors.blue),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildMetricCard(
                  theme: theme,
                  title: AppLocalizations.of(context)!.driverUtilization,
                  value: '${utilizationRate.toStringAsFixed(1)}%',
                  subtitle: '$onlineDrivers of $totalDrivers online',
                  icon: Icons.people,
                  color: Colors.blue,
                  progress: utilizationRate / 100,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  theme: theme,
                  title: AppLocalizations.of(context)!.averageRating,
                  value: avgRating.toStringAsFixed(2),
                  subtitle: AppLocalizations.of(context)!.acrossAllDrivers,
                  icon: Icons.star,
                  color: Colors.amber,
                  progress: avgRating / 5,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  theme: theme,
                  title: AppLocalizations.of(context)!.totalDeliveries,
                  value: _loadingDeliveries ? '...' : _totalDeliveries.toString(),
                  subtitle: AppLocalizations.of(context)!.allTimeCompleted,
                  icon: Icons.local_shipping,
                  color: Colors.green,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  theme: theme,
                  title: AppLocalizations.of(context)!.pendingOrders,
                  value: pendingCount.toString(),
                  subtitle: AppLocalizations.of(context)!.awaitingAssignment,
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  theme: theme,
                  title: AppLocalizations.of(context)!.priorityOrders,
                  value: priorityCount.toString(),
                  subtitle: AppLocalizations.of(context)!.requiresImmediateAttention,
                  icon: Icons.priority_high,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    final cardColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        color: onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
