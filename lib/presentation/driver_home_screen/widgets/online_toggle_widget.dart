import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class OnlineToggleWidget extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const OnlineToggleWidget({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.check : Icons.close,
              color: Colors.white,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? AppLocalizations.of(context)!.youAreOnline : AppLocalizations.of(context)!.youAreOffline,
                  style: TextStyle(
                    color: AppTheme.textOnLight,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  isOnline
                      ? AppLocalizations.of(context)!.readyToAcceptDeliveries
                      : AppLocalizations.of(context)!.goOnlineToStartEarning,
                  style: TextStyle(
                    color: AppTheme.textOnLight.withAlpha(179),
                    fontSize: 11.sp,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
