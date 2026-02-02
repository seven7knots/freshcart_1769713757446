import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
        'title': 'Cheap Italian food open now',
        'query': 'cheap Italian food open now',
      },
      {
        'icon': Icons.local_grocery_store,
        'title': 'Fresh vegetables under \$20',
        'query': 'fresh vegetables under 20',
      },
      {
        'icon': Icons.local_pharmacy,
        'title': 'Pharmacy near me',
        'query': 'pharmacy near me',
      },
      {
        'icon': Icons.build,
        'title': 'Mechanics within 5 miles',
        'query': 'mechanics within 5 miles',
      },
      {
        'icon': Icons.cleaning_services,
        'title': 'Cleaners available today',
        'query': 'cleaners available today',
      },
      {
        'icon': Icons.shopping_bag,
        'title': 'Retail stores open now',
        'query': 'retail stores open now',
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
              Text(
                'Smart Suggestions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Try asking AI in natural language:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
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
                        ),
                      ),
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
