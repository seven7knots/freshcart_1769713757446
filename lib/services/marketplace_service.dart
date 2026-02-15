import 'dart:io';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../models/service_booking_model.dart';
import '../models/marketplace_listing_model.dart';

class MarketplaceService {
  final SupabaseClient _client = Supabase.instance.client;

  // ========== SERVICES SECTION ==========

  Future<List<ServiceModel>> getServicesByType(
    String type, {
    int limit = 50,
  }) async {
    try {
      print('🔍 Fetching services of type: $type');
      final response = await _client
          .from('services')
          .select()
          .eq('type', type)
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(limit);

      print('✅ Found ${(response as List).length} services');
      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading services: $e');
      throw Exception('Failed to load services: $e');
    }
  }

  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('id', serviceId)
          .maybeSingle();

      if (response == null) return null;
      return ServiceModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get service: $e');
    }
  }

  Future<ServiceBookingModel> createBooking({
    required String serviceId,
    required String providerId,
    required double baseFare,
    required double total,
    DateTime? scheduledTime,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    double? distanceKm,
    int? durationMinutes,
    double? quantity,
    double distanceFare = 0.0,
    double timeFare = 0.0,
    double additionalCharges = 0.0,
    double platformFee = 0.0,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('service_bookings')
          .insert({
            'service_id': serviceId,
            'customer_id': userId,
            'provider_id': providerId,
            'status': 'requested',
            'scheduled_time': scheduledTime?.toIso8601String(),
            'pickup_address': pickupAddress,
            'pickup_lat': pickupLat,
            'pickup_lng': pickupLng,
            'dropoff_address': dropoffAddress,
            'dropoff_lat': dropoffLat,
            'dropoff_lng': dropoffLng,
            'distance_km': distanceKm,
            'duration_minutes': durationMinutes,
            'quantity': quantity,
            'base_fare': baseFare,
            'distance_fare': distanceFare,
            'time_fare': timeFare,
            'additional_charges': additionalCharges,
            'platform_fee': platformFee,
            'total': total,
            'currency': 'USD',
            'payment_method': paymentMethod,
            'payment_status': 'pending',
            'notes': notes,
          })
          .select()
          .single();

      return ServiceBookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<ServiceBookingModel>> getMyBookings({
    String? status,
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query =
          _client.from('service_bookings').select().eq('customer_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => ServiceBookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _client.from('service_bookings').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('service_bookings').update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> rateService(String bookingId, int rating, String? review) async {
    try {
      await _client.from('service_bookings').update({
        'customer_rating': rating,
        'customer_review': review,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to rate service: $e');
    }
  }

  Future<List<ServiceModel>> searchServices(
    String query, {
    String? type,
    int limit = 50,
  }) async {
    try {
      var queryBuilder = _client
          .from('services')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%');

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type);
      }

      final response =
          await queryBuilder.order('rating', ascending: false).limit(limit);

      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search services: $e');
    }
  }

  // ========== MARKETPLACE LISTINGS SECTION ==========

  /// Get listings with filters including location-based filtering.
  ///
  /// If [locationLat] and [locationLng] are provided, filters listings
  /// within [radiusKm] km using a bounding box approach.
  /// If [locationCity] is provided (without lat/lng), matches on location_text.
  Future<List<MarketplaceListingModel>> getListings({
    String? category,
    String? condition,
    int limit = 50,
    int offset = 0,
    double? locationLat,
    double? locationLng,
    String? locationCity,
    double radiusKm = 30,
  }) async {
    try {
      print('🔍 Fetching marketplace listings...');
      print('   Category: ${category ?? "all"}');
      print('   Location: ${locationCity ?? "all"} (${locationLat ?? "no"}, ${locationLng ?? "no"})');

      var query = _client
          .from('marketplace_listings')
          .select()
          .eq('is_active', true)
          .eq('is_sold', false);

      if (category != null) {
        query = query.eq('category', category);
      }
      if (condition != null) {
        query = query.eq('condition', condition);
      }

      // Location filtering using bounding box
      if (locationLat != null && locationLng != null) {
        // Calculate bounding box for radiusKm
        final latDelta = radiusKm / 111.0; // ~111km per degree of latitude
        final lngDelta = radiusKm / (111.0 * math.cos(locationLat * math.pi / 180));

        final minLat = locationLat - latDelta;
        final maxLat = locationLat + latDelta;
        final minLng = locationLng - lngDelta;
        final maxLng = locationLng + lngDelta;

        query = query
            .gte('location_lat', minLat)
            .lte('location_lat', maxLat)
            .gte('location_lng', minLng)
            .lte('location_lng', maxLng);

        print('   Bounding box: lat[$minLat, $maxLat] lng[$minLng, $maxLng]');
      } else if (locationCity != null) {
        // Fallback: match on location_text containing the city name
        query = query.ilike('location_text', '%$locationCity%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('✅ Found ${(response as List).length} listings');

      var listings = (response as List)
          .map((json) => MarketplaceListingModel.fromJson(json))
          .toList();

      // If lat/lng filtering was used, sort by distance (nearest first)
      if (locationLat != null && locationLng != null) {
        listings.sort((a, b) {
          final distA = _haversine(locationLat, locationLng,
              a.locationLat ?? 0, a.locationLng ?? 0);
          final distB = _haversine(locationLat, locationLng,
              b.locationLat ?? 0, b.locationLng ?? 0);
          return distA.compareTo(distB);
        });
      }

      return listings;
    } catch (e) {
      print('❌ Error loading listings: $e');
      throw Exception('Failed to load listings: $e');
    }
  }

  /// Haversine distance in km
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<MarketplaceListingModel?> getListingById(String listingId) async {
    try {
      final response = await _client
          .from('marketplace_listings')
          .select()
          .eq('id', listingId)
          .maybeSingle();

      if (response == null) return null;
      return MarketplaceListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get listing: $e');
    }
  }

  Future<MarketplaceListingModel> createListing({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> imageUrls,
    String? locationText,
    double? locationLat,
    double? locationLng,
    bool isNegotiable = true,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('marketplace_listings')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'price': price,
            'currency': 'USD',
            'category': category,
            'condition': condition,
            'images': imageUrls,
            'location_text': locationText,
            'location_lat': locationLat,
            'location_lng': locationLng,
            'is_negotiable': isNegotiable,
            'is_sold': false,
            'is_active': true,
          })
          .select()
          .single();

      return MarketplaceListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('marketplace_listings').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', listingId);
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _client.from('marketplace_listings').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', listingId);
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  Future<void> markAsSold(String listingId) async {
    try {
      await _client.from('marketplace_listings').update({
        'is_sold': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', listingId);
    } catch (e) {
      throw Exception('Failed to mark as sold: $e');
    }
  }

  Future<List<MarketplaceListingModel>> getMyListings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('marketplace_listings')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MarketplaceListingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load my listings: $e');
    }
  }

  Future<void> incrementViews(String listingId) async {
    try {
      await _client.rpc(
        'increment_listing_views',
        params: {'listing_id': listingId},
      );
    } catch (e) {
      try {
        final listing = await getListingById(listingId);
        if (listing != null) {
          await _client
              .from('marketplace_listings')
              .update({'views': listing.views + 1}).eq('id', listingId);
        }
      } catch (_) {}
    }
  }

  // ========== STORAGE SECTION ==========

  Future<String> uploadImage(File file) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await _client.storage.from('marketplace-images').upload(fileName, file);

      return _client.storage.from('marketplace-images').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadImages(List<File> files) async {
    try {
      final urls = <String>[];
      for (final file in files) {
        final url = await uploadImage(file);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }
}