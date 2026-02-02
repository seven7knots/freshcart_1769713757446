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

  PromoCodeModel({
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

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    return null;
  }

  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  factory PromoCodeModel.fromMap(Map<String, dynamic> map) {
    return PromoCodeModel(
      id: map['id'] as String,
      code: map['code'] as String,
      type: map['type'] as String?,
      value: _toDouble(map['value']),
      currency: (map['currency'] as String?) ?? 'USD',
      minOrderAmount: _toDouble(map['min_order_amount']),
      maxDiscount:
          map['max_discount'] != null ? _toDouble(map['max_discount']) : null,
      usageLimit: map['usage_limit'] as int?,
      usedCount: (map['used_count'] as int?) ?? 0,
      perUserLimit: (map['per_user_limit'] as int?) ?? 1,
      validFrom: _parseDate(map['valid_from']),
      validUntil: _parseDate(map['valid_until']),
      applicableStores: (map['applicable_stores'] as List?) ?? const [],
      applicableCategories: (map['applicable_categories'] as List?) ?? const [],
      firstOrderOnly: (map['first_order_only'] as bool?) ?? false,
      isActive: (map['is_active'] as bool?) ?? true,
      createdBy: map['created_by'] as String?,
      createdAt: _parseDate(map['created_at']),
    );
  }
}
