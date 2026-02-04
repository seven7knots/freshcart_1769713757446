class AdminCategoryModel {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final bool isActive;
  final int sortOrder;
  final bool isMarketplace;

  const AdminCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.parentId,
    required this.isActive,
    required this.sortOrder,
    required this.isMarketplace,
  });

  factory AdminCategoryModel.fromMap(Map<String, dynamic> map) {
    return AdminCategoryModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      parentId: map['parent_id']?.toString(),
      isActive: (map['is_active'] as bool?) ?? true,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isMarketplace: (map['is_marketplace'] as bool?) ?? false,
    );
  }

  AdminCategoryModel copyWith({
    String? name,
    String? type,
    String? parentId,
    bool? isActive,
    int? sortOrder,
    bool? isMarketplace,
  }) {
    return AdminCategoryModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      isMarketplace: isMarketplace ?? this.isMarketplace,
    );
  }
}
