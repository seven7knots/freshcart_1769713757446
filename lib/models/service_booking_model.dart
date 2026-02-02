class ServiceBookingModel {
  final String id;
  final String? bookingNumber;
  final String serviceId;
  final String customerId;
  final String providerId;
  final String status;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? distanceKm;
  final int? durationMinutes;
  final double? quantity;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double additionalCharges;
  final double platformFee;
  final double total;
  final String currency;
  final String? paymentMethod;
  final String paymentStatus;
  final String? paymentGatewayRef;
  final int? customerRating;
  final String? customerReview;
  final int? providerRating;
  final String? notes;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceBookingModel({
    required this.id,
    this.bookingNumber,
    required this.serviceId,
    required this.customerId,
    required this.providerId,
    this.status = 'requested',
    this.scheduledTime,
    this.startedAt,
    this.completedAt,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.distanceKm,
    this.durationMinutes,
    this.quantity,
    required this.baseFare,
    this.distanceFare = 0.0,
    this.timeFare = 0.0,
    this.additionalCharges = 0.0,
    this.platformFee = 0.0,
    required this.total,
    this.currency = 'USD',
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentGatewayRef,
    this.customerRating,
    this.customerReview,
    this.providerRating,
    this.notes,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceBookingModel.fromJson(Map<String, dynamic> json) {
    return ServiceBookingModel(
      id: json['id'] as String,
      bookingNumber: json['booking_number'] as String?,
      serviceId: json['service_id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      status: json['status'] as String? ?? 'requested',
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      pickupAddress: json['pickup_address'] as String?,
      pickupLat: json['pickup_lat'] != null
          ? (json['pickup_lat'] as num).toDouble()
          : null,
      pickupLng: json['pickup_lng'] != null
          ? (json['pickup_lng'] as num).toDouble()
          : null,
      dropoffAddress: json['dropoff_address'] as String?,
      dropoffLat: json['dropoff_lat'] != null
          ? (json['dropoff_lat'] as num).toDouble()
          : null,
      dropoffLng: json['dropoff_lng'] != null
          ? (json['dropoff_lng'] as num).toDouble()
          : null,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      baseFare: (json['base_fare'] as num).toDouble(),
      distanceFare: json['distance_fare'] != null
          ? (json['distance_fare'] as num).toDouble()
          : 0.0,
      timeFare: json['time_fare'] != null
          ? (json['time_fare'] as num).toDouble()
          : 0.0,
      additionalCharges: json['additional_charges'] != null
          ? (json['additional_charges'] as num).toDouble()
          : 0.0,
      platformFee: json['platform_fee'] != null
          ? (json['platform_fee'] as num).toDouble()
          : 0.0,
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentGatewayRef: json['payment_gateway_ref'] as String?,
      customerRating: json['customer_rating'] as int?,
      customerReview: json['customer_review'] as String?,
      providerRating: json['provider_rating'] as int?,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
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
      'booking_number': bookingNumber,
      'service_id': serviceId,
      'customer_id': customerId,
      'provider_id': providerId,
      'status': status,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'quantity': quantity,
      'base_fare': baseFare,
      'distance_fare': distanceFare,
      'time_fare': timeFare,
      'additional_charges': additionalCharges,
      'platform_fee': platformFee,
      'total': total,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_gateway_ref': paymentGatewayRef,
      'customer_rating': customerRating,
      'customer_review': customerReview,
      'provider_rating': providerRating,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
