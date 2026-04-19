import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8.h),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              size: 20.w,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            AppLocalizations.of(context)!.enableLocation,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              AppLocalizations.of(context)!.weNeedYourLocationToDeliver,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: 85.w,
            child: ElevatedButton(
              onPressed: _isRequestingPermission
                  ? null
                  : _requestLocationPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                shadowColor: theme.colorScheme.shadow,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
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
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppLocalizations.of(context)!.allowLocationAccess,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),
          TextButton(
            onPressed: widget.onPermissionDenied,
            child: Text(
              AppLocalizations.of(context)!.enterAddressManually,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
