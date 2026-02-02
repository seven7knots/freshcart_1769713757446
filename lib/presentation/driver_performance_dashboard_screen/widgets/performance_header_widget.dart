import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class PerformanceHeaderWidget extends StatelessWidget {
  final String driverName;
  final bool isOnline;
  final int activeHours;
  final double todayEarnings;

  const PerformanceHeaderWidget({
    super.key,
    required this.driverName,
    required this.isOnline,
    required this.activeHours,
    required this.todayEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isOnline ? Colors.green : AppTheme.borderDark,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $driverName',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: AppTheme.textSecondaryOf(context),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      '$activeHours hrs',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Active Today',
                      style: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(color: AppTheme.borderDark),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Earnings",
                style: TextStyle(
                  color: AppTheme.textSecondaryOf(context),
                  fontSize: 12.sp,
                ),
              ),
              Text(
                '\$${todayEarnings.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
