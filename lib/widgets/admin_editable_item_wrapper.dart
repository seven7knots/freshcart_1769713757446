import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../presentation/admin_edit_overlay_system_screen/widgets/content_edit_modal_widget.dart';

/// A wrapper widget that adds admin edit controls (3-dot menu) to any item
/// when admin edit mode is enabled.
/// 
/// Usage:
/// ```dart
/// AdminEditableItemWrapper(
///   contentType: 'product',
///   contentId: product['id'],
///   contentData: product,
///   onDeleted: () => _refreshProducts(),
///   child: YourProductCard(...),
/// )
/// ```
class AdminEditableItemWrapper extends StatelessWidget {
  final Widget child;
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;
  final Alignment menuAlignment;
  final EdgeInsets menuPadding;
  final bool showBorder;

  const AdminEditableItemWrapper({
    super.key,
    required this.child,
    required this.contentType,
    this.contentId,
    this.contentData,
    this.onDeleted,
    this.onUpdated,
    this.menuAlignment = Alignment.topRight,
    this.menuPadding = const EdgeInsets.all(4),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    // If not admin or edit mode is off, just return the child
    if (!authProvider.isAdmin || !adminProvider.isEditMode) {
      return child;
    }

    return Stack(
      children: [
        // The actual content with optional edit border
        Container(
          decoration: showBorder
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: child,
        ),

        // 3-dot menu button
        Positioned(
          top: menuPadding.top,
          right: menuAlignment == Alignment.topRight ? menuPadding.right : null,
          left: menuAlignment == Alignment.topLeft ? menuPadding.left : null,
          child: _AdminItemMenuButton(
            contentType: contentType,
            contentId: contentId,
            contentData: contentData,
            onDeleted: onDeleted,
            onUpdated: onUpdated,
          ),
        ),
      ],
    );
  }
}

class _AdminItemMenuButton extends StatelessWidget {
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const _AdminItemMenuButton({
    required this.contentType,
    this.contentId,
    this.contentData,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAdminMenu(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: 4.w,
          ),
        ),
      ),
    );
  }

  void _showAdminMenu(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminActionSheet(
        contentType: contentType,
        contentId: contentId,
        contentData: contentData,
        onDeleted: onDeleted,
        onUpdated: onUpdated,
      ),
    );
  }
}

class _AdminActionSheet extends StatelessWidget {
  final String contentType;
  final String? contentId;
  final Map<String, dynamic>? contentData;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const _AdminActionSheet({
    required this.contentType,
    this.contentId,
    this.contentData,
    this.onDeleted,
    this.onUpdated,
  });

  String get _contentLabel {
    switch (contentType) {
      case 'ad':
      case 'carousel':
        return 'Ad / Banner';
      case 'product':
        return 'Product';
      case 'category':
        return 'Category';
      case 'store':
        return 'Store';
      case 'listing':
      case 'marketplace':
        return 'Listing';
      case 'service':
        return 'Service';
      default:
        return 'Item';
    }
  }

  IconData get _contentIcon {
    switch (contentType) {
      case 'ad':
      case 'carousel':
        return Icons.campaign;
      case 'product':
        return Icons.shopping_bag;
      case 'category':
        return Icons.category;
      case 'store':
        return Icons.store;
      case 'listing':
      case 'marketplace':
        return Icons.storefront;
      case 'service':
        return Icons.home_repair_service;
      default:
        return Icons.edit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemName = contentData?['name'] ?? contentData?['title'] ?? _contentLabel;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_contentIcon, color: Colors.orange, size: 24),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit $_contentLabel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          itemName.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),

            // Action buttons
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Edit button
                  _buildActionTile(
                    context,
                    icon: Icons.edit,
                    iconColor: Colors.blue,
                    title: 'Edit $_contentLabel',
                    subtitle: 'Modify details, text, and settings',
                    onTap: () {
                      Navigator.pop(context);
                      _openEditModal(context);
                    },
                  ),

                  SizedBox(height: 1.5.h),

                  // Change Image button
                  _buildActionTile(
                    context,
                    icon: Icons.image,
                    iconColor: Colors.purple,
                    title: 'Change Image',
                    subtitle: 'Update or replace the image',
                    onTap: () {
                      Navigator.pop(context);
                      _openEditModal(context); // Opens modal with image field
                    },
                  ),

                  SizedBox(height: 1.5.h),

                  // Duplicate button
                  _buildActionTile(
                    context,
                    icon: Icons.copy,
                    iconColor: Colors.teal,
                    title: 'Duplicate',
                    subtitle: 'Create a copy of this $_contentLabel',
                    onTap: () {
                      Navigator.pop(context);
                      _duplicateItem(context);
                    },
                  ),

                  SizedBox(height: 1.5.h),

                  // Toggle Active status
                  _buildActionTile(
                    context,
                    icon: _isActive ? Icons.visibility_off : Icons.visibility,
                    iconColor: Colors.orange,
                    title: _isActive ? 'Deactivate' : 'Activate',
                    subtitle: _isActive
                        ? 'Hide this $_contentLabel from customers'
                        : 'Make this $_contentLabel visible',
                    onTap: () {
                      Navigator.pop(context);
                      _toggleActive(context);
                    },
                  ),

                  SizedBox(height: 1.5.h),

                  // Delete button
                  _buildActionTile(
                    context,
                    icon: Icons.delete,
                    iconColor: Colors.red,
                    title: 'Delete $_contentLabel',
                    subtitle: 'Permanently remove this item',
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(context);
                    },
                    isDanger: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  bool get _isActive {
    if (contentData == null) return true;
    return contentData!['is_active'] == true ||
        contentData!['is_available'] == true ||
        contentData!['status'] == 'active';
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withOpacity(0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? Colors.red.withOpacity(0.2)
                : theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDanger ? Colors.red : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: contentType == 'carousel' ? 'ad' : contentType,
        contentId: contentId,
        contentData: contentData,
        onSaved: () {
          Navigator.pop(context);
          onUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_contentLabel updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _duplicateItem(BuildContext context) {
    // Create a copy of content data without the ID
    final duplicateData = Map<String, dynamic>.from(contentData ?? {});
    duplicateData.remove('id');
    duplicateData['name'] = '${duplicateData['name'] ?? duplicateData['title'] ?? ''} (Copy)';
    duplicateData['title'] = '${duplicateData['title'] ?? duplicateData['name'] ?? ''} (Copy)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: contentType == 'carousel' ? 'ad' : contentType,
        contentId: null, // null = create new
        contentData: duplicateData,
        onSaved: () {
          Navigator.pop(context);
          onUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_contentLabel duplicated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _toggleActive(BuildContext context) async {
    // TODO: Implement toggle active via service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isActive ? 'Deactivated' : 'Activated'} $_contentLabel'),
        backgroundColor: Colors.orange,
      ),
    );
    onUpdated?.call();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $_contentLabel?'),
        content: Text(
          'Are you sure you want to permanently delete this $_contentLabel? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(BuildContext context) async {
    // TODO: Implement delete via appropriate service based on contentType
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_contentLabel deleted'),
        backgroundColor: Colors.red,
      ),
    );
    onDeleted?.call();
  }
}

