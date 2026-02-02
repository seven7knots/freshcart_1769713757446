class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    this.type,
    required this.title,
    this.titleAr,
    this.body,
    this.bodyAr,
    this.imageUrl,
    this.actionType,
    this.actionData = const {},
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? type;
  final String title;
  final String? titleAr;
  final String? body;
  final String? bodyAr;
  final String? imageUrl;
  final String? actionType;
  final Map<String, dynamic> actionData;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String?,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      body: json['body'] as String?,
      bodyAr: json['body_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      actionType: json['action_type'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
