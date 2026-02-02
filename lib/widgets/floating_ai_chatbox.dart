import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../routes/app_routes.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';

class FloatingAIChatbox extends ConsumerStatefulWidget {
  const FloatingAIChatbox({super.key});

  @override
  ConsumerState<FloatingAIChatbox> createState() => _FloatingAIChatboxState();
}

class _FloatingAIChatboxState extends ConsumerState<FloatingAIChatbox>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  final TextEditingController _quickMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quickMessageController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _openFullChat() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, AppRoutes.aiChatAssistant);
    setState(() {
      _isExpanded = false;
    });
  }

  void _sendQuickMessage(String message) {
    if (message.trim().isEmpty) return;
    ref.read(aiConversationProvider.notifier).addQuickMessage(message);
    _quickMessageController.clear();
    _openFullChat();
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(aiConversationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 4.w,
      bottom: 10.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded) ...[
            _buildQuickChatBox(conversationState),
            SizedBox(height: 2.h),
          ],
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _toggleExpanded,
              onLongPress: _openFullChat,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeInOut,
                builder: (context, glowValue, child) {
                  return Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kjRed.withOpacity(
                            0.3 + (0.2 * glowValue),
                          ),
                          blurRadius: 20.0 + (10.0 * glowValue),
                          spreadRadius: 2.0 + (2.0 * glowValue),
                        ),
                      ],
                    ),
                    child: SizedBox(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChatBox(AIConversationState conversationState) {
    return Container(
      width: 80.w,
      constraints: BoxConstraints(maxHeight: 35.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 15.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: Border.all(
                          color: AppTheme.kjRed.withAlpha(77),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: Size(4.w, 4.w),
                          painter: MinimalRobotIconPainter(
                            primaryColor: AppTheme.kjRed,
                            accentColor: AppTheme.primaryDark,
                            isDark: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _openFullChat,
                  child: Icon(
                    Icons.open_in_full,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: conversationState.messages.isEmpty
                ? _buildQuickSuggestions()
                : _buildRecentMessages(conversationState),
          ),
          _buildQuickInput(),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Track my order',
      'Find nearby restaurants',
      'Plan meals',
    ];

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions:',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.sp),
          ),
          SizedBox(height: 1.h),
          ...suggestions.map((suggestion) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: GestureDetector(
                onTap: () => _sendQuickMessage(suggestion),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12.sp),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentMessages(AIConversationState conversationState) {
    final recentMessages = conversationState.messages.length > 3
        ? conversationState.messages.sublist(
            conversationState.messages.length - 3,
          )
        : conversationState.messages;

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(3.w),
      itemCount: recentMessages.length,
      itemBuilder: (context, index) {
        final message = recentMessages[index];
        final isUser = message.role == 'user';

        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: 60.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 11.sp),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickInput() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.w)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: TextField(
                controller: _quickMessageController,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12.sp),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 1.h),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendQuickMessage,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () => _sendQuickMessage(_quickMessageController.text),
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Icon(Icons.send,
                  color: Theme.of(context).colorScheme.onPrimary, size: 4.w),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for minimal futuristic robot icon with A and I antennas
class MinimalRobotIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;

  MinimalRobotIconPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.06;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final headRadius = size.width * 0.28;

    // Robot head (rounded rectangle for modern look)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + size.height * 0.05),
        width: headRadius * 2,
        height: headRadius * 2.2,
      ),
      Radius.circular(headRadius * 0.6),
    );

    // Draw head outline with gradient effect
    paint.color = primaryColor.withAlpha(38);
    canvas.drawRRect(headRect, paint);

    strokePaint.color = primaryColor;
    canvas.drawRRect(headRect, strokePaint);

    // Left antenna forming "A" shape
    final leftAntennaPath = Path();
    final leftAntennaX = centerX - headRadius * 0.5;
    final antennaTop = centerY - headRadius * 0.9;
    final antennaHeight = headRadius * 0.7;

    // A shape (inverted V with crossbar)
    leftAntennaPath.moveTo(
      leftAntennaX - headRadius * 0.25,
      antennaTop + antennaHeight,
    );
    leftAntennaPath.lineTo(leftAntennaX, antennaTop);
    leftAntennaPath.lineTo(
      leftAntennaX + headRadius * 0.25,
      antennaTop + antennaHeight,
    );
    // Crossbar for A
    leftAntennaPath.moveTo(
      leftAntennaX - headRadius * 0.15,
      antennaTop + antennaHeight * 0.6,
    );
    leftAntennaPath.lineTo(
      leftAntennaX + headRadius * 0.15,
      antennaTop + antennaHeight * 0.6,
    );

    strokePaint.color = primaryColor;
    canvas.drawPath(leftAntennaPath, strokePaint);

    // Right antenna forming "I" shape
    final rightAntennaPath = Path();
    final rightAntennaX = centerX + headRadius * 0.5;

    // I shape (vertical line with top and bottom caps)
    rightAntennaPath.moveTo(rightAntennaX - headRadius * 0.15, antennaTop);
    rightAntennaPath.lineTo(rightAntennaX + headRadius * 0.15, antennaTop);
    rightAntennaPath.moveTo(rightAntennaX, antennaTop);
    rightAntennaPath.lineTo(rightAntennaX, antennaTop + antennaHeight);
    rightAntennaPath.moveTo(
      rightAntennaX - headRadius * 0.15,
      antennaTop + antennaHeight,
    );
    rightAntennaPath.lineTo(
      rightAntennaX + headRadius * 0.15,
      antennaTop + antennaHeight,
    );

    strokePaint.color = accentColor;
    canvas.drawPath(rightAntennaPath, strokePaint);

    // Minimal face - single horizontal light line (visor style)
    final visorY = centerY + size.height * 0.02;
    final visorPath = Path();
    visorPath.moveTo(centerX - headRadius * 0.5, visorY);
    visorPath.lineTo(centerX + headRadius * 0.5, visorY);

    strokePaint.color = primaryColor;
    strokePaint.strokeWidth = size.width * 0.05;
    canvas.drawPath(visorPath, strokePaint);

    // Two small eye indicators on the visor
    paint.color = primaryColor;
    final leftEye = Offset(centerX - headRadius * 0.3, visorY);
    final rightEye = Offset(centerX + headRadius * 0.3, visorY);
    canvas.drawCircle(leftEye, size.width * 0.04, paint);
    canvas.drawCircle(rightEye, size.width * 0.04, paint);

    // Subtle glow effect on eyes
    paint.color = primaryColor.withAlpha(77);
    canvas.drawCircle(leftEye, size.width * 0.07, paint);
    canvas.drawCircle(rightEye, size.width * 0.07, paint);
  }

  @override
  bool shouldRepaint(covariant MinimalRobotIconPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
