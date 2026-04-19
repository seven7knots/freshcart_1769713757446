import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/subscription_plan_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlanCardWidget extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  const PlanCardWidget({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isCurrentPlan
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(
                plan.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isCurrentPlan)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'CURRENT',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(
                '\$${plan.price.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Text(
                  '/${plan.billingCycle ?? 'month'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (plan.description != null) ...[
            SizedBox(height: 1.h),
            Text(
              plan.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: 2.h),
          Text(
            AppLocalizations.of(context)!.features,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          ...plan.features.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      feature.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentPlan ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan
                    ? Colors.grey.shade400
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                disabledBackgroundColor: Colors.grey.shade400.withValues(
                  alpha: 0.3,
                ),
              ),
              child: Text(
                isCurrentPlan ? AppLocalizations.of(context)!.currentPlan : AppLocalizations.of(context)!.subscribe2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
