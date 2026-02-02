import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all available subscription plans
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final response = await _client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => SubscriptionPlanModel(
                id: json['id'] as String,
                name: json['name'] as String,
                nameAr: json['name_ar'] as String?,
                description: json['description'] as String?,
                descriptionAr: json['description_ar'] as String?,
                type: json['type'] as String?,
                price: (json['price'] as num).toDouble(),
                currency: json['currency'] as String? ?? 'USD',
                billingCycle: json['billing_cycle'] as String?,
                features: json['features'] as List<dynamic>? ?? [],
                freeDeliveryThreshold:
                    (json['free_delivery_threshold'] as num?)?.toDouble(),
                commissionDiscount:
                    (json['commission_discount'] as num?)?.toDouble() ?? 0.0,
                aiRequestsLimit: json['ai_requests_limit'] as int?,
                isActive: json['is_active'] as bool? ?? true,
                sortOrder: json['sort_order'] as int? ?? 0,
                createdAt: json['created_at'] != null
                    ? DateTime.parse(json['created_at'] as String)
                    : null,
                updatedAt: json['updated_at'] != null
                    ? DateTime.parse(json['updated_at'] as String)
                    : null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to load subscription plans: $e');
    }
  }

  // Get user's current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get current subscription: $e');
    }
  }

  // Subscribe to a plan
  Future<void> subscribeToPlan({
    required String planId,
    required String paymentMethod,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Cancel any existing active subscription
      await _client
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('status', 'active');

      // Create new subscription
      final now = DateTime.now();
      await _client.from('subscriptions').insert({
        'user_id': userId,
        'plan_id': planId,
        'status': 'active',
        'payment_method': paymentMethod,
        'start_date': now.toIso8601String(),
        'next_billing_date':
            now.add(const Duration(days: 30)).toIso8601String(),
        'auto_renew': true,
      });

      // Update user's subscription_id
      await _client
          .from('users')
          .update({'subscription_id': planId}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to subscribe: $e');
    }
  }

  // Pause subscription
  Future<void> pauseSubscription() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('subscriptions')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('status', 'active');
    } catch (e) {
      throw Exception('Failed to pause subscription: $e');
    }
  }

  // Resume subscription
  Future<void> resumeSubscription() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('subscriptions')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('status', 'paused');
    } catch (e) {
      throw Exception('Failed to resume subscription: $e');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('status', 'active');

      // Remove subscription_id from user
      await _client
          .from('users')
          .update({'subscription_id': null}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }
}
