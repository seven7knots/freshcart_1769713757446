import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int maxQuantity;
  final bool enabled;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    this.maxQuantity = 10,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildQuantityButton(
                icon: 'remove',
                onPressed: enabled && quantity > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        onQuantityChanged(quantity - 1);
                      }
                    : null,
              ),
              SizedBox(width: 4.w),
              Container(
                width: 15.w,
                height: 6.h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    quantity.toString(),
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              _buildQuantityButton(
                icon: 'add',
                onPressed: enabled && quantity < maxQuantity
                    ? () {
                        HapticFeedback.lightImpact();
                        onQuantityChanged(quantity + 1);
                      }
                    : null,
              ),
              SizedBox(width: 4.w),
              if (quantity >= maxQuantity)
                Expanded(
                  child: Text(
                    'Maximum quantity reached',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required String icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 12.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: onPressed != null
            ? AppTheme.lightTheme.colorScheme.primary
            : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: CustomIconWidget(
              iconName: icon,
              color: onPressed != null
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
