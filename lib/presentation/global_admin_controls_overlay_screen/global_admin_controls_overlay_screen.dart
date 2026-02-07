import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import './widgets/admin_overlay_fab_widget.dart';

class GlobalAdminControlsOverlayScreen extends StatefulWidget {
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
  State<GlobalAdminControlsOverlayScreen> createState() =>
      _GlobalAdminControlsOverlayScreenState();
}

class _GlobalAdminControlsOverlayScreenState
    extends State<GlobalAdminControlsOverlayScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure admin status is checked when this widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAdminStatusChecked();
    });
  }

  Future<void> _ensureAdminStatusChecked() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Only check if authenticated and admin status hasn't been determined yet
    if (authProvider.isAuthenticated && !adminProvider.isAdmin) {
      await adminProvider.checkAdminStatus();
      debugPrint(
          '[GlobalAdminControls] Admin status checked: ${adminProvider.isAdmin}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AdminProvider>(
      builder: (context, authProvider, adminProvider, _) {
        // Don't show admin controls if not admin
        if (!adminProvider.isAdmin) {
          return widget.child;
        }

        return Stack(
          children: [
            // Main content
            widget.child,

            // Edit mode indicator banner
            if (adminProvider.isEditMode)
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 18.h,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(179),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            'Admin Edit Mode ON — Tap edit icons on sections',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Floating Action Button for toggling edit mode
            AdminOverlayFabWidget(
              isActive: adminProvider.isEditMode,
              onToggle: () {
                adminProvider.toggleEditMode();

                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      adminProvider.isEditMode
                          ? '✏️ Edit mode enabled - tap edit icons to modify content'
                          : '👁️ Edit mode disabled - viewing as customer',
                    ),
                    backgroundColor: adminProvider.isEditMode
                        ? Colors.orange
                        : Colors.grey[700],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: 20.h,
                      left: 4.w,
                      right: 4.w,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
