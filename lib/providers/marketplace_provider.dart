import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/marketplace_listing_model.dart';
import '../models/service_booking_model.dart';
import '../models/service_model.dart';
import '../services/marketplace_service.dart';

// Service provider
final marketplaceServiceProvider = Provider<MarketplaceService>((ref) {
  return MarketplaceService();
});

// Marketplace tab state (0 = Services, 1 = Products)
final marketplaceTabProvider = StateProvider<int>((ref) => 0);

// ============================================================
// LOCATION STATE
// ============================================================

/// Selected marketplace location (city name, null = "All Lebanon")
final marketplaceLocationCityProvider = StateProvider<String?>((ref) => null);

/// Selected marketplace latitude
final marketplaceLocationLatProvider = StateProvider<double?>((ref) => null);

/// Selected marketplace longitude
final marketplaceLocationLngProvider = StateProvider<double?>((ref) => null);

/// Selected marketplace address display text
final marketplaceLocationAddressProvider = StateProvider<String>((ref) => 'All Lebanon');

// ============================================================
// SERVICES
// ============================================================

// Services by type
final servicesByTypeProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, type) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getServicesByType(type);
});

// Service detail
final serviceDetailProvider =
    FutureProvider.family<ServiceModel?, String>((ref, serviceId) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getServiceById(serviceId);
});

// My bookings
final myBookingsProvider =
    FutureProvider.family<List<ServiceBookingModel>, String?>(
        (ref, status) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getMyBookings(status: status);
});

/// Normalize category filter for marketplace listings ONLY.
String? _normalizeCategoryFilter(dynamic rawCategory) {
  if (rawCategory == null) return null;

  if (rawCategory is String) {
    final v = rawCategory.trim();
    if (v.isEmpty) return null;
    if (v.toLowerCase() == 'all') return null;
    return v;
  }

  if (rawCategory is int) {
    return null;
  }

  return rawCategory.toString();
}

// ============================================================
// MARKETPLACE LISTINGS WITH LOCATION FILTER
// ============================================================

final listingsProvider =
    FutureProvider.family<List<MarketplaceListingModel>, Map<String, dynamic>>(
        (ref, filters) async {
  final service = ref.watch(marketplaceServiceProvider);

  final category = _normalizeCategoryFilter(filters['category']);
  final condition = filters['condition'] as String?;
  final limit = filters['limit'] as int? ?? 50;
  final offset = filters['offset'] as int? ?? 0;

  // Location filter from provider state
  final locationLat = ref.watch(marketplaceLocationLatProvider);
  final locationLng = ref.watch(marketplaceLocationLngProvider);
  final locationCity = ref.watch(marketplaceLocationCityProvider);

  return service.getListings(
    category: category,
    condition: condition,
    limit: limit,
    offset: offset,
    locationLat: locationLat,
    locationLng: locationLng,
    locationCity: locationCity,
    radiusKm: 30, // 30km radius for nearby listings
  );
});

// Listing detail
final listingDetailProvider =
    FutureProvider.family<MarketplaceListingModel?, String>(
        (ref, listingId) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getListingById(listingId);
});

// My listings
final myListingsProvider =
    FutureProvider<List<MarketplaceListingModel>>((ref) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.getMyListings();
});

// Selected filters state
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedConditionProvider = StateProvider<String?>((ref) => null);