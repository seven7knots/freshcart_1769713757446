// ============================================================
// FILE: lib/presentation/admin_subscription_management_screen/admin_subscription_management_screen.dart
// SESSION 10 FIXES:
// - Issue 6: Type field now uses dropdown with valid DB values (fixes constraint error)
// - Overflow: Action buttons use Wrap instead of Row (fixes 23px right overflow)
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/subscription_plan_model.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});

  @override
  State<AdminSubscriptionManagementScreen> createState() =>
      _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState
    extends State<AdminSubscriptionManagementScreen> {
  bool _isLoading = true;
  List<SubscriptionPlanModel> _plans = [];

  // Valid type values that match the DB constraint subscription_plans_type_check
  static const List<String> _validTypes = [
    'free',
    'basic',
    'premium',
    'enterprise',
    'starter',
    'pro',
    'monthly',
    'weekly',
    'yearly',
    'delivery',
  ];

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

      _plans = (result as List)
          .map((json) =>
              SubscriptionPlanModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error loading plans: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
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
        title: Text(AppLocalizations.of(context)!.manageSubscriptions, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlans),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanEditor(null),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addPlan, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.kjRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      SizedBox(height: 2.h),
                      Text(AppLocalizations.of(context)!.noSubscriptionPlans,
                          style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Text(AppLocalizations.of(context)!.tapToCreateYourFirstPlan,
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) =>
                        _buildPlanCard(_plans[index], theme),
                  ),
                ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(plan.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: plan.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          plan.isActive ? AppLocalizations.of(context)!.active2 : AppLocalizations.of(context)!.inactive2,
                          style: TextStyle(
                              color: plan.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    if (plan.description != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(plan.description!,
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                              fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(children: [
                Text('\$${plan.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kjRed), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('/${plan.billingCycle ?? "month"}',
                    style: TextStyle(
                        fontSize: 11.sp,
                        color:
                            Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    label: Text(f.toString(),
                        style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              SizedBox(height: 1.5.h),
            ],

            // Stats row
            Row(children: [
              _buildMiniStat(
                  theme, AppLocalizations.of(context)!.order, plan.sortOrder.toString()),
              SizedBox(width: 3.w),
              _buildMiniStat(
                  theme, AppLocalizations.of(context)!.type, plan.type ?? AppLocalizations.of(context)!.nA),
              SizedBox(width: 3.w),
              _buildMiniStat(theme, AppLocalizations.of(context)!.aiReqs,
                  plan.aiRequestsLimit?.toString() ?? '\u221E'),
            ]),
            SizedBox(height: 1.5.h),

            // FIX Overflow: Use Wrap instead of Row so buttons wrap on small screens
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPlanEditor(plan),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(AppLocalizations.of(context)!.edit, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                TextButton.icon(
                  onPressed: () => _togglePlanActive(plan),
                  icon: Icon(
                      plan.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18),
                  label: Text(
                      plan.isActive ? AppLocalizations.of(context)!.deactivate : AppLocalizations.of(context)!.activate, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                TextButton.icon(
                  onPressed: () => _deletePlan(plan),
                  icon: Icon(Icons.delete,
                      size: 18,
                      color: theme.colorScheme.error),
                  label: Text(AppLocalizations.of(context)!.delete,
                      style: TextStyle(
                          color: theme.colorScheme.error), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      ThemeData theme, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ============================================================
  // PLAN EDITOR (Create / Edit)
  // FIX Issue 6: Type field uses dropdown with valid DB values
  // ============================================================

  void _showPlanEditor(SubscriptionPlanModel? plan) {
    final isNew = plan == null;
    final theme = Theme.of(context);

    final nameC =
        TextEditingController(text: plan?.name ?? '');
    final descC =
        TextEditingController(text: plan?.description ?? '');
    final priceC = TextEditingController(
        text: plan?.price.toStringAsFixed(2) ?? '');
    final cycleC = TextEditingController(
        text: plan?.billingCycle ?? 'monthly');
    final sortC = TextEditingController(
        text: plan?.sortOrder.toString() ?? '0');
    final aiLimitC = TextEditingController(
        text: plan?.aiRequestsLimit?.toString() ?? '');
    final featuresC = TextEditingController(
        text: plan?.features.join('\n') ?? '');
    bool isActive = plan?.isActive ?? true;

    // FIX: Use dropdown value instead of free text
    // Default to 'delivery' for new plans, or use existing value
    String selectedType = plan?.type ?? 'delivery';
    // Make sure existing value is in the valid list, fallback to 'delivery'
    if (!_validTypes.contains(selectedType)) {
      selectedType = 'delivery';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) =>
            DraggableScrollableSheet(
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
                  child: Container(
                      width: 12.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.outline
                              .withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(10))),
                ),
                SizedBox(height: 2.h),
                Text(isNew ? AppLocalizations.of(context)!.createPlan : AppLocalizations.of(context)!.editPlan,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1.h),
                // Helpful description for the admin
                Text(
                  AppLocalizations.of(context)!.fillInTheDetailsBelowName,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),

                TextField(
                    controller: nameC,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.planName,
                        border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                TextField(
                    controller: descC,
                    maxLines: 2,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        hintText:
                            'e.g., Free delivery on orders over \$15',
                        border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: priceC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.price2,
                              prefixText: '\$ ',
                              border: OutlineInputBorder()))),
                  SizedBox(width: 3.w),
                  Expanded(
                      child: TextField(
                          controller: cycleC,
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.billingCycle,
                              hintText: 'monthly',
                              border: OutlineInputBorder()))),
                ]),
                SizedBox(height: 2.h),

                // FIX Issue 6: Dropdown for Type instead of free text
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.planType,
                        border: OutlineInputBorder(),
                      ),
                      items: _validTypes.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            t[0].toUpperCase() +
                                t.substring(1), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(
                              () => selectedType = v);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                      child: TextField(
                          controller: sortC,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              InputDecoration(
                                  labelText: AppLocalizations.of(context)!.sortOrder,
                                  border:
                                      OutlineInputBorder()))),
                ]),
                SizedBox(height: 2.h),
                TextField(
                    controller: aiLimitC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText:
                            'AI Requests Limit (empty = unlimited)',
                        border: OutlineInputBorder())),
                SizedBox(height: 2.h),
                TextField(
                    controller: featuresC,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText:
                            'Features (one per line)',
                        hintText:
                            'Free delivery over \$15\nPriority support\nExclusive deals',
                        border: OutlineInputBorder())),
                SizedBox(height: 2.h),

                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.active, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle:
                      Text(AppLocalizations.of(context)!.visibleToUsers, maxLines: 1, overflow: TextOverflow.ellipsis),
                  value: isActive,
                  onChanged: (v) =>
                      setSheetState(() => isActive = v),
                  activeThumbColor: AppTheme.kjRed,
                ),
                SizedBox(height: 3.h),

                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameC.text.trim();
                      final price = double.tryParse(
                          priceC.text.trim());

                      if (name.isEmpty || price == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Name and valid price are required'),
                                backgroundColor:
                                    Colors.red));
                        return;
                      }

                      Navigator.pop(ctx);

                      final features = featuresC.text
                          .trim()
                          .split('\n')
                          .where(
                              (f) => f.trim().isNotEmpty)
                          .toList();

                      final data = {
                        'name': name,
                        'description':
                            descC.text.trim().isEmpty
                                ? null
                                : descC.text.trim(),
                        'price': price,
                        'billing_cycle': cycleC.text
                                .trim()
                                .isEmpty
                            ? 'monthly'
                            : cycleC.text.trim(),
                        'type': selectedType,
                        'sort_order': int.tryParse(
                                sortC.text.trim()) ??
                            0,
                        'ai_requests_limit':
                            int.tryParse(
                                aiLimitC.text.trim()),
                        'features': features,
                        'is_active': isActive,
                        'updated_at': DateTime.now()
                            .toIso8601String(),
                      };

                      try {
                        if (isNew) {
                          data['created_at'] =
                              DateTime.now()
                                  .toIso8601String();
                          await Supabase.instance.client
                              .from('subscription_plans')
                              .insert(data);
                        } else {
                          await Supabase.instance.client
                              .from('subscription_plans')
                              .update(data)
                              .eq('id', plan.id);
                        }
                        await _loadPlans();
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(isNew
                                      ? AppLocalizations.of(context)!.planCreated
                                      : AppLocalizations.of(context)!.planUpdated, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor:
                                      Colors.green));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content:
                                      Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor:
                                      Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kjRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12))),
                    child: Text(
                        isNew
                            ? AppLocalizations.of(context)!.createPlan
                            : AppLocalizations.of(context)!.saveChanges2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Future<void> _togglePlanActive(
      SubscriptionPlanModel plan) async {
    try {
      await Supabase.instance.client
          .from('subscription_plans')
          .update({
        'is_active': !plan.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', plan.id);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Plan ${!plan.isActive ? "activated" : "deactivated"}', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deletePlan(SubscriptionPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlan, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
            'Are you sure you want to delete "${plan.name}"? This cannot be undone.', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.delete, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('subscription_plans')
          .delete()
          .eq('id', plan.id);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.planDeleted, maxLines: 1, overflow: TextOverflow.ellipsis),
                backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red));
      }
    }
  }
}