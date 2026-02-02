import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_theme.dart';
import './widgets/listing_context_card_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';

class MarketplaceChatScreen extends ConsumerStatefulWidget {
  const MarketplaceChatScreen({super.key});

  @override
  ConsumerState<MarketplaceChatScreen> createState() =>
      _MarketplaceChatScreenState();
}

class _MarketplaceChatScreenState extends ConsumerState<MarketplaceChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final MessagingService _messagingService = MessagingService();

  ConversationModel? _conversation;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _messageSubscription;
  RealtimeChannel? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageSubscription?.unsubscribe();
    _conversationSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      // Get conversation ID from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final conversationId = args?['conversationId'] as String?;
      final listingId = args?['listingId'] as String?;
      final sellerId = args?['sellerId'] as String?;

      if (conversationId != null) {
        // Load existing conversation
        final conv =
            await _messagingService.getConversationById(conversationId);
        if (conv != null) {
          setState(() {
            _conversation = conv;
          });
          await _loadMessages();
          _setupRealtimeSubscriptions();
        }
      } else if (listingId != null && sellerId != null) {
        // Create or get conversation
        final conv = await _messagingService.getOrCreateConversation(
          listingId: listingId,
          sellerId: sellerId,
        );
        setState(() {
          _conversation = conv;
        });
        await _loadMessages();
        _setupRealtimeSubscriptions();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading conversation: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversation: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_conversation == null) return;

    try {
      final messages = await _messagingService.getMessages(
        conversationId: _conversation!.id,
      );
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      print('❌ Error loading messages: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    if (_conversation == null) return;

    // Subscribe to new messages
    _messageSubscription = _messagingService.subscribeToMessages(
      conversationId: _conversation!.id,
      onNewMessage: (message) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        _markMessagesAsRead();
      },
    );

    // Subscribe to conversation updates
    _conversationSubscription =
        _messagingService.subscribeToConversationUpdates(
      conversationId: _conversation!.id,
      onUpdate: (updatedConv) {
        setState(() {
          _conversation = updatedConv;
        });
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_conversation == null) return;

    try {
      await _messagingService.markAllMessagesAsRead(_conversation!.id);
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_conversation == null || _isSending) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _messagingService.sendMessage(
        conversationId: _conversation!.id,
        content: content,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Conversation not found',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
    }

    final otherParticipant =
        _conversation!.getOtherParticipantProfile(currentUserId);
    final otherParticipantName =
        otherParticipant?['full_name'] as String? ?? 'User';
    final otherParticipantImage =
        otherParticipant?['profile_image_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 4.w,
              backgroundImage: otherParticipantImage != null
                  ? NetworkImage(otherParticipantImage)
                  : null,
              child: otherParticipantImage == null
                  ? Icon(Icons.person, size: 4.w)
                  : null,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipantName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Listing context card
          if (_conversation!.listing != null)
            ListingContextCardWidget(
              listing: _conversation!.listing!,
            ),
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 15.w,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser = message.senderId == currentUserId;
                      return MessageBubbleWidget(
                        message: message,
                        isCurrentUser: isCurrentUser,
                      );
                    },
                  ),
          ),
          // Message input
          MessageInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }
}
