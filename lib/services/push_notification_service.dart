// ============================================================
// FILE: lib/services/push_notification_service.dart
// ============================================================
// SESSION 20 – Issue 10: Real Push Notifications via FCM
//
// SESSION 24 FIXES:
// - Task 8: FCM token dedup – _saveFcmToken() now has a
//   "already saved this session" guard. Prevents the 2× token
//   save within 24ms seen in logcat (initialize + registerDevice
//   both called _saveFcmToken on app start).
// - Task 9: Android 13+ notification permission – now uses
//   permission_handler to explicitly request POST_NOTIFICATIONS
//   which fixes the "unable to pop dialog" error on OnePlus/Oppo.
//   FirebaseMessaging.requestPermission() alone doesn't always
//   trigger the native Android dialog on these OEM skins.
//
// SESSION 26 FIXES:
// - Bug #3: _tokenSavedThisSession flag now set SYNCHRONOUSLY
//   before the async save, not after. Previously two calls 20ms
//   apart both passed the guard before either completed the save.
//   Also added _tokenSaveInProgress Completer so concurrent
//   callers await the same save operation.
// - Bug #4: _saveTokenToSupabase now checks if Supabase is
//   initialized before attempting to save. If not ready, logs
//   a message and returns (token will be saved later when
//   registerDevice() is called after auth completes).
// - Bug #5: registerDevice() merchant topic subscription now
//   queries merchants.id instead of merchants.store_id (which
//   doesn't exist in the DB schema).
//
// SESSION 31 FIXES:
// - Bug #6: TECNO KF8 (and other devices with outdated/broken
//   Play Services) would hang forever on getToken() and
//   subscribeToTopic() because Firebase Installations Service
//   is unavailable (FIS_AUTH_ERROR). Added 8-second timeouts
//   on getToken(), subscribeToTopic(), and unsubscribeFromTopic()
//   so the app never blocks startup on these devices. The errors
//   are absorbed gracefully — the app starts normally and FCM
//   simply won't work on those devices.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'supabase_service.dart';

/// Top-level background handler – MUST be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _initialized = false;

  // SESSION 24 (Task 8): Guard to prevent duplicate token saves.
  // SESSION 26 (Bug #3): Now set BEFORE the async save, not after.
  static bool _tokenSavedThisSession = false;

  // SESSION 26 (Bug #3): In-flight dedup for token save.
  // If a save is already in progress, subsequent callers await
  // the same Completer instead of firing a parallel save.
  static Completer<void>? _tokenSaveCompleter;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kj_delivery_orders',
    'Order Updates',
    description:
        'Notifications for order status updates, driver assignments, and delivery alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();

    await _setupLocalNotifications();

    // Create Android notification channel
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // SESSION 26 (Bug #4): Attempt token save, but don't block init.
    // If Supabase isn't ready yet, _saveTokenToSupabase will skip
    // gracefully. Token will be saved later when registerDevice()
    // is called after auth completes.
    await _saveFcmToken();

    // SESSION 26 FIX (Bug #3 re-login): Route through _saveFcmToken()
    // so the dedup guard applies. Previously this called
    // _saveTokenToSupabase() directly, bypassing _tokenSavedThisSession,
    // which caused a double save when onTokenRefresh fired at the same
    // time as registerDevice() after sign-out → sign-in.
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
      // Don't reset _tokenSavedThisSession here – let registerDevice()
      // handle the reset if it needs a fresh save. The refresh listener
      // only needs to save if it hasn't been saved yet this session.
      _saveFcmToken();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }

    // SESSION 31 (Bug #6): subscribeToTopic hangs forever on devices
    // with broken Play Services (e.g. TECNO KF8 — FIS_AUTH_ERROR).
    // Added 8-second timeout so startup is never blocked.
    try {
      await _messaging
          .subscribeToTopic('system_alerts')
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic(system_alerts) skipped: $e');
    }

    _initialized = true;
    debugPrint('[FCM] Push notification service initialized');
  }

  // ============================================================
  // PERMISSION – SESSION 24 (Task 9) FIX
  // ============================================================

  static Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      debugPrint('[FCM] Android notification permission status: $status');

      if (status.isDenied) {
        final result = await Permission.notification.request();
        debugPrint('[FCM] Android notification permission result: $result');

        if (result.isPermanentlyDenied) {
          debugPrint('[FCM] ⚠️ Notification permission permanently denied. '
              'User must enable in device Settings > Apps > KJ Delivery > Notifications');
        }
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('[FCM] FCM permission status: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ============================================================
  // LOCAL NOTIFICATIONS SETUP
  // ============================================================

  static Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // ============================================================
  // FCM TOKEN MANAGEMENT – SESSION 24 (Task 8) + SESSION 26 FIX
  // ============================================================

  static Future<void> _saveFcmToken() async {
    // SESSION 26 (Bug #3): Check the flag FIRST (synchronous guard)
    if (_tokenSavedThisSession) {
      debugPrint('[FCM] Token save SKIPPED (already saved this session)');
      return;
    }

    // SESSION 26 (Bug #3): If a save is already in-flight, await it
    if (_tokenSaveCompleter != null && !_tokenSaveCompleter!.isCompleted) {
      debugPrint('[FCM] Token save DEDUPED (awaiting in-flight save)');
      await _tokenSaveCompleter!.future;
      return;
    }

    // SESSION 26 (Bug #3): Set flag SYNCHRONOUSLY before any async work.
    // This prevents the race where two calls 20ms apart both pass the
    // guard before either completes the save.
    _tokenSavedThisSession = true;
    _tokenSaveCompleter = Completer<void>();

    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint(
              '[FCM] APNs token not yet available, will retry on refresh');
          // Reset flag so it can retry later
          _tokenSavedThisSession = false;
          _tokenSaveCompleter!.complete();
          return;
        }
      }

      // SESSION 31 (Bug #6): getToken() hangs forever on devices with
      // broken Play Services (FIS_AUTH_ERROR). Added 8-second timeout
      // so startup is never blocked on TECNO KF8 and similar devices.
      final token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 8));

      if (token != null) {
        debugPrint('[FCM] Token obtained: ${token.substring(0, 20)}...');
        await _saveTokenToSupabase(token);
        // Flag stays true – token saved successfully
      } else {
        // No token available, reset flag for retry
        _tokenSavedThisSession = false;
      }

      _tokenSaveCompleter!.complete();
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      // Reset flag so it can retry later
      _tokenSavedThisSession = false;
      _tokenSaveCompleter!.complete(); // Absorb error, retry later
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    // SESSION 26 (Bug #4): Check if Supabase is initialized before
    // attempting to save. During cold start, FCM initializes and
    // obtains a token ~6.6 seconds BEFORE Supabase.init() completes.
    // Previously this threw "You must initialize the supabase instance
    // before calling Supabase.instance".
    try {
      // This will throw if Supabase hasn't been initialized yet
      final client = SupabaseService.client;
      final user = client.auth.currentUser;

      if (user == null) {
        debugPrint('[FCM] No user logged in, skipping token save');
        return;
      }

      await client.from('users').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
        'device_platform': Platform.isIOS ? 'ios' : 'android',
      }).eq('id', user.id);

      debugPrint('[FCM] Token saved to Supabase for user ${user.id}');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('not initialized') ||
          errorStr.contains('initialize')) {
        // SESSION 26 (Bug #4): Supabase not ready yet. This is expected
        // during cold start. Token will be saved when registerDevice()
        // is called after auth completes.
        debugPrint('[FCM] Supabase not initialized yet, token save deferred to registerDevice()');
      } else {
        debugPrint('[FCM] Error saving token to Supabase: $e');
      }
    }
  }

  // SESSION 26 FIX: Guard to prevent duplicate registerDevice() calls.
  // Logcat showed role_merchant and store_ topics subscribed 2x,
  // meaning registerDevice() was called twice in quick succession.
  static Completer<void>? _registerDeviceCompleter;

  static Future<void> registerDevice() async {
    // Dedup: if already in progress, await the same operation
    if (_registerDeviceCompleter != null && !_registerDeviceCompleter!.isCompleted) {
      debugPrint('[FCM] registerDevice DEDUPED (already in progress)');
      await _registerDeviceCompleter!.future;
      return;
    }

    _registerDeviceCompleter = Completer<void>();

    try {
      _tokenSavedThisSession = false;
      await _saveFcmToken();

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        _registerDeviceCompleter!.complete();
        return;
      }

      final userData = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = userData?['role'] as String? ?? 'customer';

      // SESSION 31 (Bug #6): subscribeToTopic hangs on broken Play Services.
      try {
        await _messaging
            .subscribeToTopic('role_$role')
            .timeout(const Duration(seconds: 8));
        debugPrint('[FCM] Subscribed to topic: role_$role');
      } catch (e) {
        debugPrint('[FCM] subscribeToTopic(role_$role) skipped: $e');
      }

      if (role == 'driver') {
        try {
          await _messaging
              .subscribeToTopic('new_orders')
              .timeout(const Duration(seconds: 8));
          debugPrint('[FCM] Driver subscribed to: new_orders');
        } catch (e) {
          debugPrint('[FCM] subscribeToTopic(new_orders) skipped: $e');
        }
      }

      if (role == 'merchant') {
        // SESSION 26 (Bug #5): Query merchants.id instead of
        // merchants.store_id. The merchants table does not have
        // a store_id column – the merchant's own id is used to
        // identify their store for topic subscription purposes.
        final merchant = await SupabaseService.client
            .from('merchants')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (merchant != null && merchant['id'] != null) {
          final merchantId = merchant['id'] as String;
          try {
            await _messaging
                .subscribeToTopic('store_$merchantId')
                .timeout(const Duration(seconds: 8));
            debugPrint('[FCM] Merchant subscribed to: store_$merchantId');
          } catch (e) {
            debugPrint('[FCM] subscribeToTopic(store_$merchantId) skipped: $e');
          }
        }
      }

      _registerDeviceCompleter!.complete();
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topics: $e');
      _registerDeviceCompleter!.complete(); // Absorb error, non-fatal
    }
  }

  static Future<void> unregisterDevice() async {
    _tokenSavedThisSession = false;

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client.from('users').update({
          'fcm_token': null,
          'fcm_token_updated_at': null,
        }).eq('id', user.id);
      }

      for (final topic in [
        'role_customer',
        'role_driver',
        'role_merchant',
        'role_admin',
        'new_orders'
      ]) {
        try {
          await _messaging
              .unsubscribeFromTopic(topic)
              .timeout(const Duration(seconds: 8));
        } catch (e) { debugPrint('[PUSH_NOTIFICATION_SERVICE] Silent error: $e'); }
      }

      // SESSION 31 (Bug #6): deleteToken can also hang on broken Play Services.
      try {
        await _messaging.deleteToken().timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[FCM] deleteToken skipped: $e');
      }

      debugPrint('[FCM] Device unregistered');
    } catch (e) {
      debugPrint('[FCM] Error unregistering: $e');
    }
  }

  // ============================================================
  // MESSAGE HANDLERS
  // ============================================================

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'KJ Delivery',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFE64A19),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    _storeNotificationLocally(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    _navigateFromPayload(message.data);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data =
            jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromPayload(data);
      } catch (e) {
        debugPrint('[FCM] Error parsing notification payload: $e');
      }
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('[FCM] Navigator not available');
      return;
    }

    final type = data['type'] as String? ?? '';
    final orderId = data['order_id'] as String?;
    final storeId = data['store_id'] as String?;

    switch (type) {
      case 'order_update':
      case 'order_status':
      case 'order_confirmed':
      case 'order_preparing':
      case 'order_ready':
      case 'order_picked_up':
      case 'order_delivered':
        if (orderId != null) {
          navigator.pushNamed('/order-tracking', arguments: {'id': orderId});
        }
        break;

      case 'new_order':
        navigator.pushNamed('/enhanced-order-management');
        break;

      case 'driver_assigned':
      case 'delivery_update':
        if (orderId != null) {
          navigator.pushNamed('/order-tracking', arguments: {'id': orderId});
        }
        break;

      case 'new_delivery_request':
        navigator.pushNamed('/driver-orders');
        break;

      case 'promotion':
      case 'deal':
        if (storeId != null) {
          navigator.pushNamed('/store-detail', arguments: storeId);
        }
        break;

      case 'system_alert':
        navigator.pushNamed('/notifications');
        break;

      default:
        navigator.pushNamed('/notifications');
        break;
    }
  }

  // ============================================================
  // HELPER: Store notification for in-app display
  // ============================================================

  static Future<void> _storeNotificationLocally(RemoteMessage message) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client.from('notifications').insert({
        'user_id': user.id,
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'general',
        'data': message.data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[FCM] Error storing notification: $e');
    }
  }

  // ============================================================
  // PUBLIC API
  // ============================================================

  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[FCM] Notification queued for user: $userId');
    } catch (e) {
      debugPrint('[FCM] Error sending notification: $e');
    }
  }

  static Future<void> notifyOrderStatus({
    required String customerId,
    required String orderId,
    required String status,
    String? storeName,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed!';
        body = storeName != null
            ? '$storeName has confirmed your order'
            : 'Your order has been confirmed';
        break;
      case 'preparing':
        title = 'Order Being Prepared';
        body = storeName != null
            ? '$storeName is preparing your order'
            : 'Your order is being prepared';
        break;
      case 'ready':
        title = 'Order Ready for Pickup';
        body = 'Your order is ready and waiting for a driver';
        break;
      case 'picked_up':
      case 'in_transit':
        title = 'Order On Its Way!';
        body = 'Your driver has picked up your order';
        break;
      case 'delivered':
        title = 'Order Delivered!';
        body = 'Your order has been delivered. Enjoy!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order has been cancelled';
        break;
      default:
        title = 'Order Update';
        body = 'Your order status has been updated to $status';
    }

    await sendToUser(
      userId: customerId,
      title: title,
      body: body,
      type: 'order_$status',
      data: {'order_id': orderId, 'type': 'order_status'},
    );
  }

  static Future<void> notifyMerchantNewOrder({
    required String merchantUserId,
    required String orderId,
    required double total,
  }) async {
    await sendToUser(
      userId: merchantUserId,
      title: 'New Order!',
      body: 'You have a new order worth \$${total.toStringAsFixed(2)}',
      type: 'new_order',
      data: {'order_id': orderId, 'type': 'new_order'},
    );
  }

  static Future<void> notifyDriverNewDelivery({
    required String driverUserId,
    required String orderId,
    required String pickupAddress,
  }) async {
    await sendToUser(
      userId: driverUserId,
      title: 'New Delivery Request',
      body: 'Pickup from: $pickupAddress',
      type: 'new_delivery_request',
      data: {'order_id': orderId, 'type': 'new_delivery_request'},
    );
  }
}
