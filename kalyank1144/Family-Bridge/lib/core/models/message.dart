import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  location,
  system,
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

@HiveType(typeId: 11)
class Message {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String conversationId;
  
  @HiveField(2)
  final String senderId;
  
  @HiveField(3)
  final String senderName;
  
  @HiveField(4)
  final String? content;
  
  @HiveField(5)
  final MessageType type;
  
  @HiveField(6)
  final DateTime timestamp;
  
  @HiveField(7)
  MessageStatus status;
  
  @HiveField(8)
  final String? mediaUrl;
  
  @HiveField(9)
  final String? thumbnailUrl;
  
  @HiveField(10)
  final Map<String, dynamic>? metadata;
  
  @HiveField(11)
  final List<String> readBy;
  
  @HiveField(12)
  final String? replyToId;
  
  @HiveField(13)
  bool isEdited;
  
  @HiveField(14)
  DateTime? editedAt;
  
  @HiveField(15)
  bool isDeleted;
  
  @HiveField(16)
  DateTime? deletedAt;
  
  Message({
    String? id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.content,
    required this.type,
    DateTime? timestamp,
    this.status = MessageStatus.pending,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    List<String>? readBy,
    this.replyToId,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       readBy = readBy ?? [];
  
  void markAsSent() {
    status = MessageStatus.sent;
  }
  
  void markAsDelivered() {
    status = MessageStatus.delivered;
  }
  
  void markAsRead(String userId) {
    if (!readBy.contains(userId)) {
      readBy.add(userId);
      status = MessageStatus.read;
    }
  }
  
  void markAsFailed() {
    status = MessageStatus.failed;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'readBy': readBy,
      'replyToId': replyToId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      type: MessageType.values[json['type']],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status'] ?? 0],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      metadata: json['metadata'] != null 
        ? Map<String, dynamic>.from(json['metadata']) 
        : null,
      readBy: json['readBy'] != null 
        ? List<String>.from(json['readBy']) 
        : [],
      replyToId: json['replyToId'],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null 
        ? DateTime.parse(json['editedAt']) 
        : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null 
        ? DateTime.parse(json['deletedAt']) 
        : null,
    );
  }
  
  Message copyWith({
    String? content,
    MessageStatus? status,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      replyToId: replyToId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 11;
  
  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      content: fields[4] as String?,
      type: MessageType.values[fields[5] as int],
      timestamp: fields[6] as DateTime,
      status: MessageStatus.values[fields[7] as int],
      mediaUrl: fields[8] as String?,
      thumbnailUrl: fields[9] as String?,
      metadata: fields[10] != null 
        ? Map<String, dynamic>.from(fields[10] as Map) 
        : null,
      readBy: fields[11] != null 
        ? List<String>.from(fields[11] as List) 
        : [],
      replyToId: fields[12] as String?,
      isEdited: fields[13] as bool,
      editedAt: fields[14] as DateTime?,
      isDeleted: fields[15] as bool,
      deletedAt: fields[16] as DateTime?,
    );
  }
  
  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.type.index)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.status.index)
      ..writeByte(8)
      ..write(obj.mediaUrl)
      ..writeByte(9)
      ..write(obj.thumbnailUrl)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.readBy)
      ..writeByte(12)
      ..write(obj.replyToId)
      ..writeByte(13)
      ..write(obj.isEdited)
      ..writeByte(14)
      ..write(obj.editedAt)
      ..writeByte(15)
      ..write(obj.isDeleted)
      ..writeByte(16)
      ..write(obj.deletedAt);
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