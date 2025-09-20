import 'package:hive/hive.dart';

class HiveEmergencyContact extends HiveObject {
  String id;
  String userId;
  String familyId;
  String name;
  String relationship;
  String phone;
  String? photoUrl;
  int priority;
  DateTime createdAt;
  DateTime updatedAt;
  bool pendingSync;

  HiveEmergencyContact({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.name,
    required this.relationship,
    required this.phone,
    this.photoUrl,
    required this.priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pendingSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'family_id': familyId,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'photo_url': photoUrl,
        'priority': priority,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory HiveEmergencyContact.fromMap(Map<String, dynamic> map) =>
      HiveEmergencyContact(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        familyId: map['family_id'] as String,
        name: map['name'] as String,
        relationship: map['relationship'] as String,
        phone: map['phone'] as String,
        photoUrl: map['photo_url'] as String?,
        priority: map['priority'] as int? ?? 999,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        pendingSync: map['pending_sync'] as bool? ?? false,
      );
}

class HiveEmergencyContactAdapter extends TypeAdapter<HiveEmergencyContact> {
  @override
  final int typeId = 7;

  @override
  HiveEmergencyContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveEmergencyContact(
      id: fields[0] as String,
      userId: fields[1] as String,
      familyId: fields[2] as String,
      name: fields[3] as String,
      relationship: fields[4] as String,
      phone: fields[5] as String,
      photoUrl: fields[6] as String?,
      priority: fields[7] as int,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      pendingSync: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HiveEmergencyContact obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.familyId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.relationship)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.photoUrl)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.pendingSync);
  }
}