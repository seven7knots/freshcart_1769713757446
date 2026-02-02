import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ContextualEditMenuWidget extends StatelessWidget {
  final String contentType;
  final String contentId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onChangeStatus;
  final VoidCallback? onAssignDriver;

  const ContextualEditMenuWidget({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
    this.onAssignDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.blue,
            onTap: onEdit,
          ),
          _buildMenuItem(
            icon: Icons.delete,
            label: 'Delete',
            color: Colors.red,
            onTap: onDelete,
          ),
          _buildMenuItem(
            icon: Icons.visibility,
            label: 'Status',
            color: Colors.green,
            onTap: onChangeStatus,
          ),
          if (onAssignDriver != null)
            _buildMenuItem(
              icon: Icons.local_shipping,
              label: 'Assign Driver',
              color: Colors.orange,
              onTap: onAssignDriver!,
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
