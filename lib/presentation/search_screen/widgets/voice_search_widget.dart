import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
          // Add this line - provide path parameter for non-web platforms
          await _audioRecorder.start(
            const RecordConfig(),
            path: 'voice_search.m4a',
          );
        }

        // Auto-stop after 10 seconds
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
    // Simulate voice processing
    await Future.delayed(const Duration(seconds: 2));

    // Mock voice recognition results
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
        content: Text('Microphone permission is required for voice search'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
    widget.onClose?.call();
  }

  void _showRecordingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to start voice recording. Please try again.'),
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
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
                  color: AppTheme.lightTheme.colorScheme.onSurface,
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
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: _opacityAnimation.value)
                        : AppTheme
                            .lightTheme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? CircularProgressIndicator(
                            color: AppTheme.lightTheme.colorScheme.primary,
                          )
                        : CustomIconWidget(
                            iconName: _isRecording ? 'mic' : 'mic_off',
                            color: _isRecording
                                ? AppTheme.lightTheme.colorScheme.onPrimary
                                : AppTheme.lightTheme.colorScheme.primary,
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
                ? 'Processing your voice...'
                : _isRecording
                    ? 'Listening...'
                    : 'Tap to start voice search',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 2.h),

          Text(
            _isRecording
                ? 'Say what you\'re looking for'
                : 'Voice search helps you find products quickly',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

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
                      child: Text('Stop'),
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
                      child: Text('Start Voice Search'),
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
