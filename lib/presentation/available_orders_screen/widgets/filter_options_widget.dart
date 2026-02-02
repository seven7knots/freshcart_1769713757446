import 'package:flutter/material.dart' hide FilterChip;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class FilterOptionsWidget extends StatefulWidget {
  final double maxDistance;
  final double minEarnings;
  final List<String> preferredStoreTypes;
  final Function(double, double, List<String>) onApply;

  const FilterOptionsWidget({
    super.key,
    required this.maxDistance,
    required this.minEarnings,
    required this.preferredStoreTypes,
    required this.onApply,
  });

  @override
  State<FilterOptionsWidget> createState() => _FilterOptionsWidgetState();
}

class _FilterOptionsWidgetState extends State<FilterOptionsWidget> {
  late double _maxDistance;
  late double _minEarnings;
  late List<String> _selectedStoreTypes;

  final List<String> _availableStoreTypes = [
    'Restaurant',
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Fashion',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.maxDistance;
    _minEarnings = widget.minEarnings;
    _selectedStoreTypes = List.from(widget.preferredStoreTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            SizedBox(height: 2.h),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Orders',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _maxDistance = 10.0;
                        _minEarnings = 0.0;
                        _selectedStoreTypes = [];
                      });
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Filter options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Max distance
                  Text(
                    'Maximum Distance',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxDistance,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          activeColor: AppTheme.lightTheme.colorScheme.primary,
                          inactiveColor:
                              AppTheme.lightTheme.scaffoldBackgroundColor,
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${_maxDistance.toStringAsFixed(0)} km',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // Min earnings
                  Text(
                    'Minimum Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minEarnings,
                          min: 0.0,
                          max: 20.0,
                          divisions: 40,
                          activeColor: AppTheme.lightTheme.colorScheme.primary,
                          inactiveColor:
                              AppTheme.lightTheme.scaffoldBackgroundColor,
                          onChanged: (value) {
                            setState(() {
                              _minEarnings = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '\$${_minEarnings.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // Store types
                  Text(
                    'Preferred Store Types',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _availableStoreTypes.map((type) {
                      final isSelected = _selectedStoreTypes.contains(type);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStoreTypes.remove(type);
                            } else {
                              _selectedStoreTypes.add(type);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.2)
                                : AppTheme.lightTheme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme.lightTheme.colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: EdgeInsets.only(right: 1.w),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                ),
                              Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
            // Apply button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _maxDistance,
                      _minEarnings,
                      _selectedStoreTypes,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
