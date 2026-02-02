import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterControlsWidget extends StatelessWidget {
  final String driverStatusFilter;
  final String orderPriorityFilter;
  final Function(String) onDriverStatusChanged;
  final Function(String) onOrderPriorityChanged;

  const FilterControlsWidget({
    super.key,
    required this.driverStatusFilter,
    required this.orderPriorityFilter,
    required this.onDriverStatusChanged,
    required this.onOrderPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver Status',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          children: [
            _buildFilterChip(
              label: 'All',
              isSelected: driverStatusFilter == 'all',
              onTap: () => onDriverStatusChanged('all'),
            ),
            _buildFilterChip(
              label: 'Online',
              isSelected: driverStatusFilter == 'online',
              onTap: () => onDriverStatusChanged('online'),
            ),
            _buildFilterChip(
              label: 'Offline',
              isSelected: driverStatusFilter == 'offline',
              onTap: () => onDriverStatusChanged('offline'),
            ),
            _buildFilterChip(
              label: 'Busy',
              isSelected: driverStatusFilter == 'busy',
              onTap: () => onDriverStatusChanged('busy'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Order Priority',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          children: [
            _buildFilterChip(
              label: 'All',
              isSelected: orderPriorityFilter == 'all',
              onTap: () => onOrderPriorityChanged('all'),
            ),
            _buildFilterChip(
              label: 'Priority',
              isSelected: orderPriorityFilter == 'priority',
              onTap: () => onOrderPriorityChanged('priority'),
            ),
            _buildFilterChip(
              label: 'Standard',
              isSelected: orderPriorityFilter == 'standard',
              onTap: () => onOrderPriorityChanged('standard'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
