import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class GoalTrackingWidget extends StatelessWidget {
  final double currentEarnings;
  final double dailyGoal;
  final int currentDeliveries;
  final int deliveryGoal;

  const GoalTrackingWidget({
    super.key,
    required this.currentEarnings,
    required this.dailyGoal,
    required this.currentDeliveries,
    required this.deliveryGoal,
  });

  @override
  Widget build(BuildContext context) {
    final earningsProgress = currentEarnings / dailyGoal;
    final deliveriesProgress = currentDeliveries / deliveryGoal;

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
            'Daily Goals',
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildGoalProgress(
            icon: Icons.attach_money,
            label: 'Earnings Goal',
            current: '\$${currentEarnings.toStringAsFixed(2)}',
            target: '\$${dailyGoal.toStringAsFixed(2)}',
            progress: earningsProgress.clamp(0.0, 1.0),
            color: Colors.green,
            context: context,
          ),
          SizedBox(height: 2.h),
          _buildGoalProgress(
            icon: Icons.local_shipping,
            label: 'Delivery Goal',
            current: '$currentDeliveries',
            target: '$deliveryGoal',
            progress: deliveriesProgress.clamp(0.0, 1.0),
            color: Colors.blue,
            context: context,
          ),
          SizedBox(height: 2.h),
          if (earningsProgress < 1.0) _buildProjection(),
        ],
      ),
    );
  }

  Widget _buildGoalProgress({
    required IconData icon,
    required String label,
    required String current,
    required String target,
    required double progress,
    required Color color,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              current,
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'of $target',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.5.h,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% Complete',
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildProjection() {
    final remaining = dailyGoal - currentEarnings;
    final avgPerDelivery =
        currentDeliveries > 0 ? currentEarnings / currentDeliveries : 10.0;
    final deliveriesNeeded = (remaining / avgPerDelivery).ceil();

    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: AppTheme.primaryDark.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryDark,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Complete $deliveriesNeeded more deliveries to reach your daily goal',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
