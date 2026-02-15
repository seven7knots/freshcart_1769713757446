import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/user_address_model.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

/// Reusable bottom sheet for selecting saved addresses or picking a new one.
///
/// Usage:
/// ```dart
/// final selected = await SavedAddressesSheet.show(
///   context,
///   mode: MapPickerMode.delivery, // controls which map picker mode opens
/// );
/// if (selected != null) {
///   // Use selected.address, selected.lat, selected.lng, selected.radiusKm
/// }
/// ```
class SavedAddressesSheet extends StatefulWidget {
  final UserAddress? currentSelection;

  const SavedAddressesSheet({
    super.key,
    this.currentSelection,
  });

  /// Show the sheet and return the selected address (or null if dismissed)
  static Future<UserAddress?> show(
    BuildContext context, {
    UserAddress? currentSelection,
  }) {
    return showModalBottomSheet<UserAddress>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => SavedAddressesSheet(
        currentSelection: currentSelection,
      ),
    );
  }

  @override
  State<SavedAddressesSheet> createState() => _SavedAddressesSheetState();
}

class _SavedAddressesSheetState extends State<SavedAddressesSheet> {
  final _locationService = LocationService();
  List<UserAddress> _addresses = [];
  bool _isLoading = true;
  bool _isGettingGps = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final addrs = await _locationService.loadSavedAddresses();
    if (mounted) setState(() { _addresses = addrs; _isLoading = false; });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingGps = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        final address = await _locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        final userAddr = UserAddress(
          address: address,
          lat: position.latitude,
          lng: position.longitude,
          label: 'GPS',
        );
        // Save and cache
        await _locationService.addAddress(userAddr.copyWith(label: 'RECENT'));
        await _locationService.cacheSelectedAddress(userAddr);
        if (mounted) Navigator.pop(context, userAddr);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  Future<void> _pickOnMap() async {
    // Close the sheet first
    Navigator.pop(context);

    // Remove UniversalMapPickerScreen navigation - undefined class
    /*
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalMapPickerScreen(mode: widget.mode),
      ),
    );

    if (result != null) {
      // Save and cache
      await _locationService.addAddress(result.copyWith(label: 'RECENT'));
      await _locationService.cacheSelectedAddress(result);
      // Return result via the original show() caller
      // Since we already popped, we need to use a callback pattern.
      // The caller should handle the Navigator.push result directly.
      // This is handled by returning from the static show() method.
    }
    */
  }

  Future<void> _selectAddress(UserAddress addr) async {
    await _locationService.cacheSelectedAddress(addr);
    if (mounted) Navigator.pop(context, addr);
  }

  Future<void> _deleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Address'),
        content: Text('Remove "${_addresses[index].address}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _locationService.removeAddress(index);
      await _loadAddresses();
    }
  }

  IconData _labelIcon(String label) {
    switch (label.toUpperCase()) {
      case 'HOME':
        return Icons.home;
      case 'WORK':
        return Icons.work;
      case 'STORE':
        return Icons.store;
      case 'GPS':
      case 'RECENT':
        return Icons.history;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryRed = AppTheme.kjRed;

    return Container(
      constraints: BoxConstraints(maxHeight: 70.h),
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            'Select Location',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 2.h),

          // Pick on map
          _buildActionTile(
            theme: theme,
            icon: Icons.map,
            iconColor: primaryRed,
            title: 'Pick on Map',
            subtitle: 'Search or tap to select location',
            onTap: () async {
              // Remove UniversalMapPickerScreen navigation
              // Navigator.pop(context); // close sheet
              // final result = await Navigator.push<UserAddress>(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) =>
              //         UniversalMapPickerScreen(mode: widget.mode),
              //   ),
              // );
              // Note: result handled by the caller's Navigator.push
              // The static show() will return null since we popped the sheet.
              // For this flow, use the direct Navigator.push pattern instead.
            },
          ),

          // Use current location
          _buildActionTile(
            theme: theme,
            icon: Icons.my_location,
            iconColor: Colors.blue,
            title: 'Use Current Location',
            subtitle: 'Detect via GPS',
            trailing: _isGettingGps
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isGettingGps ? null : _useCurrentLocation,
          ),

          // Divider
          if (_addresses.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Divider(color: theme.colorScheme.outline.withOpacity(0.15)),
            SizedBox(height: 0.5.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Addresses',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 1.h),
          ],

          // Saved addresses list
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final addr = _addresses[index];
                  final isSelected =
                      widget.currentSelection?.address == addr.address;

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryRed.withOpacity(0.08)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? primaryRed
                            : theme.colorScheme.outline.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _labelIcon(addr.label),
                          color: primaryRed,
                          size: 5.w,
                        ),
                      ),
                      title: Text(
                        addr.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryRed,
                        ),
                      ),
                      subtitle: Text(
                        addr.address,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (addr.hasCoordinates)
                            Icon(Icons.gps_fixed,
                                size: 4.w, color: Colors.green),
                          SizedBox(width: 1.w),
                          GestureDetector(
                            onTap: () => _deleteAddress(index),
                            child: Icon(Icons.close,
                                size: 5.w,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      onTap: () => _selectAddress(addr),
                    ),
                  );
                },
              ),
            ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.5.w),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 6.w),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}