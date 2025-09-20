import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'health_record.g.dart';

enum HealthRecordType {
  dailyCheckIn,
  vitals,
  medication,
  appointment,
  symptom,
  emergency,
  note,
}

enum MoodLevel {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
}

@HiveType(typeId: 12)
class HealthRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final HealthRecordType type;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final Map<String, dynamic> data;
  
  @HiveField(5)
  final String? notes;
  
  @HiveField(6)
  final List<String> attachments;
  
  @HiveField(7)
  final String? recordedBy;
  
  @HiveField(8)
  final bool isCritical;
  
  @HiveField(9)
  final bool requiresFollowUp;
  
  @HiveField(10)
  final DateTime? followUpDate;
  
  @HiveField(11)
  final Map<String, dynamic>? vitals;
  
  @HiveField(12)
  final MoodLevel? mood;
  
  @HiveField(13)
  final int? painLevel;
  
  @HiveField(14)
  final List<String> symptoms;
  
  @HiveField(15)
  final bool synced;
  
  HealthRecord({
    String? id,
    required this.userId,
    required this.type,
    DateTime? timestamp,
    required this.data,
    this.notes,
    List<String>? attachments,
    this.recordedBy,
    this.isCritical = false,
    this.requiresFollowUp = false,
    this.followUpDate,
    this.vitals,
    this.mood,
    this.painLevel,
    List<String>? symptoms,
    this.synced = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       attachments = attachments ?? [],
       symptoms = symptoms ?? [];
  
  bool get needsAttention => isCritical || requiresFollowUp;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'notes': notes,
      'attachments': attachments,
      'recordedBy': recordedBy,
      'isCritical': isCritical,
      'requiresFollowUp': requiresFollowUp,
      'followUpDate': followUpDate?.toIso8601String(),
      'vitals': vitals,
      'mood': mood?.index,
      'painLevel': painLevel,
      'symptoms': symptoms,
      'synced': synced,
    };
  }
  
  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'],
      userId: json['userId'],
      type: HealthRecordType.values[json['type']],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
      notes: json['notes'],
      attachments: json['attachments'] != null 
        ? List<String>.from(json['attachments']) 
        : [],
      recordedBy: json['recordedBy'],
      isCritical: json['isCritical'] ?? false,
      requiresFollowUp: json['requiresFollowUp'] ?? false,
      followUpDate: json['followUpDate'] != null 
        ? DateTime.parse(json['followUpDate']) 
        : null,
      vitals: json['vitals'] != null 
        ? Map<String, dynamic>.from(json['vitals']) 
        : null,
      mood: json['mood'] != null 
        ? MoodLevel.values[json['mood']] 
        : null,
      painLevel: json['painLevel'],
      symptoms: json['symptoms'] != null 
        ? List<String>.from(json['symptoms']) 
        : [],
      synced: json['synced'] ?? false,
    );
  }
  
  HealthRecord copyWith({
    String? notes,
    List<String>? attachments,
    bool? isCritical,
    bool? requiresFollowUp,
    DateTime? followUpDate,
    Map<String, dynamic>? vitals,
    MoodLevel? mood,
    int? painLevel,
    List<String>? symptoms,
    bool? synced,
  }) {
    return HealthRecord(
      id: id,
      userId: userId,
      type: type,
      timestamp: timestamp,
      data: data,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      recordedBy: recordedBy,
      isCritical: isCritical ?? this.isCritical,
      requiresFollowUp: requiresFollowUp ?? this.requiresFollowUp,
      followUpDate: followUpDate ?? this.followUpDate,
      vitals: vitals ?? this.vitals,
      mood: mood ?? this.mood,
      painLevel: painLevel ?? this.painLevel,
      symptoms: symptoms ?? this.symptoms,
      synced: synced ?? this.synced,
    );
  }
}

class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 12;
  
  @override
  HealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthRecord(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: HealthRecordType.values[fields[2] as int],
      timestamp: fields[3] as DateTime,
      data: Map<String, dynamic>.from(fields[4] as Map),
      notes: fields[5] as String?,
      attachments: fields[6] != null 
        ? List<String>.from(fields[6] as List) 
        : [],
      recordedBy: fields[7] as String?,
      isCritical: fields[8] as bool,
      requiresFollowUp: fields[9] as bool,
      followUpDate: fields[10] as DateTime?,
      vitals: fields[11] != null 
        ? Map<String, dynamic>.from(fields[11] as Map) 
        : null,
      mood: fields[12] != null 
        ? MoodLevel.values[fields[12] as int] 
        : null,
      painLevel: fields[13] as int?,
      symptoms: fields[14] != null 
        ? List<String>.from(fields[14] as List) 
        : [],
      synced: fields[15] as bool,
    );
  }
  
  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.attachments)
      ..writeByte(7)
      ..write(obj.recordedBy)
      ..writeByte(8)
      ..write(obj.isCritical)
      ..writeByte(9)
      ..write(obj.requiresFollowUp)
      ..writeByte(10)
      ..write(obj.followUpDate)
      ..writeByte(11)
      ..write(obj.vitals)
      ..writeByte(12)
      ..write(obj.mood?.index)
      ..writeByte(13)
      ..write(obj.painLevel)
      ..writeByte(14)
      ..write(obj.symptoms)
      ..writeByte(15)
      ..write(obj.synced);
  }
  
  @override
  int get hashCode => typeId.hashCode;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}