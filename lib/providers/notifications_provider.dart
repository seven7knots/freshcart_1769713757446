import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  RealtimeChannel? _notificationsChannel;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Fetch initial notifications and subscribe to realtime updates
  Future<void> initialize(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch initial notifications
      await fetchNotifications(userId);

      // Subscribe to realtime notifications
      await _subscribeToNotifications(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('[NOTIFICATIONS] Error initializing: $e');
    }
  }

  /// Fetch notifications from database
  Future<void> fetchNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      notifyListeners();
      debugPrint(
        '[NOTIFICATIONS] Fetched ${_notifications.length} notifications',
      );
    } catch (e) {
      _error = 'Failed to fetch notifications: $e';
      notifyListeners();
      debugPrint('[NOTIFICATIONS] Error fetching: $e');
    }
  }

  /// Subscribe to realtime notification updates
  Future<void> _subscribeToNotifications(String userId) async {
    try {
      // Unsubscribe from existing channel if any
      await _notificationsChannel?.unsubscribe();

      _notificationsChannel = _client
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              final newNotification = NotificationModel.fromJson(
                payload.newRecord,
              );
              _notifications.insert(0, newNotification);
              notifyListeners();
              debugPrint(
                '[NOTIFICATIONS] New notification received: ${newNotification.title}',
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              final updatedNotification = NotificationModel.fromJson(
                payload.newRecord,
              );
              final index = _notifications.indexWhere(
                (n) => n.id == updatedNotification.id,
              );
              if (index != -1) {
                _notifications[index] = updatedNotification;
                notifyListeners();
                debugPrint(
                  '[NOTIFICATIONS] Notification updated: ${updatedNotification.id}',
                );
              }
            },
          )
          .subscribe();

      debugPrint(
        '[NOTIFICATIONS] Subscribed to realtime updates for user: $userId',
      );
    } catch (e) {
      debugPrint('[NOTIFICATIONS] Error subscribing to realtime: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          type: _notifications[index].type,
          title: _notifications[index].title,
          titleAr: _notifications[index].titleAr,
          body: _notifications[index].body,
          bodyAr: _notifications[index].bodyAr,
          imageUrl: _notifications[index].imageUrl,
          actionType: _notifications[index].actionType,
          actionData: _notifications[index].actionData,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }

      debugPrint('[NOTIFICATIONS] Marked as read: $notificationId');
    } catch (e) {
      debugPrint('[NOTIFICATIONS] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      // Update local state
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            titleAr: n.titleAr,
            body: n.body,
            bodyAr: n.bodyAr,
            imageUrl: n.imageUrl,
            actionType: n.actionType,
            actionData: n.actionData,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      notifyListeners();
      debugPrint('[NOTIFICATIONS] Marked all as read for user: $userId');
    } catch (e) {
      debugPrint('[NOTIFICATIONS] Error marking all as read: $e');
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }

  /// Cleanup subscriptions
  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    debugPrint('[NOTIFICATIONS] Provider disposed, channel unsubscribed');
    super.dispose();
  }
}
