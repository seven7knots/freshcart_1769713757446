import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import './widgets/admin_overlay_fab_widget.dart';

class GlobalAdminControlsOverlayScreen extends StatelessWidget {
  final Widget child;
  final String contentType;
  final String? contentId;

  const GlobalAdminControlsOverlayScreen({
    super.key,
    required this.child,
    required this.contentType,
    this.contentId,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) return child;

    final admin = Provider.of<AdminProvider>(context);

    return Stack(
      children: [
        child,
        if (admin.isEditMode)
          Positioned(
            left: 4.w,
            right: 4.w,
            bottom: 18.h,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Admin edit mode is ON — tap edit icons on supported sections.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        AdminOverlayFabWidget(
          isActive: admin.isEditMode,
          onToggle: () => context.read<AdminProvider>().toggleEditMode(),
        ),
      ],
    );
  }
}
