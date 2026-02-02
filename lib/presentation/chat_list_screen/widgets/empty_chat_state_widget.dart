import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
              color: Colors.grey[400],
            ),
            SizedBox(height: 3.h),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Start chatting with sellers about items you are interested in',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
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
                'Explore Marketplace',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
