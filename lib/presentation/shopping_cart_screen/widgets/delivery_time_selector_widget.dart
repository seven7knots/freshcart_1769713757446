import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

class DeliveryTimeSelectorWidget extends StatefulWidget {
  final String? selectedSlot;
  final Function(String, double)? onSlotSelected;

  const DeliveryTimeSelectorWidget({
    super.key,
    this.selectedSlot,
    this.onSlotSelected,
  });

  @override
  State<DeliveryTimeSelectorWidget> createState() =>
      _DeliveryTimeSelectorWidgetState();
}

class _DeliveryTimeSelectorWidgetState
    extends State<DeliveryTimeSelectorWidget> {
  String? _selectedSlot;

  final List<Map<String, dynamic>> _deliverySlots = [
    {
      'id': 'express_30',
      'title': 'Express Delivery',
      'subtitle': '30-45 minutes',
      'price': 4.99,
      'isExpress': true,
      'icon': 'flash_on',
    },
    {
      'id': 'standard_2h',
      'title': 'Standard Delivery',
      'subtitle': '2-3 hours',
      'price': 2.99,
      'isExpress': false,
      'icon': 'local_shipping',
    },
    {
      'id': 'scheduled_today',
      'title': 'Scheduled Today',
      'subtitle': '4:00 PM - 6:00 PM',
      'price': 1.99,
      'isExpress': false,
      'icon': 'schedule',
    },
    {
      'id': 'scheduled_tomorrow',
      'title': 'Scheduled Tomorrow',
      'subtitle': '10:00 AM - 12:00 PM',
      'price': 0.99,
      'isExpress': false,
      'icon': 'event',
    },
    {
      'id': 'free_delivery',
      'title': 'Free Delivery',
      'subtitle': 'Tomorrow 2:00 PM - 6:00 PM',
      'price': 0.0,
      'isExpress': false,
      'icon': 'local_shipping',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.selectedSlot ?? _deliverySlots.first['id'];
  }

  void _selectSlot(String slotId, double price) {
    setState(() {
      _selectedSlot = slotId;
    });

    HapticFeedback.lightImpact();
    widget.onSlotSelected?.call(slotId, price);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'access_time',
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 3.w),
                Flexible(child: Text(
                  AppLocalizations.of(context)!.deliveryTime,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),

          Container(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),

          // Delivery Slots
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: _deliverySlots.map((slot) {
                final isSelected = _selectedSlot == slot['id'];
                final isExpress = slot['isExpress'] ?? false;
                final price = slot['price'] as double;

                return GestureDetector(
                  onTap: () => _selectSlot(slot['id'], price),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio Button
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: 2,
                            ),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : null,
                        ),

                        SizedBox(width: 3.w),

                        // Icon
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: isExpress
                                ? theme.colorScheme.tertiary
                                    .withValues(alpha: 0.1)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CustomIconWidget(
                            iconName: slot['icon'],
                            size: 20,
                            color: isExpress
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.primary,
                          ),
                        ),

                        SizedBox(width: 3.w),

                        // Slot Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    slot['title'],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (isExpress) ...[
                                    SizedBox(width: 2.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'FAST',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.onTertiary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 8.sp,
                                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                slot['subtitle'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),

                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (price > 0)
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)
                            else
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'FREE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondary,
                                    fontWeight: FontWeight.w700,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            if (isExpress) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                AppLocalizations.of(context)!.fastest,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
