class AdModel {
  final String id;
  final String title;
  final String? description;
  final String format;
  final String status;
  final String imageUrl;
  final List<String> images;
  final String linkType;
  final String? linkTargetId;
  final String? externalUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final List<int> recurringDays;
  final int displayOrder;
  final int autoPlayInterval;
  final int impressions;
  final int clicks;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdModel({
    required this.id,
    required this.title,
    this.description,
    required this.format,
    required this.status,
    required this.imageUrl,
    this.images = const [],
    required this.linkType,
    this.linkTargetId,
    this.externalUrl,
    this.startDate,
    this.endDate,
    this.isRecurring = false,
    this.recurringDays = const [],
    this.displayOrder = 0,
    this.autoPlayInterval = 4000,
    this.impressions = 0,
    this.clicks = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      format: json['format'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      linkType: json['link_type'] as String,
      linkTargetId: json['link_target_id'] as String?,
      externalUrl: json['external_url'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringDays: json['recurring_days'] != null
          ? List<int>.from(json['recurring_days'] as List)
          : [],
      displayOrder: json['display_order'] as int? ?? 0,
      autoPlayInterval: json['auto_play_interval'] as int? ?? 4000,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
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
      'title': title,
      'description': description,
      'format': format,
      'status': status,
      'image_url': imageUrl,
      'images': images,
      'link_type': linkType,
      'link_target_id': linkTargetId,
      'external_url': externalUrl,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_recurring': isRecurring,
      'recurring_days': recurringDays,
      'display_order': displayOrder,
      'auto_play_interval': autoPlayInterval,
      'impressions': impressions,
      'clicks': clicks,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get ctr {
    if (impressions == 0) return 0.0;
    return (clicks / impressions) * 100;
  }

  bool get isActive {
    if (status != 'active') return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  AdModel copyWith({
    String? id,
    String? title,
    String? description,
    String? format,
    String? status,
    String? imageUrl,
    List<String>? images,
    String? linkType,
    String? linkTargetId,
    String? externalUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    List<int>? recurringDays,
    int? displayOrder,
    int? autoPlayInterval,
    int? impressions,
    int? clicks,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      linkType: linkType ?? this.linkType,
      linkTargetId: linkTargetId ?? this.linkTargetId,
      externalUrl: externalUrl ?? this.externalUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDays: recurringDays ?? this.recurringDays,
      displayOrder: displayOrder ?? this.displayOrder,
      autoPlayInterval: autoPlayInterval ?? this.autoPlayInterval,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
