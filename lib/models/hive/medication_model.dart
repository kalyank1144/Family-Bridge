import 'package:hive/hive.dart';

class HiveMedicationSchedule extends HiveObject {
  String id;
  String userId;
  String familyId;
  String name;
  String dosage;
  List<String> times; // e.g., 08:00, 12:00
  List<DateTime> takenLog; // timestamps when taken
  DateTime startDate;
  DateTime? endDate;
  DateTime updatedAt;
  bool pendingSync;

  HiveMedicationSchedule({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.name,
    required this.dosage,
    this.times = const [],
    this.takenLog = const [],
    DateTime? startDate,
    this.endDate,
    DateTime? updatedAt,
    this.pendingSync = false,
  })  : startDate = startDate ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'family_id': familyId,
        'name': name,
        'dosage': dosage,
        'times': times,
        'taken_log': takenLog.map((e) => e.toIso8601String()).toList(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory HiveMedicationSchedule.fromMap(Map<String, dynamic> map) =>
      HiveMedicationSchedule(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        familyId: map['family_id'] as String,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        times: (map['times'] as List?)?.cast<String>() ?? const [],
        takenLog: (map['taken_log'] as List?)
                ?.map((e) => DateTime.parse(e as String))
                .toList() ??
            const [],
        startDate: DateTime.parse(map['start_date'] as String),
        endDate:
            map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        pendingSync: map['pending_sync'] as bool? ?? false,
      );
}

class HiveMedicationScheduleAdapter extends TypeAdapter<HiveMedicationSchedule> {
  @override
  final int typeId = 5;

  @override
  HiveMedicationSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveMedicationSchedule(
      id: fields[0] as String,
      userId: fields[1] as String,
      familyId: fields[2] as String,
      name: fields[3] as String,
      dosage: fields[4] as String,
      times: (fields[5] as List?)?.cast<String>() ?? const [],
      takenLog: (fields[6] as List?)?.cast<DateTime>() ?? const [],
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      pendingSync: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HiveMedicationSchedule obj) {
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
      ..write(obj.dosage)
      ..writeByte(5)
      ..write(obj.times)
      ..writeByte(6)
      ..write(obj.takenLog)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.pendingSync);
  }
}
