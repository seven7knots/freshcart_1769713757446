// ============================================================
// FILE: lib/models/category_model.dart
// ============================================================
// Category model with subcategory support (self-referencing via parent_id)
// ============================================================

class Category {
  final String id;
  final String name;
  final String? nameAr;
  final String? type;
  final String? icon;
  final String? description;
  final String? descriptionAr;
  final String? parentId; // null = top-level category, has value = subcategory
  final int sortOrder;
  final bool isActive;
  final bool isDemo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested data (populated when needed)
  final List<Category>? subcategories;
  final Category? parent;
  final int? storeCount; // Number of stores in this category

  Category({
    required this.id,
    required this.name,
    this.nameAr,
    this.type,
    this.icon,
    this.description,
    this.descriptionAr,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.isDemo = false,
    this.createdAt,
    this.updatedAt,
    this.subcategories,
    this.parent,
    this.storeCount,
  });

  /// Is this a top-level category?
  bool get isTopLevel => parentId == null;

  /// Is this a subcategory?
  bool get isSubcategory => parentId != null;

  /// Has subcategories?
  bool get hasSubcategories => subcategories != null && subcategories!.isNotEmpty;

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
          .map((s) => Category.fromMap(s as Map<String, dynamic>))
          .toList();
    }

    // Handle nested parent if present
    Category? parent;
    if (map['parent'] != null && map['parent'] is Map) {
      parent = Category.fromMap(map['parent'] as Map<String, dynamic>);
    }

    return Category(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String?,
      type: map['type'] as String?,
      icon: map['icon'] as String?,
      description: map['description'] as String?,
      descriptionAr: map['description_ar'] as String?,
      parentId: map['parent_id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      isDemo: map['is_demo'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      subcategories: subcategories,
      parent: parent,
      storeCount: map['store_count'] as int?,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) => Category.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'icon': icon,
      'description': description,
      'description_ar': descriptionAr,
      'parent_id': parentId,
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
    return {
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'icon': icon,
      'description': description,
      'description_ar': descriptionAr,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? type,
    String? icon,
    String? description,
    String? descriptionAr,
    String? parentId,
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
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      parentId: parentId ?? this.parentId,
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

