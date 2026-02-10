import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int maxQuantity;
  final bool enabled;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    this.maxQuantity = 99,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quantity', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        SizedBox(height: 1.h),
        Row(children: [
          _buildButton(theme, Icons.remove, enabled && quantity > 1 ? () {
            HapticFeedback.lightImpact();
            onQuantityChanged(quantity - 1);
          } : null),
          SizedBox(width: 4.w),
          Container(
            width: 15.w, height: 6.h,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(quantity.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
          ),
          SizedBox(width: 4.w),
          _buildButton(theme, Icons.add, enabled && quantity < maxQuantity ? () {
            HapticFeedback.lightImpact();
            onQuantityChanged(quantity + 1);
          } : null),
          if (quantity >= maxQuantity) ...[
            SizedBox(width: 4.w),
            Expanded(child: Text('Max quantity reached',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))),
          ],
        ]),
      ]),
    );
  }

  Widget _buildButton(ThemeData theme, IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 12.w, height: 6.h,
      decoration: BoxDecoration(
        color: onPressed != null ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Center(child: Icon(icon, color: onPressed != null
            ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant, size: 20)),
      )),
    );
  }
}