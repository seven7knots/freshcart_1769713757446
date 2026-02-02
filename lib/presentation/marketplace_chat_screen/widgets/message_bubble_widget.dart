import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/message_model.dart';

class MessageBubbleWidget extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 3.w,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 3.w, color: Colors.grey[600]),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.5.h,
              ),
              decoration: BoxDecoration(
                color:
                    isCurrentUser ? const Color(0xFFE50914) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.w),
                  topRight: Radius.circular(4.w),
                  bottomLeft:
                      isCurrentUser ? Radius.circular(4.w) : Radius.zero,
                  bottomRight:
                      isCurrentUser ? Radius.zero : Radius.circular(4.w),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color:
                              isCurrentUser ? Colors.white70 : Colors.grey[600],
                          fontSize: 10.sp,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 1.w),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 3.w,
                          color: message.isRead
                              ? Colors.blue[300]
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              radius: 3.w,
              backgroundColor: const Color(0xFFE50914),
              child: Icon(Icons.person, size: 3.w, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
