import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    final Color bubbleBg = isCurrentUser
        ? const Color(0xFFE50914)
        : (isLight ? Colors.grey.shade200 : Colors.black87);
    final Color textColor = isCurrentUser
        ? Colors.white
        : (isLight ? Colors.black87 : Colors.white.withOpacity(0.9));
    final Color timestampColor = isCurrentUser
        ? Colors.white.withOpacity(0.65)
        : (isLight ? Colors.grey.shade500 : Colors.white.withOpacity(0.35));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: isLight
                  ? Colors.grey.shade300
                  : Colors.white.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: isLight ? Colors.grey : Colors.white54,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                    ),
                  ),
                  child: _buildMessageContent(textColor),
                ),
                // Timestamp + read status
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: timestampColor,
                          fontSize: 11,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? const Color(0xFFE50914)
                              : timestampColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Color textColor) {
    // Image attachment
    if (message.messageType == 'image' &&
        message.attachmentUrl != null &&
        message.attachmentUrl!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(imageUrl: 
              message.attachmentUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 200,
                height: 120,
                color: Colors.white12,
                child: const Icon(Icons.broken_image, color: Colors.white38),
              ),
            ),
          ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      );
    }

    // Text message
    return Text(
      message.content,
      style: TextStyle(color: textColor, fontSize: 14, height: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      final local = timestamp.toLocal();
    return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day}/${timestamp.month}';
  }
}