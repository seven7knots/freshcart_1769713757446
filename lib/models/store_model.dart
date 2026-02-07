// ============================================================
// FILE: lib/models/store_model.dart
// ============================================================
// Store model matching database schema
// ============================================================

class Store {
  final String id;
  final String? merchantId;
  final String? ownerUserId;
  final String name;
  final String? nameAr;
  final String? category; // Category name/type
  final String? description;
  final String? descriptionAr;
  final String? imageUrl;
  final String? bannerUrl;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final bool isActive;
  final bool isFeatured;
  final double? minimumOrder;
  final int? averagePrepTimeMinutes;
  final double? deliveryFeeOverride;
  final double rating;
  final int totalReviews;
  final Map<String, dynamic>? operatingHours;
  final bool isAcceptingOrders;
  final bool isDemo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested data (populated when joining)
  final String? categoryName;
  final String? merchantName;
  final int? productCount;

  Store({
    required this.id,
    this.merchantId,
    this.ownerUserId,
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
    this.minimumOrder,
    this.averagePrepTimeMinutes,
    this.deliveryFeeOverride,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.operatingHours,
    this.isAcceptingOrders = true,
    this.isDemo = false,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.merchantName,
    this.productCount,
  });

  /// Get display name (Arabic if available)
  String getDisplayName({bool preferArabic = false}) {
    if (preferArabic && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  /// Get display description
  String? getDisplayDescription({bool preferArabic = false}) {
    if (preferArabic && descriptionAr != null && descriptionAr!.isNotEmpty) {
      return descriptionAr;
    }
    return description;
  }

  /// Has location data?
  bool get hasLocation => locationLat != null && locationLng != null;

  /// Format rating for display
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Format prep time for display
  String get prepTimeDisplay {
    if (averagePrepTimeMinutes == null) return 'N/A';
    if (averagePrepTimeMinutes! < 60) return '$averagePrepTimeMinutes min';
    final hours = averagePrepTimeMinutes! ~/ 60;
    final mins = averagePrepTimeMinutes! % 60;
    return mins > 0 ? '$hours h $mins min' : '$hours h';
  }

  /// Can receive orders?
  bool get canReceiveOrders => isActive && isAcceptingOrders;

  factory Store.fromMap(Map<String, dynamic> map) {
    // Handle nested category data
    //
    // Supports BOTH shapes:
    // 1) Old:   categories: { name: ... }
    // 2) New:   category: { name: ... }, subcategory: { name: ... }
    String? categoryName;

    if (map['category'] != null && map['category'] is Map) {
      final cat = map['category'] as Map;
      categoryName = cat['name'] as String?;
    } else if (map['categories'] != null && map['categories'] is Map) {
      final cat = map['categories'] as Map;
      categoryName = cat['name'] as String?;
    }

    // Handle nested merchant data
    String? merchantName;
    if (map['merchants'] != null && map['merchants'] is Map) {
      merchantName = map['merchants']['business_name'] as String?;
    }

    return Store(
      id: map['id'] as String,
      merchantId: map['merchant_id'] as String?,
      ownerUserId: map['owner_user_id'] as String?,
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String?,
      category: map['category'] as String?,
      description: map['description'] as String?,
      descriptionAr: map['description_ar'] as String?,
      imageUrl: map['image_url'] as String?,
      bannerUrl: map['banner_url'] as String?,
      address: map['address'] as String?,
      locationLat: map['location_lat'] != null
          ? (map['location_lat'] as num).toDouble()
          : null,
      locationLng: map['location_lng'] != null
          ? (map['location_lng'] as num).toDouble()
          : null,
      isActive: map['is_active'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      minimumOrder: map['minimum_order'] != null
          ? (map['minimum_order'] as num).toDouble()
          : null,
      averagePrepTimeMinutes: map['average_prep_time_minutes'] as int?,
      deliveryFeeOverride: map['delivery_fee_override'] != null
          ? (map['delivery_fee_override'] as num).toDouble()
          : null,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : 0.0,
      totalReviews: map['total_reviews'] as int? ?? 0,
      operatingHours: map['operating_hours'] as Map<String, dynamic>?,
      isAcceptingOrders: map['is_accepting_orders'] as bool? ?? true,
      isDemo: map['is_demo'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      categoryName: categoryName,
      merchantName: merchantName,
      productCount: map['product_count'] as int?,
    );
  }

  factory Store.fromJson(Map<String, dynamic> json) => Store.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_id': merchantId,
      'owner_user_id': ownerUserId,
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
      'is_demo': isDemo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Create payload for inserting new store
  Map<String, dynamic> toInsertPayload() {
    return {
      'merchant_id': merchantId,
      'owner_user_id': ownerUserId,
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
      'is_accepting_orders': isAcceptingOrders,
    };
  }

  Store copyWith({
    String? id,
    String? merchantId,
    String? ownerUserId,
    String? name,
    String? nameAr,
    String? category,
    String? description,
    String? descriptionAr,
    String? imageUrl,
    String? bannerUrl,
    String? address,
    double? locationLat,
    double? locationLng,
    bool? isActive,
    bool? isFeatured,
    double? minimumOrder,
    int? averagePrepTimeMinutes,
    double? deliveryFeeOverride,
    double? rating,
    int? totalReviews,
    Map<String, dynamic>? operatingHours,
    bool? isAcceptingOrders,
    bool? isDemo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? merchantName,
    int? productCount,
  }) {
    return Store(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      category: category ?? this.category,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      averagePrepTimeMinutes:
          averagePrepTimeMinutes ?? this.averagePrepTimeMinutes,
      deliveryFeeOverride: deliveryFeeOverride ?? this.deliveryFeeOverride,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      operatingHours: operatingHours ?? this.operatingHours,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      merchantName: merchantName ?? this.merchantName,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  String toString() {
    return 'Store(id: $id, name: $name, category: $category, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
