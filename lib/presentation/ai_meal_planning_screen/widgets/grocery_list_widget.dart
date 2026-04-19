import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/generated/app_localizations.dart';

class GroceryListWidget extends StatelessWidget {
  final Map<String, dynamic> groceryList;
  final double totalCost;

  const GroceryListWidget({
    super.key,
    required this.groceryList,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groceryList.entries.map((category) {
          final categoryName = category.key;
          final rawItems = category.value;
          if (rawItems is! List) return const SizedBox.shrink();
          final items = rawItems;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFFE50914),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              ...items.map((item) {
                final itemData = item as Map<String, dynamic>;

                // SESSION 29 FIX: AI returns 'item' not 'name' — support both
                final itemName = (itemData['item'] ?? itemData['name'] ?? '').toString().trim();
                final quantity = (itemData['quantity'] ?? '').toString().trim();
                final productId = itemData['product_id']?.toString();
                final isAvailable = productId != null && productId != 'null' && productId.isNotEmpty;

                // Only show if we have a name
                if (itemName.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color: isAvailable
                          ? Colors.green.withOpacity(0.25)
                          : Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            if (quantity.isNotEmpty)
                              Text(
                                quantity,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.sp,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Show availability badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.withOpacity(0.15)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isAvailable ? AppLocalizations.of(context)!.inStore : AppLocalizations.of(context)!.notAvailable,
                          style: TextStyle(
                            color: isAvailable
                                ? Colors.greenAccent
                                : Colors.white38,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 2.h),
            ],
          );
        }),
      ],
    );
  }
}