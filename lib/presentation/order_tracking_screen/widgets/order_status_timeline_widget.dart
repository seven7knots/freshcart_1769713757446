import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OrderStatusTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> orderStatuses;
  final int currentStatusIndex;

  const OrderStatusTimelineWidget({
    super.key,
    required this.orderStatuses,
    required this.currentStatusIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.h),
          ...orderStatuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = index <= currentStatusIndex;
            final isActive = index == currentStatusIndex;
            final isLast = index == orderStatuses.length - 1;

            return _buildTimelineItem(
              context,
              status: status,
              isCompleted: isCompleted,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required Map<String, dynamic> status,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final colorScheme = AppTheme.lightTheme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppTheme.lightTheme.colorScheme.secondary
                    : colorScheme.outline.withValues(alpha: 0.3),
                border: Border.all(
                  color: isActive
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.5),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: isCompleted
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.lightTheme.colorScheme.onSecondary,
                      size: 3.w,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 8.h,
                color: isCompleted
                    ? AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
          ],
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status['title'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                if (status['timestamp'] != null)
                  Text(
                    status['timestamp'] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (status['description'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      status['description'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
