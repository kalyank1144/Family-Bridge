import 'package:hive/hive.dart';

class HiveUserProfile extends HiveObject {
  String id;
  String name;
  String userType; // elder, caregiver, youth
  String? avatarUrl;
  Map<String, dynamic> preferences;
  List<String> familyGroupIds;
  DateTime updatedAt;
  DateTime? lastSyncedAt;

  HiveUserProfile({
    required this.id,
    required this.name,
    required this.userType,
    this.avatarUrl,
    this.preferences = const {},
    this.familyGroupIds = const [],
    DateTime? updatedAt,
    this.lastSyncedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'user_type': userType,
        'avatar_url': avatarUrl,
        'preferences': preferences,
        'family_group_ids': familyGroupIds,
        'updated_at': updatedAt.toIso8601String(),
        'last_synced_at': lastSyncedAt?.toIso8601String(),
      };

  factory HiveUserProfile.fromMap(Map<String, dynamic> map) => HiveUserProfile(
        id: map['id'] as String,
        name: map['name'] as String? ?? 'Unknown',
        userType: map['user_type'] as String? ?? 'elder',
        avatarUrl: map['avatar_url'] as String?,
        preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
        familyGroupIds: (map['family_group_ids'] as List?)?.cast<String>() ??
            const <String>[],
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : DateTime.now(),
        lastSyncedAt: map['last_synced_at'] != null
            ? DateTime.parse(map['last_synced_at'])
            : null,
      );
}

class HiveUserProfileAdapter extends TypeAdapter<HiveUserProfile> {
  @override
  final int typeId = 1;

  @override
  HiveUserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return HiveUserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      userType: fields[2] as String,
      avatarUrl: fields[3] as String?,
      preferences: (fields[4] as Map?)?.cast<String, dynamic>() ?? const {},
      familyGroupIds: (fields[5] as List?)?.cast<String>() ?? const [],
      updatedAt: fields[6] as DateTime?,
      lastSyncedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userType)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.preferences)
      ..writeByte(5)
      ..write(obj.familyGroupIds)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.lastSyncedAt);
  }
}
