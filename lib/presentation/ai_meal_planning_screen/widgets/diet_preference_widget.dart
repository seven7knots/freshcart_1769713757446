import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class DietPreferenceWidget extends StatelessWidget {
  final List<String> dietTypes;
  final String selectedDiet;
  final Function(String) onDietChanged;

  const DietPreferenceWidget({
    super.key,
    required this.dietTypes,
    required this.selectedDiet,
    required this.onDietChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dietType,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: dietTypes.map((diet) {
            final isSelected = selectedDiet == diet;
            return GestureDetector(
              onTap: () => onDietChanged(diet),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6.w),
                  border: Border.all(
                    color:
                        isSelected ? const Color(0xFFE50914) : Colors.white24,
                  ),
                ),
                child: Text(
                  diet.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
