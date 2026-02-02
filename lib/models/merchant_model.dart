class Merchant {
  final String id;
  final String userId;
  final String businessName;
  final String? businessType;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final double serviceRadiusKm;
  final double commissionRate;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessType,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    this.address,
    this.locationLat,
    this.locationLng,
    this.serviceRadiusKm = 10.0,
    this.commissionRate = 0.15,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Merchant.fromMap(Map<String, dynamic> map) {
    return Merchant(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      businessName: map['business_name'] as String,
      businessType: map['business_type'] as String?,
      logoUrl: map['logo_url'] as String?,
      bannerUrl: map['banner_url'] as String?,
      description: map['description'] as String?,
      address: map['address'] as String?,
      locationLat: map['location_lat'] != null
          ? (map['location_lat'] as num).toDouble()
          : null,
      locationLng: map['location_lng'] != null
          ? (map['location_lng'] as num).toDouble()
          : null,
      serviceRadiusKm: map['service_radius_km'] != null
          ? (map['service_radius_km'] as num).toDouble()
          : 10.0,
      commissionRate: map['commission_rate'] != null
          ? (map['commission_rate'] as num).toDouble()
          : 0.15,
      isVerified: map['is_verified'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_type': businessType,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'description': description,
      'address': address,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'service_radius_km': serviceRadiusKm,
      'commission_rate': commissionRate,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Merchant copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessType,
    String? logoUrl,
    String? bannerUrl,
    String? description,
    String? address,
    double? locationLat,
    double? locationLng,
    double? serviceRadiusKm,
    double? commissionRate,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Merchant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      description: description ?? this.description,
      address: address ?? this.address,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      commissionRate: commissionRate ?? this.commissionRate,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
