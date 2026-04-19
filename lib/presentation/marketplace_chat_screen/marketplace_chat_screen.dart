// ============================================================
// FILE: lib/presentation/marketplace_chat_screen/marketplace_chat_screen.dart
// ============================================================
// SESSION 28 FIX:
// CRASH: _loadConversation() was called from initState() which called
// ScaffoldMessenger.of(context) before the widget tree was fully built.
// Flutter throws: "dependOnInheritedWidgetOfExactType was called before
// _MarketplaceChatScreenState.initState() completed."
//
// FIX: Added _hasLoadedConversation guard + moved load call to
// didChangeDependencies() — identical pattern to listing detail screen.
// ScaffoldMessenger.of(context) is now only called after mount completes.
// ============================================================

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
import '../../l10n/generated/app_localizations.dart';

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
  bool _hasLoadedConversation = false; // SESSION 28 FIX: guard flag
  RealtimeChannel? _messageSubscription;
  RealtimeChannel? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    // SESSION 28 FIX: Do NOT call _loadConversation() here.
    // initState() runs before the widget is fully mounted in the tree,
    // so ModalRoute.of(context) and ScaffoldMessenger.of(context) are
    // not yet available — calling them crashes with:
    // "dependOnInheritedWidgetOfExactType was called before initState completed"
    // Moved to didChangeDependencies() below.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // SESSION 28 FIX: Load here instead — called after initState AND
    // whenever dependencies (like ModalRoute) change. Guard ensures
    // we only load once.
    if (!_hasLoadedConversation) {
      _hasLoadedConversation = true;
      _loadConversation();
    }
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
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final conversationId = args?['conversationId'] as String?;
      final listingId = args?['listingId'] as String?;
      final sellerId = args?['sellerId'] as String?;

      if (conversationId != null) {
        final conv =
            await _messagingService.getConversationById(conversationId);
        if (!mounted) return;
        if (conv != null) {
          setState(() => _conversation = conv);
          await _loadMessages();
          _setupRealtimeSubscriptions();
        }
      } else if (listingId != null && sellerId != null) {
        final conv = await _messagingService.getOrCreateConversation(
          listingId: listingId,
          sellerId: sellerId,
        );
        setState(() => _conversation = conv);
        await _loadMessages();
        _setupRealtimeSubscriptions();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      // Safe: ScaffoldMessenger called only after mount is confirmed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load conversation: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  Future<void> _loadMessages() async {
    if (_conversation == null) return;

    try {
      final messages = await _messagingService.getMessages(
        conversationId: _conversation!.id,
      );
      setState(() => _messages = messages);
      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      // Non-fatal — messages just won't show, user can retry
    }
  }

  void _setupRealtimeSubscriptions() {
    if (_conversation == null) return;

    _messageSubscription = _messagingService.subscribeToMessages(
      conversationId: _conversation!.id,
      onNewMessage: (message) {
        setState(() => _messages.add(message));
        _scrollToBottom();
        _markMessagesAsRead();
      },
    );

    _conversationSubscription =
        _messagingService.subscribeToConversationUpdates(
      conversationId: _conversation!.id,
      onUpdate: (updatedConv) {
        setState(() => _conversation = updatedConv);
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
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

  Future<void> _markMessagesAsRead() async {
    if (_conversation == null) return;
    try {
      await _messagingService.markAllMessagesAsRead(_conversation!.id);
    } catch (e) { debugPrint('[MARKETPLACE_CHAT_SCREEN] Silent error: $e'); }
  }

  Future<void> _sendMessage() async {
    if (_conversation == null || _isSending) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _messagingService.sendMessage(
        conversationId: _conversation!.id,
        content: content,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.conversationNotFound,
            style: TextStyle(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    final otherParticipant =
        _conversation!.getOtherParticipantProfile(currentUserId);
    final otherParticipantName =
        otherParticipant?['full_name'] as String? ?? AppLocalizations.of(context)!.user;
    final otherParticipantImage =
        otherParticipant?['profile_image_url'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                    AppLocalizations.of(context)!.activeNow,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (_conversation!.listing != null)
            ListingContextCardWidget(
              listing: _conversation!.listing!,
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 15.w, color: Colors.grey),
                        SizedBox(height: 2.h),
                        Text(
                          AppLocalizations.of(context)!.noMessagesYet,
                          style:
                              TextStyle(fontSize: 14.sp, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 1.h),
                        Text(
                          AppLocalizations.of(context)!.startTheConversation,
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 2.h),
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