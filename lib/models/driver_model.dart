// ============================================================
// FILE: lib/models/driver_model.dart
// ============================================================
// Complete driver model with approval workflow support
// ============================================================

import 'user_model.dart';

/// Vehicle types enum
enum VehicleType {
  motorcycle,
  car,
  bicycle,
  van;

  static VehicleType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'car':
        return VehicleType.car;
      case 'bicycle':
        return VehicleType.bicycle;
      case 'van':
        return VehicleType.van;
      default:
        return VehicleType.motorcycle;
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.van:
        return 'Van';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.car:
        return '🚗';
      case VehicleType.bicycle:
        return '🚲';
      case VehicleType.van:
        return '🚐';
    }
  }
}

class Driver {
  final String id;
  final String userId;

  // Personal info
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;

  // Documents
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? licenseImageUrl;
  final String? idCardNumber;
  final String? idCardImageUrl;

  // Vehicle info
  final VehicleType vehicleType;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleImageUrl;

  // Approval workflow
  final ApplicationStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy;

  // Operational status
  final bool isOnline;
  final bool isActive;
  final bool isAvailable;

  // Location - support both naming conventions
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastLocationUpdate;

  // Aliases for compatibility with existing code
  double? get currentLocationLat => currentLat;
  double? get currentLocationLng => currentLng;

  // Stats
  final int totalDeliveries;
  final double totalEarnings;
  final double rating;
  final int ratingCount;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Current assignment (populated when needed)
  final DriverOrder? currentOrder;

  Driver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.licenseNumber,
    this.licenseExpiry,
    this.licenseImageUrl,
    this.idCardNumber,
    this.idCardImageUrl,
    this.vehicleType = VehicleType.motorcycle,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleImageUrl,
    this.status = ApplicationStatus.pending,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    this.isOnline = false,
    this.isActive = true,
    this.isAvailable = true,
    this.currentLat,
    this.currentLng,
    this.lastLocationUpdate,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.rating = 5.0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.currentOrder,
  });

  /// Check if driver is approved
  bool get isApproved => status == ApplicationStatus.approved;

  /// Check if driver is pending
  bool get isPending => status == ApplicationStatus.pending;

  /// Check if driver is rejected
  bool get isRejected => status == ApplicationStatus.rejected;

  /// Check if driver is suspended
  bool get isSuspended => status == ApplicationStatus.suspended;

  /// Check if driver can take orders (approved, active, online, available)
  bool get canTakeOrders => isApproved && isActive && isOnline && isAvailable;

  /// Check if driver has current location
  bool get hasLocation => currentLat != null && currentLng != null;

  /// Format rating for display
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Format earnings for display
  String get earningsDisplay => '\$${totalEarnings.toStringAsFixed(2)}';

  /// Factory constructor from Map (for Supabase responses)
  factory Driver.fromMap(Map<String, dynamic> map) {
    // Handle nested order if present
    DriverOrder? currentOrder;
    if (map['current_order'] != null && map['current_order'] is Map) {
      currentOrder =
          DriverOrder.fromMap(map['current_order'] as Map<String, dynamic>);
    }

    return Driver(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      licenseNumber: map['license_number'] as String?,
      licenseExpiry: map['license_expiry'] != null
          ? DateTime.tryParse(map['license_expiry'] as String)
          : null,
      licenseImageUrl: map['license_image_url'] as String?,
      idCardNumber: map['id_card_number'] as String?,
      idCardImageUrl: map['id_card_image_url'] as String?,
      vehicleType: VehicleType.fromString(map['vehicle_type'] as String?),
      vehiclePlate: map['vehicle_plate'] as String?,
      vehicleModel: map['vehicle_model'] as String?,
      vehicleColor: map['vehicle_color'] as String?,
      vehicleImageUrl: map['vehicle_image_url'] as String?,
      status: ApplicationStatus.fromString(map['status'] as String?),
      rejectionReason: map['rejection_reason'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.tryParse(map['approved_at'] as String)
          : null,
      approvedBy: map['approved_by'] as String?,
      isOnline: map['is_online'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      isAvailable: map['is_available'] as bool? ?? true,
      // Support both naming conventions
      currentLat: (map['current_lat'] ?? map['current_location_lat']) != null
          ? ((map['current_lat'] ?? map['current_location_lat']) as num).toDouble()
          : null,
      currentLng: (map['current_lng'] ?? map['current_location_lng']) != null
          ? ((map['current_lng'] ?? map['current_location_lng']) as num).toDouble()
          : null,
      lastLocationUpdate: map['last_location_update'] != null
          ? DateTime.tryParse(map['last_location_update'] as String)
          : null,
      totalDeliveries: map['total_deliveries'] as int? ?? 0,
      totalEarnings: map['total_earnings'] != null
          ? (map['total_earnings'] as num).toDouble()
          : 0,
      rating:
          map['rating'] != null ? (map['rating'] as num).toDouble() : 5.0,
      ratingCount: map['rating_count'] as int? ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      currentOrder: currentOrder,
    );
  }

  /// Alias for fromMap - for compatibility with existing code
  factory Driver.fromJson(Map<String, dynamic> json) => Driver.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'license_number': licenseNumber,
      'license_expiry': licenseExpiry?.toIso8601String(),
      'license_image_url': licenseImageUrl,
      'id_card_number': idCardNumber,
      'id_card_image_url': idCardImageUrl,
      'vehicle_type': vehicleType.name,
      'vehicle_plate': vehiclePlate,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_image_url': vehicleImageUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'is_online': isOnline,
      'is_active': isActive,
      'is_available': isAvailable,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'total_deliveries': totalDeliveries,
      'total_earnings': totalEarnings,
      'rating': rating,
      'rating_count': ratingCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Alias for toMap - for compatibility with existing code
  Map<String, dynamic> toJson() => toMap();

  /// Create application payload for new driver
  Map<String, dynamic> toApplicationPayload() {
    return {
      'full_name': fullName,
      'phone': phone,
      'vehicle_type': vehicleType.name,
      'vehicle_plate': vehiclePlate,
      'license_number': licenseNumber,
      'avatar_url': avatarUrl,
    };
  }

  Driver copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? licenseImageUrl,
    String? idCardNumber,
    String? idCardImageUrl,
    VehicleType? vehicleType,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleImageUrl,
    ApplicationStatus? status,
    String? rejectionReason,
    DateTime? approvedAt,
    String? approvedBy,
    bool? isOnline,
    bool? isActive,
    bool? isAvailable,
    double? currentLat,
    double? currentLng,
    DateTime? lastLocationUpdate,
    int? totalDeliveries,
    double? totalEarnings,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DriverOrder? currentOrder,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }

  @override
  String toString() {
    return 'Driver(id: $id, fullName: $fullName, status: ${status.name}, '
        'isOnline: $isOnline, vehicleType: ${vehicleType.name})';
  }
}

/// Simple order reference for driver
class DriverOrder {
  final String id;
  final String status;
  final String? storeName;
  final String? customerAddress;
  final double? deliveryFee;

  DriverOrder({
    required this.id,
    required this.status,
    this.storeName,
    this.customerAddress,
    this.deliveryFee,
  });

  factory DriverOrder.fromMap(Map<String, dynamic> map) {
    return DriverOrder(
      id: map['id'] as String,
      status: map['status'] as String,
      storeName: map['store_name'] as String?,
      customerAddress: map['customer_address'] as String?,
      deliveryFee: map['delivery_fee'] != null
          ? (map['delivery_fee'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'store_name': storeName,
      'customer_address': customerAddress,
      'delivery_fee': deliveryFee,
    };
  }
}

