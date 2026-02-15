// ============================================================
// FILE: lib/presentation/marketplace_home_screen/widgets/marketplace_location_picker.dart
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Result returned from the location picker
class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
  });
}

class MarketplaceLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const MarketplaceLocationPicker({super.key, this.initialLocation});

  @override
  State<MarketplaceLocationPicker> createState() => _MarketplaceLocationPickerState();
}

class _MarketplaceLocationPickerState extends State<MarketplaceLocationPicker> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late LatLng _selectedLocation;
  String _selectedAddress = '';
  String? _selectedCity;
  bool _isLoadingAddress = false;
  bool _isLoadingGps = false;

  List<Map<String, dynamic>> _searchResults = [];

  // Comprehensive Lebanon locations
  static const List<Map<String, dynamic>> _allLocations = [
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
  ];

  static const List<Map<String, dynamic>> _quickCities = [
    {'name': 'Beirut', 'lat': 33.8938, 'lng': 35.5018},
    {'name': 'Tripoli', 'lat': 34.4367, 'lng': 35.8497},
    {'name': 'Saida', 'lat': 33.5633, 'lng': 35.3756},
    {'name': 'Jounieh', 'lat': 33.9808, 'lng': 35.6178},
    {'name': 'Tyre', 'lat': 33.2705, 'lng': 35.2038},
    {'name': 'Baalbek', 'lat': 34.0047, 'lng': 36.2110},
    {'name': 'Zahle', 'lat': 33.8463, 'lng': 35.9020},
    {'name': 'Batroun', 'lat': 34.2559, 'lng': 35.6586},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(33.8938, 35.5018);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (latLng) => _updateLocation(latLng),
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (newPos) => _updateLocation(newPos),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top: Search bar
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search city, area, or address...',
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14.sp),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            ),
                        ],
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(maxHeight: 30.h),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final r = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on, color: AppTheme.kjRed, size: 20),
                                title: Text(r['name'] ?? '', style: TextStyle(fontSize: 13.sp)),
                                subtitle: r['sub'] != null ? Text(r['sub'], style: TextStyle(fontSize: 10.sp)) : null,
                                onTap: () => _selectResult(r),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // Quick city chips
                if (_searchResults.isEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: 5.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickCities.length,
                      itemBuilder: (context, index) {
                        final city = _quickCities[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 2.w),
                          child: ActionChip(
                            label: Text(city['name'] as String, style: TextStyle(fontSize: 11.sp)),
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                            onPressed: () {
                              final ll = LatLng(city['lat'] as double, city['lng'] as double);
                              setState(() {
                                _selectedLocation = ll;
                                _selectedCity = city['name'] as String;
                                _selectedAddress = '${city['name']}, Lebanon';
                              });
                              _animateTo(ll, zoom: 14);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom: Address + confirm
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, -3))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Icon(Icons.location_on, color: AppTheme.kjRed, size: 24),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_selectedCity ?? 'Select Location',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          if (_isLoadingAddress)
                            SizedBox(height: 2.h, child: const LinearProgressIndicator())
                          else
                            Text(
                              _selectedAddress.isNotEmpty ? _selectedAddress : 'Tap on map or search to select',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                        ]),
                      ),
                    ]),
                    SizedBox(height: 2.h),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingGps ? null : _useMyLocation,
                          icon: _isLoadingGps
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kjRed))
                              : Icon(Icons.my_location, color: AppTheme.kjRed, size: 18),
                          label: Text('My Location', style: TextStyle(fontSize: 12.sp, color: AppTheme.kjRed)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.kjRed),
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text('Confirm Location', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kjRed, foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        final q = query.toLowerCase();
        final matches = _allLocations.where((loc) {
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
    setState(() {
      _selectedLocation = ll;
      _selectedCity = result['name'] as String;
      _selectedAddress = '${result['name']}, ${result['sub'] ?? 'Lebanon'}';
      _searchResults = [];
    });
    _searchController.text = result['name'] as String;
    _animateTo(ll, zoom: 14);
    FocusScope.of(context).unfocus();
  }

  // ============================================================
  // MAP
  // ============================================================

  void _updateLocation(LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _reverseGeocode(latLng);
  }

  void _animateTo(LatLng ll, {double zoom = 14}) {
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: ll, zoom: zoom)));
  }

  void _reverseGeocode(LatLng latLng) {
    setState(() => _isLoadingAddress = true);

    // Find nearest known location
    double minDist = double.infinity;
    String nearestName = '';

    for (final loc in _allLocations) {
      final dist = _haversine(latLng.latitude, latLng.longitude, loc['lat'] as double, loc['lng'] as double);
      if (dist < minDist) {
        minDist = dist;
        nearestName = loc['name'] as String;
      }
    }

    setState(() {
      if (minDist < 10) {
        _selectedCity = nearestName;
        _selectedAddress = '$nearestName, Lebanon';
      } else {
        _selectedCity = 'Custom Location';
        _selectedAddress = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
      }
      _isLoadingAddress = false;
    });
  }

  /// Haversine distance in km
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // ============================================================
  // GPS
  // ============================================================

  Future<void> _useMyLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.red));
          setState(() => _isLoadingGps = false);
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permanently denied. Enable in settings.'), backgroundColor: Colors.red));
        setState(() => _isLoadingGps = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final ll = LatLng(pos.latitude, pos.longitude);
      _updateLocation(ll);
      _animateTo(ll, zoom: 15);
      if (mounted) HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _confirmLocation() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, LocationPickerResult(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      address: _selectedAddress,
      city: _selectedCity,
    ));
  }
}