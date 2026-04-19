import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class MealCalendarWidget extends StatelessWidget {
  final List<dynamic> meals;

  const MealCalendarWidget({
    super.key,
    required this.meals,
  });

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _portionLabel(BuildContext context, dynamic v) {
    final raw = (v ?? '').toString().trim();
    if (raw.isEmpty) return AppLocalizations.of(context)!.medium;
    return _capitalize(raw);
  }

  String _ingredientsLabel(dynamic ingredients) {
    if (ingredients is! List || ingredients.isEmpty) return '';
    final parts = <String>[];
    for (final raw in ingredients) {
      if (raw is Map) {
        final name = (raw['name'] ?? '').toString().trim();
        final qty = (raw['qty'] ?? raw['quantity'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        parts.add(qty.isEmpty ? name : '$name ($qty)');
      } else if (raw is String) {
        parts.add(raw);
      }
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: meals.map((meal) {
        final mealData = meal as Map<String, dynamic>;
        final name = (mealData['name'] ?? mealData['meal_name'] ?? '')
            .toString()
            .trim();
        final cuisine = (mealData['cuisine'] ?? '').toString().trim();
        final description = (mealData['description'] ?? '').toString().trim();
        final prepTime = mealData['prep_time_min'] ?? mealData['prep_time'] ?? 0;
        final price =
            mealData['est_price_usd'] ?? mealData['estimated_cost'] ?? 0;
        final ingredients = _ingredientsLabel(mealData['ingredients']);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty
                              ? AppLocalizations.of(context)!.meal
                              : name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        if (cuisine.isNotEmpty) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            cuisine,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50913).withAlpha(51),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      '\$${(price is num ? price : 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: const Color(0xFFE50913),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white70, size: 4.w),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      '${prepTime is num ? prepTime.toInt() : 0} min',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(Icons.restaurant, color: Colors.white70, size: 4.w),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      _portionLabel(context, mealData['portion_size']),
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (ingredients.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  AppLocalizations.of(context)!.ingredients,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  ingredients,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  maxLines: 3,
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
