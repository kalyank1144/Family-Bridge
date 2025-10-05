import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

import 'message_reactions.dart';
import 'package:family_bridge/core/models/message_model.dart';
import 'voice_message_player.dart';

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
    final isElder = userType == 'elder';
    
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 50 : 16,
        right: isMe ? 16 : 50,
        top: showAvatar ? 16 : 4,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for incoming messages
          if (!isMe) ..[
            if (showAvatar) 
              _buildModernAvatar()
            else 
              SizedBox(width: isElder ? 48 : 42),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name for incoming messages
                  if (showAvatar && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: isElder ? 16 : 14,
                          fontWeight: FontWeight.w700,
                          color: _getSenderColor(),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  
                  // Reply preview
                  if (message.replyToId != null && message.replyToMessage != null)
                    _buildModernReplyPreview(),
                  
                  // Message bubble
                  Container(
                    decoration: BoxDecoration(
                      color: _getBubbleColor(context),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 20 : (showAvatar ? 4 : 20)),
                        topRight: Radius.circular(isMe ? (showAvatar ? 4 : 20) : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: _buildMessageContent(context),
                  ),
                  
                  // Reactions
                  if (message.reactions.isNotEmpty) ..[
                    const SizedBox(height: 4),
                    MessageReactions(
                      reactions: message.reactions,
                      userType: userType,
                      onAddReaction: onReact,
                    ),
                  ],
                  
                  // Message footer with timestamp and status
                  _buildModernMessageFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatar() {
    final isElder = userType == 'elder';
    final avatarRadius = isElder ? 24.0 : 21.0;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getSenderColor().withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: _getSenderColor(),
        backgroundImage: message.senderAvatar != null
            ? NetworkImage(message.senderAvatar!)
            : null,
        child: message.senderAvatar == null
            ? Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isElder ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildModernReplyPreview() {
    final isElder = userType == 'elder';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.white.withOpacity(0.15) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe 
              ? Colors.white.withOpacity(0.2) 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _getSenderColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.replyToMessage!.senderName,
                    style: TextStyle(
                      fontSize: isElder ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: _getSenderColor(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.replyToMessage!.content ?? '[Media]',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isElder ? 14 : 12,
                      color: isMe 
                          ? Colors.white.withOpacity(0.8) 
                          : Colors.grey.shade700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final isElder = userType == 'elder';
    final imageSize = isElder ? 280.0 : 240.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with modern styling
        Container(
          constraints: BoxConstraints(
            maxWidth: imageSize,
            maxHeight: imageSize * 0.75,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  message.mediaUrl ?? '',
                  width: imageSize,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: imageSize,
                      height: imageSize * 0.6,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: _getAccentColor(),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: imageSize,
                      height: imageSize * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: isElder ? 60 : 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              fontSize: isElder ? 16 : 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Image overlay for better readability of caption
                if (message.content != null && message.content!.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        message.content!,
                        style: TextStyle(
                          fontSize: _getTextSize(),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Caption below image (if image has overlay, this won't show)
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Text(
              message.content!,
              style: TextStyle(
                fontSize: _getTextSize(),
                color: isMe ? Colors.white.withOpacity(0.9) : Colors.black87,
                height: 1.3,
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

  Widget _buildModernMessageFooter() {
    final isElder = userType == 'elder';
    
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: isElder ? 12 : 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Status indicator for sent messages
          if (isMe) ..[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(),
                size: isElder ? 16 : 14,
                color: _getStatusColor(),
              ),
            ),
          ],
          
          // Edited indicator
          if (message.isEdited) ..[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'edited',
                style: TextStyle(
                  fontSize: isElder ? 10 : 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
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
      return Colors.white;
    }
  }
  
  Color _getAccentColor() {
    switch (userType) {
      case 'elder':
        return Colors.blue.shade600;
      case 'caregiver':
        return Colors.teal.shade600;
      case 'youth':
        return Colors.purple.shade600;
      default:
        return Colors.blue;
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