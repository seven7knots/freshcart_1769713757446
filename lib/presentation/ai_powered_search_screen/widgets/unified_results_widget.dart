import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UnifiedResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String selectedCategory;

  const UnifiedResultsWidget({
    required this.results,
    required this.selectedCategory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filteredResults = selectedCategory == 'all'
        ? results
        : results
            .where((r) =>
                r['category']?.toString().toLowerCase() == selectedCategory ||
                r['item_type'] == selectedCategory)
            .toList();

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final item = filteredResults[index];
        return _buildResultCard(context, item);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> item) {
    final itemType = item['item_type'] ?? 'product';
    final name = item['name'] ?? 'Unknown';
    final description = item['description'] ?? '';
    final price = item['price'] ?? 0.0;
    final currency = item['currency'] ?? 'USD';
    final imageUrl = item['image_url'];
    final availability = item['availability'] ?? false;
    final category = item['category'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(3.w),
                ),
                child: Image.network(
                  imageUrl ?? '',
                  height: 20.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 20.h,
                      width: double.infinity,
                      color: Colors.grey[800],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              Positioned(
                top: 2.w,
                left: 2.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: itemType == 'product' ? Colors.blue : Colors.purple,
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    itemType == 'product' ? 'Product' : 'Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!availability)
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      'Unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currency \$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: const Color(0xFFE50914),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (category.isNotEmpty)
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: availability
                          ? () {
                              // Navigate to detail screen
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        disabledBackgroundColor: Colors.grey,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      child: Text(
                        itemType == 'product' ? 'View' : 'Book',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
