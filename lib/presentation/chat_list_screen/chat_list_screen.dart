import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/conversation_model.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import './widgets/conversation_card_widget.dart';
import './widgets/empty_chat_state_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _searchController = TextEditingController();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Buying, Selling

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final conversations = await _messagingService.getConversations();
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  void _filterConversations(String query) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    setState(() {
      _filteredConversations = _conversations.where((conv) {
        if (query.isNotEmpty) {
          final otherParticipant =
              conv.getOtherParticipantProfile(currentUserId);
          final name =
              (otherParticipant?['full_name'] as String? ?? '').toLowerCase();
          final listingTitle =
              (conv.listing?['title'] as String? ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          if (!name.contains(searchLower) &&
              !listingTitle.contains(searchLower)) {
            return false;
          }
        }

        if (_selectedFilter == 'Buying') {
          return conv.buyerId == currentUserId;
        } else if (_selectedFilter == 'Selling') {
          return conv.sellerId == currentUserId;
        }

        return true;
      }).toList();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterConversations(_searchController.text);
  }

  Future<void> _archiveConversation(String conversationId) async {
    try {
      await _messagingService.archiveConversation(conversationId);
      await _loadConversations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.conversationArchived, maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    } catch (e) {
      print('❌ Error archiving conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConversations,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchConversations,
                hintStyle: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.w),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),
          // Filter tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _buildFilterChip(AppLocalizations.of(context)!.all2),
                SizedBox(width: 2.w),
                _buildFilterChip(AppLocalizations.of(context)!.buying),
                SizedBox(width: 2.w),
                _buildFilterChip(AppLocalizations.of(context)!.selling),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          // Conversations list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? EmptyChatStateWidget(
                        onExploreMarketplace: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.marketplaceScreen,
                          );
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return ConversationCardWidget(
                              conversation: conversation,
                              currentUserId: currentUserId,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.marketplaceChatScreen,
                                  arguments: {
                                    'conversationId': conversation.id,
                                  },
                                ).then((_) => _loadConversations());
                              },
                              onArchive: () =>
                                  _archiveConversation(conversation.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE50914) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(5.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}