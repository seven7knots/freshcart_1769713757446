// ============================================================
// FILE: lib/presentation/marketplace_screen/widgets/marketplace_top_bar_widget.dart
// ============================================================
// Replaces hardcoded city dropdown with tappable location bar
// that opens the Google Maps location picker.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MarketplaceTopBarWidget extends StatelessWidget {
  final String selectedLocation;
  final VoidCallback onLocationTap;
  final VoidCallback? onClearLocation;
  final bool hasCustomLocation;

  const MarketplaceTopBarWidget({
    super.key,
    required this.selectedLocation,
    required this.onLocationTap,
    this.onClearLocation,
    this.hasCustomLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, size: 6.w, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),

          // Location bar — tappable, opens map picker
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onLocationTap();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 4.5.w, color: AppTheme.kjRed),
                    SizedBox(width: 1.5.w),
                    Expanded(
                      child: Text(
                        selectedLocation,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    // Map icon hint
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: AppTheme.kjRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.map_outlined, size: 3.5.w, color: AppTheme.kjRed),
                    ),
                    // Clear button (when custom location is set)
                    if (hasCustomLocation && onClearLocation != null) ...[
                      SizedBox(width: 1.w),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onClearLocation!();
                        },
                        child: Container(
                          padding: EdgeInsets.all(0.8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 3.w, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ] else
                      Icon(Icons.keyboard_arrow_down, size: 5.w, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),

          // Notifications
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, size: 6.w, color: theme.iconTheme.color),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE50914),
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 4.w, minHeight: 4.w),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}