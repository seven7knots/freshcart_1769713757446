import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class QuickInquiryButtonsWidget extends StatelessWidget {
  final Function(String) onInquirySelected;

  const QuickInquiryButtonsWidget({
    super.key,
    required this.onInquirySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final inquiries = [
      {'icon': Icons.check_circle_outline, 'text': AppLocalizations.of(context)!.isThisAvailable},
      {'icon': Icons.attach_money, 'text': AppLocalizations.of(context)!.canYouNegotiatePrice},
      {'icon': Icons.info_outline, 'text': AppLocalizations.of(context)!.whatIsTheCondition},
      {'icon': Icons.schedule, 'text': AppLocalizations.of(context)!.whenCanIPickUp},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.quickInquiries,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.5.h),
          Text(
            AppLocalizations.of(context)!.sendAQuickMessageToThe,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: inquiries.map((inquiry) {
              return InkWell(
                onTap: () => onInquirySelected(inquiry['text'] as String),
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inquiry['icon'] as IconData,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Flexible(child: Text(
                        inquiry['text'] as String,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}