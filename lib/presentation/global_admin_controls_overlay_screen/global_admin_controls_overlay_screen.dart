import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/auth_provider.dart';
import './widgets/admin_overlay_fab_widget.dart';

/// Global Admin Controls Overlay Screen
/// Provides universal administrative interface accessible across all screens
/// when user role equals 'admin'
class GlobalAdminControlsOverlayScreen extends StatefulWidget {
  final Widget child;
  final String
      contentType; // 'product', 'category', 'store', 'ad', 'user', 'order'
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
  bool _isOverlayActive = false;
  String? _selectedContentId;

  void _toggleOverlay() {
    setState(() {
      _isOverlayActive = !_isOverlayActive;
    });
  }

  void _showContextMenu(String contentId, Offset position) {
    setState(() {
      _selectedContentId = contentId;
    });

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: _buildContextMenuItems(contentId),
    ).then((value) {
      setState(() {
        _selectedContentId = null;
      });
    });
  }

  List<PopupMenuEntry> _buildContextMenuItems(String contentId) {
    return [
      PopupMenuItem(
        child: ListTile(
          leading: const Icon(Icons.edit, color: Colors.blue),
          title: const Text('Edit'),
          onTap: () {
            Navigator.pop(context);
            _handleEdit(contentId);
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete'),
          onTap: () {
            Navigator.pop(context);
            _handleDelete(contentId);
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: const Icon(Icons.visibility, color: Colors.green),
          title: const Text('Change Status'),
          onTap: () {
            Navigator.pop(context);
            _handleChangeStatus(contentId);
          },
        ),
      ),
      if (widget.contentType == 'order')
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.orange),
            title: const Text('Assign Driver'),
            onTap: () {
              Navigator.pop(context);
              _handleAssignDriver(contentId);
            },
          ),
        ),
    ];
  }

  void _handleEdit(String contentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${widget.contentType}: $contentId')),
    );
  }

  void _handleDelete(String contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            Text('Are you sure you want to delete this ${widget.contentType}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Deleted ${widget.contentType}: $contentId')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleChangeStatus(String contentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Change status for ${widget.contentType}: $contentId')),
    );
  }

  void _handleAssignDriver(String contentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign driver to order: $contentId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Only show overlay controls for admin users
    if (!authProvider.isAdmin) {
      return widget.child;
    }

    return Stack(
      children: [
        // Original content
        widget.child,
        // Admin overlay (when active)
        if (_isOverlayActive)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin Edit Mode Active',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Tap on any ${widget.contentType} to edit',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _toggleOverlay,
                        child: const Text('Exit Edit Mode'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Floating Action Button
        AdminOverlayFabWidget(
          isActive: _isOverlayActive,
          onToggle: _toggleOverlay,
        ),
      ],
    );
  }
}
