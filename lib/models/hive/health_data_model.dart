import 'package:hive/hive.dart';

class HiveHealthRecord extends HiveObject {
  String id;
  String userId;
  String familyId;
  String category; // vitals, symptom, medication_log
  Map<String, dynamic> data; // flexible payload
  DateTime recordedAt;
  DateTime updatedAt;
  bool pendingSync;

  HiveHealthRecord({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.category,
    required this.data,
    required this.recordedAt,
    DateTime? updatedAt,
    this.pendingSync = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'family_id': familyId,
        'category': category,
        'data': data,
        'recorded_at': recordedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory HiveHealthRecord.fromMap(Map<String, dynamic> map) => HiveHealthRecord(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        familyId: map['family_id'] as String,
        category: map['category'] as String,
        data: Map<String, dynamic>.from(map['data'] ?? {}),
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        pendingSync: map['pending_sync'] as bool? ?? false,
      );
}

class HiveHealthRecordAdapter extends TypeAdapter<HiveHealthRecord> {
  @override
  final int typeId = 3;

  @override
  HiveHealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveHealthRecord(
      id: fields[0] as String,
      userId: fields[1] as String,
      familyId: fields[2] as String,
      category: fields[3] as String,
      data: (fields[4] as Map).cast<String, dynamic>(),
      recordedAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
      pendingSync: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HiveHealthRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.familyId)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.recordedAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.pendingSync);
  }
}
