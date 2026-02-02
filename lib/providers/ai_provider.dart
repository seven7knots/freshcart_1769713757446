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

      final response = await _aiService.generateResponse(
        userMessage: message,
        conversationId: state.conversationId,
        conversationHistory: conversationHistory,
        contextData: state.contextData,
      );

      final aiMessage = AIMessageModel(
        id: _uuid.v4(),
        conversationId: state.conversationId,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      // Track AI feature usage
      await AnalyticsService.logAIFeatureUsage(
        featureName: 'chat_assistant',
        additionalParams: {
          'conversation_id': state.conversationId,
          'message_count': state.messages.length,
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get AI response: $e',
      );
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
