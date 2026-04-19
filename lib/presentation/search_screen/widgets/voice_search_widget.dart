import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class VoiceSearchWidget extends StatefulWidget {
  final Function(String)? onVoiceResult;
  final VoidCallback? onClose;

  const VoiceSearchWidget({
    super.key,
    this.onVoiceResult,
    this.onClose,
  });

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _recordingPath = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startRecording();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() => _isRecording = true);

        if (kIsWeb) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: 'voice_search.wav',
          );
        } else {
          await _audioRecorder.start(
            const RecordConfig(),
            path: 'voice_search.m4a',
          );
        }

        Future.delayed(const Duration(seconds: 10), () {
          if (_isRecording) {
            _stopRecording();
          }
        });
      } else {
        _showPermissionError();
      }
    } catch (e) {
      _showRecordingError();
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      final path = await _audioRecorder.stop();
      if (path != null) {
        _recordingPath = path;
        await _processVoiceInput();
      }
    } catch (e) {
      _showRecordingError();
    }
  }

  Future<void> _processVoiceInput() async {
    await Future.delayed(const Duration(seconds: 2));

    final mockResults = [
      'organic apples',
      'fresh milk',
      'whole wheat bread',
      'chicken breast',
      'greek yogurt',
    ];

    final randomResult =
        mockResults[DateTime.now().millisecond % mockResults.length];

    setState(() => _isProcessing = false);
    widget.onVoiceResult?.call(randomResult);
    widget.onClose?.call();
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.microphonePermissionIsRequiredForVoice2, maxLines: 1, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.settings,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
    widget.onClose?.call();
  }

  void _showRecordingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.unableToStartVoiceRecordingPlease, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 8.h, 4.w, 0),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    widget.onClose?.call();
                  }
                },
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Voice animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? theme.colorScheme.primary
                            .withValues(alpha: _opacityAnimation.value)
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          )
                        : CustomIconWidget(
                            iconName: _isRecording ? 'mic' : 'mic_off',
                            color: _isRecording
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                            size: 48,
                          ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 4.h),

          // Status text
          Text(
            _isProcessing
                ? AppLocalizations.of(context)!.processingYourVoice
                : _isRecording
                    ? AppLocalizations.of(context)!.listening
                    : AppLocalizations.of(context)!.tapToStartVoiceSearch,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),

          SizedBox(height: 2.h),

          Text(
            _isRecording
                ? 'Say what you\'re looking for'
                : AppLocalizations.of(context)!.voiceSearchHelpsYouFindProducts,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),

          const Spacer(),

          // Action buttons
          if (_isRecording) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _stopRecording();
                      },
                      child: Text(AppLocalizations.of(context)!.stop, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isProcessing) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _startRecording();
                      },
                      child: Text(AppLocalizations.of(context)!.startVoiceSearch, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}