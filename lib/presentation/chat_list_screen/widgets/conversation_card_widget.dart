import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/conversation_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class ConversationCardWidget extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const ConversationCardWidget({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant =
        conversation.getOtherParticipantProfile(currentUserId);
    final otherParticipantName =
        otherParticipant?['full_name'] as String? ?? AppLocalizations.of(context)!.user;
    final otherParticipantImage =
        otherParticipant?['profile_image_url'] as String?;
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final listing = conversation.listing;
    final listingTitle = listing?['title'] as String? ?? AppLocalizations.of(context)!.listing;
    final listingImages = listing?['images'] as List? ?? [];
    final listingImageUrl =
        listingImages.isNotEmpty ? listingImages[0] as String? : null;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        color: Colors.red,
        child: Icon(Icons.archive, color: Colors.white, size: 6.w),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.archiveConversation, maxLines: 1, overflow: TextOverflow.ellipsis),
            content: Text(
                AppLocalizations.of(context)!.areYouSureYouWantTo9, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.archive, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onArchive(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200!, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 6.w,
                    backgroundImage: otherParticipantImage != null
                        ? NetworkImage(otherParticipantImage)
                        : null,
                    child: otherParticipantImage == null
                        ? Icon(Icons.person, size: 6.w)
                        : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50914),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 3.w),
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherParticipantName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Flexible(child: Text(
                      'About: $listingTitle',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    SizedBox(height: 0.5.h),
                    Flexible(child: Text(
                      conversation.lastMessageContent ?? AppLocalizations.of(context)!.noMessagesYet,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: unreadCount > 0 ? Colors.black : Colors.grey,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              // Listing thumbnail
              if (listingImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.w),
                  child: CachedNetworkImage(
                    imageUrl: listingImageUrl,
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, size: 4.w, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
