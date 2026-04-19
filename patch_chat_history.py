"""Issue 5: AI Mate chat history — persistence + history drawer + new chat.

- providers/ai_provider.dart: persist conversations + messages to Supabase,
  add loadConversation(id), change clearConversation to reset flag.
- ai_chat_assistant_screen.dart: top bar with history + new-chat buttons.
- NEW: presentation/ai_conversation_history_screen/ai_conversation_history_screen.dart.
- routes/app_routes.dart: register new route.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent


# ------------------ ai_provider.dart ------------------
def patch_ai_provider() -> None:
    path = ROOT / 'lib/providers/ai_provider.dart'
    s = path.read_text(encoding='utf-8')

    # 1) Add `persisted` flag to state.
    old_state = """class AIConversationState {
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
}"""

    new_state = """class AIConversationState {
  final String conversationId;
  final List<AIMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final Map<String, dynamic>? contextData;
  // True once the conversation has a row in ai_conversations. Created on first
  // user send so empty conversations never litter the history list.
  final bool persisted;

  AIConversationState({
    required this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.contextData,
    this.persisted = false,
  });

  AIConversationState copyWith({
    String? conversationId,
    List<AIMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    Map<String, dynamic>? contextData,
    bool? persisted,
  }) {
    return AIConversationState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      contextData: contextData ?? this.contextData,
      persisted: persisted ?? this.persisted,
    );
  }
}"""

    if old_state not in s:
        raise SystemExit("ai_provider: state class block not found verbatim")
    s = s.replace(old_state, new_state)

    # 2) Insert persistence helpers inside the notifier (after _getUserContext).
    anchor = """  Future<Map<String, dynamic>> _getUserContext() async {"""
    if anchor not in s:
        raise SystemExit("ai_provider: _getUserContext anchor not found")

    # 3) Wire persistence into sendMessage.
    # Replace initial user-message append to also ensure row + insert user message.
    old_user_append = """  Future<void> sendMessage(String message) async {
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
    );"""

    new_user_append = """  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Ensure the conversation row exists before any DB insert of messages.
    await _ensureConversationPersisted(firstMessage: message);

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

    // Fire-and-forget DB insert for user message. RLS guards by user_id.
    unawaited(_persistMessage(role: 'user', content: message));"""

    if old_user_append not in s:
        raise SystemExit("ai_provider: sendMessage user-append block not found")
    s = s.replace(old_user_append, new_user_append)

    # Persist assistant reply too. Find block after `state = state.copyWith(... aiMessage)`.
    old_assistant = """      final aiMessage = AIMessageModel(
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
      );"""

    new_assistant = """      final aiMessage = AIMessageModel(
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

      unawaited(_persistMessage(role: 'assistant', content: response));"""

    if old_assistant not in s:
        raise SystemExit("ai_provider: sendMessage assistant-append block not found")
    s = s.replace(old_assistant, new_assistant)

    # 4) Replace clearConversation + append new public methods.
    old_clear = """  void clearConversation() {
    state = AIConversationState(conversationId: _uuid.v4());
  }

  void addQuickMessage(String message) {
    sendMessage(message);
  }
}"""

    new_clear = """  void clearConversation() {
    // Fresh un-persisted conversation; row only gets created on next send.
    state = AIConversationState(conversationId: _uuid.v4());
  }

  void addQuickMessage(String message) {
    sendMessage(message);
  }

  // ============================================================
  // Chat history persistence
  // ============================================================

  Future<void> _ensureConversationPersisted({required String firstMessage}) async {
    if (state.persisted) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final title = _titleFromMessage(firstMessage);
    try {
      await SupabaseService.client.from('ai_conversations').insert({
        'id': state.conversationId,
        'user_id': user.id,
        'title': title,
      });
      state = state.copyWith(persisted: true);
    } catch (e) {
      debugPrint('[AI_HISTORY] Failed to create conversation row: $e');
    }
  }

  Future<void> _persistMessage({
    required String role,
    required String content,
  }) async {
    if (!state.persisted) return;
    try {
      await SupabaseService.client.from('ai_messages').insert({
        'conversation_id': state.conversationId,
        'role': role,
        'content': content,
      });
    } catch (e) {
      debugPrint('[AI_HISTORY] Failed to persist $role message: $e');
    }
  }

  String _titleFromMessage(String message) {
    final trimmed = message.trim().replaceAll(RegExp(r'\\s+'), ' ');
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 40)}...';
  }

  /// Load a past conversation by id and make it active.
  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rows = await SupabaseService.client
          .from('ai_messages')
          .select('id, conversation_id, role, content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (rows as List).map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return AIMessageModel(
          id: m['id']?.toString() ?? _uuid.v4(),
          conversationId: conversationId,
          role: (m['role'] ?? 'user').toString(),
          content: (m['content'] ?? '').toString(),
          timestamp: m['created_at'] != null
              ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
      }).toList();

      state = AIConversationState(
        conversationId: conversationId,
        messages: messages,
        persisted: true,
      );
    } catch (e) {
      debugPrint('[AI_HISTORY] loadConversation failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load conversation.',
      );
    }
  }

  void startNewConversation() => clearConversation();
}"""

    if old_clear not in s:
        raise SystemExit("ai_provider: clearConversation block not found")
    s = s.replace(old_clear, new_clear)

    # 5) Add `import 'dart:async';` for unawaited().
    if "import 'dart:async';" not in s:
        # insert after first import line
        s = s.replace(
            "import 'package:flutter/foundation.dart';",
            "import 'dart:async';\nimport 'package:flutter/foundation.dart';",
            1,
        )

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


# ------------------ ai_chat_assistant_screen.dart ------------------
def patch_chat_screen() -> None:
    path = ROOT / 'lib/presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart'
    s = path.read_text(encoding='utf-8')

    # Insert a top bar Row before the Expanded in the build method.
    old_body = """    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: hasMessages
                  ? _buildChatView(conversationState)
                  : _buildWelcomeView(),
            ),"""

    new_body = """    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isLight),
            // Main content area
            Expanded(
              child: hasMessages
                  ? _buildChatView(conversationState)
                  : _buildWelcomeView(),
            ),"""

    if old_body not in s:
        raise SystemExit("chat screen: Scaffold body anchor not found")
    s = s.replace(old_body, new_body)

    # Append _buildTopBar method before _buildWelcomeView.
    old_welcome_sig = """  /// Welcome view when no messages - clean, centered design
  Widget _buildWelcomeView() {"""

    new_welcome_sig = """  Widget _buildTopBar(bool isLight) {
    final Color iconColor =
        isLight ? Colors.black54 : Colors.white.withOpacity(0.75);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'New chat',
            icon: Icon(Icons.add_circle_outline_rounded, color: iconColor),
            onPressed: () {
              ref.read(aiConversationProvider.notifier).startNewConversation();
              _messageController.clear();
            },
          ),
          IconButton(
            tooltip: 'Chat history',
            icon: Icon(Icons.history_rounded, color: iconColor),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.aiConversationHistory,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Welcome view when no messages - clean, centered design
  Widget _buildWelcomeView() {"""

    if old_welcome_sig not in s:
        raise SystemExit("chat screen: welcome view anchor not found")
    s = s.replace(old_welcome_sig, new_welcome_sig)

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


# ------------------ history screen (new) ------------------
HISTORY_SCREEN = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../../providers/ai_provider.dart';
import '../../services/supabase_service.dart';

class AIConversationHistoryScreen extends ConsumerStatefulWidget {
  const AIConversationHistoryScreen({super.key});

  @override
  ConsumerState<AIConversationHistoryScreen> createState() =>
      _AIConversationHistoryScreenState();
}

class _AIConversationHistoryScreenState
    extends ConsumerState<AIConversationHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in to see your chat history.';
        _items = [];
      });
      return;
    }
    try {
      final convRows = await SupabaseService.client
          .from('ai_conversations')
          .select('id, title, updated_at')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(50);

      final rows = (convRows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Fetch last message preview per conversation (best-effort).
      for (final row in rows) {
        try {
          final last = await SupabaseService.client
              .from('ai_messages')
              .select('content, created_at, role')
              .eq('conversation_id', row['id'])
              .order('created_at', ascending: false)
              .limit(1);
          final lastList = last as List;
          row['preview'] = lastList.isNotEmpty
              ? (lastList.first as Map)['content']?.toString() ?? ''
              : '';
        } catch (_) {
          row['preview'] = '';
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = rows;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load history.';
        _items = [];
      });
    }
  }

  Future<void> _delete(String id) async {
    setState(() {
      _items.removeWhere((r) => r['id'] == id);
    });
    try {
      await SupabaseService.client
          .from('ai_conversations')
          .delete()
          .eq('id', id);
    } catch (_) {
      // Silent — row will reappear on reload if delete failed.
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final diff = DateTime.now().toUtc().difference(t.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color bg = isLight ? theme.scaffoldBackgroundColor : const Color(0xFF0D0D0D);
    final Color tileBg = isLight ? Colors.white : const Color(0xFF1A1A1A);
    final Color fg = isLight ? Colors.black87 : Colors.white;
    final Color sub = isLight ? Colors.black54 : Colors.white60;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chat history'),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              ref.read(aiConversationProvider.notifier).startNewConversation();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: sub, fontSize: 14),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        'No past chats yet.',
                        style: TextStyle(color: sub, fontSize: 14),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 1.h),
                        itemBuilder: (context, index) {
                          final row = _items[index];
                          final id = row['id'].toString();
                          final title =
                              (row['title'] ?? 'Untitled chat').toString();
                          final preview = (row['preview'] ?? '').toString();
                          final when = _relativeTime(row['updated_at']?.toString());

                          return Dismissible(
                            key: ValueKey(id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB8070F),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _delete(id),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await ref
                                    .read(aiConversationProvider.notifier)
                                    .loadConversation(id);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.all(3.5.w),
                                decoration: BoxDecoration(
                                  color: tileBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isLight
                                        ? Colors.black.withOpacity(0.06)
                                        : Colors.white.withOpacity(0.06),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              color: fg,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          when,
                                          style: TextStyle(
                                            color: sub,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (preview.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        preview,
                                        style: TextStyle(
                                          color: sub,
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
"""


def write_history_screen() -> None:
    folder = ROOT / 'lib/presentation/ai_conversation_history_screen'
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / 'ai_conversation_history_screen.dart'
    target.write_text(HISTORY_SCREEN, encoding='utf-8', newline='\n')
    print(f"wrote {target.relative_to(ROOT)}")


# ------------------ routes ------------------
def patch_routes() -> None:
    path = ROOT / 'lib/routes/app_routes.dart'
    s = path.read_text(encoding='utf-8')

    # import
    import_line = "import '../presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart';"
    new_import = (
        "import '../presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart';\n"
        "import '../presentation/ai_conversation_history_screen/ai_conversation_history_screen.dart';"
    )
    if "ai_conversation_history_screen.dart" not in s:
        s = s.replace(import_line, new_import, 1)

    # constant
    old_const = """  static const String aiChatAssistant = '/ai-chat-assistant-screen';
  static const String aiMealPlanning = '/ai-meal-planning-screen';
  static const String aiPoweredSearch = '/ai-powered-search-screen';"""
    new_const = """  static const String aiChatAssistant = '/ai-chat-assistant-screen';
  static const String aiMealPlanning = '/ai-meal-planning-screen';
  static const String aiPoweredSearch = '/ai-powered-search-screen';
  static const String aiConversationHistory = '/ai-conversation-history-screen';"""
    if "aiConversationHistory" not in s:
        s = s.replace(old_const, new_const)

    # route map entry
    old_map = """    aiChatAssistant: (context) => const AIChatAssistantScreen(),
    aiMealPlanning: (context) => const AIMealPlanningScreen(),
    aiPoweredSearch: (context) => const AIChatAssistantScreen(),"""
    new_map = """    aiChatAssistant: (context) => const AIChatAssistantScreen(),
    aiMealPlanning: (context) => const AIMealPlanningScreen(),
    aiPoweredSearch: (context) => const AIChatAssistantScreen(),
    aiConversationHistory: (context) => const AIConversationHistoryScreen(),"""
    if "AIConversationHistoryScreen()" not in s:
        s = s.replace(old_map, new_map)

    path.write_text(s, encoding='utf-8')
    print(f"patched {path.relative_to(ROOT)}")


patch_ai_provider()
patch_chat_screen()
write_history_screen()
patch_routes()
print("done")
