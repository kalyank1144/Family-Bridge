import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 3)
class MessageModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String senderId;

  @HiveField(2)
  late String senderName;

  @HiveField(3)
  String? senderImageUrl;

  @HiveField(4)
  late String content;

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late String messageType; // text, image, audio, video, file

  @HiveField(7)
  String? mediaUrl;

  @HiveField(8)
  String? localMediaPath;

  @HiveField(9)
  late bool isRead;

  @HiveField(10)
  late bool isSent;

  @HiveField(11)
  late bool isDelivered;

  @HiveField(12)
  String? familyId;

  @HiveField(13)
  String? recipientId;

  @HiveField(14)
  String? replyToId;

  @HiveField(15)
  Map<String, dynamic>? metadata;

  @HiveField(16)
  DateTime? editedAt;

  @HiveField(17)
  DateTime? deletedAt;

  @HiveField(18)
  List<String>? reactions;

  @HiveField(19)
  bool isSynced = false;

  @HiveField(20)
  int? messageOrder;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.content,
    required this.timestamp,
    this.messageType = 'text',
    this.mediaUrl,
    this.localMediaPath,
    this.isRead = false,
    this.isSent = false,
    this.isDelivered = false,
    this.familyId,
    this.recipientId,
    this.replyToId,
    this.metadata,
    this.editedAt,
    this.deletedAt,
    this.reactions,
    this.isSynced = false,
    this.messageOrder,
  });

  bool get hasMedia => mediaUrl != null || localMediaPath != null;
  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  String get displayTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'localMediaPath': localMediaPath,
      'isRead': isRead,
      'isSent': isSent,
      'isDelivered': isDelivered,
      'familyId': familyId,
      'recipientId': recipientId,
      'replyToId': replyToId,
      'metadata': metadata,
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'reactions': reactions,
      'isSynced': isSynced,
      'messageOrder': messageOrder,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderImageUrl: json['senderImageUrl'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      localMediaPath: json['localMediaPath'],
      isRead: json['isRead'] ?? false,
      isSent: json['isSent'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      familyId: json['familyId'],
      recipientId: json['recipientId'],
      replyToId: json['replyToId'],
      metadata: json['metadata'],
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt']) 
          : null,
      deletedAt: json['deletedAt'] != null 
          ? DateTime.parse(json['deletedAt']) 
          : null,
      reactions: json['reactions'] != null 
          ? List<String>.from(json['reactions']) 
          : null,
      isSynced: json['isSynced'] ?? false,
      messageOrder: json['messageOrder'],
    );
  }
}