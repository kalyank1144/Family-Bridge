import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/utils/helpers.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Robert',
      'message': 'Good morning everyone!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'elder',
    },
    {
      'sender': 'Mary',
      'message': 'Hi Dad! How are you feeling today?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      'type': 'caregiver',
    },
    {
      'sender': 'Robert',
      'message': 'I am feeling great! Just took my morning medication.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      'type': 'elder',
    },
    {
      'sender': 'Alex',
      'message': 'That\'s awesome Grandpa! 😊',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'type': 'youth',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '3 members online',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['sender'] == 'You';
                
                return _buildMessageBubble(
                  message['sender'] as String,
                  message['message'] as String,
                  message['timestamp'] as DateTime,
                  message['type'] as String,
                  isCurrentUser,
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.photo,
                      color: AppConfig.primaryColor,
                    ),
                    onPressed: () {},
                  ),
                  
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: AppConfig.primaryColor,
                    ),
                    onPressed: () {},
                  ),
                  
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  CircleAvatar(
                    backgroundColor: AppConfig.primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String sender,
    String message,
    DateTime timestamp,
    String type,
    bool isCurrentUser,
  ) {
    Color bubbleColor;
    switch (type) {
      case 'elder':
        bubbleColor = AppConfig.elderPrimaryColor.withOpacity(0.1);
        break;
      case 'caregiver':
        bubbleColor = AppConfig.caregiverPrimaryColor.withOpacity(0.1);
        break;
      case 'youth':
        bubbleColor = AppConfig.youthPrimaryColor.withOpacity(0.1);
        break;
      default:
        bubbleColor = Colors.grey[200]!;
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppConfig.primaryColor 
                    : bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                Helpers.getRelativeTime(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
