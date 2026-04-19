import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GroceryListWidget extends StatelessWidget {
  final List<dynamic> groceryList;
  final double totalCost;

  const GroceryListWidget({
    super.key,
    required this.groceryList,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    if (groceryList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Center(
          child: Text(
            'Grocery list is empty.',
            style: TextStyle(color: Colors.white60, fontSize: 13.sp),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groceryList.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final item = Map<String, dynamic>.from(raw);
          final name = (item['name'] ?? item['item'] ?? '').toString().trim();
          final qty = (item['qty'] ?? item['quantity'] ?? '').toString().trim();
          final priceRaw = item['est_price_usd'] ?? item['price'] ?? 0;
          final price = priceRaw is num ? priceRaw.toDouble() : 0.0;
          if (name.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (qty.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 0.3.h),
                          child: Text(
                            qty,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFFE50913),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE50913).withAlpha(30),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '\$${totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  color: const Color(0xFFE50913),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
