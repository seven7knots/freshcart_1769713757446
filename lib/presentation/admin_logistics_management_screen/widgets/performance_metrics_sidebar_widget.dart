import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/driver_model.dart';
import '../../../models/order_model.dart';

class PerformanceMetricsSidebarWidget extends StatelessWidget {
  final List<DriverModel> drivers;
  final List<OrderModel> orders;

  const PerformanceMetricsSidebarWidget({
    super.key,
    required this.drivers,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final onlineDrivers = drivers.where((d) => d.isOnline).length;
    final totalDrivers = drivers.length;
    final utilizationRate =
        totalDrivers > 0 ? (onlineDrivers / totalDrivers * 100) : 0.0;

    final avgRating = drivers.isNotEmpty
        ? drivers.map((d) => d.rating).reduce((a, b) => a + b) / drivers.length
        : 0.0;

    final totalDeliveries =
        drivers.fold<int>(0, (sum, d) => sum + d.totalDeliveries);

    return Container(
      width: 70.w,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.analytics, color: Colors.blue),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildMetricCard(
                  title: 'Driver Utilization',
                  value: '${utilizationRate.toStringAsFixed(1)}%',
                  subtitle: '$onlineDrivers of $totalDrivers online',
                  icon: Icons.people,
                  color: Colors.blue,
                  progress: utilizationRate / 100,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  title: 'Average Rating',
                  value: avgRating.toStringAsFixed(2),
                  subtitle: 'Across all drivers',
                  icon: Icons.star,
                  color: Colors.amber,
                  progress: avgRating / 5,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  title: 'Total Deliveries',
                  value: totalDeliveries.toString(),
                  subtitle: 'All-time completed',
                  icon: Icons.local_shipping,
                  color: Colors.green,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  title: 'Pending Orders',
                  value: orders.length.toString(),
                  subtitle: 'Awaiting assignment',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                SizedBox(height: 2.h),
                _buildMetricCard(
                  title: 'Priority Orders',
                  value: orders.where((o) => o.isPriority).length.toString(),
                  subtitle: 'Requires immediate attention',
                  icon: Icons.priority_high,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
