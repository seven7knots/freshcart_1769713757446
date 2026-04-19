import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import './widgets/admin_overlay_fab_widget.dart';
import '../../l10n/generated/app_localizations.dart';

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
  // ============================================================
  // ISSUE 2 FIX: Removed _ensureAdminStatusChecked from initState.
  //
  // Previously this called adminProvider.checkAdminStatus() every
  // time this widget mounted, which triggered refreshRoles() and
  // caused redundant Supabase API calls. The admin status is already
  // resolved during app initialization (main.dart postFrameCallback)
  // and kept current by the Supabase auth stream listener.
  //
  // The Consumer2 below already reads adminProvider.isAdmin reactively,
  // so when the role IS resolved, this widget rebuilds automatically.
  // ============================================================

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
                      borderRadius: BorderRadius.circular(16),
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
                            AppLocalizations.of(context)!.adminEditModeOnTapEdit,
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
                          ? AppLocalizations.of(context)!.editModeEnabledTapEditIcons
                          : AppLocalizations.of(context)!.editModeDisabledViewingAsCustomer, maxLines: 1, overflow: TextOverflow.ellipsis),
                    backgroundColor: adminProvider.isEditMode
                        ? Colors.orange
                        : Colors.grey.shade700,
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