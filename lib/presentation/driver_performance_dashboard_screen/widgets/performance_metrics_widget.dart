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
    final avgPerDelivery =
        completedDeliveries > 0 ? earnings / completedDeliveries : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: '$completedDeliveries/$totalDeliveries',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.thumb_up,
                  label: 'Acceptance',
                  value: '${acceptanceRate.toStringAsFixed(0)}%',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.timer,
                  label: 'Avg Time',
                  value: '${averageDeliveryTime.toStringAsFixed(0)} min',
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.attach_money,
                  label: 'Per Delivery',
                  value: '\$${avgPerDelivery.toStringAsFixed(2)}',
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondaryOf(context),
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
