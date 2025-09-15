import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/presence_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _presenceChannel;
  StreamController<List<Message>>? _messagesController;
  StreamController<Map<String, FamilyMemberPresence>>? _presenceController;
  StreamController<List<TypingIndicator>>? _typingController;
  
  String? _currentFamilyId;
  String? _currentUserId;
  String? _currentUserType;
  
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Stream<List<Message>> get messagesStream => 
      _messagesController?.stream ?? const Stream.empty();
  
  Stream<Map<String, FamilyMemberPresence>> get presenceStream => 
      _presenceController?.stream ?? const Stream.empty();
  
  Stream<List<TypingIndicator>> get typingStream => 
      _typingController?.stream ?? const Stream.empty();

  Future<void> initialize({
    required String familyId,
    required String userId,
    required String userType,
  }) async {
    _currentFamilyId = familyId;
    _currentUserId = userId;
    _currentUserType = userType;
    
    await _disposeChannels();
    
    _messagesController = StreamController<List<Message>>.broadcast();
    _presenceController = StreamController<Map<String, FamilyMemberPresence>>.broadcast();
    _typingController = StreamController<List<TypingIndicator>>.broadcast();
    
    await _setupMessageSubscription();
    await _setupPresenceChannel();
    await _loadInitialMessages();
  }

  Future<void> _setupMessageSubscription() async {
    _messageChannel = _supabase
        .channel('messages:$_currentFamilyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: _currentFamilyId,
          ),
          callback: (payload) {
            _handleMessageChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _setupPresenceChannel() async {
    final Map<String, FamilyMemberPresence> onlineUsers = {};
    final List<TypingIndicator> typingUsers = [];
    
    _presenceChannel = _supabase
        .channel('family:$_currentFamilyId')
        .onPresenceSync((payload) {
          onlineUsers.clear();
          for (final presence in payload) {
            final userId = presence['user_id'] as String?;
            if (userId != null) {
              onlineUsers[userId] = FamilyMemberPresence.fromJson(presence);
            }
          }
          _presenceController?.add(Map.from(onlineUsers));
        })
        .onPresenceJoin((payload) {
          final userId = payload['user_id'] as String?;
          if (userId != null) {
            onlineUsers[userId] = FamilyMemberPresence.fromJson(payload);
            _presenceController?.add(Map.from(onlineUsers));
          }
        })
        .onPresenceLeave((payload) {
          final userId = payload['user_id'] as String?;
          if (userId != null) {
            onlineUsers.remove(userId);
            _presenceController?.add(Map.from(onlineUsers));
          }
        })
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final data = payload['payload'] as Map<String, dynamic>;
            final isTyping = data['is_typing'] as bool;
            final userId = data['user_id'] as String;
            
            if (isTyping) {
              typingUsers.removeWhere((t) => t.userId == userId);
              typingUsers.add(TypingIndicator.fromJson(data));
            } else {
              typingUsers.removeWhere((t) => t.userId == userId);
            }
            _typingController?.add(List.from(typingUsers));
          },
        )
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _updateMyPresence(isOnline: true);
          }
        });
  }

  Future<void> _updateMyPresence({required bool isOnline}) async {
    await _presenceChannel?.track({
      'user_id': _currentUserId,
      'user_name': await _getUserName(),
      'user_type': _currentUserType,
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setTypingStatus(bool isTyping) async {
    await _presenceChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': _currentUserId,
        'user_name': await _getUserName(),
        'is_typing': isTyping,
        'started_at': DateTime.now().toIso8601String(),
      },
    );
  }

  void _handleMessageChange(PostgresChangePayload payload) async {
    if (payload.eventType == PostgresChangeEvent.insert) {
      await _loadInitialMessages();
    } else if (payload.eventType == PostgresChangeEvent.update) {
      await _loadInitialMessages();
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      await _loadInitialMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('family_id', _currentFamilyId!)
          .order('timestamp', ascending: false)
          .limit(100);
      
      final messages = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
      
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messagesController?.add(messages);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      _messagesController?.addError(e);
    }
  }

  Future<Message> sendMessage({
    required String content,
    required MessageType type,
    MessagePriority priority = MessagePriority.normal,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = _uuid.v4();
    final timestamp = DateTime.now();
    
    final message = Message(
      id: messageId,
      familyId: _currentFamilyId!,
      senderId: _currentUserId!,
      senderName: await _getUserName(),
      senderType: _currentUserType!,
      content: content,
      type: type,
      priority: priority,
      timestamp: timestamp,
      replyToId: replyToId,
      mentions: mentions,
      metadata: metadata,
      status: MessageStatus.sending,
    );
    
    try {
      await _supabase.from('messages').insert(message.toJson());
      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending message: $e');
      return message.copyWith(status: MessageStatus.failed);
    }
  }

  Future<Message> sendVoiceMessage({
    required String audioPath,
    required int duration,
    String? transcription,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final audioUrl = await _uploadAudio(audioPath);
    
    return sendMessage(
      content: transcription ?? '[Voice message]',
      type: MessageType.voice,
      priority: priority,
      metadata: {
        'voice_url': audioUrl,
        'voice_duration': duration,
        'voice_transcription': transcription,
      },
    );
  }

  Future<Message> sendMediaMessage({
    required String mediaPath,
    required MessageType type,
    String? caption,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final mediaUrl = await _uploadMedia(mediaPath, type);
    final thumbnailUrl = type == MessageType.video 
        ? await _generateVideoThumbnail(mediaPath)
        : null;
    
    return sendMessage(
      content: caption ?? '[Media]',
      type: type,
      priority: priority,
      metadata: {
        'media_url': mediaUrl,
        'media_thumbnail': thumbnailUrl,
      },
    );
  }

  Future<Message> sendLocationMessage({
    required double latitude,
    required double longitude,
    String? locationName,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    return sendMessage(
      content: locationName ?? 'Shared location',
      type: MessageType.location,
      priority: priority,
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
      },
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('read_by')
          .eq('id', messageId)
          .single();
      
      List<String> readBy = List<String>.from(response['read_by'] ?? []);
      if (!readBy.contains(_currentUserId)) {
        readBy.add(_currentUserId!);
        
        await _supabase
            .from('messages')
            .update({'read_by': readBy})
            .eq('id', messageId);
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<void> addReaction(String messageId, String emoji) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();
      
      List<dynamic> reactions = response['reactions'] ?? [];
      
      reactions.removeWhere((r) => r['user_id'] == _currentUserId);
      
      reactions.add({
        'user_id': _currentUserId,
        'user_name': await _getUserName(),
        'emoji': emoji,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await _supabase
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true, 'content': '[Message deleted]'})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error editing message: $e');
    }
  }

  Future<String> _uploadAudio(String audioPath) async {
    final fileName = '${_uuid.v4()}.m4a';
    final file = await _supabase.storage
        .from('voice_messages')
        .upload(fileName, File(audioPath));
    
    return _supabase.storage
        .from('voice_messages')
        .getPublicUrl(fileName);
  }

  Future<String> _uploadMedia(String mediaPath, MessageType type) async {
    final bucket = type == MessageType.image ? 'images' : 'videos';
    final extension = type == MessageType.image ? 'jpg' : 'mp4';
    final fileName = '${_uuid.v4()}.$extension';
    
    await _supabase.storage
        .from(bucket)
        .upload(fileName, File(mediaPath));
    
    return _supabase.storage
        .from(bucket)
        .getPublicUrl(fileName);
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    return null;
  }

  Future<String> _getUserName() async {
    final userData = await _supabase
        .from('users')
        .select('name')
        .eq('id', _currentUserId!)
        .single();
    return userData['name'] ?? 'Unknown';
  }

  Future<void> dispose() async {
    await _disposeChannels();
    await _messagesController?.close();
    await _presenceController?.close();
    await _typingController?.close();
  }

  Future<void> _disposeChannels() async {
    await _updateMyPresence(isOnline: false);
    await _messageChannel?.unsubscribe();
    await _presenceChannel?.unsubscribe();
  }
}

class File {
  final String path;
  File(this.path);
}