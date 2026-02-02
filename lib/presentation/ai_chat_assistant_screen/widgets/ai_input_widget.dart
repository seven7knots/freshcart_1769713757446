import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AIInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onVoicePressed;
  final bool isLoading;
  final bool isRecording;

  const AIInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoicePressed,
    this.isLoading = false,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 1.5.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 10.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onVoicePressed != null)
              GestureDetector(
                onTap: isLoading ? null : onVoicePressed,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording
                        ? const Color(0xFFE50914)
                        : const Color(0xFF2A2A2A),
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
              ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        isRecording ? 'Recording...' : 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: isRecording
                          ? const Color(0xFFE50914)
                          : Colors.white54,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) =>
                      isLoading || isRecording ? null : onSend(),
                  enabled: !isLoading && !isRecording,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: isLoading || isRecording ? null : onSend,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isLoading || isRecording
                        ? [Colors.grey, Colors.grey]
                        : [
                            const Color(0xFFE50914),
                            const Color(0xFFE50914).withAlpha(204),
                          ],
                  ),
                ),
                child: Icon(
                  isLoading ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
