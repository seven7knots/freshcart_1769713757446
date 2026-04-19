import 'package:flutter/material.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) {
          final bool isActive = currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE50913)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}
