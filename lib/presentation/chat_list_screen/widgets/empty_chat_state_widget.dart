import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class EmptyChatStateWidget extends StatelessWidget {
  final VoidCallback onExploreMarketplace;

  const EmptyChatStateWidget({
    super.key,
    required this.onExploreMarketplace,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 20.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 3.h),
            Text(
              AppLocalizations.of(context)!.noConversationsYet,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.startChattingWithSellersAboutItems,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: onExploreMarketplace,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.exploreMarketplace,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
