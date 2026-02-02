import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagingService {
  final SupabaseClient _client = Supabase.instance.client;

  // ========== CONVERSATIONS ==========

  /// Get or create conversation between buyer and seller for a listing
  Future<ConversationModel> getOrCreateConversation({
    required String listingId,
    required String sellerId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('🔍 Getting/creating conversation for listing: $listingId');

      // Try to find existing conversation
      final existing = await _client
          .from('conversations')
          .select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images)
          ''')
          .eq('buyer_id', userId)
          .eq('seller_id', sellerId)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        print('✅ Found existing conversation: ${existing['id']}');
        return ConversationModel.fromJson(existing);
      }

      // Create new conversation
      print('📝 Creating new conversation');
      final response = await _client.from('conversations').insert({
        'buyer_id': userId,
        'seller_id': sellerId,
        'listing_id': listingId,
      }).select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images)
          ''').single();

      print('✅ Created new conversation: ${response['id']}');
      return ConversationModel.fromJson(response);
    } catch (e) {
      print('❌ Error getting/creating conversation: $e');
      throw Exception('Failed to get/create conversation: $e');
    }
  }

  /// Get all conversations for current user
  Future<List<ConversationModel>> getConversations({
    bool includeArchived = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('🔍 Fetching conversations for user: $userId');

      var query = _client.from('conversations').select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images, status)
          ''');

      // Filter by user participation
      query = query.or('buyer_id.eq.$userId,seller_id.eq.$userId');

      // Filter archived if needed
      if (!includeArchived) {
        query = query
            .or('is_archived_by_buyer.eq.false,is_archived_by_seller.eq.false');
      }

      final response = await query.order('last_message_at', ascending: false);

      print('✅ Found ${(response as List).length} conversations');
      return (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading conversations: $e');
      throw Exception('Failed to load conversations: $e');
    }
  }

  /// Get conversation by ID
  Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final response = await _client.from('conversations').select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images, status)
          ''').eq('id', conversationId).maybeSingle();

      if (response == null) return null;
      return ConversationModel.fromJson(response);
    } catch (e) {
      print('❌ Error getting conversation: $e');
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get conversation to determine user role
      final conv = await getConversationById(conversationId);
      if (conv == null) throw Exception('Conversation not found');

      final isBuyer = conv.buyerId == userId;
      final field = isBuyer ? 'is_archived_by_buyer' : 'is_archived_by_seller';

      await _client
          .from('conversations')
          .update({field: true}).eq('id', conversationId);

      print('✅ Archived conversation: $conversationId');
    } catch (e) {
      print('❌ Error archiving conversation: $e');
      throw Exception('Failed to archive conversation: $e');
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get conversation to determine user role
      final conv = await getConversationById(conversationId);
      if (conv == null) throw Exception('Conversation not found');

      final isBuyer = conv.buyerId == userId;
      final field = isBuyer ? 'buyer_unread_count' : 'seller_unread_count';

      await _client
          .from('conversations')
          .update({field: 0}).eq('id', conversationId);

      print('✅ Marked conversation as read: $conversationId');
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  // ========== MESSAGES ==========

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('🔍 Fetching messages for conversation: $conversationId');

      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      print('✅ Found ${(response as List).length} messages');
      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('📤 Sending message to conversation: $conversationId');

      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': messageType,
            'attachment_url': attachmentUrl,
          })
          .select()
          .single();

      print('✅ Message sent: ${response['id']}');
      return MessageModel.fromJson(response);
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _client.from('messages').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);

      print('✅ Marked message as read: $messageId');
    } catch (e) {
      print('❌ Error marking message as read: $e');
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      print('✅ Marked all messages as read in conversation: $conversationId');
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  // ========== REALTIME SUBSCRIPTIONS ==========

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(MessageModel) onNewMessage,
  }) {
    print('🔔 Subscribing to messages for conversation: $conversationId');

    final channel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            print('📨 New message received: ${payload.newRecord}');
            final message = MessageModel.fromJson(payload.newRecord);
            onNewMessage(message);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation updates
  RealtimeChannel subscribeToConversationUpdates({
    required String conversationId,
    required Function(ConversationModel) onUpdate,
  }) {
    print('🔔 Subscribing to conversation updates: $conversationId');

    final channel = _client
        .channel('conversation:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: conversationId,
          ),
          callback: (payload) async {
            print('🔄 Conversation updated: ${payload.newRecord}');
            // Fetch full conversation with joins
            final conv = await getConversationById(conversationId);
            if (conv != null) {
              onUpdate(conv);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to all conversations for current user
  RealtimeChannel subscribeToAllConversations({
    required Function() onUpdate,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    print('🔔 Subscribing to all conversations for user: $userId');

    final channel = _client
        .channel('user_conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            print('🔄 Conversations updated');
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Get total unread count for current user
  Future<int> getTotalUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      print('🔍 Fetching total unread count for user: $userId');

      final conversations = await _client
          .from('conversations')
          .select(
              'buyer_id, seller_id, buyer_unread_count, seller_unread_count')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId');

      int totalUnread = 0;
      for (final conv in conversations as List) {
        if (conv['buyer_id'] == userId) {
          totalUnread += (conv['buyer_unread_count'] as int? ?? 0);
        } else if (conv['seller_id'] == userId) {
          totalUnread += (conv['seller_unread_count'] as int? ?? 0);
        }
      }

      print('✅ Total unread count: $totalUnread');
      return totalUnread;
    } catch (e) {
      print('❌ Error getting total unread count: $e');
      return 0;
    }
  }
}
