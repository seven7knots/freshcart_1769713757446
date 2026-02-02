import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  static FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Analytics not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  static FirebaseAnalyticsObserver get observer {
    if (_observer == null) {
      throw Exception('Analytics not initialized. Call initialize() first.');
    }
    return _observer!;
  }

  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      debugPrint('✅ Google Analytics initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Analytics: $e');
    }
  }

  // ==================== USER PROPERTIES ====================

  static Future<void> setUserProperties({
    required String userId,
    required String userRole,
    String? subscriptionStatus,
    bool? isVerified,
    double? walletBalance,
  }) async {
    try {
      await _analytics?.setUserId(id: userId);
      await _analytics?.setUserProperty(name: 'user_role', value: userRole);

      if (subscriptionStatus != null) {
        await _analytics?.setUserProperty(
          name: 'subscription_status',
          value: subscriptionStatus,
        );
      }

      if (isVerified != null) {
        await _analytics?.setUserProperty(
          name: 'user_verified',
          value: isVerified.toString(),
        );
      }

      if (walletBalance != null) {
        await _analytics?.setUserProperty(
          name: 'wallet_balance_range',
          value: _getWalletBalanceRange(walletBalance),
        );
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  static String _getWalletBalanceRange(double balance) {
    if (balance == 0) return '0';
    if (balance < 10) return '1-10';
    if (balance < 50) return '10-50';
    if (balance < 100) return '50-100';
    if (balance < 500) return '100-500';
    return '500+';
  }

  // ==================== USER FUNNEL TRACKING ====================

  static Future<void> logOnboardingStart() async {
    await _analytics?.logEvent(
      name: 'onboarding_start',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> logOnboardingComplete() async {
    await _analytics?.logEvent(
      name: 'onboarding_complete',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> logLocationPermissionGranted() async {
    await _analytics?.logEvent(
      name: 'location_permission_granted',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // ==================== AUTHENTICATION TRACKING ====================

  static Future<void> logSignUp({
    required String method,
    bool success = true,
  }) async {
    await _analytics?.logSignUp(signUpMethod: method);
    await _analytics?.logEvent(
      name: 'sign_up_attempt',
      parameters: {
        'method': method,
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logLogin({
    required String method,
    bool success = true,
  }) async {
    await _analytics?.logLogin(loginMethod: method);
    await _analytics?.logEvent(
      name: 'login_attempt',
      parameters: {
        'method': method,
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logPasswordReset(String email) async {
    await _analytics?.logEvent(
      name: 'password_reset_request',
      parameters: {
        'email_domain': email.split('@').last,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logLogout() async {
    await _analytics?.logEvent(
      name: 'logout',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // ==================== ORDER CONVERSION TRACKING ====================

  static Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
  }) async {
    await _analytics?.logViewItem(
      currency: 'USD',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: category,
          price: price,
        ),
      ],
    );
  }

  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
    required int quantity,
  }) async {
    await _analytics?.logAddToCart(
      currency: 'USD',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: category,
          price: price,
          quantity: quantity,
        ),
      ],
    );
  }

  static Future<void> logBeginCheckout({
    required double cartTotal,
    required int itemCount,
    required List<Map<String, dynamic>> items,
  }) async {
    await _analytics?.logBeginCheckout(
      currency: 'USD',
      value: cartTotal,
      items: items
          .map((item) => AnalyticsEventItem(
                itemId: item['id'] ?? '',
                itemName: item['name'] ?? '',
                price: (item['price'] ?? 0.0).toDouble(),
                quantity: item['quantity'] ?? 1,
              ))
          .toList(),
    );
  }

  static Future<void> logPurchase({
    required String orderId,
    required double total,
    required double tax,
    required double deliveryFee,
    required List<Map<String, dynamic>> items,
    String? coupon,
  }) async {
    await _analytics?.logPurchase(
      currency: 'USD',
      transactionId: orderId,
      value: total,
      tax: tax,
      shipping: deliveryFee,
      coupon: coupon,
      items: items
          .map((item) => AnalyticsEventItem(
                itemId: item['id'] ?? '',
                itemName: item['name'] ?? '',
                price: (item['price'] ?? 0.0).toDouble(),
                quantity: item['quantity'] ?? 1,
              ))
          .toList(),
    );
  }

  static Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await _analytics?.logEvent(
      name: 'remove_from_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'currency': 'USD',
      },
    );
  }

  // ==================== ADMIN ACTION TRACKING ====================

  static Future<void> logAdminDashboardAccess() async {
    await _analytics?.logEvent(
      name: 'admin_dashboard_access',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> logAdminUserManagement({
    required String action,
    required String targetUserId,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_user_management',
      parameters: {
        'action': action,
        'target_user_id': targetUserId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAdminOrderApproval({
    required String orderId,
    required bool approved,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_order_approval',
      parameters: {
        'order_id': orderId,
        'approved': approved,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAdminDriverAssignment({
    required String orderId,
    required String driverId,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_driver_assignment',
      parameters: {
        'order_id': orderId,
        'driver_id': driverId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAdminWalletAdjustment({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_wallet_adjustment',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== AI FEATURE TRACKING ====================

  static Future<void> logAIChatStart() async {
    await _analytics?.logEvent(
      name: 'ai_chat_start',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> logAIMessageSent({
    required String conversationId,
    required int messageCount,
  }) async {
    await _analytics?.logEvent(
      name: 'ai_message_sent',
      parameters: {
        'conversation_id': conversationId,
        'message_count': messageCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAIMealPlanningStart() async {
    await _analytics?.logEvent(
      name: 'ai_meal_planning_start',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> logAIMealPlanGenerated({
    required String dietType,
    required double budget,
    required int householdSize,
  }) async {
    await _analytics?.logEvent(
      name: 'ai_meal_plan_generated',
      parameters: {
        'diet_type': dietType,
        'budget': budget,
        'household_size': householdSize,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAISmartSearchUsed({
    required String query,
    required int resultsCount,
  }) async {
    await _analytics?.logEvent(
      name: 'ai_smart_search_used',
      parameters: {
        'query_length': query.length,
        'results_count': resultsCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logAIFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) async {
    await _analytics?.logEvent(
      name: 'ai_feature_usage',
      parameters: {
        'feature_name': featureName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  // ==================== DRIVER METRICS TRACKING ====================

  static Future<void> logDriverOnlineStatusChange({
    required String driverId,
    required bool isOnline,
  }) async {
    await _analytics?.logEvent(
      name: 'driver_online_status_change',
      parameters: {
        'driver_id': driverId,
        'is_online': isOnline,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logDriverOrderAssigned({
    required String driverId,
    required String orderId,
    required double estimatedEarnings,
  }) async {
    await _analytics?.logEvent(
      name: 'driver_order_assigned',
      parameters: {
        'driver_id': driverId,
        'order_id': orderId,
        'estimated_earnings': estimatedEarnings,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logDriverOrderAccepted({
    required String driverId,
    required String orderId,
    required double estimatedEarnings,
    required int responseTimeSeconds,
  }) async {
    await _analytics?.logEvent(
      name: 'driver_order_accepted',
      parameters: {
        'driver_id': driverId,
        'order_id': orderId,
        'estimated_earnings': estimatedEarnings,
        'response_time_seconds': responseTimeSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logDriverOrderRejected({
    required String driverId,
    required String orderId,
    String? reason,
  }) async {
    await _analytics?.logEvent(
      name: 'driver_order_rejected',
      parameters: {
        'driver_id': driverId,
        'order_id': orderId,
        'reason': reason ?? 'not_specified',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logDriverDeliveryCompleted({
    required String driverId,
    required String orderId,
    required double earnings,
    required int deliveryTimeMinutes,
  }) async {
    await _analytics?.logEvent(
      name: 'driver_delivery_completed',
      parameters: {
        'driver_id': driverId,
        'order_id': orderId,
        'earnings': earnings,
        'delivery_time_minutes': deliveryTimeMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== SCREEN VIEW TRACKING ====================

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // ==================== SEARCH TRACKING ====================

  static Future<void> logSearch({
    required String searchTerm,
    String? category,
  }) async {
    await _analytics?.logSearch(
      searchTerm: searchTerm,
      parameters: category != null ? {'category': category} : null,
    );
  }

  // ==================== CUSTOM EVENTS ====================

  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics?.logEvent(
      name: eventName,
      parameters:
          parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
  }
}
