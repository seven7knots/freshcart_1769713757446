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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (data.isEmpty) return _buildEmptyState(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 3.h),
        SizedBox(height: 30.h, child: LineChart(_buildLineChartData(cs))),
      ]),
    );
  }

  LineChartData _buildLineChartData(ColorScheme cs) {
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
        getDrawingHorizontalLine: (value) => FlLine(color: cs.outline.withOpacity(0.15), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 30, interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) return const SizedBox.shrink();
              String label = '';
              if (period == 'weekly') {
                final dateStr = data[index]['date'] as String;
                final parts = dateStr.split('-');
                label = parts.length >= 3 ? parts[2] : '';
              } else if (period == 'monthly') {
                label = (data[index]['week'] as String).replaceAll('Week ', 'W');
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 40,
            interval: maxY > 0 ? maxY / 5 : 20,
            getTitlesWidget: (value, meta) =>
                Text('\$${value.toInt()}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10.sp)),
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: cs.outline.withOpacity(0.15))),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: [AppTheme.kjRed, AppTheme.kjRed.withOpacity(0.7)]),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(radius: 4, color: AppTheme.kjRed, strokeWidth: 2, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppTheme.kjRed.withOpacity(0.2), AppTheme.kjRed.withOpacity(0.02)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots
              .map((spot) => LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 3.h),
        Icon(Icons.show_chart, size: 15.w, color: cs.onSurfaceVariant),
        SizedBox(height: 2.h),
        Text('No earnings data available', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp)),
      ]),
    );
  }
}