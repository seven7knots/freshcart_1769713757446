// ============================================================
// FILE: lib/models/merchant_model.dart
// ============================================================
// Complete merchant model with approval workflow support
// ============================================================

import 'user_model.dart';

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
  
  // Approval workflow fields
  final ApplicationStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data (populated when joining)
  final String? userEmail;
  final String? userName;
  final List<MerchantStore>? stores;

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
    this.status = ApplicationStatus.pending,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
    this.stores,
  });

  /// Check if merchant is approved
  bool get isApproved => status == ApplicationStatus.approved;

  /// Check if merchant is pending
  bool get isPending => status == ApplicationStatus.pending;

  /// Check if merchant is rejected
  bool get isRejected => status == ApplicationStatus.rejected;

  /// Check if merchant is suspended
  bool get isSuspended => status == ApplicationStatus.suspended;

  /// Check if merchant can operate (approved and active)
  bool get canOperate => isApproved && isActive;

  factory Merchant.fromMap(Map<String, dynamic> map) {
    // Handle nested user data if present
    String? userEmail;
    String? userName;
    
    if (map['users'] != null && map['users'] is Map) {
      final userData = map['users'] as Map<String, dynamic>;
      userEmail = userData['email'] as String?;
      userName = userData['full_name'] as String?;
    } else if (map['profiles'] != null && map['profiles'] is Map) {
      final profileData = map['profiles'] as Map<String, dynamic>;
      userEmail = profileData['email'] as String?;
      userName = profileData['full_name'] as String?;
    }

    // Handle nested stores if present
    List<MerchantStore>? stores;
    if (map['stores'] != null && map['stores'] is List) {
      stores = (map['stores'] as List)
          .map((s) => MerchantStore.fromMap(s as Map<String, dynamic>))
          .toList();
    }

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
      status: ApplicationStatus.fromString(map['status'] as String?),
      rejectionReason: map['rejection_reason'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.tryParse(map['approved_at'] as String)
          : null,
      approvedBy: map['approved_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userEmail: userEmail,
      userName: userName,
      stores: stores,
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
      'status': status.name,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create application payload for new merchant
  Map<String, dynamic> toApplicationPayload() {
    return {
      'business_name': businessName,
      'business_type': businessType,
      'description': description,
      'address': address,
      'logo_url': logoUrl,
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
    ApplicationStatus? status,
    String? rejectionReason,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userEmail,
    String? userName,
    List<MerchantStore>? stores,
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
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      stores: stores ?? this.stores,
    );
  }

  @override
  String toString() {
    return 'Merchant(id: $id, businessName: $businessName, status: ${status.name}, '
        'isVerified: $isVerified, isActive: $isActive)';
  }
}

/// Simple store reference for merchant
class MerchantStore {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;

  MerchantStore({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isActive = true,
  });

  factory MerchantStore.fromMap(Map<String, dynamic> map) {
    return MerchantStore(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}

