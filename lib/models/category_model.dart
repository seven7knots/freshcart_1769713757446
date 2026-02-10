// ============================================================
// FILE: lib/models/category_model.dart
// ============================================================
// Category model with subcategory support (self-referencing via parent_id)
// FIX: Removed isMarketplace (column doesn't exist in DB)
// ADDED: imageUrl field, storeId field for in-store categories
// ============================================================

class Category {
  final String id;
  final String name;
  final String? nameAr;
  final String? type;
  final String? icon;
  final String? imageUrl; // Category image
  final String? description;
  final String? descriptionAr;
  final String? parentId; // null = top-level, has value = subcategory
  final String? storeId; // null = global category, has value = in-store category
  final int sortOrder;
  final bool isActive;
  final bool isDemo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested data (populated when needed)
  final List<Category>? subcategories;
  final Category? parent;
  final int storeCount; // Number of stores in this category

  Category({
    required this.id,
    required this.name,
    this.nameAr,
    this.type,
    this.icon,
    this.imageUrl,
    this.description,
    this.descriptionAr,
    this.parentId,
    this.storeId,
    this.sortOrder = 0,
    this.isActive = true,
    this.isDemo = false,
    this.createdAt,
    this.updatedAt,
    this.subcategories,
    this.parent,
    this.storeCount = 0,
  });

  /// Is this a top-level category?
  bool get isTopLevel => parentId == null;

  /// Is this a subcategory?
  bool get isSubcategory => parentId != null;

  /// Has subcategories?
  bool get hasSubcategories =>
      subcategories != null && subcategories!.isNotEmpty;

  /// Is this an in-store category?
  bool get isStoreCategory => storeId != null;

  /// Get display name (Arabic if available, fallback to English)
  String getDisplayName({bool preferArabic = false}) {
    if (preferArabic && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  /// Get display description
  String? getDisplayDescription({bool preferArabic = false}) {
    if (preferArabic && descriptionAr != null && descriptionAr!.isNotEmpty) {
      return descriptionAr;
    }
    return description;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    // Handle nested subcategories if present
    List<Category>? subcategories;
    if (map['subcategories'] != null && map['subcategories'] is List) {
      subcategories = (map['subcategories'] as List)
          .where((s) => s != null)
          .map((s) => Category.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    // Handle nested parent if present
    Category? parent;
    if (map['parent'] != null && map['parent'] is Map) {
      parent =
          Category.fromMap(Map<String, dynamic>.from(map['parent'] as Map));
    }

    // Defensive parsing helpers
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return fallback;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Category(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] as String?) ?? '',
      nameAr: map['name_ar'] as String?,
      type: map['type'] as String?,
      icon: map['icon'] as String?,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      descriptionAr: map['description_ar'] as String?,
      parentId: map['parent_id']?.toString(),
      storeId: map['store_id']?.toString(),
      sortOrder: parseInt(map['sort_order'], fallback: 0),
      isActive: parseBool(map['is_active'], fallback: true),
      isDemo: parseBool(map['is_demo'], fallback: false),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      subcategories: subcategories,
      parent: parent,
      storeCount: parseInt(map['store_count'], fallback: 0),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'icon': icon,
      'image_url': imageUrl,
      'description': description,
      'description_ar': descriptionAr,
      'parent_id': parentId,
      'store_id': storeId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'is_demo': isDemo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Create payload for inserting new category
  Map<String, dynamic> toInsertPayload() {
    final data = <String, dynamic>{
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'icon': icon,
      'image_url': imageUrl,
      'description': description,
      'description_ar': descriptionAr,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'is_demo': isDemo,
    };
    if (storeId != null) data['store_id'] = storeId;
    return data;
  }

  Category copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? type,
    String? icon,
    String? imageUrl,
    String? description,
    String? descriptionAr,
    String? parentId,
    String? storeId,
    int? sortOrder,
    bool? isActive,
    bool? isDemo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Category>? subcategories,
    Category? parent,
    int? storeCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      parentId: parentId ?? this.parentId,
      storeId: storeId ?? this.storeId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategories: subcategories ?? this.subcategories,
      parent: parent ?? this.parent,
      storeCount: storeCount ?? this.storeCount,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, parentId: $parentId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}