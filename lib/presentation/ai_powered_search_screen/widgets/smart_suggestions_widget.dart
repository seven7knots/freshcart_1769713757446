import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class SmartSuggestionsWidget extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SmartSuggestionsWidget({
    required this.onSuggestionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {
        'icon': Icons.restaurant,
        'title': AppLocalizations.of(context)!.cheapItalianFoodOpenNow,
        'query': AppLocalizations.of(context)!.cheapItalianFoodOpenNow2,
      },
      {
        'icon': Icons.local_grocery_store,
        'title': 'Fresh vegetables under \$20',
        'query': AppLocalizations.of(context)!.freshVegetablesUnder20,
      },
      {
        'icon': Icons.local_pharmacy,
        'title': AppLocalizations.of(context)!.pharmacyNearMe,
        'query': AppLocalizations.of(context)!.pharmacyNearMe2,
      },
      {
        'icon': Icons.build,
        'title': AppLocalizations.of(context)!.mechanicsWithin5Miles,
        'query': AppLocalizations.of(context)!.mechanicsWithin5Miles2,
      },
      {
        'icon': Icons.cleaning_services,
        'title': AppLocalizations.of(context)!.cleanersAvailableToday,
        'query': AppLocalizations.of(context)!.cleanersAvailableToday2,
      },
      {
        'icon': Icons.shopping_bag,
        'title': AppLocalizations.of(context)!.retailStoresOpenNow,
        'query': AppLocalizations.of(context)!.retailStoresOpenNow2,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFFE50914),
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Flexible(child: Text(
                AppLocalizations.of(context)!.smartSuggestions,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            AppLocalizations.of(context)!.tryAskingAiInNaturalLanguage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ...suggestions.map((suggestion) {
            return GestureDetector(
              onTap: () => onSuggestionTap(suggestion['query'] as String),
              child: Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914).withAlpha(51),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Icon(
                        suggestion['icon'] as IconData,
                        color: const Color(0xFFE50914),
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        suggestion['title'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white38,
                      size: 4.w,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
