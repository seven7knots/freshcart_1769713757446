import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdminOverlayFabWidget extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const AdminOverlayFabWidget({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10.h,
      right: 4.w,
      child: SizedBox(),
    );
  }
}
