import 'package:flutter/material.dart';

/// DEPRECATED: The floating AI chatbox has been removed from the application.
/// AI is now only accessible via the AI Mate tab in the bottom navigation bar.
///
/// This stub is kept to prevent import errors. It renders nothing.
class FloatingAIChatbox extends StatelessWidget {
  const FloatingAIChatbox({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Kept for backward compatibility — renders nothing.
class MinimalRobotIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;

  MinimalRobotIconPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}