import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../models/user_address_model.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

enum MapPickerMode { delivery, marketplace, storeSetup, driverZone, search }

const List<Map<String, dynamic>> _kLebanonLocations = [
  {'name': 'Beirut', 'sub': 'Capital, Lebanon', 'lat': 33.8938, 'lng': 35.5018},
  {'name': 'Tripoli', 'sub': 'North Lebanon', 'lat': 34.4367, 'lng': 35.8497},
  {'name': 'Saida (Sidon)', 'sub': 'South Lebanon', 'lat': 33.5633, 'lng': 35.3756},
  {'name': 'Jounieh', 'sub': 'Mount Lebanon', 'lat': 33.9808, 'lng': 35.6178},
  {'name': 'Byblos (Jbeil)', 'sub': 'Mount Lebanon', 'lat': 34.1236, 'lng': 35.6511},
  {'name': 'Tyre', 'sub': 'South Lebanon', 'lat': 33.2705, 'lng': 35.2038},
  {'name': 'Baalbek', 'sub': 'Beqaa Valley', 'lat': 34.0047, 'lng': 36.2110},
  {'name': 'Zahle', 'sub': 'Beqaa Valley', 'lat': 33.8463, 'lng': 35.9020},
  {'name': 'Nabatieh', 'sub': 'South Lebanon', 'lat': 33.3772, 'lng': 35.4836},
  {'name': 'Aley', 'sub': 'Mount Lebanon', 'lat': 33.8167, 'lng': 35.6000},
  {'name': 'Achrafieh', 'sub': 'Beirut', 'lat': 33.8886, 'lng': 35.5170},
  {'name': 'Hamra', 'sub': 'Beirut', 'lat': 33.8959, 'lng': 35.4840},
  {'name': 'Verdun', 'sub': 'Beirut', 'lat': 33.8850, 'lng': 35.4800},
  {'name': 'Gemmayzeh', 'sub': 'Beirut', 'lat': 33.8920, 'lng': 35.5130},
  {'name': 'Mar Mikhael', 'sub': 'Beirut', 'lat': 33.8890, 'lng': 35.5200},
  {'name': 'Ras Beirut', 'sub': 'Beirut', 'lat': 33.9000, 'lng': 35.4780},
  {'name': 'Badaro', 'sub': 'Beirut', 'lat': 33.8750, 'lng': 35.5100},
  {'name': 'Raouche', 'sub': 'Beirut', 'lat': 33.8980, 'lng': 35.4700},
  {'name': 'Tariq el Jdideh', 'sub': 'Beirut', 'lat': 33.8750, 'lng': 35.4900},
  {'name': 'Baabda', 'sub': 'Mount Lebanon', 'lat': 33.8339, 'lng': 35.5444},
  {'name': 'Beit Mery', 'sub': 'Mount Lebanon', 'lat': 33.8578, 'lng': 35.5869},
  {'name': 'Broummana', 'sub': 'Mount Lebanon', 'lat': 33.8750, 'lng': 35.6383},
  {'name': 'Bikfaya', 'sub': 'Mount Lebanon', 'lat': 33.9267, 'lng': 35.6450},
  {'name': 'Antelias', 'sub': 'Mount Lebanon', 'lat': 33.9150, 'lng': 35.5900},
  {'name': 'Dbayeh', 'sub': 'Mount Lebanon', 'lat': 33.9217, 'lng': 35.5783},
  {'name': 'Kaslik', 'sub': 'Mount Lebanon', 'lat': 33.9700, 'lng': 35.6100},
  {'name': 'Harissa', 'sub': 'Mount Lebanon', 'lat': 33.9800, 'lng': 35.6350},
  {'name': 'Faraya', 'sub': 'Mount Lebanon', 'lat': 34.0000, 'lng': 35.8167},
  {'name': 'Ehden', 'sub': 'North Lebanon', 'lat': 34.3000, 'lng': 35.9833},
  {'name': 'Bsharri', 'sub': 'North Lebanon', 'lat': 34.2500, 'lng': 36.0167},
  {'name': 'Batroun', 'sub': 'North Lebanon', 'lat': 34.2559, 'lng': 35.6586},
  {'name': 'Chouf', 'sub': 'Mount Lebanon', 'lat': 33.7000, 'lng': 35.5833},
  {'name': 'Deir el Qamar', 'sub': 'Mount Lebanon', 'lat': 33.6972, 'lng': 35.5617},
  {'name': 'Beiteddine', 'sub': 'Mount Lebanon', 'lat': 33.6942, 'lng': 35.5733},
  {'name': 'Chtaura', 'sub': 'Beqaa Valley', 'lat': 33.8167, 'lng': 35.8500},
  {'name': 'Aanjar', 'sub': 'Beqaa Valley', 'lat': 33.7333, 'lng': 35.9333},
  {'name': 'Bint Jbeil', 'sub': 'South Lebanon', 'lat': 33.1167, 'lng': 35.4333},
  {'name': 'Marjayoun', 'sub': 'South Lebanon', 'lat': 33.3617, 'lng': 35.5917},
  {'name': 'Jezzine', 'sub': 'South Lebanon', 'lat': 33.5333, 'lng': 35.5833},
  {'name': 'Douma', 'sub': 'North Lebanon', 'lat': 34.1833, 'lng': 35.8667},
  {'name': 'Chekka', 'sub': 'North Lebanon', 'lat': 34.3167, 'lng': 35.7167},
  {'name': 'Halba', 'sub': 'North Lebanon', 'lat': 34.5500, 'lng': 36.0833},
  {'name': 'Zgharta', 'sub': 'North Lebanon', 'lat': 34.3833, 'lng': 35.8833},
  {'name': 'Hermel', 'sub': 'Beqaa Valley', 'lat': 34.3944, 'lng': 36.3861},
  {'name': 'Hazmieh', 'sub': 'Mount Lebanon', 'lat': 33.8614, 'lng': 35.5500},
  {'name': 'Sin el Fil', 'sub': 'Mount Lebanon', 'lat': 33.8883, 'lng': 35.5533},
  {'name': 'Dekwaneh', 'sub': 'Mount Lebanon', 'lat': 33.8933, 'lng': 35.5600},
  {'name': 'Dora', 'sub': 'Mount Lebanon', 'lat': 33.9017, 'lng': 35.5650},
  {'name': 'Bourj Hammoud', 'sub': 'Mount Lebanon', 'lat': 33.8950, 'lng': 35.5450},
  {'name': 'Jal el Dib', 'sub': 'Mount Lebanon', 'lat': 33.9100, 'lng': 35.5750},
  {'name': 'Zalka', 'sub': 'Mount Lebanon', 'lat': 33.9067, 'lng': 35.5717},
  {'name': 'Khalde', 'sub': 'Mount Lebanon', 'lat': 33.7950, 'lng': 35.4833},
  {'name': 'Damour', 'sub': 'Mount Lebanon', 'lat': 33.7167, 'lng': 35.4500},
  {'name': 'Bhamdoun', 'sub': 'Mount Lebanon', 'lat': 33.7950, 'lng': 35.6500},
  {'name': 'Sofar', 'sub': 'Mount Lebanon', 'lat': 33.7750, 'lng': 35.7167},
];

const List<Map<String, dynamic>> _kQuickCities = [
  {'name': 'Beirut', 'lat': 33.8938, 'lng': 35.5018},
  {'name': 'Tripoli', 'lat': 34.4367, 'lng': 35.8497},
  {'name': 'Jounieh', 'lat': 33.9808, 'lng': 35.6178},
  {'name': 'Saida', 'lat': 33.5633, 'lng': 35.3756},
  {'name': 'Zahle', 'lat': 33.8463, 'lng': 35.9020},
  {'name': 'Batroun', 'lat': 34.2559, 'lng': 35.6586},
];

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
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  double _radiusKm = 5.0;
  bool _myLocationEnabled = false;

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
    _checkLocationPermission();
  }

  /// Check if location permission is already granted.
  /// If yes, enable the blue dot immediately. If not, wait for the
  /// user to tap the "my location" FAB which triggers the request.
  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (mounted) setState(() => _myLocationEnabled = true);
      }
    } catch (_) {
      // Geolocator not available — leave disabled
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (query.trim().length >= 2) {
        final q = query.toLowerCase();
        final matches = _kLebanonLocations.where((loc) {
          final name = (loc['name'] as String).toLowerCase();
          final sub = (loc['sub'] as String?)?.toLowerCase() ?? '';
          return name.contains(q) || sub.contains(q);
        }).toList();
        setState(() => _searchResults = matches);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  void _selectResult(Map<String, dynamic> result) {
    final ll = LatLng(result['lat'] as double, result['lng'] as double);
    final label = '${result['name']}, ${result['sub'] ?? AppLocalizations.of(context)!.lebanon}';
    setState(() {
      _selectedLocation = ll;
      _selectedAddress = label;
      _searchResults = [];
    });
    _searchController.text = result['name'] as String;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 14));
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _isLoadingAddress = true;
      _searchResults = [];
    });
    _searchController.clear();
    try {
      final address = await _locationService
          .reverseGeocode(latLng.latitude, latLng.longitude)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      // TimeoutException on cold connection or network error
      // — fall back to raw coordinates so the user isn't stuck
      debugPrint('[MAP] reverseGeocode failed/timed out: $e');
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        // Permission was granted — enable blue dot
        if (!_myLocationEnabled) setState(() => _myLocationEnabled = true);
        await _selectLocation(latLng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.couldNotGetCurrentLocation, maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.tapOnTheMapToSelect, maxLines: 1, overflow: TextOverflow.ellipsis)));
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
    const primaryRed = AppTheme.kjRed;
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final dividerColor = theme.dividerColor;
    final initialTarget = _selectedLocation ??
        const LatLng(
            LocationService.defaultLat, LocationService.defaultLng);

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP: direct Stack child — fills stack naturally ──
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
                        title: AppLocalizations.of(context)!.selected,
                        snippet: _selectedAddress,
                      ),
                    ),
                  }
                : {},
            circles: _buildCircles(),
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── TOP: search bar + results ─────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 1.h),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(14),
                    color: cardColor,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                                color: onSurface),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.searchCityOrArea,
                              hintStyle:
                                  TextStyle(color: onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close,
                                color: onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Search results
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      color: cardColor,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: 30.h),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: dividerColor),
                            itemBuilder: (context, index) {
                              final r = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                    Icons.location_on,
                                    color: primaryRed,
                                    size: 20),
                                title: Text(
                                  r['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: onSurface,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: r['sub'] != null
                                    ? Text(r['sub'],
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : null,
                                onTap: () => _selectResult(r),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                // Quick city chips
                if (_searchResults.isEmpty)
                  SizedBox(
                    height: 5.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: _kQuickCities.length,
                      itemBuilder: (context, index) {
                        final city = _kQuickCities[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 2.w),
                          child: Material(
                            elevation: 2,
                            borderRadius:
                                BorderRadius.circular(20),
                            color: cardColor,
                            child: ActionChip(
                              label: Text(
                                  city['name'] as String,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                              backgroundColor: cardColor,
                              side: BorderSide(
                                  color: dividerColor),
                              onPressed: () {
                                final ll = LatLng(
                                    city['lat'] as double,
                                    city['lng'] as double);
                                setState(() {
                                  _selectedLocation = ll;
                                  _selectedAddress =
                                      '${city['name']}, Lebanon';
                                  _searchResults = [];
                                });
                                _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                        ll, 13));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── FAB: my location ─────────────────────────────────
          Positioned(
            bottom: _showRadius ? 32.h : 23.h,
            right: 4.w,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: cardColor,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isLoadingLocation
                    ? null
                    : _goToCurrentLocation,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryRed))
                      : const Icon(Icons.my_location,
                          color: primaryRed, size: 22),
                ),
              ),
            ),
          ),

          // ── BOTTOM: address + confirm ─────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 12,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              color: cardColor,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 10.w,
                          height: 4,
                          decoration: BoxDecoration(
                            color: dividerColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      Text(
                        _screenTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: primaryRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingAddress
                                ? Text(
                                    AppLocalizations.of(context)!.gettingAddress,
                                    style: TextStyle(
                                        color: onSurfaceVariant,
                                        fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)
                                : Text(
                                    _selectedLocation != null &&
                                            _selectedAddress
                                                .isNotEmpty
                                        ? _selectedAddress
                                        : AppLocalizations.of(context)!.tapTheMapOrSearchTo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          _selectedLocation != null
                                              ? onSurface
                                              : onSurfaceVariant,
                                      fontWeight:
                                          _selectedLocation != null
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      if (_showRadius &&
                          _selectedLocation != null) ...[
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            const Icon(Icons.radar,
                                color: primaryRed, size: 18),
                            const SizedBox(width: 8),
                            Flexible(child: Text(
                              'Radius: ${_radiusKm.toStringAsFixed(1)} km',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 0.5,
                          max: 50.0,
                          divisions: 99,
                          activeColor: primaryRed,
                          label:
                              '${_radiusKm.toStringAsFixed(1)} km',
                          onChanged: (v) =>
                              setState(() => _radiusKm = v),
                        ),
                      ],
                      SizedBox(height: 1.5.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _selectedLocation != null
                              ? _confirmSelection
                              : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            AppLocalizations.of(context)!.confirmLocation,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.grey.shade300,
                            disabledForegroundColor:
                                Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}