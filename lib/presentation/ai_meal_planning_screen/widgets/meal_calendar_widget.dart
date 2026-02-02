import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MealCalendarWidget extends StatelessWidget {
  final List<dynamic> meals;

  const MealCalendarWidget({
    super.key,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: meals.map((meal) {
        final mealData = meal as Map<String, dynamic>;
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mealData['name'] ?? 'Meal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(51),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      '\$${(mealData['estimated_cost'] ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: const Color(0xFFE50914),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Colors.white70,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${mealData['prep_time'] ?? 0} min',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(
                    Icons.restaurant,
                    color: Colors.white70,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    mealData['difficulty'] ?? 'Medium',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              if (mealData['ingredients'] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  'Ingredients:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  (mealData['ingredients'] as List).join(', '),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
