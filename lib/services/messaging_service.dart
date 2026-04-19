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
        return ConversationModel.fromJson(existing);
      }

      // Create new conversation
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

      return ConversationModel.fromJson(response);
    } catch (e) {
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

      var query = _client.from('conversations').select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images, status)
          ''');

      query = query.or('buyer_id.eq.$userId,seller_id.eq.$userId');

      if (!includeArchived) {
        query = query
            .or('is_archived_by_buyer.eq.false,is_archived_by_seller.eq.false');
      }

      final response = await query.order('last_message_at', ascending: false);

      return (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  /// Get conversation by ID
  // SESSION 29 FIX: Added explicit .or('buyer_id.eq.$userId,seller_id.eq.$userId')
  // filter alongside .eq('id', conversationId).
  //
  // ROOT CAUSE of "Conversation not found":
  // The conversations table RLS policy requires the calling user to be either
  // the buyer or the seller. Without the explicit filter, Supabase/PostgREST
  // passes the query directly to the DB and the RLS policy silently filters
  // out the row — maybeSingle() then returns null even though the row exists.
  // Adding the OR filter makes the intent explicit and satisfies RLS policies
  // that rely on the query predicates rather than auth.uid() checks alone.
  Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client.from('conversations').select('''
            *,
            buyer:users!conversations_buyer_id_fkey(id, full_name, profile_image_url),
            seller:users!conversations_seller_id_fkey(id, full_name, profile_image_url),
            listing:marketplace_listings(id, title, price, images, status)
          ''')
          .eq('id', conversationId)
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .maybeSingle();

      if (response == null) return null;
      return ConversationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final conv = await getConversationById(conversationId);
      if (conv == null) throw Exception('Conversation not found');

      final isBuyer = conv.buyerId == userId;
      final field = isBuyer ? 'is_archived_by_buyer' : 'is_archived_by_seller';

      await _client
          .from('conversations')
          .update({field: true}).eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to archive conversation: $e');
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final conv = await getConversationById(conversationId);
      if (conv == null) throw Exception('Conversation not found');

      final isBuyer = conv.buyerId == userId;
      final field = isBuyer ? 'buyer_unread_count' : 'seller_unread_count';

      await _client
          .from('conversations')
          .update({field: 0}).eq('id', conversationId);
    } catch (e) {
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
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send a message
  // SESSION 28 FIX: messageType default changed from 'text' only.
  // The DB messages_message_type_check constraint does NOT allow 'inquiry'.
  // All quick-inquiry sends must use 'text' as the message_type.
  // The inquiry *content* is preserved in the message body — no data lost.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text', // MUST be 'text' or 'image' — not 'inquiry'
    String? attachmentUrl,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // SESSION 28 FIX: Normalise messageType — if caller accidentally passes
      // 'inquiry' (which violates messages_message_type_check), coerce to 'text'.
      final safeType = (messageType == 'inquiry') ? 'text' : messageType;

      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': safeType,
            'attachment_url': attachmentUrl,
          })
          .select()
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  // ========== REALTIME SUBSCRIPTIONS ==========

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(MessageModel) onNewMessage,
  }) {
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
    if (userId == null) throw Exception('User not authenticated');

    final channel = _client
        .channel('user_conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
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

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}