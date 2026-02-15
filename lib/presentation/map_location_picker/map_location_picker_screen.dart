import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../models/user_address_model.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

/// Universal map location picker used across the entire application.
///
/// Usage modes (controlled by [MapPickerMode]):
/// - delivery: Customer picking delivery address (no radius)
/// - marketplace: Seller setting listing location (no radius)
/// - storeSetup: Merchant setting store location + delivery radius
/// - driverZone: Driver/admin setting service zone + radius
/// - search: User filtering results by area + radius
enum MapPickerMode { delivery, marketplace, storeSetup, driverZone, search }

class UniversalMapPickerScreen extends StatefulWidget {
  final MapPickerMode mode;
  final double? initialLat;
  final double? initialLng;
  final double? initialRadiusKm;
  final String? title;

  const UniversalMapPickerScreen({
    super.key,
    this.mode = MapPickerMode.delivery,
    this.initialLat,
    this.initialLng,
    this.initialRadiusKm,
    this.title,
  });

  @override
  State<UniversalMapPickerScreen> createState() =>
      _UniversalMapPickerScreenState();
}

class _UniversalMapPickerScreenState extends State<UniversalMapPickerScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  final _locationService = LocationService();

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  List<PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  Timer? _debounce;

  double _radiusKm = 5.0;
  bool get _showRadius =>
      widget.mode == MapPickerMode.storeSetup ||
      widget.mode == MapPickerMode.driverZone ||
      widget.mode == MapPickerMode.search;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
    if (widget.initialRadiusKm != null) {
      _radiusKm = widget.initialRadiusKm!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String get _screenTitle {
    if (widget.title != null) return widget.title!;
    switch (widget.mode) {
      case MapPickerMode.delivery:
        return 'Set Delivery Address';
      case MapPickerMode.marketplace:
        return 'Set Item Location';
      case MapPickerMode.storeSetup:
        return 'Set Store Location';
      case MapPickerMode.driverZone:
        return 'Set Service Zone';
      case MapPickerMode.search:
        return 'Set Search Area';
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        _selectLocation(latLng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get current location')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _isLoadingAddress = true;
      _showPredictions = false;
    });

    try {
      final address = await _locationService.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );
      if (mounted) {
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _searchPlaces(String query) async {
    final results = await _locationService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _predictions = results;
        _showPredictions = results.isNotEmpty;
      });
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() {
      _showPredictions = false;
      _searchController.text = prediction.description;
    });
    FocusScope.of(context).unfocus();

    final addr = await _locationService.getPlaceDetails(prediction.placeId);
    if (addr != null && addr.hasCoordinates && mounted) {
      final latLng = LatLng(addr.lat!, addr.lng!);
      setState(() {
        _selectedLocation = latLng;
        _selectedAddress = addr.address;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    }
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap on the map to select a location')));
      return;
    }

    Navigator.pop(
      context,
      UserAddress(
        address: _selectedAddress,
        lat: _selectedLocation!.latitude,
        lng: _selectedLocation!.longitude,
        radiusKm: _showRadius ? _radiusKm : null,
      ),
    );
  }

  Set<Circle> _buildCircles() {
    if (!_showRadius || _selectedLocation == null) return {};
    return {
      Circle(
        circleId: const CircleId('radius'),
        center: _selectedLocation!,
        radius: _radiusKm * 1000,
        fillColor: AppTheme.kjRed.withOpacity(0.1),
        strokeColor: AppTheme.kjRed.withOpacity(0.4),
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryRed = AppTheme.kjRed;

    final initialTarget = _selectedLocation ??
        const LatLng(LocationService.defaultLat, LocationService.defaultLng);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _selectedLocation != null ? 15 : 10,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _selectLocation,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      infoWindow: InfoWindow(
                        title: 'Selected',
                        snippet: _selectedAddress,
                      ),
                    ),
                  }
                : {},
            circles: _buildCircles(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(3.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: theme.iconTheme.color),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                          onChanged: (query) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () => _searchPlaces(query),
                            );
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close,
                              color: theme.colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _showPredictions = false);
                          },
                        ),
                    ],
                  ),
                ),
                if (_showPredictions)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    constraints: BoxConstraints(maxHeight: 30.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(2.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final pred = _predictions[index];
                        return ListTile(
                          leading: Icon(Icons.location_on,
                              color: primaryRed, size: 5.w),
                          title: Text(
                            pred.description,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectPrediction(pred),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(5.w)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _screenTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  if (_selectedLocation != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryRed, size: 6.w),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _isLoadingAddress
                              ? Text('Getting address...',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: theme
                                          .colorScheme.onSurfaceVariant))
                              : Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Tap on the map or search to select a location',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_showRadius && _selectedLocation != null) ...[
                    SizedBox(height: 1.5.h),
                    Row(
                      children: [
                        Icon(Icons.radar, color: primaryRed, size: 5.w),
                        SizedBox(width: 2.w),
                        Text(
                          'Radius: ${_radiusKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 0.5,
                      max: 50.0,
                      divisions: 99,
                      activeColor: primaryRed,
                      label: '${_radiusKm.toStringAsFixed(1)} km',
                      onChanged: (v) => setState(() => _radiusKm = v),
                    ),
                  ],
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null
                          ? _confirmSelection
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.w)),
                      ),
                      child: Text('Confirm Location',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: _showRadius ? 32.h : 22.h,
            right: 4.w,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: theme.colorScheme.surface,
              onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryRed))
                  : Icon(Icons.my_location, color: primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}