import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InterpretedFiltersWidget extends StatelessWidget {
  final Map<String, dynamic> filters;
  final VoidCallback onClear;

  const InterpretedFiltersWidget({
    required this.filters,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filters['category'] != null && filters['category'] != 'all') {
      chips.add(_buildChip(
        'Category: ${filters['category']}',
        Icons.category,
      ));
    }

    if (filters['min_price'] != null || filters['max_price'] != null) {
      final minPrice = filters['min_price'];
      final maxPrice = filters['max_price'];
      String priceText = 'Price: ';
      if (minPrice != null && maxPrice != null) {
        priceText += '\$$minPrice - \$$maxPrice';
      } else if (minPrice != null) {
        priceText += 'Over \$$minPrice';
      } else {
        priceText += 'Under \$$maxPrice';
      }
      chips.add(_buildChip(priceText, Icons.attach_money));
    }

    if (filters['open_now'] == true) {
      chips.add(_buildChip('Open Now', Icons.access_time));
    }

    if (filters['sort_by'] != null && filters['sort_by'] != 'relevance') {
      final sortBy = filters['sort_by'];
      String sortText = 'Sort: ';
      if (sortBy == 'price_low') {
        sortText += 'Price Low-High';
      } else if (sortBy == 'price_high') {
        sortText += 'Price High-Low';
      }
      chips.add(_buildChip(sortText, Icons.sort));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFFE50914),
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              Text(
                'AI Interpreted:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: const Color(0xFFE50914),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(5.w),
        border: Border.all(
          color: const Color(0xFFE50914).withAlpha(77),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE50914),
            size: 4.w,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
