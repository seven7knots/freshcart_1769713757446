import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AdCardWidget extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;

  const AdCardWidget({
    super.key,
    required this.ad,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ad['status'] as String;
    final impressions = ad['impressions'] as int? ?? 0;
    final clicks = ad['clicks'] as int? ?? 0;
    final ctr = impressions > 0
        ? (clicks / impressions * 100).toStringAsFixed(2)
        : '0.00';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12.0),
            ),
            child: CustomImageWidget(
              imageUrl: ad['image_url'] as String,
              width: double.infinity,
              height: 20.h,
              fit: BoxFit.cover,
              semanticLabel: '${ad['title']} ad banner',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                if (ad['description'] != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    ad['description'] as String,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 2.h),
                // Analytics
                Row(
                  children: [
                    _buildMetric('Impressions', impressions.toString()),
                    SizedBox(width: 4.w),
                    _buildMetric('Clicks', clicks.toString()),
                    SizedBox(width: 4.w),
                    _buildMetric('CTR', '$ctr%'),
                  ],
                ),
                SizedBox(height: 2.h),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onEdit();
                        },
                        icon: const CustomIconWidget(
                          iconName: 'edit',
                          size: 18,
                        ),
                        label: const Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showStatusMenu(context);
                        },
                        icon: const CustomIconWidget(
                          iconName: 'swap_horiz',
                          size: 18,
                        ),
                        label: const Text('Status'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onDelete();
                      },
                      icon: CustomIconWidget(
                        iconName: 'delete',
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'expired':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  TextStyle(fontSize: 10.sp, color: theme.colorScheme.outline),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }

  void _showStatusMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Ad Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildStatusOption(context, 'draft', 'Draft'),
            _buildStatusOption(context, 'scheduled', 'Scheduled'),
            _buildStatusOption(context, 'active', 'Active'),
            _buildStatusOption(context, 'paused', 'Paused'),
            _buildStatusOption(context, 'expired', 'Expired'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, String status, String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onStatusChange(status);
      },
    );
  }
}
