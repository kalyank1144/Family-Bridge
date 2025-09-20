import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/presence_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService.instance;
  
  List<Message> _messages = [];
  List<Message> _searchResults = [];
  Map<String, Presence> _onlineUsers = {};
  bool _isTyping = false;
  Message? _selectedMessage;
  Message? _replyToMessage;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  
  List<Message> get messages => _messages;
  List<Message> get searchResults => _searchResults;
  Map<String, Presence> get onlineUsers => _onlineUsers;
  bool get isTyping => _isTyping;
  Message? get selectedMessage => _selectedMessage;
  Message? get replyToMessage => _replyToMessage;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _presenceSubscription;
  Timer? _typingTimer;
  
  ChatProvider();
  
  Future<void> initialize(String familyId) async {
    await loadMessages(familyId);
    _subscribeToMessages(familyId);
    _subscribeToPresence(familyId);
  }
  
  Future<void> loadMessages(String familyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _messages = await _chatService.getMessages(familyId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _subscribeToMessages(String familyId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .subscribeToMessages(familyId)
        .listen((message) {
      _messages.insert(0, message);
      notifyListeners();
    });
  }
  
  void _subscribeToPresence(String familyId) {
    _presenceSubscription?.cancel();
    _presenceSubscription = _chatService
        .subscribeToPresence(familyId)
        .listen((presence) {
      _onlineUsers[presence.userId] = presence;
      notifyListeners();
      
      if (!presence.isOnline) {
        Future.delayed(const Duration(seconds: 1), () {
          _onlineUsers.remove(presence.userId);
          notifyListeners();
        });
      }
    });
  }
  
  Future<void> sendMessage(String familyId, String text, {String? mediaUrl}) async {
    try {
      final message = await _chatService.sendMessage(
        familyId: familyId,
        text: text,
        mediaUrl: mediaUrl,
        replyToId: _replyToMessage?.id,
      );
      
      if (_replyToMessage != null) {
        clearReply();
      }
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> sendVoiceMessage(String familyId, String voiceUrl, {int? duration}) async {
    try {
      await _chatService.sendVoiceMessage(
        familyId: familyId,
        voiceUrl: voiceUrl,
        duration: duration,
      );
    } catch (e) {
      _error = 'Failed to send voice message: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> deleteMessage(Message message) async {
    try {
      await _chatService.deleteMessage(message.id);
      _messages.removeWhere((m) => m.id == message.id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete message: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> editMessage(Message message, String newText) async {
    try {
      await _chatService.editMessage(message.id, newText);
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message.copyWith(
          text: newText,
          isEdited: true,
          editedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to edit message: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> addReaction(Message message, String emoji) async {
    try {
      await _chatService.addReaction(message.id, emoji);
      // Update local message with reaction
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        final reactions = Map<String, List<String>>.from(message.reactions ?? {});
        final userId = _chatService.currentUserId;
        if (reactions.containsKey(emoji)) {
          if (!reactions[emoji]!.contains(userId)) {
            reactions[emoji]!.add(userId);
          }
        } else {
          reactions[emoji] = [userId];
        }
        _messages[index] = message.copyWith(reactions: reactions);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add reaction: ${e.toString()}';
      notifyListeners();
    }
  }
  
  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
    
    if (typing) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _isTyping = false;
        notifyListeners();
      });
    } else {
      _typingTimer?.cancel();
    }
  }
  
  void selectMessage(Message? message) {
    _selectedMessage = message;
    notifyListeners();
  }
  
  void setReplyToMessage(Message? message) {
    _replyToMessage = message;
    notifyListeners();
  }
  
  void clearReply() {
    _replyToMessage = null;
    notifyListeners();
  }
  
  void searchMessages(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _messages.where((message) {
        return message.text.toLowerCase().contains(query.toLowerCase()) ||
               (message.senderName?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}