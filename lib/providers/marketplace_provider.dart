import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../models/service_booking_model.dart';
import '../models/marketplace_listing_model.dart';
import '../services/marketplace_service.dart';

// Service provider
final marketplaceServiceProvider = Provider((ref) => MarketplaceService());

// Marketplace tab state (0 = Services, 1 = Products)
final marketplaceTabProvider = StateProvider<int>((ref) => 0);

// Services by type
final servicesByTypeProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, type) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getServicesByType(type);
});

// Service detail
final serviceDetailProvider =
    FutureProvider.family<ServiceModel?, String>((ref, serviceId) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getServiceById(serviceId);
});

// My bookings
final myBookingsProvider =
    FutureProvider.family<List<ServiceBookingModel>, String?>(
        (ref, status) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getMyBookings(status: status);
});

// Marketplace listings with filters
final listingsProvider =
    FutureProvider.family<List<MarketplaceListingModel>, Map<String, dynamic>>(
        (ref, filters) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getListings(
    category: filters['category'] as String?,
    condition: filters['condition'] as String?,
    limit: filters['limit'] as int? ?? 50,
    offset: filters['offset'] as int? ?? 0,
  );
});

// Listing detail
final listingDetailProvider =
    FutureProvider.family<MarketplaceListingModel?, String>(
        (ref, listingId) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getListingById(listingId);
});

// My listings
final myListingsProvider =
    FutureProvider<List<MarketplaceListingModel>>((ref) async {
  final service = ref.watch(marketplaceServiceProvider);
  return await service.getMyListings();
});

// Selected filters state
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedConditionProvider = StateProvider<String?>((ref) => null);
