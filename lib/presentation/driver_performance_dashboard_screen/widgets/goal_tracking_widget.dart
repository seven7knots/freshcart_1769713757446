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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final earningsProgress = currentEarnings / dailyGoal;
    final deliveriesProgress = currentDeliveries / deliveryGoal;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Daily Goals',
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        _buildGoalProgress(
          context: context, icon: Icons.attach_money, label: 'Earnings Goal',
          current: '\$${currentEarnings.toStringAsFixed(2)}', target: '\$${dailyGoal.toStringAsFixed(2)}',
          progress: earningsProgress.clamp(0.0, 1.0), color: Colors.green,
        ),
        SizedBox(height: 2.h),
        _buildGoalProgress(
          context: context, icon: Icons.local_shipping, label: 'Delivery Goal',
          current: '$currentDeliveries', target: '$deliveryGoal',
          progress: deliveriesProgress.clamp(0.0, 1.0), color: Colors.blue,
        ),
        SizedBox(height: 2.h),
        if (earningsProgress < 1.0) _buildProjection(context),
      ]),
    );
  }

  Widget _buildGoalProgress({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String current,
    required String target,
    required double progress,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 5.w),
        SizedBox(width: 2.w),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp)),
      ]),
      SizedBox(height: 1.h),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(current, style: TextStyle(color: cs.onSurface, fontSize: 16.sp, fontWeight: FontWeight.bold)),
        Text('of $target', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp)),
      ]),
      SizedBox(height: 1.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 1.5.h,
        ),
      ),
      SizedBox(height: 0.5.h),
      Text('${(progress * 100).toStringAsFixed(0)}% Complete',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp)),
    ]);
  }

  Widget _buildProjection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = dailyGoal - currentEarnings;
    final avgPerDelivery = currentDeliveries > 0 ? currentEarnings / currentDeliveries : 10.0;
    final deliveriesNeeded = (remaining / avgPerDelivery).ceil();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.kjRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.kjRed.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.lightbulb_outline, color: AppTheme.kjRed, size: 5.w),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            'Complete $deliveriesNeeded more deliveries to reach your daily goal',
            style: TextStyle(color: cs.onSurface, fontSize: 11.sp),
          ),
        ),
      ]),
    );
  }
}