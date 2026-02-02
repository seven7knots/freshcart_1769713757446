import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class QuickInquiryButtonsWidget extends StatelessWidget {
  final Function(String) onInquirySelected;

  const QuickInquiryButtonsWidget({
    super.key,
    required this.onInquirySelected,
  });

  @override
  Widget build(BuildContext context) {
    final inquiries = [
      {'icon': Icons.check_circle_outline, 'text': 'Is this available?'},
      {'icon': Icons.attach_money, 'text': 'Can you negotiate price?'},
      {'icon': Icons.info_outline, 'text': 'What is the condition?'},
      {'icon': Icons.schedule, 'text': 'When can I pick up?'},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Quick Inquiries',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Send a quick message to the seller',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
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
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inquiry['icon'] as IconData,
                        size: 18,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        inquiry['text'] as String,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
