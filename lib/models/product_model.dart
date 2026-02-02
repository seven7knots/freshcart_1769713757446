class ProductModel {
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
  final List<String> images;
  final bool isAvailable;
  final bool isFeatured;
  final int? stockQuantity;
  final int lowStockThreshold;
  final String? sku;
  final String? barcode;
  final Map<String, dynamic>? nutritionalInfo;
  final List<Map<String, dynamic>> options;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
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
    this.images = const [],
    this.isAvailable = true,
    this.isFeatured = false,
    this.stockQuantity,
    this.lowStockThreshold = 10,
    this.sku,
    this.barcode,
    this.nutritionalInfo,
    this.options = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      price: (json['price'] as num).toDouble(),
      salePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['image_url'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      stockQuantity: json['stock_quantity'] as int?,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 10,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      nutritionalInfo: json['nutritional_info'] as Map<String, dynamic>?,
      options: json['options'] != null
          ? List<Map<String, dynamic>>.from(json['options'] as List)
          : [],
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
      'options': options,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
