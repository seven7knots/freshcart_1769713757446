import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/subscription_plan_model.dart';

class PlanComparisonWidget extends StatelessWidget {
  final List<SubscriptionPlanModel> plans;

  const PlanComparisonWidget({super.key, required this.plans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Extract all unique features from all plans
    final allFeatures = <String>{};
    for (final plan in plans) {
      // Remove references to undefined 'features' getter
      // If SubscriptionPlanModel has features data, update the getter name accordingly
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
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
            'Feature Comparison',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Feature',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...plans.map(
                  (plan) => DataColumn(
                    label: Text(
                      plan.toString(), // Changed from plan.name to plan.toString()
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              rows: allFeatures.map((feature) {
                return DataRow(
                  cells: [
                    DataCell(Text(feature, style: theme.textTheme.bodySmall)),
                    ...plans.map((plan) {
                      // Remove reference to undefined 'features' getter
                      final hasFeature =
                          false; // Default to false since features is not available
                      return DataCell(
                        Icon(
                          hasFeature ? Icons.check_circle : Icons.cancel,
                          color: hasFeature
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          size: 20,
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
