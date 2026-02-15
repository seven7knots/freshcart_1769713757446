class OrderModel {
  final String id;
  final String? orderNumber;
  final String customerId;
  final String? storeId;
  final String? driverId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tip;
  final double discount;
  final double tax;
  final double total;
  final String currency;
  final String? paymentMethod;
  final String paymentStatus;
  final String? paymentGatewayRef;
  final Map<String, dynamic>? paymentGatewayResponse;
  final bool isPriority;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? deliveryInstructions;
  final String? customerPhone;
  final DateTime? scheduledFor;
  final int? estimatedPrepTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? promoCodeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // COD tracking fields
  final double? cashCollectedAmount;
  final DateTime? cashCollectedAt;
  final String? cashConfirmedByAdmin;
  // Items stored as JSONB
  final List<dynamic>? items;
  final double? distanceKm;
  final String? phone;
  final String? instructions;

  const OrderModel({
    required this.id,
    this.orderNumber,
    required this.customerId,
    this.storeId,
    this.driverId,
    this.status = 'pending',
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.serviceFee = 0.0,
    this.tip = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    this.currency = 'USD',
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentGatewayRef,
    this.paymentGatewayResponse,
    this.isPriority = false,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryInstructions,
    this.customerPhone,
    this.scheduledFor,
    this.estimatedPrepTime,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.cancelledAt,
    this.cancellationReason,
    this.promoCodeId,
    this.createdAt,
    this.updatedAt,
    this.cashCollectedAmount,
    this.cashCollectedAt,
    this.cashConfirmedByAdmin,
    this.items,
    this.distanceKm,
    this.phone,
    this.instructions,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // customer_id may come from 'customer_id' or 'user_id' depending on context
    final customerId = (json['customer_id'] as String?) ??
        (json['user_id'] as String?) ??
        '';

    return OrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String?,
      customerId: customerId,
      storeId: json['store_id'] as String?,
      driverId: json['driver_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentGatewayRef: json['payment_gateway_ref'] as String?,
      paymentGatewayResponse:
          json['payment_gateway_response'] as Map<String, dynamic>?,
      isPriority: json['is_priority'] as bool? ?? false,
      deliveryAddress: json['delivery_address'] as String? ?? '',
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      deliveryInstructions: json['delivery_instructions'] as String?,
      customerPhone: json['customer_phone'] as String? ?? json['phone'] as String?,
      scheduledFor: _tryParseDate(json['scheduled_for']),
      estimatedPrepTime: json['estimated_prep_time'] as int?,
      estimatedDeliveryTime: _tryParseDate(json['estimated_delivery_time']),
      actualDeliveryTime: _tryParseDate(json['actual_delivery_time']),
      cancelledAt: _tryParseDate(json['cancelled_at']),
      cancellationReason: json['cancellation_reason'] as String?,
      promoCodeId: json['promo_code_id'] as String?,
      createdAt: _tryParseDate(json['created_at']),
      updatedAt: _tryParseDate(json['updated_at']),
      cashCollectedAmount: (json['cash_collected_amount'] as num?)?.toDouble(),
      cashCollectedAt: _tryParseDate(json['cash_collected_at']),
      cashConfirmedByAdmin: json['cash_confirmed_by_admin'] as String?,
      items: json['items'] as List<dynamic>?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  /// Safely parse date strings — returns null on failure instead of crashing
  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'store_id': storeId,
      'driver_id': driverId,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'service_fee': serviceFee,
      'tip': tip,
      'discount': discount,
      'tax': tax,
      'total': total,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_gateway_ref': paymentGatewayRef,
      'payment_gateway_response': paymentGatewayResponse,
      'is_priority': isPriority,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'delivery_instructions': deliveryInstructions,
      'customer_phone': customerPhone,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'estimated_prep_time': estimatedPrepTime,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'promo_code_id': promoCodeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cash_collected_amount': cashCollectedAmount,
      'cash_collected_at': cashCollectedAt?.toIso8601String(),
      'cash_confirmed_by_admin': cashConfirmedByAdmin,
      'items': items,
      'distance_km': distanceKm,
      'phone': phone,
      'instructions': instructions,
    };
  }
}