import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class QuickActionToolbarWidget extends StatelessWidget {
  final int onlineDriversCount;
  final int totalDriversCount;
  final int pendingOrdersCount;
  final VoidCallback onRefresh;
  final VoidCallback onToggleOrderQueue;

  const QuickActionToolbarWidget({
    super.key,
    required this.onlineDriversCount,
    required this.totalDriversCount,
    required this.pendingOrdersCount,
    required this.onRefresh,
    required this.onToggleOrderQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatChip(
            icon: Icons.people,
            label: 'Drivers',
            value: '$onlineDriversCount/$totalDriversCount',
            color: Colors.green,
          ),
          _buildStatChip(
            icon: Icons.assignment,
            label: 'Orders',
            value: pendingOrdersCount.toString(),
            color: Colors.orange,
          ),
          Row(
            children: [
              IconButton(
                onPressed: onToggleOrderQueue,
                icon: const Icon(Icons.list_alt),
                tooltip: 'Toggle Order Queue',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
