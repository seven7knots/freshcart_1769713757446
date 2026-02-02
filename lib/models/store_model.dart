class StoreModel {
  final String id;
  final String merchantId;
  final String name;
  final String? nameAr;
  final String? category;
  final String? description;
  final String? descriptionAr;
  final String? imageUrl;
  final String? bannerUrl;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final bool isActive;
  final bool isFeatured;
  final double minimumOrder;
  final int averagePrepTimeMinutes;
  final double? deliveryFeeOverride;
  final double rating;
  final int totalReviews;
  final Map<String, dynamic>? operatingHours;
  final bool isAcceptingOrders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoreModel({
    required this.id,
    required this.merchantId,
    required this.name,
    this.nameAr,
    this.category,
    this.description,
    this.descriptionAr,
    this.imageUrl,
    this.bannerUrl,
    this.address,
    this.locationLat,
    this.locationLng,
    this.isActive = true,
    this.isFeatured = false,
    this.minimumOrder = 0.0,
    this.averagePrepTimeMinutes = 30,
    this.deliveryFeeOverride,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.operatingHours,
    this.isAcceptingOrders = true,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      merchantId: json['merchant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['name_ar'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      address: json['address'] as String?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      minimumOrder: (json['minimum_order'] as num?)?.toDouble() ?? 0.0,
      averagePrepTimeMinutes: json['average_prep_time_minutes'] as int? ?? 30,
      deliveryFeeOverride: (json['delivery_fee_override'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      operatingHours: json['operating_hours'] as Map<String, dynamic>?,
      isAcceptingOrders: json['is_accepting_orders'] as bool? ?? true,
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
      'merchant_id': merchantId,
      'name': name,
      'name_ar': nameAr,
      'category': category,
      'description': description,
      'description_ar': descriptionAr,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'address': address,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'is_active': isActive,
      'is_featured': isFeatured,
      'minimum_order': minimumOrder,
      'average_prep_time_minutes': averagePrepTimeMinutes,
      'delivery_fee_override': deliveryFeeOverride,
      'rating': rating,
      'total_reviews': totalReviews,
      'operating_hours': operatingHours,
      'is_accepting_orders': isAcceptingOrders,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
