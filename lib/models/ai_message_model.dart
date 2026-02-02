class AIMessageModel {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final MessageContentType contentType;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isError;

  AIMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.contentType = MessageContentType.text,
    this.metadata,
    required this.timestamp,
    this.isError = false,
  });

  factory AIMessageModel.fromJson(Map<String, dynamic> json) {
    return AIMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      contentType: MessageContentType.values.firstWhere(
        (e) => e.toString() == 'MessageContentType.${json['content_type']}',
        orElse: () => MessageContentType.text,
      ),
      metadata: json['metadata'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isError: json['is_error'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'content_type': contentType.toString().split('.').last,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'is_error': isError,
    };
  }
}

enum MessageContentType {
  text,
  productCard,
  orderSummary,
  mealPlan,
  actionButtons,
}
