import 'package:flutter/material.dart';
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
