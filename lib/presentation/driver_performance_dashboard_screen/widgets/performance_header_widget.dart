import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnline ? Colors.green : cs.outline.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, $driverName',
                style: TextStyle(color: cs.onSurface, fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Row(children: [
              Container(
                width: 2.5.w, height: 2.5.w,
                decoration: BoxDecoration(color: isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant, shape: BoxShape.circle),
              ),
              SizedBox(width: 2.w),
              Text(isOnline ? AppLocalizations.of(context)!.online2 : AppLocalizations.of(context)!.offline2,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ]),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Text('$activeHours hrs',
                  style: TextStyle(color: cs.primary, fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(AppLocalizations.of(context)!.activeToday, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        SizedBox(height: 2.h),
        Divider(color: cs.outline.withOpacity(0.2)),
        SizedBox(height: 1.h),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(AppLocalizations.of(context)!.todaySEarnings, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text('\$${todayEarnings.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green, fontSize: 20.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}