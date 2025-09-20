import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/elder_provider.dart';
import '../widgets/voice_navigation_widget.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  late VoiceService _voiceService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _highContrastMode = false;
  bool _isRecordingVoice = false;
  
  // Mock messages for demonstration
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'daughter',
      senderName: 'Anna',
      message: 'Hi Mom! How are you feeling today?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isFromElder: false,
    ),
    ChatMessage(
      id: '2',
      senderId: 'elder',
      senderName: 'You',
      message: 'I\'m doing well, dear. Just had my morning walk.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      isFromElder: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'son',
      senderName: 'John',
      message: 'That\'s great! Did you take your medication?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isFromElder: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    await _voiceService.announceScreen('Family Messages');
    
    final elderProvider = context.read<ElderProvider>();
    if (elderProvider.unreadMessages > 0) {
      await _voiceService.speak('You have ${elderProvider.unreadMessages} new messages');
    }
    
    // Register voice commands
    _voiceService.registerCommand('read messages', () => _readMessages());
    _voiceService.registerCommand('send message', () => _startVoiceMessage());
    _voiceService.registerCommand('reply', () => _startVoiceMessage());
  }

  void _readMessages() {
    for (var message in _messages.where((m) => !m.isFromElder).take(3)) {
      _voiceService.speak('${message.senderName} says: ${message.message}');
    }
  }

  void _startVoiceMessage() {
    _voiceService.startListening(
      onResult: (words) {
        setState(() {
          _messageController.text = words;
        });
      },
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'elder',
            senderName: 'You',
            message: _messageController.text,
            timestamp: DateTime.now(),
            isFromElder: true,
          ),
        );
      });
      
      _messageController.clear();
      _voiceService.confirmAction('Message sent');
      
      // Scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Family Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 32),
            onPressed: _readMessages,
            tooltip: 'Read messages aloud',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Family Members Bar
            Container(
              height: 100,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _FamilyMemberAvatar(
                    name: 'Anna',
                    relationship: 'Daughter',
                    isOnline: true,
                  ),
                  _FamilyMemberAvatar(
                    name: 'John',
                    relationship: 'Son',
                    isOnline: false,
                  ),
                  _FamilyMemberAvatar(
                    name: 'Sarah',
                    relationship: 'Granddaughter',
                    isOnline: true,
                  ),
                ],
              ),
            ),
            
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Voice Input Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _voiceService.isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _startVoiceMessage,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type or speak message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 20),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _sendMessage,
                      padding: const EdgeInsets.all(12),
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
}

class _FamilyMemberAvatar extends StatelessWidget {
  final String name;
  final String relationship;
  final bool isOnline;

  const _FamilyMemberAvatar({
    required this.name,
    required this.relationship,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    return Align(
      alignment: message.isFromElder
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isFromElder
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!message.isFromElder)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: message.isFromElder
                    ? AppTheme.primaryBlue
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isFromElder ? 20 : 4),
                  bottomRight: Radius.circular(message.isFromElder ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 20,
                  color: message.isFromElder
                      ? Colors.white
                      : AppTheme.darkText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                timeFormat.format(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromElder;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromElder,
  });
}