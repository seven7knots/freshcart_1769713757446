import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import '../../providers/ai_provider.dart';
import '../../services/analytics_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/typing_indicator_widget.dart';

/// Unified AI Mate screen - combines chat assistant + AI-powered search
/// into a single clean interface. All AI features accessible from here.
class AIChatAssistantScreen extends ConsumerStatefulWidget {
  const AIChatAssistantScreen({super.key});

  @override
  ConsumerState<AIChatAssistantScreen> createState() =>
      _AIChatAssistantScreenState();
}

class _AIChatAssistantScreenState extends ConsumerState<AIChatAssistantScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logAIChatStart();
    AnalyticsService.logScreenView(screenName: 'ai_mate_screen');
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final state = ref.read(aiConversationProvider);

    AnalyticsService.logAIMessageSent(
      conversationId: state.conversationId,
      messageCount: state.messages.length + 1,
    );

    ref.read(aiConversationProvider.notifier).sendMessage(message);
    _messageController.clear();
    _scrollToBottom();
  }

  void _handleQuickSuggestion(String suggestion) {
    ref.read(aiConversationProvider.notifier).sendMessage(suggestion);
    _scrollToBottom();
  }

  Future<void> _handleVoiceInput() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage();
        return;
      }

      setState(() => _isRecording = true);

      if (kIsWeb) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: 'voice_message.wav',
        );
      } else {
        await _audioRecorder.start(
          const RecordConfig(),
          path: 'voice_message.m4a',
        );
      }

      Future.delayed(const Duration(seconds: 60), () {
        if (_isRecording) _stopRecording();
      });
    } catch (e) {
      debugPrint('Recording error: $e');
      setState(() => _isRecording = false);
      _showSnackBar('Failed to start recording. Please try again.');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessingVoice = true;
      });

      final path = await _audioRecorder.stop();
      if (path != null) {
        await _processVoiceInput(path);
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      _showSnackBar('Failed to process recording.');
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<void> _processVoiceInput(String audioPath) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final transcribedText =
          'Voice message transcribed (Lebanese Arabic support coming soon)';
      _messageController.text = transcribedText;
      _sendMessage();

      AnalyticsService.logAIFeatureUsage(
        featureName: 'voice_input_lebanese_arabic',
        additionalParams: {
          'audio_path': audioPath,
          'conversation_id': ref.read(aiConversationProvider).conversationId,
        },
      );
    } catch (e) {
      debugPrint('Voice processing error: $e');
      _showSnackBar('Failed to process voice input.');
    }
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Microphone permission is required for voice input'),
        backgroundColor: AppTheme.kjRed,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.kjRed,
      ),
    );
  }

  void _showPlusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlusMenuSheet(),
    );
  }

  Widget _buildPlusMenuSheet() {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _buildPlusMenuItem(
            icon: Icons.restaurant_menu_rounded,
            label: 'Meal Planning',
            subtitle: 'Plan meals, get grocery lists & add to cart',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.aiMealPlanning);
            },
          ),
          _buildPlusMenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Clear Conversation',
            subtitle: 'Start a fresh chat',
            onTap: () {
              ref.read(aiConversationProvider.notifier).clearConversation();
              Navigator.pop(context);
            },
          ),
          _buildPlusMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Tips',
            subtitle: 'Learn what AI Mate can do',
            onTap: () {
              Navigator.pop(context);
              _showHelpSheet();
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPlusMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.kjRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.kjRed, size: 20),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.all(4.w),
        constraints: BoxConstraints(maxHeight: 70.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'What AI Mate can do',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildHelpItem(
                Icons.search_rounded,
                'Find Products & Stores',
                'Search across all stores, compare prices, find the cheapest option for any product.',
              ),
              _buildHelpItem(
                Icons.shopping_cart_rounded,
                'Add to Cart',
                'Found what you need? Add products directly to your cart from the chat.',
              ),
              _buildHelpItem(
                Icons.local_shipping_rounded,
                'Track Orders',
                'Check the status of your current and past orders instantly.',
              ),
              _buildHelpItem(
                Icons.restaurant_menu_rounded,
                'Meal Planning',
                'Get personalized meal plans with grocery lists. Tap + to access.',
              ),
              _buildHelpItem(
                Icons.local_offer_rounded,
                'Deals & Offers',
                'Discover active promotions, discounts, and the best deals available.',
              ),
              _buildHelpItem(
                Icons.support_agent_rounded,
                'Customer Support',
                'Help with refunds, cancellations, order issues, and general questions.',
              ),
              _buildHelpItem(
                Icons.mic_rounded,
                'Voice Commands',
                'Tap the microphone to speak your request. Arabic support coming soon.',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.kjRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.kjRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(aiConversationProvider);
    final hasMessages = conversationState.messages.isNotEmpty;
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color scaffoldBg = isLight ? theme.scaffoldBackgroundColor : const Color(0xFF0D0D0D);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: hasMessages
                  ? _buildChatView(conversationState)
                  : _buildWelcomeView(),
            ),
            // Error banner
            if (conversationState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.withOpacity(0.1),
                child: Text(
                  conversationState.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            // Input bar
            _buildInputBar(conversationState),
          ],
        ),
      ),
    );
  }

  /// Welcome view when no messages - clean, centered design
  Widget _buildWelcomeView() {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color titleColor = isLight ? Colors.black87 : Colors.white.withOpacity(0.85);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 12.h),
            // Welcome text
            Text(
              'What can I help with?',
              style: TextStyle(
                color: titleColor,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5.h),
            // Quick suggestion chips
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color chipBg = isLight ? Colors.grey.shade100 : Colors.white.withOpacity(0.06);
    final Color chipBorder = isLight ? Colors.grey.shade300 : Colors.white.withOpacity(0.1);
    final Color chipIconColor = isLight ? Colors.grey.shade600 : Colors.white.withOpacity(0.5);
    final Color chipTextColor = isLight ? Colors.grey.shade700 : Colors.white.withOpacity(0.7);
    final suggestions = [
      _SuggestionItem(
        Icons.search_rounded,
        'Find the cheapest milk near me',
      ),
      _SuggestionItem(
        Icons.local_offer_rounded,
        'Show me today\'s best deals',
      ),
      _SuggestionItem(
        Icons.restaurant_rounded,
        'I\'m hungry, suggest something to eat',
      ),
      _SuggestionItem(
        Icons.local_shipping_rounded,
        'Track my latest order',
      ),
      _SuggestionItem(
        Icons.store_rounded,
        'What stores are open right now?',
      ),
      _SuggestionItem(
        Icons.shopping_bag_rounded,
        'Help me plan a grocery list',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((s) {
        return GestureDetector(
          onTap: () => _handleQuickSuggestion(s.text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: chipBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  s.icon,
                  color: chipIconColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.text,
                    style: TextStyle(
                      color: chipTextColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Chat view with messages
  Widget _buildChatView(AIConversationState conversationState) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: conversationState.messages.length +
          (conversationState.isLoading || conversationState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == conversationState.messages.length) {
          return const TypingIndicatorWidget();
        }

        final message = conversationState.messages[index];
        return MessageBubbleWidget(
          message: message,
          isUser: message.role == 'user',
        );
      },
    );
  }

  /// Clean input bar with + button, text field, mic, and send
  /// Fully theme-aware: adapts colors for both light and dark mode.
  Widget _buildInputBar(AIConversationState conversationState) {
    final bool isDisabled = conversationState.isLoading ||
        conversationState.isStreaming ||
        _isProcessingVoice;

    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    // Adaptive colors
    final Color outerBg = isLight ? theme.scaffoldBackgroundColor : const Color(0xFF0D0D0D);
    final Color barBg = isLight ? Colors.grey.shade200 : const Color(0xFF1A1A1A);
    final Color barBorder = isLight ? Colors.grey.shade300 : Colors.white.withOpacity(0.08);
    final Color iconColor = isLight ? Colors.grey.shade600 : Colors.white.withOpacity(0.5);
    final Color textColor = isLight ? Colors.black87 : Colors.white;
    final Color hintColor = isLight ? Colors.grey.shade500 : Colors.white.withOpacity(0.35);
    final Color sendBg = isLight
        ? (isDisabled ? Colors.grey.shade300 : Colors.grey.shade400)
        : (isDisabled ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12));
    final Color sendIcon = isLight
        ? (isDisabled ? Colors.grey.shade500 : Colors.white)
        : (isDisabled ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.8));

    return Container(
      padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.h),
      decoration: BoxDecoration(
        color: outerBg,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: barBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: barBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Plus button
            GestureDetector(
              onTap: _showPlusMenu,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12, top: 12),
                child: Icon(
                  Icons.add_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            // Text field — wrapped in Theme to override global inputDecorationTheme
            Expanded(
              child: Theme(
                data: theme.copyWith(
                  inputDecorationTheme: InputDecorationThemeData(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: _isRecording ? 'Listening...' : 'Ask anything',
                    hintStyle: TextStyle(
                      color: _isRecording ? AppTheme.kjRed : hintColor,
                      fontSize: 15,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isDisabled ? null : _sendMessage(),
                  enabled: !isDisabled && !_isRecording,
                ),
              ),
            ),
            // Voice button
            GestureDetector(
              onTap: isDisabled ? null : _handleVoiceInput,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 8, top: 8),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _isRecording ? AppTheme.kjRed : Colors.transparent,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                    color: _isRecording ? Colors.white : iconColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Send button
            GestureDetector(
              onTap: isDisabled ? null : _sendMessage,
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6, top: 6),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sendBg,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: sendIcon,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem {
  final IconData icon;
  final String text;
  _SuggestionItem(this.icon, this.text);
}