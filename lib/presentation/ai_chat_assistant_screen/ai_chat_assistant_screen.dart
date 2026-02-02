import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import '../../providers/ai_provider.dart';
import '../../services/analytics_service.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/ai_input_widget.dart';
import './widgets/quick_suggestions_widget.dart';
import './widgets/typing_indicator_widget.dart';

class AIChatAssistantScreen extends ConsumerStatefulWidget {
  const AIChatAssistantScreen({super.key});

  @override
  ConsumerState<AIChatAssistantScreen> createState() =>
      _AIChatAssistantScreenState();
}

class _AIChatAssistantScreenState extends ConsumerState<AIChatAssistantScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessingVoice = false;

  @override
  void initState() {
    super.initState();

    // Track AI chat start
    AnalyticsService.logAIChatStart();
    AnalyticsService.logScreenView(screenName: 'ai_chat_assistant_screen');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final state = ref.read(aiConversationProvider);

    // Track AI message sent
    AnalyticsService.logAIMessageSent(
      conversationId: state.conversationId,
      messageCount: state.messages.length + 1,
    );

    ref.read(aiConversationProvider.notifier).sendMessage(message);
    _messageController.clear();
    _scrollToBottom();
  }

  void _handleQuickSuggestion(String suggestion) {
    ref.read(aiConversationProvider.notifier).addQuickMessage(suggestion);
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
      // Check microphone permission
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

      // Auto-stop after 60 seconds
      Future.delayed(const Duration(seconds: 60), () {
        if (_isRecording) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Recording error: $e');
      setState(() => _isRecording = false);
      _showErrorMessage('Failed to start recording. Please try again.');
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
      _showErrorMessage('Failed to process recording.');
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    if (kIsWeb) return true; // Browser handles permissions

    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<void> _processVoiceInput(String audioPath) async {
    try {
      // TODO: Integrate with backend speech-to-text API for Lebanese Arabic
      // For now, show processing message
      await Future.delayed(const Duration(seconds: 2));

      // Simulate transcription result
      final transcribedText =
          'Voice message transcribed (Lebanese Arabic support coming soon)';

      _messageController.text = transcribedText;
      _sendMessage();

      // Track voice usage
      AnalyticsService.logAIFeatureUsage(
        featureName: 'voice_input_lebanese_arabic',
        additionalParams: {
          'audio_path': audioPath,
          'conversation_id': ref.read(aiConversationProvider).conversationId,
        },
      );
    } catch (e) {
      debugPrint('Voice processing error: $e');
      _showErrorMessage('Failed to process voice input.');
    }
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Microphone permission is required for voice input'),
        backgroundColor: const Color(0xFFE50914),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE50914),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(aiConversationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B46C1),
                    const Color(0xFF9333EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withAlpha(102),
                    blurRadius: 12.0,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white.withAlpha(242),
                  size: 5.w,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  "AI  Assistant ",
                ),
                Text(
                  _isRecording
                      ? 'Recording...'
                      : _isProcessingVoice
                          ? 'Processing...'
                          : conversationState.isLoading ||
                                  conversationState.isStreaming
                              ? 'Thinking...'
                              : 'Online',
                  style: TextStyle(
                    color: _isRecording || _isProcessingVoice
                        ? const Color(0xFFE50914)
                        : conversationState.isLoading ||
                                conversationState.isStreaming
                            ? const Color(0xFFE50914)
                            : Colors.green,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: conversationState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: conversationState.messages.length +
                        (conversationState.isLoading ||
                                conversationState.isStreaming
                            ? 1
                            : 0),
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
                  ),
          ),
          if (conversationState.messages.isEmpty)
            QuickSuggestionsWidget(
              onSuggestionTap: _handleQuickSuggestion,
            ),
          if (conversationState.error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(2.w),
              color: Colors.red.withAlpha(26),
              child: Text(
                conversationState.error!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          AIInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            onVoicePressed: _handleVoiceInput,
            isLoading: conversationState.isLoading ||
                conversationState.isStreaming ||
                _isProcessingVoice,
            isRecording: _isRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE50914),
                  const Color(0xFFE50914).withAlpha(128),
                ],
              ),
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.difference,
              ),
              child: ClipOval(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple
                                  .withOpacity(0.8 + (0.2 * value)),
                              Colors.purpleAccent
                                  .withOpacity(0.6 + (0.4 * value)),
                              Colors.cyanAccent
                                  .withOpacity(0.5 + (0.5 * value)),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.purpleAccent.withOpacity(0.4 * value),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'How can I help you today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'I can help you find products, track orders,\nplan meals, and answer questions',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                color: const Color(0xFFE50914),
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Tap mic to speak in Lebanese Arabic',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.white),
                title: const Text(
                  'Clear Conversation',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ref.read(aiConversationProvider.notifier).clearConversation();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.white),
                title: const Text(
                  'Help & FAQ',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
