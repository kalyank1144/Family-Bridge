import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/message_model.dart';
import '../models/presence_model.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/online_status_bar.dart';
import '../widgets/voice_recorder_overlay.dart';

import '../widgets/sync_status_banner.dart';

import 'chat_settings_screen.dart';


class FamilyChatScreen extends ConsumerStatefulWidget {
  final String familyId;
  final String userId;
  final String userType;

  const FamilyChatScreen({
    super.key,
    required this.familyId,
    required this.userId,
    required this.userType,
  });

  @override
  ConsumerState<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends ConsumerState<FamilyChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecordingVoice = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await ref.read(chatServiceProvider).initialize(
      familyId: widget.familyId,
      userId: widget.userId,
      userType: widget.userType,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildAppBar() {
    final presenceAsync = ref.watch(presenceStreamProvider(widget.familyId));
    
    return PreferredSize(
      preferredSize: Size.fromHeight(widget.userType == 'elder' ? 80 : 65),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getAppBarColor(),
              _getAppBarColor().withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _getAppBarColor().withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: widget.userType == 'elder' ? 28 : 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Circle',
                        style: TextStyle(
                          fontSize: widget.userType == 'elder' ? 26 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (presenceAsync.hasValue)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${presenceAsync.value!.values.where((p) => p.isOnline).length} family members active',
                                style: TextStyle(
                                  fontSize: widget.userType == 'elder' ? 14 : 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.userType == 'caregiver')
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _showSearchDialog,
                  ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _showChatSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAppBarColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.blue;
    }
  }

  Widget _buildMessagesList() {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.familyId));
    
    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading messages: $error'),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: widget.userType == 'elder' ? 20 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with your family!',
                  style: TextStyle(
                    fontSize: widget.userType == 'elder' ? 18 : 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: widget.userType == 'elder' ? 100 : 80,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == widget.userId;
            final showAvatar = index == 0 ||
                messages[index - 1].senderId != message.senderId;
            
            return MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: showAvatar,
              userType: widget.userType,
              onReply: () => _setReplyTo(message),
              onReact: (emoji) => _addReaction(message.id, emoji),
              onDelete: isMe ? () => _deleteMessage(message.id) : null,
              onEdit: isMe ? () => _editMessage(message) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    final typingAsync = ref.watch(typingStreamProvider(widget.familyId));
    
    return typingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (typingUsers) {
        final othersTyping = typingUsers
            .where((t) => t.userId != widget.userId)
            .toList();
        
        if (othersTyping.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return TypingIndicatorWidget(
          typingUsers: othersTyping,
          userType: widget.userType,
        );
      },
    );
  }

  Widget _buildQuickResponses() {
    if (widget.userType != 'elder') {
      return const SizedBox.shrink();
    }
    
    final quickResponses = ref.watch(quickResponsesProvider(widget.userType));
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: quickResponses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _sendQuickResponse(quickResponses[index]),
              child: Text(
                quickResponses[index],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final replyTo = ref.watch(replyToMessageProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTo != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to ${replyTo.senderName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        replyTo.content ?? '[Media]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => ref.read(replyToMessageProvider.notifier).state = null,
                ),
              ],
            ),
          ),
        if (widget.userType == 'elder')
          _buildQuickResponses(),
        ChatInputBar(
          controller: _messageController,
          focusNode: _focusNode,
          userType: widget.userType,
          onSendText: _sendTextMessage,
          onRecordVoice: _toggleVoiceRecording,
          onAttachMedia: _attachMedia,
          onSendLocation: _shareLocation,
        ),
      ],
    );
  }

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    
    final chatService = ref.read(chatServiceProvider);
    final replyTo = ref.read(replyToMessageProvider);
    
    chatService.sendMessage(
      content: text,
      type: MessageType.text,
      replyToId: replyTo?.id,
    );
    
    _messageController.clear();
    ref.read(replyToMessageProvider.notifier).state = null;
    _scrollToBottom();
  }

  void _sendQuickResponse(String response) {
    _sendTextMessage(response);
    HapticFeedback.lightImpact();
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecordingVoice = !_isRecordingVoice;
    });
  }

  void _attachMedia() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            if (widget.userType == 'youth')
              ListTile(
                leading: const Icon(Icons.gif),
                title: const Text('GIF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGif();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLocation() async {
    try {
      // For now, send a mock location - in real app would use GPS
      ref.read(chatServiceProvider).sendMessage(
        content: 'My current location',
        type: MessageType.location,
        latitude: 37.7749,
        longitude: -122.4194,
        locationName: 'San Francisco, CA',
      );
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location shared with family')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share location: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final imageFile = await mediaService.pickImage();
      if (imageFile != null) {
        final imageUrl = await mediaService.uploadImage(imageFile);
        ref.read(chatServiceProvider).sendMessage(
          content: '',
          type: MessageType.image,
          mediaUrl: imageUrl,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final videoFile = await mediaService.pickVideo();
      if (videoFile != null) {
        final videoUrl = await mediaService.uploadVideo(videoFile);
        ref.read(chatServiceProvider).sendMessage(
          content: '',
          type: MessageType.video,
          mediaUrl: videoUrl,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send video: $e')),
      );
    }
  }

  void _pickGif() {
    // Implement GIF picker - placeholder
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'GIF Picker\nComing Soon!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _setReplyTo(Message message) {
    ref.read(replyToMessageProvider.notifier).state = message;
    _focusNode.requestFocus();
  }

  void _addReaction(String messageId, String emoji) {
    ref.read(chatServiceProvider).addReaction(messageId, emoji);
  }

  void _deleteMessage(String messageId) {
    ref.read(chatServiceProvider).deleteMessage(messageId);
  }

  void _editMessage(Message message) {
    _messageController.text = message.content ?? '';
    _focusNode.requestFocus();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => const MessageSearchDialog(),
    );
  }

  void _showChatSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSettingsScreen(
          familyId: widget.familyId,
          userType: widget.userType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              SyncStatusBanner(),
              OnlineStatusBar(
                familyId: widget.familyId,
                userType: widget.userType,
              ),
              Expanded(child: _buildMessagesList()),
              _buildTypingIndicator(),
              _buildInputBar(),
            ],
          ),
          if (_isRecordingVoice)
            VoiceRecorderOverlay(
              userType: widget.userType,
              onCancel: () => setState(() => _isRecordingVoice = false),
              onSend: (audioPath, duration, transcription) {
                setState(() => _isRecordingVoice = false);
                ref.read(chatServiceProvider).sendVoiceMessage(
                  audioPath: audioPath,
                  duration: duration,
                  transcription: transcription,
                );
              },
            ),
        ],
      ),
    );
  }
}

class MessageSearchDialog extends StatelessWidget {
  const MessageSearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Messages'),
      content: const TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
