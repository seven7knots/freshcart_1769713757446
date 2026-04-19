import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class LoyaltyRewardsWidget extends StatelessWidget {
  final Map<String, dynamic> rewardsData;
  final VoidCallback? onViewAllPressed;

  const LoyaltyRewardsWidget({
    super.key,
    required this.rewardsData,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentPoints = rewardsData["currentPoints"] as int;
    final nextTierPoints = rewardsData["nextTierPoints"] as int;
    final progress = currentPoints / nextTierPoints;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.secondary,
            cs.secondary.withOpacity(0.80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withOpacity(0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                AppLocalizations.of(context)!.loyaltyRewards,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSecondary,
                  fontWeight: FontWeight.w700,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              TextButton(
                onPressed: onViewAllPressed,
                child: Text(
                  AppLocalizations.of(context)!.viewAll,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSecondary.withOpacity(0.80),
                    fontWeight: FontWeight.w600,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: cs.onSecondary.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'stars',
                    color: cs.onSecondary,
                    size: 6.w,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentPoints Points',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: cs.onSecondary,
                        fontWeight: FontWeight.w700,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${nextTierPoints - currentPoints} points to ${rewardsData["nextTier"]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSecondary.withOpacity(0.80),
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(
                    'Progress to ${rewardsData["nextTier"]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSecondary.withOpacity(0.80),
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Flexible(child: Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSecondary,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                width: double.infinity,
                height: 1.h,
                decoration: BoxDecoration(
                  color: cs.onSecondary.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.onSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildBenefitItem(
                  context,
                  'Free Delivery',
                  '${rewardsData["freeDeliveries"]} left',
                  'local_shipping',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildBenefitItem(
                  context,
                  'Cashback',
                  '${rewardsData["cashbackRate"]}% rate',
                  'account_balance_wallet',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: cs.onSecondary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: cs.onSecondary,
            size: 5.w,
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSecondary.withOpacity(0.80),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
