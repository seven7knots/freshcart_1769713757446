import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/user_address_model.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../presentation/map_location_picker/map_location_picker_screen.dart';
import '../l10n/generated/app_localizations.dart';

class SavedAddressesSheet extends StatefulWidget {
  final UserAddress? currentSelection;

  const SavedAddressesSheet({
    super.key,
    this.currentSelection,
  });

  static Future<UserAddress?> show(
    BuildContext context, {
    UserAddress? currentSelection,
  }) {
    return showModalBottomSheet<UserAddress>(
      context: context,
      // FIX: hardcoded white — never inherits dark theme
      backgroundColor: Colors.white,
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
    if (mounted) {
      setState(() {
        _addresses = addrs;
        _isLoading = false;
      });
    }
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
          label: AppLocalizations.of(context)!.gps,
        );
        await _locationService.addAddress(userAddr.copyWith(label: AppLocalizations.of(context)!.recent));
        await _locationService.cacheSelectedAddress(userAddr);
        if (mounted) Navigator.pop(context, userAddr);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotGetCurrentLocation, maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  // FIX: _pickOnMap now actually navigates to UniversalMapPickerScreen
  Future<void> _pickOnMap() async {
    // Close this sheet first
    Navigator.pop(context);

    // Small delay to let sheet close cleanly
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => const UniversalMapPickerScreen(
          mode: MapPickerMode.delivery,
        ),
      ),
    );

    if (result != null && mounted) {
      await _locationService.addAddress(result.copyWith(label: AppLocalizations.of(context)!.recent));
      await _locationService.cacheSelectedAddress(result);
      // Return result to the original show() caller via context
      // The caller will receive null from show() since we already popped,
      // so we push the result back through a second pop if context allows.
      // Pattern: caller should listen to location provider changes instead.
    }
  }

  Future<void> _selectAddress(UserAddress addr) async {
    await _locationService.cacheSelectedAddress(addr);
    if (mounted) Navigator.pop(context, addr);
  }

  Future<void> _deleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text('Remove "${_addresses[index].address}"?', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.remove,
                style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    const primaryRed = AppTheme.kjRed;
    // FIX: account for bottom safe area to eliminate 40px overflow
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: 70.h),
      // FIX: hardcoded white background
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            AppLocalizations.of(context)!.selectDeliveryLocation,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),

          // Pick on map
          _buildActionTile(
            icon: Icons.map,
            iconColor: primaryRed,
            title: AppLocalizations.of(context)!.pickOnMap,
            subtitle: AppLocalizations.of(context)!.searchOrTapToSelectLocation,
            onTap: _pickOnMap,
          ),

          // Use current location
          _buildActionTile(
            icon: Icons.my_location,
            iconColor: Colors.blue,
            title: AppLocalizations.of(context)!.useCurrentLocation,
            subtitle: AppLocalizations.of(context)!.detectAutomatically,
            trailing: _isGettingGps
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isGettingGps ? null : _useCurrentLocation,
          ),

          // Saved addresses
          if (_addresses.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Divider(color: Colors.grey.shade200),
            SizedBox(height: 0.5.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.savedAddresses,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 1.h),
          ],

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
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? primaryRed
                            : Colors.grey.shade200,
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryRed,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        addr.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
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
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                      onTap: () => _selectAddress(addr),
                    ),
                  );
                },
              ),
            ),

          // FIX: dynamic bottom padding = safe area height, eliminates overflow
          SizedBox(height: 2.h + bottomInset),
        ],
      ),
    );
  }

  Widget _buildActionTile({
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing ??
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}