/// Universal address model used across the entire app:
/// checkout, delivery, marketplace listings, merchant stores, driver navigation.
class UserAddress {
  final String? id;
  final String label; // HOME, WORK, STORE, OTHER
  final String address; // Full formatted address text
  final String? detail; // Building, floor, apartment
  final double? lat;
  final double? lng;
  final double? radiusKm; // Delivery radius or search radius
  final bool isDefault;

  UserAddress({
    this.id,
    this.label = 'HOME',
    required this.address,
    this.detail,
    this.lat,
    this.lng,
    this.radiusKm,
    this.isDefault = false,
  });

  /// True if this address has valid coordinates
  bool get hasCoordinates => lat != null && lng != null;

  /// Full address including detail line
  String get fullAddress {
    if (detail != null && detail!.isNotEmpty) {
      return '$address, $detail';
    }
    return address;
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String?,
      label: json['label'] as String? ?? 'HOME',
      address: json['address'] as String? ?? '',
      detail: json['detail'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      radiusKm: (json['radius_km'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'label': label,
      'address': address,
      'detail': detail,
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
      'is_default': isDefault,
    };
  }

  UserAddress copyWith({
    String? id,
    String? label,
    String? address,
    String? detail,
    double? lat,
    double? lng,
    double? radiusKm,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      detail: detail ?? this.detail,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() =>
      'UserAddress(label=$label, address=$address, lat=$lat, lng=$lng, radius=$radiusKm)';
}