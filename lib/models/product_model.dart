// ============================================================
// FILE: lib/models/product_model.dart
// ============================================================
// Product model matching database schema
// ============================================================

class Product {
  final String id;
  final String storeId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final double price;
  final double? salePrice;
  final String currency;
  final String? category;
  final String? subcategory;
  final String? imageUrl;
  final List<String>? images;
  final bool isAvailable;
  final bool isFeatured;
  final int? stockQuantity;
  final int? lowStockThreshold;
  final String? sku;
  final String? barcode;
  final Map<String, dynamic>? nutritionalInfo;
  final List<ProductOption>? options;
  final bool isDemo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested data (populated when joining)
  final String? storeName;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.price,
    this.salePrice,
    this.currency = 'USD',
    this.category,
    this.subcategory,
    this.imageUrl,
    this.images,
    this.isAvailable = true,
    this.isFeatured = false,
    this.stockQuantity,
    this.lowStockThreshold,
    this.sku,
    this.barcode,
    this.nutritionalInfo,
    this.options,
    this.isDemo = false,
    this.createdAt,
    this.updatedAt,
    this.storeName,
  });

  /// Get display name (Arabic if available)
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

  /// Is on sale?
  bool get isOnSale => salePrice != null && salePrice! < price;

  /// Current effective price
  double get effectivePrice => isOnSale ? salePrice! : price;

  /// Discount percentage
  int get discountPercent {
    if (!isOnSale) return 0;
    return (((price - salePrice!) / price) * 100).round();
  }

  /// Format price for display
  String get priceDisplay => '$currency ${price.toStringAsFixed(2)}';

  /// Format sale price for display
  String? get salePriceDisplay =>
      salePrice != null ? '$currency ${salePrice!.toStringAsFixed(2)}' : null;

  /// Format effective price for display
  String get effectivePriceDisplay =>
      '$currency ${effectivePrice.toStringAsFixed(2)}';

  /// Is low on stock?
  bool get isLowStock {
    if (stockQuantity == null || lowStockThreshold == null) return false;
    return stockQuantity! <= lowStockThreshold!;
  }

  /// Is out of stock?
  bool get isOutOfStock => stockQuantity != null && stockQuantity! <= 0;

  /// Can be ordered?
  bool get canOrder => isAvailable && !isOutOfStock;

  /// Get all image URLs
  List<String> get allImages {
    final result = <String>[];
    if (imageUrl != null) result.add(imageUrl!);
    if (images != null) result.addAll(images!);
    return result;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle nested store data
    String? storeName;
    if (map['stores'] != null && map['stores'] is Map) {
      storeName = map['stores']['name'] as String?;
    }

    // Parse images array
    List<String>? images;
    if (map['images'] != null) {
      if (map['images'] is List) {
        images = (map['images'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse options
    List<ProductOption>? options;
    if (map['options'] != null && map['options'] is List) {
      options = (map['options'] as List)
          .map((o) => ProductOption.fromMap(o as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String?,
      description: map['description'] as String?,
      descriptionAr: map['description_ar'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0,
      salePrice: map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : null,
      currency: map['currency'] as String? ?? 'USD',
      category: map['category'] as String?,
      subcategory: map['subcategory'] as String?,
      imageUrl: map['image_url'] as String?,
      images: images,
      isAvailable: map['is_available'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      stockQuantity: map['stock_quantity'] as int?,
      lowStockThreshold: map['low_stock_threshold'] as int?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      nutritionalInfo: map['nutritional_info'] as Map<String, dynamic>?,
      options: options,
      isDemo: map['is_demo'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      storeName: storeName,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'price': price,
      'sale_price': salePrice,
      'currency': currency,
      'category': category,
      'subcategory': subcategory,
      'image_url': imageUrl,
      'images': images,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'sku': sku,
      'barcode': barcode,
      'nutritional_info': nutritionalInfo,
      'options': options?.map((o) => o.toMap()).toList(),
      'is_demo': isDemo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Create payload for inserting new product
  Map<String, dynamic> toInsertPayload() {
    return {
      'store_id': storeId,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'price': price,
      'sale_price': salePrice,
      'currency': currency,
      'category': category,
      'subcategory': subcategory,
      'image_url': imageUrl,
      'images': images,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'sku': sku,
      'barcode': barcode,
      'nutritional_info': nutritionalInfo,
      'options': options?.map((o) => o.toMap()).toList(),
    };
  }

  Product copyWith({
    String? id,
    String? storeId,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    double? price,
    double? salePrice,
    String? currency,
    String? category,
    String? subcategory,
    String? imageUrl,
    List<String>? images,
    bool? isAvailable,
    bool? isFeatured,
    int? stockQuantity,
    int? lowStockThreshold,
    String? sku,
    String? barcode,
    Map<String, dynamic>? nutritionalInfo,
    List<ProductOption>? options,
    bool? isDemo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storeName,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      options: options ?? this.options,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storeName: storeName ?? this.storeName,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, storeId: $storeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Product option (e.g., size, color, toppings)
class ProductOption {
  final String name;
  final String? nameAr;
  final List<ProductOptionValue> values;
  final bool isRequired;
  final bool allowMultiple;

  ProductOption({
    required this.name,
    this.nameAr,
    required this.values,
    this.isRequired = false,
    this.allowMultiple = false,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    List<ProductOptionValue> values = [];
    if (map['values'] != null && map['values'] is List) {
      values = (map['values'] as List)
          .map((v) => ProductOptionValue.fromMap(v as Map<String, dynamic>))
          .toList();
    }

    return ProductOption(
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String?,
      values: values,
      isRequired: map['is_required'] as bool? ?? false,
      allowMultiple: map['allow_multiple'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_ar': nameAr,
      'values': values.map((v) => v.toMap()).toList(),
      'is_required': isRequired,
      'allow_multiple': allowMultiple,
    };
  }
}

/// Product option value (e.g., "Small", "Medium", "Large")
class ProductOptionValue {
  final String label;
  final String? labelAr;
  final double priceModifier;

  ProductOptionValue({
    required this.label,
    this.labelAr,
    this.priceModifier = 0.0,
  });

  factory ProductOptionValue.fromMap(Map<String, dynamic> map) {
    return ProductOptionValue(
      label: map['label'] as String? ?? '',
      labelAr: map['label_ar'] as String?,
      priceModifier: map['price_modifier'] != null
          ? (map['price_modifier'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'label_ar': labelAr,
      'price_modifier': priceModifier,
    };
  }
}

