import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

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
            AppLocalizations.of(context)!.orderProgress,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                    ? Theme.of(context).colorScheme.secondary
                    : colorScheme.outline.withValues(alpha: 0.3),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.5),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: isCompleted
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: Theme.of(context).colorScheme.onSecondary,
                      size: 3.w,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 8.h,
                color: isCompleted
                    ? Theme.of(context).colorScheme.secondary
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                if (status['timestamp'] != null)
                  Text(
                    status['timestamp'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (status['description'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      status['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}