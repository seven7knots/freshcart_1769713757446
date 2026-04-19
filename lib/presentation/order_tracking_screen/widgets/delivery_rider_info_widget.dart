import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.yourDeliveryPartner,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 3.h),
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme.onSurfaceVariant,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      riderInfo['vehicleInfo'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    tooltip: AppLocalizations.of(context)!.callRider,
                  ),
                  SizedBox(width: 2.w),
                  _buildActionButton(
                    context,
                    icon: 'message',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onMessagePressed?.call();
                    },
                    tooltip: AppLocalizations.of(context)!.messageRider,
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
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: CustomIconWidget(
          iconName: icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 5.w,
        ),
      ),
    );
  }
}