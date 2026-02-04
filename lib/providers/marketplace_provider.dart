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

String? _normalizeCategoryFilter(dynamic rawCategory) {
  if (rawCategory == null) return null;

  // Special cases used by CategoryListingsScreen
  if (rawCategory is String) {
    final v = rawCategory.trim();
    if (v.isEmpty) return null;
    if (v.toLowerCase() == 'all') return null; // "See All"
    return v;
  }

  // Home CategoriesWidget sends int ids (Restaurants/Convenience/Pharmacies/etc.)
  if (rawCategory is int) {
    switch (rawCategory) {
      case 1:
        return 'restaurants';
      case 2:
        return 'convenience';
      case 3:
        return 'pharmacies';
      case 4:
        return 'marketplace';
      default:
        // Fallback: keep stable behavior without crashing
        return rawCategory.toString();
    }
  }

  // Fallback: avoid runtime cast errors
  return rawCategory.toString();
}

// Marketplace listings with filters
final listingsProvider =
    FutureProvider.family<List<MarketplaceListingModel>, Map<String, dynamic>>(
        (ref, filters) async {
  final service = ref.watch(marketplaceServiceProvider);

  final category = _normalizeCategoryFilter(filters['category']);
  final condition = filters['condition'] as String?;
  final limit = filters['limit'] as int? ?? 50;
  final offset = filters['offset'] as int? ?? 0;

  return service.getListings(
    category: category,
    condition: condition,
    limit: limit,
    offset: offset,
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
