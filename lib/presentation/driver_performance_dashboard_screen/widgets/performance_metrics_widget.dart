import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final int completedDeliveries;
  final int totalDeliveries;
  final double acceptanceRate;
  final double averageDeliveryTime;
  final double earnings;

  const PerformanceMetricsWidget({
    super.key,
    required this.completedDeliveries,
    required this.totalDeliveries,
    required this.acceptanceRate,
    required this.averageDeliveryTime,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final avgPerDelivery = completedDeliveries > 0 ? earnings / completedDeliveries : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Performance Metrics',
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Row(children: [
          Expanded(child: _buildMetricCard(context, Icons.check_circle, 'Completed',
              '$completedDeliveries/$totalDeliveries', Colors.green)),
          SizedBox(width: 3.w),
          Expanded(child: _buildMetricCard(context, Icons.thumb_up, 'Acceptance',
              '${acceptanceRate.toStringAsFixed(0)}%', Colors.blue)),
        ]),
        SizedBox(height: 2.h),
        Row(children: [
          Expanded(child: _buildMetricCard(context, Icons.timer, 'Avg Time',
              '${averageDeliveryTime.toStringAsFixed(0)} min', Colors.orange)),
          SizedBox(width: 3.w),
          Expanded(child: _buildMetricCard(context, Icons.attach_money, 'Per Delivery',
              '\$${avgPerDelivery.toStringAsFixed(2)}', AppTheme.kjRed)),
        ]),
      ]),
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 6.w),
        SizedBox(height: 1.h),
        Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 0.5.h),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp), textAlign: TextAlign.center),
      ]),
    );
  }
}