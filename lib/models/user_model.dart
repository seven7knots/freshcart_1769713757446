import 'package:freezed_annotation/freezed_annotation.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String? phone;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  final String role;
  @JsonKey(name: 'wallet_balance')
  final double walletBalance;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  @JsonKey(name: 'referred_by')
  final String? referredBy;
  @JsonKey(name: 'subscription_id')
  final String? subscriptionId;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'location_lat')
  final double? locationLat;
  @JsonKey(name: 'location_lng')
  final double? locationLng;
  @JsonKey(name: 'default_address')
  final String? defaultAddress;
  @JsonKey(name: 'fcm_token')
  final String? fcmToken;
  @JsonKey(name: 'country_code')
  final String countryCode;
  @JsonKey(name: 'preferred_currency')
  final String preferredCurrency;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.profileImageUrl,
    this.role = 'customer',
    this.walletBalance = 0.0,
    this.referralCode,
    this.referredBy,
    this.subscriptionId,
    this.isVerified = false,
    this.isActive = true,
    this.locationLat,
    this.locationLng,
    this.defaultAddress,
    this.fcmToken,
    this.countryCode = 'LB',
    this.preferredCurrency = 'USD',
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      defaultAddress: json['default_address'] as String?,
      fcmToken: json['fcm_token'] as String?,
      countryCode: json['country_code'] as String? ?? 'LB',
      preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
