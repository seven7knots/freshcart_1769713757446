import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/messaging_service.dart';

// Messaging service provider
final messagingServiceProvider = Provider((ref) => MessagingService());

// Conversations list provider
final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final service = ref.watch(messagingServiceProvider);
  return await service.getConversations();
});

// Conversation detail provider
final conversationDetailProvider =
    FutureProvider.family<ConversationModel?, String>(
        (ref, conversationId) async {
  final service = ref.watch(messagingServiceProvider);
  return await service.getConversationById(conversationId);
});

// Messages provider for a conversation
final messagesProvider = FutureProvider.family<List<MessageModel>, String>(
    (ref, conversationId) async {
  final service = ref.watch(messagingServiceProvider);
  return await service.getMessages(conversationId: conversationId);
});

// Total unread count provider
final totalUnreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(messagingServiceProvider);
  return await service.getTotalUnreadCount();
});

// State provider for active conversation ID
final activeConversationIdProvider = StateProvider<String?>((ref) => null);
