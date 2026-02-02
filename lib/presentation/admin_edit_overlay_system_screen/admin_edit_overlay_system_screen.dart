import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import './widgets/admin_edit_button_widget.dart';
import './widgets/content_edit_modal_widget.dart';

class AdminEditOverlaySystemScreen extends StatefulWidget {
  final Widget child;
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;

  const AdminEditOverlaySystemScreen({
    super.key,
    required this.child,
    required this.contentType,
    this.contentId,
    this.contentData,
  });

  @override
  State<AdminEditOverlaySystemScreen> createState() =>
      _AdminEditOverlaySystemScreenState();
}

class _AdminEditOverlaySystemScreenState
    extends State<AdminEditOverlaySystemScreen> {
  bool _isOverlayVisible = false;

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: widget.contentType,
        contentId: widget.contentId,
        contentData: widget.contentData,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content updated successfully')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    if (!adminProvider.isAdmin) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_isOverlayVisible)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: AdminEditButtonWidget(
                  contentType: widget.contentType,
                  onEdit: _showEditModal,
                ),
              ),
            ),
          ),
        Positioned(
          top: 2.h,
          right: 4.w,
          child: FloatingActionButton.small(
            onPressed: _toggleOverlay,
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            child: CustomIconWidget(
              iconName: _isOverlayVisible ? 'close' : 'edit',
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
