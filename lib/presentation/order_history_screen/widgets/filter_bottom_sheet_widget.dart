import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  DateTimeRange? _selectedDateRange;
  RangeValues _priceRange = const RangeValues(0, 500);

  final List<String> _statusOptions = [
    'All',
    'Delivered',
    'Processing',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Recent First',
    'Oldest First',
    'Price: High to Low',
    'Price: Low to High',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _selectedDateRange = _filters['dateRange'] as DateTimeRange?;
    _priceRange =
        _filters['priceRange'] as RangeValues? ?? const RangeValues(0, 500);
  }

  void _selectDateRange() async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: theme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filters['dateRange'] = picked;
      });
    }
  }

  void _clearDateRange() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDateRange = null;
      _filters.remove('dateRange');
    });
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    _filters['priceRange'] = _priceRange;
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _filters.clear();
      _selectedDateRange = null;
      _priceRange = const RangeValues(0, 500);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.filterOrders,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      AppLocalizations.of(context)!.clearAll,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

            Divider(
              color: theme.colorScheme.outline
                  .withValues(alpha: 0.2),
              thickness: 1,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Date Range Section
                    _buildSectionTitle(context, AppLocalizations.of(context)!.dateRange),
                    SizedBox(height: 1.h),
                    GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: Text(
                              _selectedDateRange != null
                                  ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                                  : AppLocalizations.of(context)!.selectDateRange,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(
                                color: _selectedDateRange != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme
                                        .onSurfaceVariant,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Row(
                              children: [
                                if (_selectedDateRange != null)
                                  GestureDetector(
                                    onTap: _clearDateRange,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 2.w),
                                      child: CustomIconWidget(
                                        iconName: 'clear',
                                        color: theme.colorScheme
                                            .onSurfaceVariant,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                CustomIconWidget(
                                  iconName: 'calendar_today',
                                  color:
                                      theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Order Status Section
                    _buildSectionTitle(context, AppLocalizations.of(context)!.orderStatus),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: _statusOptions.map((status) {
                        final isSelected = _filters['status'] == status ||
                            (status == 'All' && _filters['status'] == null);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (status == 'All') {
                                _filters.remove('status');
                              } else {
                                _filters['status'] = status;
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade400
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade400
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              status,
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 3.h),

                    // Price Range Section
                    _buildSectionTitle(context, AppLocalizations.of(context)!.priceRange),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400
                              .withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text(
                                '\$${_priceRange.start.round()}',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Flexible(child: Text(
                                '\$${_priceRange.end.round()}',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 500,
                            divisions: 50,
                            activeColor:
                                theme.colorScheme.primary,
                            inactiveColor: Colors.grey.shade400
                                .withValues(alpha: 0.3),
                            onChanged: (RangeValues values) {
                              setState(() {
                                _priceRange = values;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Sort By Section
                    _buildSectionTitle(context, AppLocalizations.of(context)!.sortBy),
                    SizedBox(height: 1.h),
                    Column(
                      children: _sortOptions.map((option) {
                        final isSelected = _filters['sortBy'] == option;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _filters['sortBy'] = option;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(4.w),
                            margin: EdgeInsets.only(bottom: 1.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade400
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(
                                  option,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (isSelected)
                                  CustomIconWidget(
                                    iconName: 'check_circle',
                                    color:
                                        theme.colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.applyFilters,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ), maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}