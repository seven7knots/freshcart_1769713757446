class DriverModel {
  const DriverModel({
    required this.id,
    required this.userId,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.licenseNumber,
    this.licenseExpiry,
    this.documents = const {},
    this.isOnline = false,
    this.isVerified = false,
    this.isActive = true,
    this.currentLocationLat,
    this.currentLocationLng,
    this.lastLocationUpdate,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    this.zoneId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final Map<String, dynamic> documents;
  final bool isOnline;
  final bool isVerified;
  final bool isActive;
  final double? currentLocationLat;
  final double? currentLocationLng;
  final DateTime? lastLocationUpdate;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;
  final String? zoneId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseExpiry: json['license_expiry'] != null
          ? DateTime.parse(json['license_expiry'] as String)
          : null,
      documents: json['documents'] as Map<String, dynamic>? ?? {},
      isOnline: json['is_online'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      currentLocationLat: json['current_location_lat'] as double?,
      currentLocationLng: json['current_location_lng'] as double?,
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'] as String)
          : null,
      rating: json['rating'] as double? ?? 5.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      totalEarnings: json['total_earnings'] as double? ?? 0.0,
      zoneId: json['zone_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
