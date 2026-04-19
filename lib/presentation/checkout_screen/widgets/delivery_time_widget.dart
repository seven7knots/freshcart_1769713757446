import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class DeliveryTimeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> timeSlots;
  final int selectedSlotIndex;
  final ValueChanged<int> onSlotSelected;

  const DeliveryTimeWidget({
    super.key,
    required this.timeSlots,
    required this.selectedSlotIndex,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                color: colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Flexible(child: Text(
                AppLocalizations.of(context)!.deliveryTime,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 12.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: timeSlots.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final slot = timeSlots[index];
                final isSelected = index == selectedSlotIndex;
                final isExpress = slot['type'] == 'express';

                return GestureDetector(
                  onTap: () => onSlotSelected(index),
                  child: Container(
                    width: 35.w,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isExpress) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 1.5.w, vertical: 0.3.h),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'EXPRESS',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.surface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8.sp,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(width: 1.w),
                            ],
                            Expanded(
                              child: Text(
                                slot['label'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          slot['time'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 0.5.h),
                        Text(
                          slot['fee'] as double > 0
                              ? '+\$${(slot['fee'] as double).toStringAsFixed(2)}'
                              : AppLocalizations.of(context)!.free,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: slot['fee'] as double > 0
                                ? Colors.orange
                                : AppTheme.accentLight,
                            fontWeight: FontWeight.w600,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
