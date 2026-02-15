// ============================================================
// FILE: lib/presentation/admin_subscription_management_screen/admin_subscription_management_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/subscription_plan_model.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});

  @override
  State<AdminSubscriptionManagementScreen> createState() => _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState extends State<AdminSubscriptionManagementScreen> {
  bool _isLoading = true;
  List<SubscriptionPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final result = await Supabase.instance.client
          .from('subscription_plans')
          .select()
          .order('sort_order', ascending: true);

      _plans = (result as List).map((json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading plans: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlans),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanEditor(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
        backgroundColor: AppTheme.kjRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.card_membership, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    SizedBox(height: 2.h),
                    Text('No subscription plans', style: theme.textTheme.titleMedium),
                    SizedBox(height: 1.h),
                    Text('Tap + to create your first plan', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) => _buildPlanCard(_plans[index], theme),
                  ),
                ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(plan.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: plan.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: plan.isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                  if (plan.description != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(plan.description!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ]),
              ),
              Column(children: [
                Text('\$${plan.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppTheme.kjRed)),
                Text('/${plan.billingCycle ?? "month"}', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ]),
            SizedBox(height: 1.5.h),

            // Features
            if (plan.features.isNotEmpty) ...[
              Wrap(
                spacing: 1.w,
                runSpacing: 0.5.h,
                children: plan.features.take(4).map((f) {
                  return Chip(
                    label: Text(f.toString(), style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              SizedBox(height: 1.5.h),
            ],

            // Stats row
            Row(children: [
              _buildMiniStat(theme, 'Order', plan.sortOrder.toString()),
              SizedBox(width: 3.w),
              _buildMiniStat(theme, 'Type', plan.type ?? 'N/A'),
              SizedBox(width: 3.w),
              _buildMiniStat(theme, 'AI Reqs', plan.aiRequestsLimit?.toString() ?? '∞'),
            ]),
            SizedBox(height: 1.5.h),

            // Actions
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () => _showPlanEditor(plan),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _togglePlanActive(plan),
                icon: Icon(plan.isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                label: Text(plan.isActive ? 'Deactivate' : 'Activate'),
              ),
              TextButton.icon(
                onPressed: () => _deletePlan(plan),
                icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface)),
        Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  // ============================================================
  // PLAN EDITOR (Create / Edit)
  // ============================================================

  void _showPlanEditor(SubscriptionPlanModel? plan) {
    final isNew = plan == null;
    final theme = Theme.of(context);

    final nameC = TextEditingController(text: plan?.name ?? '');
    final descC = TextEditingController(text: plan?.description ?? '');
    final priceC = TextEditingController(text: plan?.price.toStringAsFixed(2) ?? '');
    final cycleC = TextEditingController(text: plan?.billingCycle ?? 'monthly');
    final typeC = TextEditingController(text: plan?.type ?? '');
    final sortC = TextEditingController(text: plan?.sortOrder.toString() ?? '0');
    final aiLimitC = TextEditingController(text: plan?.aiRequestsLimit?.toString() ?? '');
    final featuresC = TextEditingController(text: plan?.features.join('\n') ?? '');
    bool isActive = plan?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) => Padding(
            padding: EdgeInsets.all(5.w),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(width: 12.w, height: 0.5.h, decoration: BoxDecoration(color: theme.colorScheme.outline.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
                ),
                SizedBox(height: 2.h),
                Text(isNew ? 'Create Plan' : 'Edit Plan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                SizedBox(height: 3.h),

                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Plan Name *', border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                TextField(controller: descC, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                Row(children: [
                  Expanded(child: TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price *', prefixText: '\$ ', border: OutlineInputBorder()))),
                  SizedBox(width: 3.w),
                  Expanded(child: TextField(controller: cycleC, decoration: const InputDecoration(labelText: 'Billing Cycle', hintText: 'monthly', border: OutlineInputBorder()))),
                ]),
                SizedBox(height: 2.h),
                Row(children: [
                  Expanded(child: TextField(controller: typeC, decoration: const InputDecoration(labelText: 'Type', hintText: 'e.g., premium', border: OutlineInputBorder()))),
                  SizedBox(width: 3.w),
                  Expanded(child: TextField(controller: sortC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sort Order', border: OutlineInputBorder()))),
                ]),
                SizedBox(height: 2.h),
                TextField(controller: aiLimitC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'AI Requests Limit (empty = unlimited)', border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                TextField(controller: featuresC, maxLines: 4, decoration: const InputDecoration(labelText: 'Features (one per line)', border: OutlineInputBorder())),
                SizedBox(height: 2.h),

                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Visible to users'),
                  value: isActive,
                  onChanged: (v) => setSheetState(() => isActive = v),
                  activeThumbColor: AppTheme.kjRed,
                ),
                SizedBox(height: 3.h),

                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameC.text.trim();
                      final price = double.tryParse(priceC.text.trim());

                      if (name.isEmpty || price == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and valid price are required'), backgroundColor: Colors.red));
                        return;
                      }

                      Navigator.pop(ctx);

                      final features = featuresC.text.trim().split('\n').where((f) => f.trim().isNotEmpty).toList();

                      final data = {
                        'name': name,
                        'description': descC.text.trim().isEmpty ? null : descC.text.trim(),
                        'price': price,
                        'billing_cycle': cycleC.text.trim().isEmpty ? 'monthly' : cycleC.text.trim(),
                        'type': typeC.text.trim().isEmpty ? null : typeC.text.trim(),
                        'sort_order': int.tryParse(sortC.text.trim()) ?? 0,
                        'ai_requests_limit': int.tryParse(aiLimitC.text.trim()),
                        'features': features,
                        'is_active': isActive,
                        'updated_at': DateTime.now().toIso8601String(),
                      };

                      try {
                        if (isNew) {
                          data['created_at'] = DateTime.now().toIso8601String();
                          await Supabase.instance.client.from('subscription_plans').insert(data);
                        } else {
                          await Supabase.instance.client.from('subscription_plans').update(data).eq('id', plan.id);
                        }
                        await _loadPlans();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isNew ? 'Plan created!' : 'Plan updated!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(isNew ? 'Create Plan' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOGGLE ACTIVE / DELETE
  // ============================================================

  Future<void> _togglePlanActive(SubscriptionPlanModel plan) async {
    try {
      await Supabase.instance.client.from('subscription_plans').update({'is_active': !plan.isActive, 'updated_at': DateTime.now().toIso8601String()}).eq('id', plan.id);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan ${!plan.isActive ? "activated" : "deactivated"}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deletePlan(SubscriptionPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('subscription_plans').delete().eq('id', plan.id);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan deleted'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}