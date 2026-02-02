class ServiceModel {
  final String id;
  final String type;
  final String providerId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final double basePrice;
  final String currency;
  final double? pricePerKm;
  final double? pricePerHour;
  final double? pricePerUnit;
  final String? unitName;
  final String? unitNameAr;
  final double minBookingHours;
  final Map<String, dynamic>? availability;
  final Map<String, dynamic>? serviceArea;
  final List<String> images;
  final double rating;
  final int totalBookings;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.type,
    required this.providerId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.basePrice,
    this.currency = 'USD',
    this.pricePerKm,
    this.pricePerHour,
    this.pricePerUnit,
    this.unitName,
    this.unitNameAr,
    this.minBookingHours = 1.0,
    this.availability,
    this.serviceArea,
    this.images = const [],
    this.rating = 5.0,
    this.totalBookings = 0,
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      type: json['type'] as String,
      providerId: json['provider_id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      pricePerKm: json['price_per_km'] != null
          ? (json['price_per_km'] as num).toDouble()
          : null,
      pricePerHour: json['price_per_hour'] != null
          ? (json['price_per_hour'] as num).toDouble()
          : null,
      pricePerUnit: json['price_per_unit'] != null
          ? (json['price_per_unit'] as num).toDouble()
          : null,
      unitName: json['unit_name'] as String?,
      unitNameAr: json['unit_name_ar'] as String?,
      minBookingHours: json['min_booking_hours'] != null
          ? (json['min_booking_hours'] as num).toDouble()
          : 1.0,
      availability: json['availability'] as Map<String, dynamic>?,
      serviceArea: json['service_area'] as Map<String, dynamic>?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 5.0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'provider_id': providerId,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'base_price': basePrice,
      'currency': currency,
      'price_per_km': pricePerKm,
      'price_per_hour': pricePerHour,
      'price_per_unit': pricePerUnit,
      'unit_name': unitName,
      'unit_name_ar': unitNameAr,
      'min_booking_hours': minBookingHours,
      'availability': availability,
      'service_area': serviceArea,
      'images': images,
      'rating': rating,
      'total_bookings': totalBookings,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
