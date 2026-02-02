import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageIndicatorWidget({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: currentIndex == index ? 8.w : 2.w,
          height: 1.h,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
