import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OrderSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onReorderPressed;

  const OrderSummaryWidget({
    super.key,
    required this.orderData,
    this.onReorderPressed,
  });

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List<Map<String, dynamic>>;

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Order #${orderData['orderId']}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                ...items.map((item) => _buildOrderItem(context, item)),
                if (items.length > 3) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '+${items.length - 3} more items',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 3.h),
                Divider(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
                SizedBox(height: 2.h),
                _buildPricingRow(
                  context,
                  'Subtotal',
                  orderData['subtotal'] as String,
                  false,
                ),
                SizedBox(height: 1.h),
                _buildPricingRow(
                  context,
                  'Delivery Fee',
                  orderData['deliveryFee'] as String,
                  false,
                ),
                SizedBox(height: 1.h),
                _buildPricingRow(
                  context,
                  'Tax',
                  orderData['tax'] as String,
                  false,
                ),
                SizedBox(height: 2.h),
                Divider(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
                SizedBox(height: 2.h),
                _buildPricingRow(
                  context,
                  'Total',
                  orderData['total'] as String,
                  true,
                ),
              ],
            ),
          ),
          if (orderData['status'] == 'delivered') ...[
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReorderPressed,
                child: Text('Reorder Items'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImageWidget(
                imageUrl: item['image'] as String,
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
                semanticLabel: item['semanticLabel'] as String,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${item['quantity']}x ${item['price']}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item['totalPrice'] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(
    BuildContext context,
    String label,
    String value,
    bool isTotal,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
