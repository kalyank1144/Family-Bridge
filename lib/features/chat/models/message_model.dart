import 'package:flutter/foundation.dart';

enum MessageType {
  text,
  voice,
  image,
  video,
  location,
  careNote,
  announcement,
  achievement,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum MessagePriority {
  normal,
  important,
  urgent,
  emergency,
}

class MessageReaction {
  final String userId;
  final String userName;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'emoji': emoji,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['user_id'],
      userName: json['user_name'],
      emoji: json['emoji'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Message {
  final String id;
  final String familyId;
  final String senderId;
  final String senderName;
  final String senderType; // elder, caregiver, youth
  final String? senderAvatar;
  final String? content;
  final MessageType type;
  final MessageStatus status;
  final MessagePriority priority;
  final DateTime timestamp;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> readBy;
  final List<MessageReaction> reactions;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final Message? replyToMessage;
  final String? voiceTranscription;
  final int? voiceDuration;
  final String? mediaUrl;
  final String? mediaThumbnail;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isDeleted;
  final String? threadId;
  final List<String>? mentions;

  Message({
    required this.id,
    required this.familyId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.senderAvatar,
    this.content,
    required this.type,
    this.status = MessageStatus.sending,
    this.priority = MessagePriority.normal,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.readBy = const [],
    this.reactions = const [],
    this.metadata,
    this.replyToId,
    this.replyToMessage,
    this.voiceTranscription,
    this.voiceDuration,
    this.mediaUrl,
    this.mediaThumbnail,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isDeleted = false,
    this.threadId,
    this.mentions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'read_by': readBy,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'metadata': metadata,
      'reply_to_id': replyToId,
      'voice_transcription': voiceTranscription,
      'voice_duration': voiceDuration,
      'media_url': mediaUrl,
      'media_thumbnail': mediaThumbnail,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'is_deleted': isDeleted,
      'thread_id': threadId,
      'mentions': mentions,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      familyId: json['family_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderType: json['sender_type'],
      senderAvatar: json['sender_avatar'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => MessagePriority.normal,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at']) 
          : null,
      readBy: List<String>.from(json['read_by'] ?? []),
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((r) => MessageReaction.fromJson(r))
          .toList() ?? [],
      metadata: json['metadata'],
      replyToId: json['reply_to_id'],
      voiceTranscription: json['voice_transcription'],
      voiceDuration: json['voice_duration'],
      mediaUrl: json['media_url'],
      mediaThumbnail: json['media_thumbnail'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      isDeleted: json['is_deleted'] ?? false,
      threadId: json['thread_id'],
      mentions: json['mentions'] != null 
          ? List<String>.from(json['mentions']) 
          : null,
    );
  }

  Message copyWith({
    String? id,
    String? familyId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    MessagePriority? priority,
    DateTime? timestamp,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? readBy,
    List<MessageReaction>? reactions,
    Map<String, dynamic>? metadata,
    String? replyToId,
    Message? replyToMessage,
    String? voiceTranscription,
    int? voiceDuration,
    String? mediaUrl,
    String? mediaThumbnail,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isDeleted,
    String? threadId,
    List<String>? mentions,
  }) {
    return Message(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnail: mediaThumbnail ?? this.mediaThumbnail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isDeleted: isDeleted ?? this.isDeleted,
      threadId: threadId ?? this.threadId,
      mentions: mentions ?? this.mentions,
    );
  }
}