import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class SubscriptionManagementWidget extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const SubscriptionManagementWidget({
    super.key,
    required this.subscription,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = subscription['status'] ?? 'active';
    final isPaused = status == 'paused';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                AppLocalizations.of(context)!.manageSubscription,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 2.h),
            if (!isPaused)
              _buildManagementOption(
                context,
                icon: Icons.pause_circle_outline,
                title: AppLocalizations.of(context)!.pauseSubscription,
                subtitle: AppLocalizations.of(context)!.temporarilyPauseYourSubscription,
                onTap: onPause,
              ),
            if (isPaused)
              _buildManagementOption(
                context,
                icon: Icons.play_circle_outline,
                title: AppLocalizations.of(context)!.resumeSubscription,
                subtitle: AppLocalizations.of(context)!.resumeYourPausedSubscription,
                onTap: onResume,
              ),
            _buildManagementOption(
              context,
              icon: Icons.cancel_outlined,
              title: AppLocalizations.of(context)!.cancelSubscription,
              subtitle: AppLocalizations.of(context)!.cancelYourSubscriptionPermanently,
              onTap: onCancel,
              isDestructive: true,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: (isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: subscription['status'] == 'cancelled'
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
