class DeliveryModel {
  final String id;
  
  final String orderId;
  
  final String driverId;
  final String status;
  
  final DateTime? pickupTime;
  
  final DateTime? deliveryTime;
  
  final double? distanceKm;
  
  final int? durationMinutes;
  
  final double? driverEarnings;
  
  final double tipAmount;
  
  final String? routePolyline;
  
  final String? pickupPhotoUrl;
  
  final String? deliveryPhotoUrl;
  
  final String? signatureUrl;
  
  final String? failureReason;
  
  final DateTime? createdAt;
  
  final DateTime? updatedAt;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    this.status = 'assigned',
    this.pickupTime,
    this.deliveryTime,
    this.distanceKm,
    this.durationMinutes,
    this.driverEarnings,
    this.tipAmount = 0.0,
    this.routePolyline,
    this.pickupPhotoUrl,
    this.deliveryPhotoUrl,
    this.signatureUrl,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      driverId: json['driver_id'] as String,
      status: json['status'] as String? ?? 'assigned',
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'] as String)
          : null,
      deliveryTime: json['delivery_time'] != null
          ? DateTime.parse(json['delivery_time'] as String)
          : null,
      distanceKm: json['distance_km'] as double?,
      durationMinutes: json['duration_minutes'] as int?,
      driverEarnings: json['driver_earnings'] as double?,
      tipAmount: json['tip_amount'] as double? ?? 0.0,
      routePolyline: json['route_polyline'] as String?,
      pickupPhotoUrl: json['pickup_photo_url'] as String?,
      deliveryPhotoUrl: json['delivery_photo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      failureReason: json['failure_reason'] as String?,
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
      'order_id': orderId,
      'driver_id': driverId,
      'status': status,
      'pickup_time': pickupTime?.toIso8601String(),
      'delivery_time': deliveryTime?.toIso8601String(),
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'driver_earnings': driverEarnings,
      'tip_amount': tipAmount,
      'route_polyline': routePolyline,
      'pickup_photo_url': pickupPhotoUrl,
      'delivery_photo_url': deliveryPhotoUrl,
      'signature_url': signatureUrl,
      'failure_reason': failureReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}