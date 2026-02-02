import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class LocationPermissionWidget extends StatefulWidget {
  final VoidCallback onPermissionGranted;
  final VoidCallback onPermissionDenied;

  const LocationPermissionWidget({
    super.key,
    required this.onPermissionGranted,
    required this.onPermissionDenied,
  });

  @override
  State<LocationPermissionWidget> createState() =>
      _LocationPermissionWidgetState();
}

class _LocationPermissionWidgetState extends State<LocationPermissionWidget> {
  bool _isRequestingPermission = false;

  Future<void> _requestLocationPermission() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      HapticFeedback.lightImpact();

      final status = await Permission.location.request();

      if (status.isGranted) {
        widget.onPermissionGranted();
      } else {
        widget.onPermissionDenied();
      }
    } catch (e) {
      widget.onPermissionDenied();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomImageWidget(
                imageUrl:
                    "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
                width: 88.w,
                height: double.infinity,
                fit: BoxFit.cover,
                semanticLabel:
                    "Smartphone displaying location pin on map with delivery truck icon and fresh groceries in background",
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  "Enable Location",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                Text(
                  "We need your location to deliver fresh groceries to your doorstep and show nearby stores with the best deals.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: 80.w,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _isRequestingPermission
                        ? null
                        : _requestLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                      shadowColor: theme.colorScheme.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isRequestingPermission
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            "Allow Location Access",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextButton(
                  onPressed: widget.onPermissionDenied,
                  child: Text(
                    "Enter Address Manually",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
