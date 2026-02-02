import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryRiderInfoWidget extends StatelessWidget {
  final Map<String, dynamic> riderInfo;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;

  const DeliveryRiderInfoWidget({
    super.key,
    required this.riderInfo,
    this.onCallPressed,
    this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Delivery Partner',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CustomImageWidget(
                    imageUrl: riderInfo['avatar'] as String,
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                    semanticLabel: riderInfo['avatarSemanticLabel'] as String,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riderInfo['name'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: AppTheme.accentLight,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${riderInfo['rating']} (${riderInfo['totalDeliveries']} deliveries)',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      riderInfo['vehicleInfo'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildActionButton(
                    context,
                    icon: 'phone',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onCallPressed?.call();
                    },
                    tooltip: 'Call rider',
                  ),
                  SizedBox(width: 2.w),
                  _buildActionButton(
                    context,
                    icon: 'message',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onMessagePressed?.call();
                    },
                    tooltip: 'Message rider',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.secondary,
          size: 5.w,
        ),
      ),
    );
  }
}
