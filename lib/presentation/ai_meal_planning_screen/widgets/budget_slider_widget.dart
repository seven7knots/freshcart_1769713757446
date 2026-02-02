import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BudgetSliderWidget extends StatelessWidget {
  final double budget;
  final Function(double) onBudgetChanged;

  const BudgetSliderWidget({
    super.key,
    required this.budget,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '\$${budget.toStringAsFixed(0)}',
              style: TextStyle(
                color: const Color(0xFFE50914),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFE50914),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFFE50914),
            overlayColor: const Color(0xFFE50914).withAlpha(51),
            trackHeight: 0.5.h,
          ),
          child: Slider(
            value: budget,
            min: 20,
            max: 500,
            divisions: 48,
            onChanged: onBudgetChanged,
          ),
        ),
      ],
    );
  }
}
