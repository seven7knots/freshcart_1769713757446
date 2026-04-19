import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_model.dart';
import '../../l10n/generated/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<NotificationsProvider>().fetchNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null) {
                      provider.markAllAsRead(userId);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.markAllRead,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  SizedBox(height: 2.h),
                  Text(provider.error!, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () {
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) provider.fetchNotifications(userId);
                    },
                    child: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    AppLocalizations.of(context)!.noNotificationsYet,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
                  Text(
                    'You\'ll see order updates, promotions\nand more here',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }

          final grouped = _groupByDate(provider.notifications);

          return RefreshIndicator(
            onRefresh: () async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                await provider.fetchNotifications(userId);
              }
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                      child: Text(
                        group.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    ...group.items.map(
                      (notification) => _NotificationTile(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<_NotificationGroup> _groupByDate(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final n in notifications) {
      final created = n.createdAt;
      if (created == null) {
        earlierItems.add(n);
        continue;
      }
      final date = DateTime(created.year, created.month, created.day);
      if (date == today) {
        todayItems.add(n);
      } else if (date == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    final groups = <_NotificationGroup>[];
    if (todayItems.isNotEmpty) groups.add(_NotificationGroup('TODAY', todayItems));
    if (yesterdayItems.isNotEmpty) groups.add(_NotificationGroup('YESTERDAY', yesterdayItems));
    if (earlierItems.isNotEmpty) groups.add(_NotificationGroup('EARLIER', earlierItems));
    return groups;
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    context.read<NotificationsProvider>().markAsRead(notification.id);

    final actionType = notification.actionType ?? '';
    final actionData = notification.actionData;

    switch (actionType) {
      case 'order_created':
      case 'order_status':
      case 'order_accepted':
      case 'order_rejected':
      case 'order_delivered':
      case 'driver_assigned':
      case 'driver_picked_up':
        if (actionData['order_id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.orderTracking,
            arguments: {'id': actionData['order_id']},
          );
        }
        break;

      case 'driver_application_approved':
      case 'driver_application_rejected':
      case 'driver_application_pending':
        Navigator.pushNamed(context, AppRoutes.driverApplication);
        break;

      case 'merchant_application_approved':
      case 'merchant_application_rejected':
      case 'merchant_application_pending':
        Navigator.pushNamed(context, AppRoutes.merchantApplication);
        break;

      case 'promotion':
      case 'promo_code':
        AppRoutes.switchToTab(context, 0);
        break;

      default:
        debugPrint('[NOTIFICATIONS] Unknown action type: $actionType');
        break;
    }
  }
}

class _NotificationGroup {
  final String label;
  final List<NotificationModel> items;
  _NotificationGroup(this.label, this.items);
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;
    final type = notification.type ?? '';
    final title = notification.title;
    final body = notification.body ?? '';
    final createdAt = notification.createdAt;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : theme.colorScheme.primary.withOpacity(0.04),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: _getIconColor(type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIcon(type),
                color: _getIconColor(type),
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (!isRead)
                        Container(
                          width: 2.w,
                          height: 2.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTime(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10.sp,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.receipt_long_outlined;
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'order_accepted':
        return Icons.check_circle_outline;
      case 'order_rejected':
        return Icons.cancel_outlined;
      case 'order_delivered':
        return Icons.task_alt;
      case 'driver_assigned':
      case 'driver_picked_up':
        return Icons.delivery_dining;
      case 'driver_application_approved':
      case 'driver_application_rejected':
      case 'driver_application_pending':
        return Icons.drive_eta_outlined;
      case 'merchant_application_approved':
      case 'merchant_application_rejected':
      case 'merchant_application_pending':
        return Icons.store_outlined;
      case 'promotion':
      case 'promo_code':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.blue;
      case 'order_status':
      case 'order_delivered':
        return Colors.green;
      case 'order_accepted':
        return Colors.teal;
      case 'order_rejected':
        return Colors.red;
      case 'driver_assigned':
      case 'driver_picked_up':
        return Colors.orange;
      case 'driver_application_approved':
      case 'merchant_application_approved':
        return Colors.green;
      case 'driver_application_rejected':
      case 'merchant_application_rejected':
        return Colors.red;
      case 'driver_application_pending':
      case 'merchant_application_pending':
        return Colors.amber;
      case 'promotion':
      case 'promo_code':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}