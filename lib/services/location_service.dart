import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  // Configure your Google Maps API key here (same as AndroidManifest.xml)
  static const String googleApiKey = 'AIzaSyCXDutfJxPiziGezC4GXLIsOQKaTWU5vCA';

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      debugPrint('LocationService: getCurrentPosition error: $e');
      return null;
    }
  }

  /// Get last known position (fast, may be null)
  Position? get lastPosition => _lastPosition;

  // ============================================================
  // GEOCODING
  // ============================================================

  /// Reverse geocode lat/lng → formatted address string
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': googleApiKey,
          'language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['formatted_address'] as String? ?? 'Unknown';
        }
      }
      return 'Unknown location';
    } catch (e) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
  }

  /// Forward geocode address text → lat/lng (first result)
  Future<Map<String, double>?> forwardGeocode(String address) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': address,
          'key': googleApiKey,
          'components': 'country:LB',
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          return {
            'lat': (location['lat'] as num).toDouble(),
            'lng': (location['lng'] as num).toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PLACES AUTOCOMPLETE
  // ============================================================

  /// Search places using Google Places Autocomplete (biased to Lebanon)
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': googleApiKey,
          'components': 'country:lb',
          'language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List?;
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
  /// baseFee + (distance * perKmRate)
  double calculateDeliveryFee({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    double baseFee = 1.00,
    double perKmRate = 0.50,
  }) {
    final distanceKm =
        haversineDistance(fromLat, fromLng, toLat, toLng);
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

      // Fallback: single address field
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
      debugPrint('LocationService: loadSavedAddresses error: $e');
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
      debugPrint('LocationService: saveAddresses error: $e');
    }
  }

  /// Add a new address and persist
  Future<List<UserAddress>> addAddress(UserAddress newAddress) async {
    final existing = await loadSavedAddresses();

    // Check for duplicates
    final isDuplicate = existing.any((a) =>
        a.address == newAddress.address && a.label == newAddress.label);
    if (isDuplicate) return existing;

    // If first address, make it default
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
  // LOCAL CACHE (for quick access within session)
  // ============================================================

  static const _prefsKey = 'last_selected_address';

  /// Cache the user's last selected delivery location locally
  Future<void> cacheSelectedAddress(UserAddress address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(address.toJson()));
    } catch (_) {}
  }

  /// Get the cached last-selected address
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