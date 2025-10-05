import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';

// Message enums with type safety
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
  queued,
}

enum MessagePriority {
  normal,
  important,
  urgent,
  emergency,
}

/// Message reaction model
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

  Map<String, dynamic> toMap() => toJson();
  factory MessageReaction.fromMap(Map<String, dynamic> map) => MessageReaction.fromJson(map);
}

/// Unified message model for both online and offline storage
/// Combines the rich feature set from chat model with Hive compatibility
class Message extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  String senderType; // elder, caregiver, youth

  @HiveField(5)
  String? senderAvatar;

  @HiveField(6)
  String? content;

  @HiveField(7)
  MessageType type;

  @HiveField(8)
  MessageStatus status;

  @HiveField(9)
  MessagePriority priority;

  @HiveField(10)
  DateTime timestamp;

  @HiveField(11)
  bool isEdited;

  @HiveField(12)
  DateTime? editedAt;

  @HiveField(13)
  List<String> readBy;

  @HiveField(14)
  List<MessageReaction> reactions;

  @HiveField(15)
  Map<String, dynamic>? metadata;

  @HiveField(16)
  String? replyToId;

  @HiveField(17)
  String? voiceTranscription;

  @HiveField(18)
  int? voiceDuration;

  @HiveField(19)
  String? mediaUrl;

  @HiveField(20)
  String? mediaThumbnail;

  @HiveField(21)
  double? latitude;

  @HiveField(22)
  double? longitude;

  @HiveField(23)
  String? locationName;

  @HiveField(24)
  bool isDeleted;

  @HiveField(25)
  String? threadId;

  @HiveField(26)
  List<String>? mentions;

  // Offline-first specific fields
  @HiveField(27)
  bool pendingSync;

  @HiveField(28)
  DateTime updatedAt;

  @HiveField(29)
  Message? replyToMessage; // Cached reply message for offline use

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
    this.pendingSync = false,
    DateTime? updatedAt,
    this.replyToMessage,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for API communication
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
      'pending_sync': pendingSync,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (API response)
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
      pendingSync: json['pending_sync'] ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert to Map for Hive storage and local operations
  Map<String, dynamic> toMap() {
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
      'reactions': reactions.map((r) => r.toMap()).toList(),
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
      'pending_sync': pendingSync,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (Hive storage)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      senderId: map['sender_id'] as String,
      senderName: map['sender_name'] as String? ?? 'Unknown',
      senderType: map['sender_type'] as String? ?? 'elder',
      senderAvatar: map['sender_avatar'] as String?,
      content: map['content'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => MessagePriority.normal,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isEdited: map['is_edited'] as bool? ?? false,
      editedAt: map['edited_at'] != null
          ? DateTime.parse(map['edited_at'] as String)
          : null,
      readBy: (map['read_by'] as List?)?.cast<String>() ?? const [],
      reactions: (map['reactions'] as List<dynamic>?)
          ?.map((r) => MessageReaction.fromMap(r))
          .toList() ?? [],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      replyToId: map['reply_to_id'] as String?,
      voiceTranscription: map['voice_transcription'] as String?,
      voiceDuration: map['voice_duration'] as int?,
      mediaUrl: map['media_url'] as String?,
      mediaThumbnail: map['media_thumbnail'] as String?,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['location_name'] as String?,
      isDeleted: map['is_deleted'] as bool? ?? false,
      threadId: map['thread_id'] as String?,
      mentions: (map['mentions'] as List?)?.cast<String>(),
      pendingSync: map['pending_sync'] as bool? ?? false,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
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
    bool? pendingSync,
    DateTime? updatedAt,
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
      pendingSync: pendingSync ?? this.pendingSync,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Mark message as read by a user
  Message markAsReadBy(String userId) {
    if (readBy.contains(userId)) return this;
    
    return copyWith(
      readBy: [...readBy, userId],
      updatedAt: DateTime.now(),
    );
  }

  /// Add reaction to message
  Message addReaction(MessageReaction reaction) {
    // Remove existing reaction from the same user with same emoji
    final updatedReactions = reactions.where(
      (r) => !(r.userId == reaction.userId && r.emoji == reaction.emoji)
    ).toList();
    
    updatedReactions.add(reaction);
    
    return copyWith(
      reactions: updatedReactions,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove reaction from message
  Message removeReaction(String userId, String emoji) {
    final updatedReactions = reactions.where(
      (r) => !(r.userId == userId && r.emoji == emoji)
    ).toList();
    
    return copyWith(
      reactions: updatedReactions,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if message needs sync
  bool get needsSync => pendingSync;

  /// Check if message is from current user
  bool isFromUser(String currentUserId) => senderId == currentUserId;

  /// Check if message was read by user
  bool wasReadBy(String userId) => readBy.contains(userId);

  /// Get reaction count for specific emoji
  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  /// Check if user reacted with emoji
  bool hasUserReaction(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, senderName: $senderName, type: $type, priority: $priority, timestamp: $timestamp}';
  }
}

/// Hive adapter for Message model
class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 1; // Make sure this is unique across your app

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Message(
      id: fields[0] as String,
      familyId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      senderType: fields[4] as String,
      senderAvatar: fields[5] as String?,
      content: fields[6] as String?,
      type: fields[7] as MessageType,
      status: fields[8] as MessageStatus,
      priority: fields[9] as MessagePriority,
      timestamp: fields[10] as DateTime,
      isEdited: fields[11] as bool,
      editedAt: fields[12] as DateTime?,
      readBy: (fields[13] as List?)?.cast<String>() ?? [],
      reactions: (fields[14] as List?)?.cast<MessageReaction>() ?? [],
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
      replyToId: fields[16] as String?,
      voiceTranscription: fields[17] as String?,
      voiceDuration: fields[18] as int?,
      mediaUrl: fields[19] as String?,
      mediaThumbnail: fields[20] as String?,
      latitude: fields[21] as double?,
      longitude: fields[22] as double?,
      locationName: fields[23] as String?,
      isDeleted: fields[24] as bool,
      threadId: fields[25] as String?,
      mentions: (fields[26] as List?)?.cast<String>(),
      pendingSync: fields[27] as bool,
      updatedAt: fields[28] as DateTime,
      replyToMessage: fields[29] as Message?,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(30) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.senderType)
      ..writeByte(5)
      ..write(obj.senderAvatar)
      ..writeByte(6)
      ..write(obj.content)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.isEdited)
      ..writeByte(12)
      ..write(obj.editedAt)
      ..writeByte(13)
      ..write(obj.readBy)
      ..writeByte(14)
      ..write(obj.reactions)
      ..writeByte(15)
      ..write(obj.metadata)
      ..writeByte(16)
      ..write(obj.replyToId)
      ..writeByte(17)
      ..write(obj.voiceTranscription)
      ..writeByte(18)
      ..write(obj.voiceDuration)
      ..writeByte(19)
      ..write(obj.mediaUrl)
      ..writeByte(20)
      ..write(obj.mediaThumbnail)
      ..writeByte(21)
      ..write(obj.latitude)
      ..writeByte(22)
      ..write(obj.longitude)
      ..writeByte(23)
      ..write(obj.locationName)
      ..writeByte(24)
      ..write(obj.isDeleted)
      ..writeByte(25)
      ..write(obj.threadId)
      ..writeByte(26)
      ..write(obj.mentions)
      ..writeByte(27)
      ..write(obj.pendingSync)
      ..writeByte(28)
      ..write(obj.updatedAt)
      ..writeByte(29)
      ..write(obj.replyToMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// Hive adapters for enums
class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 2;

  @override
  MessageType read(BinaryReader reader) {
    return MessageType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    writer.writeByte(obj.index);
  }
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 3;

  @override
  MessageStatus read(BinaryReader reader) {
    return MessageStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    writer.writeByte(obj.index);
  }
}

class MessagePriorityAdapter extends TypeAdapter<MessagePriority> {
  @override
  final int typeId = 4;

  @override
  MessagePriority read(BinaryReader reader) {
    return MessagePriority.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, MessagePriority obj) {
    writer.writeByte(obj.index);
  }
}

class MessageReactionAdapter extends TypeAdapter<MessageReaction> {
  @override
  final int typeId = 5;

  @override
  MessageReaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return MessageReaction(
      userId: fields[0] as String,
      userName: fields[1] as String,
      emoji: fields[2] as String,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MessageReaction obj) {
    writer
      ..writeByte(4) // Number of fields
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.userName)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.timestamp);
  }
}