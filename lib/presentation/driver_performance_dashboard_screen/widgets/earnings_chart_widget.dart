import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class EarningsChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String period;

  const EarningsChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              _buildLineChartData(),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < data.length; i++) {
      final earnings = (data[i]['earnings'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), earnings));
      if (earnings > maxY) maxY = earnings;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 5 : 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderDark,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const SizedBox.shrink();
              }

              String label = '';
              if (period == 'weekly') {
                final dateStr = data[index]['date'] as String;
                final parts = dateStr.split('-');
                label = parts.length >= 3 ? parts[2] : '';
              } else if (period == 'monthly') {
                label =
                    (data[index]['week'] as String).replaceAll('Week ', 'W');
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 10.sp,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: maxY > 0 ? maxY / 5 : 20,
            getTitlesWidget: (value, meta) {
              return Text(
                '\$${value.toInt()}',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: 10.sp,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: AppTheme.borderDark,
        ),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Color(0xFFE10600), Color(0xFFFF3B30)],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryDark,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE10600).withValues(alpha: 0.3),
                const Color(0xFFFF3B30).withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '\$${spot.y.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Icon(
            Icons.show_chart,
            size: 15.w,
            color: Colors.white.withAlpha(179),
          ),
          SizedBox(height: 2.h),
          Text(
            'No earnings data available',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
