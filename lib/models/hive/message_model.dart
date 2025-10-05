import 'package:hive/hive.dart';

class HiveChatMessage extends HiveObject {
  String id;
  String familyId;
  String senderId;
  String senderName;
  String senderType;
  String? content;
  String type; // text, voice, image, video, location
  String status; // sending, sent, delivered, read, failed, queued
  String priority; // normal, important, urgent, emergency
  DateTime timestamp;
  bool isEdited;
  DateTime? editedAt;
  List<String> readBy;
  Map<String, dynamic>? metadata;
  String? replyToId;
  bool isDeleted;
  List<String>? mentions;
  bool pendingSync;
  DateTime updatedAt;

  HiveChatMessage({
    required this.id,
    required this.familyId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.content,
    required this.type,
    required this.status,
    required this.priority,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.readBy = const [],
    this.metadata,
    this.replyToId,
    this.isDeleted = false,
    this.mentions,
    this.pendingSync = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'family_id': familyId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_type': senderType,
        'content': content,
        'type': type,
        'status': status,
        'priority': priority,
        'timestamp': timestamp.toIso8601String(),
        'is_edited': isEdited,
        'edited_at': editedAt?.toIso8601String(),
        'read_by': readBy,
        'metadata': metadata,
        'reply_to_id': replyToId,
        'is_deleted': isDeleted,
        'mentions': mentions,
        'pending_sync': pendingSync,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory HiveChatMessage.fromMap(Map<String, dynamic> map) => HiveChatMessage(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        senderId: map['sender_id'] as String,
        senderName: map['sender_name'] as String? ?? 'Unknown',
        senderType: map['sender_type'] as String? ?? 'elder',
        content: map['content'] as String?,
        type: map['type'] as String? ?? 'text',
        status: map['status'] as String? ?? 'sent',
        priority: map['priority'] as String? ?? 'normal',
        timestamp: DateTime.parse(map['timestamp'] as String),
        isEdited: map['is_edited'] as bool? ?? false,
        editedAt: map['edited_at'] != null
            ? DateTime.parse(map['edited_at'] as String)
            : null,
        readBy: (map['read_by'] as List?)?.cast<String>() ?? const [],
        metadata: map['metadata'] != null
            ? Map<String, dynamic>.from(map['metadata'])
            : null,
        replyToId: map['reply_to_id'] as String?,
        isDeleted: map['is_deleted'] as bool? ?? false,
        mentions: (map['mentions'] as List?)?.cast<String>(),
        pendingSync: map['pending_sync'] as bool? ?? false,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
      );
}

class HiveChatMessageAdapter extends TypeAdapter<HiveChatMessage> {
  @override
  final int typeId = 2;

  @override
  HiveChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveChatMessage(
      id: fields[0] as String,
      familyId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      senderType: fields[4] as String,
      content: fields[5] as String?,
      type: fields[6] as String,
      status: fields[7] as String,
      priority: fields[8] as String,
      timestamp: fields[9] as DateTime,
      isEdited: fields[10] as bool,
      editedAt: fields[11] as DateTime?,
      readBy: (fields[12] as List?)?.cast<String>() ?? const [],
      metadata: (fields[13] as Map?)?.cast<String, dynamic>(),
      replyToId: fields[14] as String?,
      isDeleted: fields[15] as bool,
      mentions: (fields[16] as List?)?.cast<String>(),
      pendingSync: fields[17] as bool? ?? false,
      updatedAt: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveChatMessage obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.isEdited)
      ..writeByte(11)
      ..write(obj.editedAt)
      ..writeByte(12)
      ..write(obj.readBy)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.replyToId)
      ..writeByte(15)
      ..write(obj.isDeleted)
      ..writeByte(16)
      ..write(obj.mentions)
      ..writeByte(17)
      ..write(obj.pendingSync)
      ..writeByte(18)
      ..write(obj.updatedAt);
  }
}
