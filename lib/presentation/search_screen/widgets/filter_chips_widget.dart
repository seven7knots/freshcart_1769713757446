import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final theme = Theme.of(context);

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
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeFilters.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'tune',
                    color: activeFilters.isNotEmpty
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    AppLocalizations.of(context)!.filter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: activeFilters.isNotEmpty
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (activeFilters.isNotEmpty) ...[
                    SizedBox(width: 1.w),
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        activeFilters.length.toString(),
                        style:
                            theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(
            filter.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRemoveFilter?.call(filter.id);
            },
            child: CustomIconWidget(
              iconName: 'close',
              color: theme.colorScheme.onSecondaryContainer,
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