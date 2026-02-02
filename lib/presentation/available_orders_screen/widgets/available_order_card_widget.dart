import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class AvailableOrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;

  const AvailableOrderCardWidget({
    super.key,
    required this.order,
    required this.onAccept,
  });

  @override
  State<AvailableOrderCardWidget> createState() =>
      _AvailableOrderCardWidgetState();
}

class _AvailableOrderCardWidgetState extends State<AvailableOrderCardWidget> {
  bool _isExpanded = false;
  int _remainingSeconds = 60;
  Timer? _countdownTimer;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        // Auto-decline after timeout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order expired'),
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
          );
        }
      }
    });
  }

  void _handleAccept() async {
    setState(() {
      _isAccepting = true;
    });

    _countdownTimer?.cancel();
    widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.order['stores'] as Map<String, dynamic>?;
    final storeName = store?['name'] as String? ?? 'Unknown Store';
    final storeImage = store?['image_url'] as String?;
    final storeAddress = store?['address'] as String? ?? '';

    final deliveryAddress = widget.order['delivery_address'] as String? ?? '';
    final distance = widget.order['distance_km'] as double? ?? 0.0;
    final earnings = widget.order['estimated_earnings'] as double? ?? 0.0;
    final orderValue = widget.order['total'] as double? ?? 0.0;
    final tip = widget.order['tip'] as double? ?? 0.0;

    final orderItems = widget.order['order_items'] as List? ?? [];
    final itemCount = orderItems.length;

    final progress = _remainingSeconds / 60.0;
    final isExpired = _remainingSeconds <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store info and countdown
                  Row(
                    children: [
                      // Store image
                      Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: AppTheme.lightTheme.scaffoldBackgroundColor,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: storeImage != null
                              ? CustomImageWidget(
                                  imageUrl: storeImage,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.store,
                                  color: AppTheme.textSecondaryOf(context),
                                  size: 8.w,
                                ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      // Store name and address
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 4.w,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                                SizedBox(width: 1.w),
                                Expanded(
                                  child: Text(
                                    storeAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppTheme.textSecondaryOf(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Countdown timer
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.0,
                              backgroundColor:
                                  AppTheme.lightTheme.scaffoldBackgroundColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isExpired
                                    ? AppTheme.lightTheme.colorScheme.error
                                    : AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '$_remainingSeconds',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isExpired
                                  ? AppTheme.lightTheme.colorScheme.error
                                  : AppTheme.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Delivery address
                  Row(
                    children: [
                      Icon(
                        Icons.navigation_outlined,
                        size: 5.w,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          deliveryAddress,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Distance and earnings
                  Row(
                    children: [
                      // Distance
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.route,
                                size: 5.w,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Earnings
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 5.w,
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '\$${earnings.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Expandable details
                  if (_isExpanded) ...[
                    SizedBox(height: 2.h),
                    Divider(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      height: 1,
                    ),
                    SizedBox(height: 2.h),
                    // Order details
                    _buildDetailRow('Items', '$itemCount items'),
                    SizedBox(height: 1.h),
                    _buildDetailRow(
                        'Order Value', '\$${orderValue.toStringAsFixed(2)}'),
                    if (tip > 0) ...[
                      SizedBox(height: 1.h),
                      _buildDetailRow('Tip', '\$${tip.toStringAsFixed(2)}'),
                    ],
                  ],
                ],
              ),
            ),
          ),
          // Accept button
          if (!isExpired)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isAccepting ? null : _handleAccept,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    decoration: BoxDecoration(
                      gradient: _isAccepting ? null : AppTheme.gradientAccent,
                      color: _isAccepting
                          ? AppTheme.textSecondaryOf(context)
                          : null,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.0),
                        bottomRight: Radius.circular(12.0),
                      ),
                    ),
                    child: Center(
                      child: _isAccepting
                          ? SizedBox(
                              width: 5.w,
                              height: 5.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Accept Order',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppTheme.textSecondaryOf(context),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}
