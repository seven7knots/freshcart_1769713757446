import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onExploreProducts;

  const EmptyStateWidget({
    super.key,
    this.onExploreProducts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 4.h),

            Container(
              width: 60.w,
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'shopping_bag',
                    color: Theme.of(context).colorScheme.outline,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  CustomIconWidget(
                    iconName: 'receipt_long',
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
                    size: 32,
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            Text(
              AppLocalizations.of(context)!.noOrdersYet2,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),

            SizedBox(height: 1.5.h),

            Text(
              AppLocalizations.of(context)!.startShoppingToSeeYourOrder,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),

            SizedBox(height: 4.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onExploreProducts?.call();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'explore',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Flexible(child: Text(
                      AppLocalizations.of(context)!.exploreProducts,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}