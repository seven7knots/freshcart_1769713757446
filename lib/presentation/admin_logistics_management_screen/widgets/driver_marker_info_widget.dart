import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/driver_model.dart';

class DriverMarkerInfoWidget extends StatelessWidget {
  final Driver driver;
  final int assignedOrdersCount;
  final VoidCallback onAssignOrders;

  const DriverMarkerInfoWidget({
    super.key,
    required this.driver,
    required this.assignedOrdersCount,
    required this.onAssignOrders,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = driver.isOnline;
    final isApproved = driver.isApproved;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isOnline ? Colors.green : Colors.grey,
                child: Text(
                  driver.id.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver ${driver.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        if (isApproved)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              'Approved',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(height: 1, color: Colors.grey.shade300),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star,
                label: 'Rating',
                value: driver.rating.toStringAsFixed(1),
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.local_shipping,
                label: 'Deliveries',
                value: driver.totalDeliveries.toString(),
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.assignment,
                label: 'Current',
                value: assignedOrdersCount.toString(),
                color: Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Vehicle: ${driver.vehicleType.icon} ${driver.vehicleType.displayName}'
            '${(driver.vehicleModel != null && driver.vehicleModel!.isNotEmpty) ? " • ${driver.vehicleModel}" : ""}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
          ),
          if (driver.vehiclePlate != null && driver.vehiclePlate!.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Plate: ${driver.vehiclePlate}',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isOnline ? onAssignOrders : null,
              icon: const Icon(Icons.add_task),
              label: const Text('Assign Orders'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
