import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<FilterChip> activeFilters;
  final VoidCallback? onFilterPressed;
  final Function(String)? onRemoveFilter;

  const FilterChipsWidget({
    super.key,
    required this.activeFilters,
    this.onFilterPressed,
    this.onRemoveFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          // Filter button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onFilterPressed?.call();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: activeFilters.isNotEmpty
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeFilters.isNotEmpty
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'tune',
                    color: activeFilters.isNotEmpty
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Filter',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: activeFilters.isNotEmpty
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (activeFilters.isNotEmpty) ...[
                    SizedBox(width: 1.w),
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        activeFilters.length.toString(),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 2.w),
          // Active filter chips
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeFilters.length,
              separatorBuilder: (context, index) => SizedBox(width: 2.w),
              itemBuilder: (context, index) {
                final filter = activeFilters[index];
                return _buildFilterChip(context, filter);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, FilterChip filter) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.secondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            filter.label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRemoveFilter?.call(filter.id);
            },
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSecondaryContainer,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChip {
  final String id;
  final String label;
  final String category;

  FilterChip({
    required this.id,
    required this.label,
    required this.category,
  });
}
