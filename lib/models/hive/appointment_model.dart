import 'package:hive/hive.dart';

class HiveAppointment extends HiveObject {
  String id;
  String userId;
  String familyId;
  String title;
  String? description;
  DateTime startAt;
  DateTime? endAt;
  DateTime? reminderAt;
  String status; // scheduled, done, cancelled
  DateTime updatedAt;
  bool pendingSync;

  HiveAppointment({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    this.reminderAt,
    this.status = 'scheduled',
    DateTime? updatedAt,
    this.pendingSync = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'family_id': familyId,
        'title': title,
        'description': description,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
        'reminder_at': reminderAt?.toIso8601String(),
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory HiveAppointment.fromMap(Map<String, dynamic> map) => HiveAppointment(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        familyId: map['family_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        startAt: DateTime.parse(map['start_at'] as String),
        endAt: map['end_at'] != null
            ? DateTime.parse(map['end_at'] as String)
            : null,
        reminderAt: map['reminder_at'] != null
            ? DateTime.parse(map['reminder_at'] as String)
            : null,
        status: map['status'] as String? ?? 'scheduled',
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        pendingSync: map['pending_sync'] as bool? ?? false,
      );
}

class HiveAppointmentAdapter extends TypeAdapter<HiveAppointment> {
  @override
  final int typeId = 4;

  @override
  HiveAppointment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveAppointment(
      id: fields[0] as String,
      userId: fields[1] as String,
      familyId: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String?,
      startAt: fields[5] as DateTime,
      endAt: fields[6] as DateTime?,
      reminderAt: fields[7] as DateTime?,
      status: fields[8] as String,
      updatedAt: fields[9] as DateTime?,
      pendingSync: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAppointment obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.familyId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.startAt)
      ..writeByte(6)
      ..write(obj.endAt)
      ..writeByte(7)
      ..write(obj.reminderAt)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.pendingSync);
  }
}
