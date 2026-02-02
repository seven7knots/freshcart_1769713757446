import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';
import './widgets/current_plan_card_widget.dart';
import './widgets/plan_card_widget.dart';
import './widgets/subscription_management_widget.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  bool _showComparison = false;
  String _selectedPaymentMethod = 'wallet';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final currentSubAsync = ref.watch(currentSubscriptionProvider);
    final walletAsync = ref.watch(userWalletProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription Plans',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: plansAsync.when(
        data: (plans) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Plan Card
                currentSubAsync.when(
                  data: (currentSub) {
                    if (currentSub != null) {
                      return CurrentPlanCardWidget(
                        subscription: currentSub,
                        onManage: () => _showManagementOptions(currentSub),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (currentSubAsync.value != null) SizedBox(height: 3.h),

                // Section Title
                Text(
                  'Available Plans',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),

                // Available Plans List
                ...plans.map((plan) {
                  final isCurrentPlan =
                      currentSubAsync.value?['plan_id'] == plan.id;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: PlanCardWidget(
                      plan: plan,
                      isCurrentPlan: isCurrentPlan,
                      onSubscribe: () =>
                          _handleSubscribe(plan, walletAsync.value),
                    ),
                  );
                }),

                SizedBox(height: 2.h),

                // Compare Plans Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showComparison = !_showComparison;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 2.h,
                      horizontal: 4.w,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showComparison
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _showComparison ? 'Hide Comparison' : 'Compare Plans',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Plan Comparison
                if (_showComparison) ...[
                  SizedBox(height: 2.h),
                  // Remove PlanComparisonWidget as it's not defined
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Plan comparison feature coming soon',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                SizedBox(height: 3.h),

                // Payment Options Section
                _buildPaymentOptionsSection(),

                SizedBox(height: 10.h),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                'Failed to load subscription plans',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionsSection() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
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
          Text(
            'Payment Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPaymentOption(
            'wallet',
            'Wallet Payment',
            'Pay from your wallet balance',
            Icons.account_balance_wallet,
          ),
          SizedBox(height: 1.h),
          _buildPaymentOption(
            'cash',
            'Cash Payment',
            'Pay on first delivery',
            Icons.payments_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(plan, wallet) async {
    final theme = Theme.of(context);
    if (_selectedPaymentMethod == 'wallet') {
      final balance = wallet?.currentBalance ?? 0.0;
      if (balance < plan.price) {
        _showInsufficientBalanceDialog();
        return;
      }
    }

    final confirmed = await _showSubscribeConfirmation(plan);
    if (confirmed == true) {
      try {
        final subscriptionService = ref.read(subscriptionServiceProvider);
        await subscriptionService.subscribeToPlan(
          planId: plan.id,
          paymentMethod: _selectedPaymentMethod,
        );
        ref.invalidate(currentSubscriptionProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully subscribed to ${plan.name}'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to subscribe: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showSubscribeConfirmation(plan) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Subscription'),
        content: Text(
          'Subscribe to ${plan.name} for \$${plan.price.toStringAsFixed(2)}/${plan.billingCycle ?? "month"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Balance'),
        content: Text(
          'Your wallet balance is insufficient. Please top up or choose cash payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManagementOptions(Map<String, dynamic> subscription) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionManagementWidget(
        subscription: subscription,
        onPause: () async {
          Navigator.pop(context);
          await _pauseSubscription();
        },
        onResume: () async {
          Navigator.pop(context);
          await _resumeSubscription();
        },
        onCancel: () async {
          Navigator.pop(context);
          await _cancelSubscription();
        },
      ),
    );
  }

  Future<void> _pauseSubscription() async {
    final theme = Theme.of(context);
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.pauseSubscription();
      ref.invalidate(currentSubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription paused'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause subscription'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _resumeSubscription() async {
    final theme = Theme.of(context);
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.resumeSubscription();
      ref.invalidate(currentSubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription resumed'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume subscription'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription'),
        content: Text('Are you sure you want to cancel your subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final subscriptionService = ref.read(subscriptionServiceProvider);
        await subscriptionService.cancelSubscription();
        ref.invalidate(currentSubscriptionProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription cancelled'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel subscription'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
