import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import 'voice_message_player.dart';
import 'message_reactions.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String userType;
  final VoidCallback? onReply;
  final Function(String)? onReact;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.userType,
    this.onReply,
    this.onReact,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 40 : 8,
        right: isMe ? 8 : 40,
        top: showAvatar ? 12 : 2,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) _buildAvatar(),
          if (!isMe && !showAvatar) const SizedBox(width: 40),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (showAvatar && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: userType == 'elder' ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: _getSenderColor(),
                        ),
                      ),
                    ),
                  if (message.replyToId != null && message.replyToMessage != null)
                    _buildReplyPreview(),
                  Container(
                    decoration: BoxDecoration(
                      color: _getBubbleColor(context),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 16 : 4),
                        topRight: Radius.circular(isMe ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(context),
                  ),
                  if (message.reactions.isNotEmpty)
                    MessageReactions(
                      reactions: message.reactions,
                      userType: userType,
                      onAddReaction: onReact,
                    ),
                  _buildMessageFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _getSenderColor(),
      backgroundImage: message.senderAvatar != null
          ? NetworkImage(message.senderAvatar!)
          : null,
      child: message.senderAvatar == null
          ? Text(
              message.senderName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 30,
            color: _getSenderColor(),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.replyToMessage!.senderName,
                  style: TextStyle(
                    fontSize: userType == 'elder' ? 13 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message.replyToMessage!.content ?? '[Media]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: userType == 'elder' ? 13 : 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.voice:
        return _buildVoiceContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.location:
        return _buildLocationContent();
      case MessageType.careNote:
        return _buildCareNoteContent();
      case MessageType.announcement:
        return _buildAnnouncementContent();
      case MessageType.achievement:
        return _buildAchievementContent();
    }
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        message.content ?? '',
        style: TextStyle(
          fontSize: _getTextSize(),
          color: isMe ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVoiceContent() {
    return VoiceMessagePlayer(
      audioUrl: message.metadata?['voice_url'] ?? '',
      duration: message.voiceDuration ?? 0,
      transcription: message.voiceTranscription,
      isMe: isMe,
      userType: userType,
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl ?? '',
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 50),
              );
            },
          ),
        ),
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              message.content!,
              style: TextStyle(
                fontSize: _getTextSize(),
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: message.mediaThumbnail != null
                  ? Image.network(
                      message.mediaThumbnail!,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey.shade300,
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              message.content!,
              style: TextStyle(
                fontSize: _getTextSize(),
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: isMe ? Colors.white : Colors.red,
            size: userType == 'elder' ? 28 : 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.locationName ?? 'Shared location',
                  style: TextStyle(
                    fontSize: _getTextSize(),
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
                if (message.latitude != null && message.longitude != null)
                  Text(
                    '${message.latitude!.toStringAsFixed(4)}, ${message.longitude!.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: userType == 'elder' ? 12 : 10,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareNoteContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add,
                color: Colors.orange,
                size: userType == 'elder' ? 20 : 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Care Note',
                style: TextStyle(
                  fontSize: userType == 'elder' ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.content ?? '',
            style: TextStyle(
              fontSize: _getTextSize(),
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                'Announcement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.content ?? '',
            style: TextStyle(
              fontSize: _getTextSize(),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: userType == 'elder' ? 24 : 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Achievement',
                style: TextStyle(
                  fontSize: userType == 'elder' ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.content ?? '',
            style: TextStyle(
              fontSize: _getTextSize(),
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: userType == 'elder' ? 11 : 10,
              color: Colors.grey.shade600,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: userType == 'elder' ? 14 : 12,
              color: _getStatusColor(),
            ),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '(edited)',
              style: TextStyle(
                fontSize: userType == 'elder' ? 11 : 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getTextSize() {
    switch (userType) {
      case 'elder':
        return 18;
      case 'youth':
        return 14;
      default:
        return 15;
    }
  }

  Color _getBubbleColor(BuildContext context) {
    if (isMe) {
      switch (userType) {
        case 'elder':
          return Colors.blue.shade600;
        case 'caregiver':
          return Colors.teal.shade600;
        case 'youth':
          return Colors.purple.shade600;
        default:
          return Theme.of(context).primaryColor;
      }
    } else {
      return Colors.grey.shade200;
    }
  }

  Color _getSenderColor() {
    switch (message.senderType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  void _showMessageOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            if (onReact != null && userType == 'youth')
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context);
                },
              ),
            if (isMe && onEdit != null && message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                if (message.content != null) {
                  Clipboard.setData(ClipboardData(text: message.content!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied')),
                  );
                }
              },
            ),
            if (isMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final reactions = ['❤️', '👍', '😂', '😮', '😢', '🙏', '👏', '🎉'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onReact!(emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }
}