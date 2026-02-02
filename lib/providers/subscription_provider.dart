import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_service.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlanModel>>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.getSubscriptionPlans();
});

final currentSubscriptionProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.getCurrentSubscription();
});
