import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class OrderSummaryWidget extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double taxes;
  final double discount;
  final String? promoCode;
  final Function(String)? onPromoCodeApplied;
  final VoidCallback? onPromoCodeRemoved;

  const OrderSummaryWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxes,
    this.discount = 0.0,
    this.promoCode,
    this.onPromoCodeApplied,
    this.onPromoCodeRemoved,
  });

  @override
  State<OrderSummaryWidget> createState() => _OrderSummaryWidgetState();
}

class _OrderSummaryWidgetState extends State<OrderSummaryWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promoController = TextEditingController();
  bool _isExpanded = false;
  bool _isApplyingPromo = false;
  String? _promoError;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.promoCode != null) {
      _promoController.text = widget.promoCode!;
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    HapticFeedback.lightImpact();

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.trim().isEmpty) return;

    setState(() {
      _isApplyingPromo = true;
      _promoError = null;
    });

    HapticFeedback.lightImpact();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    final promoCode = _promoController.text.trim().toUpperCase();

    // Mock promo code validation
    final validPromoCodes = ['SAVE10', 'WELCOME20', 'FIRST15', 'FRESH25'];

    if (validPromoCodes.contains(promoCode)) {
      widget.onPromoCodeApplied?.call(promoCode);
      setState(() {
        _isApplyingPromo = false;
        _promoError = null;
      });
    } else {
      setState(() {
        _isApplyingPromo = false;
        _promoError = 'Invalid promo code. Please try again.';
      });
    }
  }

  void _removePromoCode() {
    _promoController.clear();
    widget.onPromoCodeRemoved?.call();
    setState(() {
      _promoError = null;
    });
    HapticFeedback.lightImpact();
  }

  double get _total {
    return widget.subtotal +
        widget.deliveryFee +
        widget.taxes -
        widget.discount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: _toggleExpansion,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'receipt_long',
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Order Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Breakdown Items
                      _buildSummaryRow(
                        context,
                        'Subtotal',
                        '\$${widget.subtotal.toStringAsFixed(2)}',
                      ),

                      SizedBox(height: 1.h),

                      _buildSummaryRow(
                        context,
                        'Delivery Fee',
                        widget.deliveryFee > 0
                            ? '\$${widget.deliveryFee.toStringAsFixed(2)}'
                            : 'FREE',
                        isDeliveryFree: widget.deliveryFee == 0,
                      ),

                      SizedBox(height: 1.h),

                      _buildSummaryRow(
                        context,
                        'Taxes & Fees',
                        '\$${widget.taxes.toStringAsFixed(2)}',
                      ),

                      if (widget.discount > 0) ...[
                        SizedBox(height: 1.h),
                        _buildSummaryRow(
                          context,
                          'Discount',
                          '-\$${widget.discount.toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      ],

                      SizedBox(height: 2.h),

                      // Promo Code Section
                      _buildPromoCodeSection(context),

                      SizedBox(height: 2.h),

                      // Total
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '\$${_total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isDiscount = false,
    bool isDeliveryFree = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            if (isDeliveryFree)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                margin: EdgeInsets.only(right: 2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FREE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDiscount
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCodeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _promoController,
                enabled: widget.promoCode == null,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  suffixIcon: widget.promoCode != null
                      ? GestureDetector(
                          onTap: _removePromoCode,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: CustomIconWidget(
                              iconName: 'close',
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
                onFieldSubmitted: (_) => _applyPromoCode(),
              ),
            ),
            if (widget.promoCode == null) ...[
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: _isApplyingPromo ? null : _applyPromoCode,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: _isApplyingPromo
                        ? theme.colorScheme.outline.withValues(alpha: 0.3)
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isApplyingPromo
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onSurface,
                            ),
                          ),
                        )
                      : Text(
                          'Apply',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
        if (_promoError != null) ...[
          SizedBox(height: 1.h),
          Text(
            _promoError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (widget.promoCode != null) ...[
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Promo code "${widget.promoCode}" applied successfully!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
