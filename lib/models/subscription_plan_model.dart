class SubscriptionPlanModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final String? type;
  final double price;
  final String currency;
  final String? billingCycle;
  final List<dynamic> features;
  final double? freeDeliveryThreshold;
  final double commissionDiscount;
  final int? aiRequestsLimit;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.type,
    required this.price,
    this.currency = 'USD',
    this.billingCycle,
    this.features = const [],
    this.freeDeliveryThreshold,
    this.commissionDiscount = 0.0,
    this.aiRequestsLimit,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      type: json['type'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      billingCycle: json['billing_cycle'] as String?,
      features: json['features'] as List<dynamic>? ?? [],
      freeDeliveryThreshold: json['free_delivery_threshold'] != null
          ? (json['free_delivery_threshold'] as num).toDouble()
          : null,
      commissionDiscount: json['commission_discount'] != null
          ? (json['commission_discount'] as num).toDouble()
          : 0.0,
      aiRequestsLimit: json['ai_requests_limit'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
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
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'type': type,
      'price': price,
      'currency': currency,
      'billing_cycle': billingCycle,
      'features': features,
      'free_delivery_threshold': freeDeliveryThreshold,
      'commission_discount': commissionDiscount,
      'ai_requests_limit': aiRequestsLimit,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? type,
    double? price,
    String? currency,
    String? billingCycle,
    List<dynamic>? features,
    double? freeDeliveryThreshold,
    double? commissionDiscount,
    int? aiRequestsLimit,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      features: features ?? this.features,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      commissionDiscount: commissionDiscount ?? this.commissionDiscount,
      aiRequestsLimit: aiRequestsLimit ?? this.aiRequestsLimit,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
