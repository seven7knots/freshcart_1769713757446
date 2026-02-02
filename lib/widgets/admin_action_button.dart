import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Reusable admin action button with consistent styling
/// Used for inline admin controls (edit, delete, create, approve, etc.)
class AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isCompact;

  const AdminActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Colors.orange;

    if (isCompact) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: buttonColor),
        tooltip: label,
        iconSize: 20,
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
