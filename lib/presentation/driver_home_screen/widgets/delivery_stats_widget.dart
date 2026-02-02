import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeliveryStatsWidget extends StatelessWidget {
  final int completedToday;
  final int activeHours;
  final double averagePerDelivery;

  const DeliveryStatsWidget({
    super.key,
    required this.completedToday,
    required this.activeHours,
    required this.averagePerDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Stats',
            style: TextStyle(
              color: AppTheme.textOnLight,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Completed',
                value: completedToday.toString(),
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.access_time,
                label: 'Active Hours',
                value: activeHours.toString(),
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.attach_money,
                label: 'Avg/Order',
                value: '\$${averagePerDelivery.toStringAsFixed(2)}',
                color: AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textOnLight,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF616161),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
