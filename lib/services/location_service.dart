import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import '../models/user_address_model.dart';

/// Universal location service used across the entire app.
/// Handles GPS, geocoding, distance calculation, and saved address persistence.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Dio _dio = Dio();

  // API key from --dart-define (no flutter_dotenv needed)
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // Android app signature headers required for Android-restricted API keys.
  static const String _androidPackage = 'com.kjdelivery.app';
  static const String _androidCert =
      'D4:25:EA:15:70:06:20:E6:CD:BE:D1:89:D6:F2:3F:AA:43:2F:AC:35';

  Options get _androidOptions => Options(headers: {
        'X-Android-Package': _androidPackage,
        'X-Android-Cert': _androidCert,
      });

  // Lebanon defaults
  static const double defaultLat = 33.8938;
  static const double defaultLng = 35.5018;

  // Cached current position
  Position? _lastPosition;

  // ============================================================
  // GPS / CURRENT LOCATION
  // ============================================================

  /// Check and request location permissions, return current position.
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('[LOCATION] Checking location service...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LOCATION] Location service NOT enabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LOCATION] Current permission: ' + permission.toString());
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LOCATION] After request: ' + permission.toString());
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LOCATION] Permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      debugPrint('[LOCATION] getCurrentPosition error: ' + e.toString());
      return null;
    }
  }

  /// Get last known position (fast, may be null)
  Position? get lastPosition => _lastPosition;

  // ============================================================
  // GEOCODING - uses device native geocoder (no API billing needed)
  // ============================================================

  /// Reverse geocode lat/lng to formatted address string using device geocoder
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      debugPrint('[GEOCODE] reverseGeocode called: ' + lat.toString() + ', ' + lng.toString());
      final placemarks = await placemarkFromCoordinates(lat, lng);
      debugPrint('[GEOCODE] placemarks count: ' + placemarks.length.toString());
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
        final addr = parts.join(', ');
        debugPrint('[GEOCODE] Success: ' + addr);
        return addr.isNotEmpty ? addr : 'Unknown location';
      }
      debugPrint('[GEOCODE] No placemarks returned');
      return 'Unknown location';
    } catch (e) {
      debugPrint('[GEOCODE] Exception: ' + e.toString());
      return lat.toStringAsFixed(5) + ', ' + lng.toStringAsFixed(5);
    }
  }

  /// Forward geocode address text to lat/lng using device geocoder
  Future<Map<String, double>?> forwardGeocode(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'lat': locations.first.latitude,
          'lng': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('[GEOCODE] forwardGeocode error: ' + e.toString());
      return null;
    }
  }

  // ============================================================
  // PLACES AUTOCOMPLETE - still uses Google API (Places API is enabled)
  // ============================================================

  /// Search places using Google Places Autocomplete (biased to Lebanon)
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    debugPrint('[PLACES] searchPlaces called query=' + query + ' len=' + query.trim().length.toString());
    if (query.trim().length < 2) {
      debugPrint('[PLACES] query too short, returning empty');
      return [];
    }

    try {
      debugPrint('[PLACES] key present: ' + googleApiKey.isNotEmpty.toString() + ' len=' + googleApiKey.length.toString());
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': googleApiKey,
          'components': 'country:lb',
          'language': 'en',
        },
        options: _androidOptions,
      );

      debugPrint('[PLACES] http_status: ' + response.statusCode.toString());
      debugPrint('[PLACES] api_status: ' + (response.data['status'] ?? '').toString());
      if (response.statusCode == 200) {
        final status = response.data['status'] as String?;
        if (status != 'OK') {
          debugPrint('[PLACES] ERROR: ' + status.toString() + ' msg=' + (response.data['error_message'] ?? '').toString());
          return [];
        }
        final predictions = response.data['predictions'] as List?;
        debugPrint('[PLACES] predictions count: ' + (predictions?.length ?? 0).toString());
        if (predictions != null) {
          return predictions
              .map((p) => PlacePrediction(
                    placeId: p['place_id'] as String,
                    description: p['description'] as String,
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[PLACES] searchPlaces error: ' + e.toString());
      return [];
    }
  }

  /// Get place details (lat/lng + formatted address) from place ID
  Future<UserAddress?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry,formatted_address',
          'key': googleApiKey,
        },
        options: _androidOptions,
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        final location = result['geometry']['location'];
        final address = result['formatted_address'] as String? ?? '';

        return UserAddress(
          address: address,
          lat: (location['lat'] as num).toDouble(),
          lng: (location['lng'] as num).toDouble(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[PLACES] getPlaceDetails error: ' + e.toString());
      return null;
    }
  }

  // ============================================================
  // DISTANCE CALCULATION
  // ============================================================

  /// Haversine distance in km between two coordinates (straight-line)
  double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);

  /// Check if a point is within a given radius of a center
  bool isWithinRadius({
    required double centerLat,
    required double centerLng,
    required double pointLat,
    required double pointLng,
    required double radiusKm,
  }) {
    return haversineDistance(centerLat, centerLng, pointLat, pointLng) <=
        radiusKm;
  }

  /// Calculate delivery fee based on distance
  double calculateDeliveryFee({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    double baseFee = 1.00,
    double perKmRate = 0.50,
  }) {
    final distanceKm = haversineDistance(fromLat, fromLng, toLat, toLng);
    final fee = baseFee + (distanceKm * perKmRate);
    return double.parse(fee.toStringAsFixed(2));
  }

  // ============================================================
  // SAVED ADDRESSES (local + Supabase)
  // ============================================================

  /// Load saved addresses from Supabase user record
  Future<List<UserAddress>> loadSavedAddresses() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      final userData = await Supabase.instance.client
          .from('users')
          .select('saved_addresses, address')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return [];

      final savedRaw = userData['saved_addresses'];
      if (savedRaw != null && savedRaw is List) {
        return savedRaw
            .map((a) => UserAddress.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }

      final singleAddress = userData['address'] as String?;
      if (singleAddress != null && singleAddress.isNotEmpty) {
        return [
          UserAddress(
            label: 'HOME',
            address: singleAddress,
            isDefault: true,
          ),
        ];
      }

      return [];
    } catch (e) {
      debugPrint('[LOCATION] loadSavedAddresses error: ' + e.toString());
      return [];
    }
  }

  /// Save addresses to Supabase user record
  Future<void> saveAddresses(List<UserAddress> addresses) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('users').update({
        'saved_addresses': addresses.map((a) => a.toJson()).toList(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[LOCATION] saveAddresses error: ' + e.toString());
    }
  }

  /// Add a new address and persist
  Future<List<UserAddress>> addAddress(UserAddress newAddress) async {
    final existing = await loadSavedAddresses();
    final isDuplicate = existing.any((a) =>
        a.address == newAddress.address && a.label == newAddress.label);
    if (isDuplicate) return existing;
    final addressToAdd = existing.isEmpty
        ? newAddress.copyWith(isDefault: true)
        : newAddress;
    existing.add(addressToAdd);
    await saveAddresses(existing);
    return existing;
  }

  /// Remove an address by index
  Future<List<UserAddress>> removeAddress(int index) async {
    final existing = await loadSavedAddresses();
    if (index >= 0 && index < existing.length) {
      existing.removeAt(index);
      await saveAddresses(existing);
    }
    return existing;
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  static const _prefsKey = 'last_selected_address';

  Future<void> cacheSelectedAddress(UserAddress address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(address.toJson()));
    } catch (e) { debugPrint('[LOCATION_SERVICE] Silent error: $e'); }
  }

  Future<UserAddress?> getCachedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      if (json != null) {
        return UserAddress.fromJson(jsonDecode(json));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Place prediction from Google Places Autocomplete
class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({required this.placeId, required this.description});
}