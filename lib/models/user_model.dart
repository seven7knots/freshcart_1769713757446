// ============================================================
// FILE: lib/models/user_model.dart
// ============================================================
// Complete user model with role management support
// ============================================================


/// Enum for user roles
enum UserRole {
  customer,
  merchant,
  driver,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'merchant':
        return UserRole.merchant;
      case 'driver':
        return UserRole.driver;
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.merchant:
        return 'Merchant';
      case UserRole.driver:
        return 'Driver';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

/// Enum for application status
enum ApplicationStatus {
  none,
  pending,
  approved,
  rejected,
  suspended;

  static ApplicationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'suspended':
        return ApplicationStatus.suspended;
      default:
        return ApplicationStatus.none;
    }
  }

  bool get isPending => this == ApplicationStatus.pending;
  bool get isApproved => this == ApplicationStatus.approved;
  bool get isRejected => this == ApplicationStatus.rejected;
  bool get isSuspended => this == ApplicationStatus.suspended;
}

/// Main user model
class UserModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Role-specific data (populated when needed)
  final MerchantInfo? merchantInfo;
  final DriverInfo? driverInfo;

  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.isActive = true,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.createdAt,
    this.updatedAt,
    this.merchantInfo,
    this.driverInfo,
  });

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is an approved merchant
  bool get isMerchant =>
      role == UserRole.merchant ||
      (merchantInfo?.status.isApproved ?? false);

  /// Check if user is an approved driver
  bool get isDriver =>
      role == UserRole.driver || (driverInfo?.status.isApproved ?? false);

  /// Check if user is a regular customer
  bool get isCustomer => !isAdmin && !isMerchant && !isDriver;

  /// Check if user has a pending merchant application
  bool get hasPendingMerchantApplication =>
      merchantInfo?.status.isPending ?? false;

  /// Check if user has a pending driver application
  bool get hasPendingDriverApplication => driverInfo?.status.isPending ?? false;

  /// Check if user is fully verified (email + phone)
  bool get isFullyVerified => emailVerified && phoneVerified;

  /// Create from database map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      isActive: map['is_active'] as bool? ?? true,
      emailVerified: map['email_verified'] as bool? ?? false,
      phoneVerified: map['phone_verified'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      merchantInfo: map['merchant'] != null
          ? MerchantInfo.fromMap(map['merchant'] as Map<String, dynamic>)
          : null,
      driverInfo: map['driver'] != null
          ? DriverInfo.fromMap(map['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create from role details RPC response
  factory UserModel.fromRoleDetails(Map<String, dynamic> map) {
    MerchantInfo? merchantInfo;
    DriverInfo? driverInfo;

    if (map['merchant'] != null && map['merchant'] is Map) {
      merchantInfo =
          MerchantInfo.fromMap(map['merchant'] as Map<String, dynamic>);
    }

    if (map['driver'] != null && map['driver'] is Map) {
      driverInfo = DriverInfo.fromMap(map['driver'] as Map<String, dynamic>);
    }

    return UserModel(
      id: map['user_id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      isActive: map['is_active'] as bool? ?? true,
      merchantInfo: merchantInfo,
      driverInfo: driverInfo,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role.name,
      'is_active': isActive,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with new values
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    MerchantInfo? merchantInfo,
    DriverInfo? driverInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      merchantInfo: merchantInfo ?? this.merchantInfo,
      driverInfo: driverInfo ?? this.driverInfo,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: ${role.name}, '
        'isAdmin: $isAdmin, isMerchant: $isMerchant, isDriver: $isDriver)';
  }
}

/// Merchant info embedded in user model
class MerchantInfo {
  final String id;
  final ApplicationStatus status;
  final String? businessName;
  final bool isVerified;
  final bool isActive;
  final String? rejectionReason;

  const MerchantInfo({
    required this.id,
    required this.status,
    this.businessName,
    this.isVerified = false,
    this.isActive = true,
    this.rejectionReason,
  });

  factory MerchantInfo.fromMap(Map<String, dynamic> map) {
    return MerchantInfo(
      id: map['id'] as String,
      status: ApplicationStatus.fromString(map['status'] as String?),
      businessName: map['business_name'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status.name,
      'business_name': businessName,
      'is_verified': isVerified,
      'is_active': isActive,
      'rejection_reason': rejectionReason,
    };
  }
}

/// Driver info embedded in user model
class DriverInfo {
  final String id;
  final ApplicationStatus status;
  final bool isOnline;
  final bool isActive;
  final bool isAvailable;
  final String? vehicleType;
  final String? rejectionReason;

  const DriverInfo({
    required this.id,
    required this.status,
    this.isOnline = false,
    this.isActive = true,
    this.isAvailable = true,
    this.vehicleType,
    this.rejectionReason,
  });

  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      id: map['id'] as String,
      status: ApplicationStatus.fromString(map['status'] as String?),
      isOnline: map['is_online'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      isAvailable: map['is_available'] as bool? ?? true,
      vehicleType: map['vehicle_type'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status.name,
      'is_online': isOnline,
      'is_active': isActive,
      'is_available': isAvailable,
      'vehicle_type': vehicleType,
      'rejection_reason': rejectionReason,
    };
  }
}

