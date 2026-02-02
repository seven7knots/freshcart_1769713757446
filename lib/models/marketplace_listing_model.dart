class MarketplaceListingModel {
  final String id;
  final String userId;
  final String title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  final double price;
  final String currency;
  final String? category;
  final String? condition;
  final List<String> images;
  final String? locationText;
  final double? locationLat;
  final double? locationLng;
  final bool isNegotiable;
  final bool isSold;
  final bool isActive;
  final bool isFlagged;
  final int views;
  final int inquiries;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MarketplaceListingModel({
    required this.id,
    required this.userId,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    required this.price,
    this.currency = 'USD',
    this.category,
    this.condition,
    this.images = const [],
    this.locationText,
    this.locationLat,
    this.locationLng,
    this.isNegotiable = true,
    this.isSold = false,
    this.isActive = true,
    this.isFlagged = false,
    this.views = 0,
    this.inquiries = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceListingModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceListingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String?,
      condition: json['condition'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      locationText: json['location_text'] as String?,
      locationLat: json['location_lat'] != null
          ? (json['location_lat'] as num).toDouble()
          : null,
      locationLng: json['location_lng'] != null
          ? (json['location_lng'] as num).toDouble()
          : null,
      isNegotiable: json['is_negotiable'] as bool? ?? true,
      isSold: json['is_sold'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isFlagged: json['is_flagged'] as bool? ?? false,
      views: json['views'] as int? ?? 0,
      inquiries: json['inquiries'] as int? ?? 0,
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
      'user_id': userId,
      'title': title,
      'title_ar': titleAr,
      'description': description,
      'description_ar': descriptionAr,
      'price': price,
      'currency': currency,
      'category': category,
      'condition': condition,
      'images': images,
      'location_text': locationText,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'is_negotiable': isNegotiable,
      'is_sold': isSold,
      'is_active': isActive,
      'is_flagged': isFlagged,
      'views': views,
      'inquiries': inquiries,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
