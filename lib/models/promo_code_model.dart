// Add this line - JSON serialization will be handled manually
// Remove this line - part 'promo_code_model.freezed.dart';

// Remove this line - @freezed
class PromoCodeModel {
  final String id;
  final String code;
  final String? type;
  final double value;
  final String currency;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final int perUserLimit;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<dynamic> applicableStores;
  final List<dynamic> applicableCategories;
  final bool firstOrderOnly;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;

  const PromoCodeModel({
    required this.id,
    required this.code,
    this.type,
    required this.value,
    this.currency = 'USD',
    this.minOrderAmount = 0.0,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.perUserLimit = 1,
    this.validFrom,
    this.validUntil,
    this.applicableStores = const [],
    this.applicableCategories = const [],
    this.firstOrderOnly = false,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String?,
      value: (json['value'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      perUserLimit: json['per_user_limit'] as int? ?? 1,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      applicableStores: json['applicable_stores'] as List<dynamic>? ?? [],
      applicableCategories:
          json['applicable_categories'] as List<dynamic>? ?? [],
      firstOrderOnly: json['first_order_only'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
