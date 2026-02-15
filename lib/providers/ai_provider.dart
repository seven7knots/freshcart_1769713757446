import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../models/ai_message_model.dart';
import 'package:uuid/uuid.dart';

final aiServiceProvider = Provider((ref) => AIService());

final aiConversationProvider =
    StateNotifierProvider<AIConversationNotifier, AIConversationState>(
  (ref) => AIConversationNotifier(ref.read(aiServiceProvider)),
);

class AIConversationState {
  final String conversationId;
  final List<AIMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final Map<String, dynamic>? contextData;

  AIConversationState({
    required this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.contextData,
  });

  AIConversationState copyWith({
    String? conversationId,
    List<AIMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    Map<String, dynamic>? contextData,
  }) {
    return AIConversationState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      contextData: contextData ?? this.contextData,
    );
  }
}

class AIConversationNotifier extends StateNotifier<AIConversationState> {
  final AIService _aiService;
  final Uuid _uuid = const Uuid();

  AIConversationNotifier(this._aiService)
      : super(AIConversationState(conversationId: const Uuid().v4()));

  void updateContext(Map<String, dynamic> contextData) {
    state = state.copyWith(contextData: contextData);
  }

  /// Keywords that suggest the user is looking for products/stores
  static const _searchKeywords = [
    'find', 'search', 'look for', 'cheapest', 'cheap', 'buy',
    'order', 'get me', 'show me', 'where can i', 'price',
    'cost', 'deals', 'discount', 'offer', 'grocery', 'groceries',
    'food', 'milk', 'bread', 'rice', 'chicken', 'meat', 'fruits',
    'vegetables', 'snack', 'drink', 'water', 'juice', 'coffee',
    'near me', 'nearby', 'closest', 'open now', 'available',
    'store', 'restaurant', 'pharmacy', 'shop',
    'hungry', 'eat', 'dinner', 'lunch', 'breakfast', 'meal',
    'suggest', 'recommend', 'best', 'top rated',
  ];

  /// Keywords that indicate order tracking intent
  static const _trackingKeywords = [
    'track', 'tracking', 'my order', 'where is', 'status',
    'delivery', 'when will', 'shipped', 'delivered',
  ];

  /// Detect if the user message is a product/search query
  bool _isProductSearchQuery(String message) {
    final lower = message.toLowerCase();
    return _searchKeywords.any((kw) => lower.contains(kw));
  }

  /// Detect if the user is asking about order tracking
  bool _isTrackingQuery(String message) {
    final lower = message.toLowerCase();
    return _trackingKeywords.any((kw) => lower.contains(kw));
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = AIMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final conversationHistory = state.messages
          .map((msg) => {'role': msg.role, 'content': msg.content})
          .toList();

      // Check if this is a product search query - if so, also search database
      Map<String, dynamic>? richMetadata;

      if (_isProductSearchQuery(message)) {
        richMetadata = await _performSmartSearch(message);
      }

      // Build context data with any search results
      final contextData = Map<String, dynamic>.from(state.contextData ?? {});
      if (richMetadata != null && richMetadata['results'] != null) {
        final results = richMetadata['results'] as List;
        if (results.isNotEmpty) {
          contextData['search_results'] = results
              .take(5)
              .map((r) =>
                  '${r['name']} - ${r['currency'] ?? 'USD'} ${r['price']} (${r['item_type']})')
              .join('\n');
          contextData['search_query'] = message;
        }
      }

      // Generate AI response with context
      final response = await _aiService.generateResponse(
        userMessage: message,
        conversationId: state.conversationId,
        conversationHistory: conversationHistory,
        contextData: contextData.isNotEmpty ? contextData : null,
      );

      // Build metadata for rich message content
      Map<String, dynamic>? messageMetadata;

      if (richMetadata != null &&
          richMetadata['results'] != null &&
          (richMetadata['results'] as List).isNotEmpty) {
        final results = richMetadata['results'] as List;
        final productCards = results.take(5).map((r) {
          return {
            'product_id': r['item_id'],
            'name': r['name'],
            'price': r['price'],
            'currency': r['currency'] ?? 'USD',
            'image_url': r['image_url'],
            'store_name': r['merchant_id'] ?? '',
            'is_available': r['availability'] ?? true,
            'category': r['category'] ?? '',
          };
        }).toList();

        messageMetadata = {
          'products': productCards,
        };
      }

      final aiMessage = AIMessageModel(
        id: _uuid.v4(),
        conversationId: state.conversationId,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        metadata: messageMetadata,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      // Track AI feature usage
      await AnalyticsService.logAIFeatureUsage(
        featureName: richMetadata != null ? 'smart_search_chat' : 'chat_assistant',
        additionalParams: {
          'conversation_id': state.conversationId,
          'message_count': state.messages.length,
          'has_products': richMetadata != null,
        },
      );
    } catch (e) {
      debugPrint('AI sendMessage error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get AI response. Please try again.',
      );
    }
  }

  /// Perform smart search across products and services
  Future<Map<String, dynamic>?> _performSmartSearch(String query) async {
    try {
      final results = await _aiService.unifiedMarketplaceSearch(
        query: query,
        sortBy: 'relevance',
      );
      return results;
    } catch (e) {
      debugPrint('Smart search error: $e');
      return null;
    }
  }

  Stream<String> streamMessage(String message) async* {
    if (message.trim().isEmpty) return;

    final userMessage = AIMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      error: null,
    );

    try {
      final conversationHistory = state.messages
          .map((msg) => {'role': msg.role, 'content': msg.content})
          .toList();

      final fullResponse = StringBuffer();
      final aiMessageId = _uuid.v4();

      await for (var chunk in _aiService.streamResponse(
        userMessage: message,
        conversationId: state.conversationId,
        conversationHistory: conversationHistory,
        contextData: state.contextData,
      )) {
        fullResponse.write(chunk);
        yield chunk;
      }

      final aiMessage = AIMessageModel(
        id: aiMessageId,
        conversationId: state.conversationId,
        role: 'assistant',
        content: fullResponse.toString(),
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isStreaming: false,
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        error: 'Failed to stream AI response: $e',
      );
    }
  }

  void clearConversation() {
    state = AIConversationState(conversationId: _uuid.v4());
  }

  void addQuickMessage(String message) {
    sendMessage(message);
  }
}