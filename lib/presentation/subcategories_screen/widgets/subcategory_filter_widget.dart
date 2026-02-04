import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SubcategoryFilterWidget extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;

  const SubcategoryFilterWidget({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Keep these values aligned with your categories.type values if you use them.
    final options = <String, String>{
      'all': 'All',
      'product': 'Products',
      'service': 'Services',
      'marketplace': 'Marketplace',
    };

    Widget chip(String key, String label) {
      final isSelected =
          (key == 'all' && (selectedType == null || selectedType!.isEmpty)) ||
              (selectedType == key);

      return GestureDetector(
        onTap: () {
          if (key == 'all') {
            onTypeChanged(null);
          } else {
            onTypeChanged(key);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.9.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: options.entries
            .map((e) => chip(e.key, e.value))
            .toList(),
      ),
    );
  }
}
