import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:family_bridge/core/models/message_model.dart';
import 'package:family_bridge/core/models/notification_preferences.dart';
import 'package:family_bridge/core/services/notification_preferences_service.dart';
import 'package:family_bridge/core/services/notification_router.dart';
import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/features/chat/models/presence_model.dart';
import 'package:family_bridge/repositories/offline_first/chat_repository.dart';
import 'package:family_bridge/services/network/network_manager.dart';
import 'package:family_bridge/services/offline/offline_manager.dart';
import 'package:family_bridge/services/sync/data_sync_service.dart';
import 'package:family_bridge/services/sync/sync_queue.dart';

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

  late ChatRepository _repo;
  StreamSubscription? _repoSub;
  StreamSubscription<NetworkStatus>? _netSub;

  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
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

    // Ensure local stores are initialized
    if (!Hive.isBoxOpen('messages')) {
      await DataSyncService.instance.initialize();
    }
    _repo = ChatRepository(box: DataSyncService.instance.messagesBox);

    // Configure notifications for current user type
    NotificationService.instance.setUserType(userType);

    // Stream local messages always
    _repoSub?.cancel();
    _repoSub = _repo.watchFamilyMessages(familyId).listen((localList) {
      final mapped = localList.map(_fromHive).toList();
      _messagesController?.add(mapped);
    });

    // Network-dependent realtime and initial load
    _netSub?.cancel();
    _netSub = NetworkManager.instance.statusStream.listen((status) async {
      if (status.isOnline) {
        await _setupMessageSubscription();
        await _setupPresenceChannel();
        await _pullInitialMessages();
      }
    });

    if (NetworkManager.instance.current.isOnline) {
      await _setupMessageSubscription();
      await _setupPresenceChannel();
      await _pullInitialMessages();
    } else {
      // Offline: rely on local data only
      final locals = _repo.getFamilyMessages(familyId).map(_fromHive).toList();
      _messagesController?.add(locals);
    }
  }

  Future<void> _setupMessageSubscription() async {
    await _messageChannel?.unsubscribe();
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
          callback: (payload) async {
            await _handleMessageChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _setupPresenceChannel() async {
    await _presenceChannel?.unsubscribe();
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

  Future<void> _handleMessageChange(PostgresChangePayload payload) async {
    try {
      if (payload.newRecord == null && payload.oldRecord == null) return;
      if (payload.eventType == PostgresChangeEvent.insert ||
          payload.eventType == PostgresChangeEvent.update) {
        final json = Map<String, dynamic>.from(payload.newRecord!);
        final model = Message.fromMap(json);
        await _repo.upsertLocal(model);

        if (payload.eventType == PostgresChangeEvent.insert && model.senderId != _currentUserId) {
          String preview;
          switch (model.type) {
            case MessageType.text:
              preview = model.content ?? '';
              break;
            case MessageType.voice:
              final secs = model.voiceDuration ?? 0;
              preview = 'Voice message (${secs}s)';
              break;
            case MessageType.image:
              preview = 'Photo';
              break;
            case MessageType.video:
              preview = 'Video';
              break;
            case MessageType.location:
              preview = model.locationName ?? 'Location shared';
              break;
            case MessageType.careNote:
              preview = 'Care note';
              break;
            case MessageType.announcement:
              preview = 'Announcement';
              break;
            case MessageType.achievement:
              preview = 'Achievement';
              break;
          }
          final prefs = _currentUserId != null
              ? await NotificationPreferencesService.instance.getPreferences(_currentUserId!)
              : const NotificationPreferences();
          final decision = NotificationRouter.instance.decide(
            userType: _currentUserType ?? 'elder',
            prefs: prefs,
            priority: model.priority,
            category: 'chat',
          );
          if (decision.deliverNow) {
            await NotificationService.instance.showMessageNotification(
              model.senderName,
              preview,
              model.priority,
              familyId: model.familyId,
              messageId: model.id,
            );
          } else {
            NotificationRouter.instance.enqueueBatch(
              key: 'chat_${_currentFamilyId ?? ''}',
              window: decision.delay ?? const Duration(minutes: 2),
              item: _BatchItem(model.senderName, preview, model.priority, {
                'family_id': model.familyId,
                'message_id': model.id,
              }),
              onFlush: (items) async {
                final count = items.length;
                await NotificationService.instance.showMessageNotification(
                  'Family Chat',
                  '$count new messages',
                  MessagePriority.important,
                  familyId: model.familyId,
                );
              },
            );
          }
        }
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord?['id'] as String?;
        if (id != null) await _repo.deleteLocal(id);
      }
    } catch (e) {
      debugPrint('Realtime message change error: $e');
    }
  }

  Future<void> _pullInitialMessages() async {
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

      // Persist locally
      for (final m in messages) {
        await _repo.upsertLocal(_toHive(m));
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messagesController?.add(messages);
    } catch (e) {
      // Fall back to local if network fails
      final locals = _repo.getFamilyMessages(_currentFamilyId!).map(_fromHive).toList();
      _messagesController?.add(locals);
    }
  }

  Future<Message> sendMessage({
    required String content,
    required MessageType type,
    MessagePriority priority = MessagePriority.normal,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
    String? mediaUrl,
    String? mediaThumbnail,
    double? latitude,
    double? longitude,
    String? locationName,
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
      mediaUrl: mediaUrl,
      mediaThumbnail: mediaThumbnail,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      status: OfflineManager.instance.isOffline || !NetworkManager.instance.current.isOnline
          ? MessageStatus.queued
          : MessageStatus.sending,
    );

    // Persist locally immediately for instant UI feedback
    final isOnline = NetworkManager.instance.current.isOnline && !OfflineManager.instance.isOffline;
    final localStatus = isOnline ? MessageStatus.sending : MessageStatus.queued;
    await _repo.upsertLocal(message.copyWith(status: localStatus, pendingSync: !isOnline));

    if (!isOnline) {
      await SyncQueue.instance.enqueue(SyncOperation(
        id: messageId,
        box: 'messages',
        table: 'messages',
        type: SyncOpType.create,
        payload: message.toJson(),
      ));
      return message.copyWith(status: MessageStatus.sending);
    }

    try {
      await _supabase.from('messages').insert(message.toJson());
      await _repo.upsertLocal(message.copyWith(status: MessageStatus.sent, pendingSync: false));
      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending message: $e');
      await SyncQueue.instance.enqueue(SyncOperation(
        id: messageId,
        box: 'messages',
        table: 'messages',
        type: SyncOpType.create,
        payload: message.toJson(),
      ));
      await _repo.upsertLocal(message.copyWith(status: MessageStatus.queued, pendingSync: true));
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
      // Queue for later
      await OfflineManager.instance.executeOrQueue(
        table: 'messages',
        payload: {
          'id': messageId,
          'read_by': [_currentUserId],
          'updated_at': DateTime.now().toIso8601String(),
        },
        type: SyncOpType.update,
      );
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
      await OfflineManager.instance.executeOrQueue(
        table: 'messages',
        payload: {
          'id': messageId,
          'reactions': [
            {
              'user_id': _currentUserId,
              'user_name': await _getUserName(),
              'emoji': emoji,
              'timestamp': DateTime.now().toIso8601String(),
            }
          ],
          'updated_at': DateTime.now().toIso8601String(),
        },
        type: SyncOpType.update,
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true, 'content': '[Message deleted]'}).
          eq('id', messageId);
    } catch (e) {
      await OfflineManager.instance.executeOrQueue(
        table: 'messages',
        payload: {
          'id': messageId,
          'is_deleted': true,
          'content': '[Message deleted]',
          'updated_at': DateTime.now().toIso8601String(),
        },
        type: SyncOpType.update,
      );
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
      await OfflineManager.instance.executeOrQueue(
        table: 'messages',
        payload: {
          'id': messageId,
          'content': newContent,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        type: SyncOpType.update,
      );
    }
  }

  Future<String> _uploadAudio(String audioPath) async {
    final fileName = '${_uuid.v4()}.m4a';
    await _supabase.storage
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
    try {
      final userData = await _supabase
          .from('users')
          .select('name')
          .eq('id', _currentUserId!)
          .single();
      return userData['name'] ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> dispose() async {
    await _disposeChannels();
    await _messagesController?.close();
    await _presenceController?.close();
    await _typingController?.close();
    await _repoSub?.cancel();
    await _netSub?.cancel();
  }

  Future<void> _disposeChannels() async {
    await _updateMyPresence(isOnline: false);
    await _messageChannel?.unsubscribe();
    await _presenceChannel?.unsubscribe();
  }

  // Mapping helpers (using unified Message model)
  Message _toHive(Message m) => m;
  Message _fromHive(Message m) => m;
}
