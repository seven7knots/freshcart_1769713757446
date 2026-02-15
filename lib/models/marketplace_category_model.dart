class MarketplaceCategoryModel {
  final String id;
  final String name;
  final String? nameAr;
  final String icon;
  final int sortOrder;
  final bool isPrimary;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MarketplaceCategoryModel({
    required this.id,
    required this.name,
    this.nameAr,
    required this.icon,
    required this.sortOrder,
    this.isPrimary = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceCategoryModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      icon: json['icon'] as String? ?? 'category',
      sortOrder: json['sort_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
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
      'icon': icon,
      'sort_order': sortOrder,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }

  MarketplaceCategoryModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? icon,
    int? sortOrder,
    bool? isPrimary,
    bool? isActive,
  }) {
    return MarketplaceCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}