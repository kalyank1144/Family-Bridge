import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'medication.g.dart';

enum MedicationFrequency {
  once,
  twice,
  thrice,
  fourTimes,
  asNeeded,
  custom,
}

enum MedicationStatus {
  active,
  paused,
  completed,
  discontinued,
}

enum DosageUnit {
  tablet,
  capsule,
  ml,
  mg,
  drops,
  spray,
  patch,
  injection,
}

@HiveType(typeId: 13)
class Medication {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final double dosage;
  
  @HiveField(5)
  final DosageUnit unit;
  
  @HiveField(6)
  final MedicationFrequency frequency;
  
  @HiveField(7)
  final List<DateTime> scheduleTimes;
  
  @HiveField(8)
  final DateTime startDate;
  
  @HiveField(9)
  final DateTime? endDate;
  
  @HiveField(10)
  MedicationStatus status;
  
  @HiveField(11)
  final String? prescribedBy;
  
  @HiveField(12)
  final String? purpose;
  
  @HiveField(13)
  final List<String> sideEffects;
  
  @HiveField(14)
  final String? instructions;
  
  @HiveField(15)
  final int? refillsRemaining;
  
  @HiveField(16)
  final DateTime? nextRefillDate;
  
  @HiveField(17)
  final bool requiresFood;
  
  @HiveField(18)
  final bool isCritical;
  
  @HiveField(19)
  final List<String> reminders;
  
  @HiveField(20)
  final Map<String, bool> takenLog;
  
  @HiveField(21)
  final String? imageUrl;
  
  @HiveField(22)
  final DateTime createdAt;
  
  @HiveField(23)
  final DateTime updatedAt;
  
  Medication({
    String? id,
    required this.userId,
    required this.name,
    this.description,
    required this.dosage,
    required this.unit,
    required this.frequency,
    required this.scheduleTimes,
    required this.startDate,
    this.endDate,
    this.status = MedicationStatus.active,
    this.prescribedBy,
    this.purpose,
    List<String>? sideEffects,
    this.instructions,
    this.refillsRemaining,
    this.nextRefillDate,
    this.requiresFood = false,
    this.isCritical = false,
    List<String>? reminders,
    Map<String, bool>? takenLog,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       sideEffects = sideEffects ?? [],
       reminders = reminders ?? [],
       takenLog = takenLog ?? {},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  bool get isActive => status == MedicationStatus.active;
  
  bool get needsRefill {
    if (refillsRemaining == null) return false;
    return refillsRemaining! <= 1;
  }
  
  bool wasTakenToday() {
    final todayKey = _getDateKey(DateTime.now());
    return takenLog[todayKey] ?? false;
  }
  
  void markAsTaken({DateTime? date}) {
    final key = _getDateKey(date ?? DateTime.now());
    takenLog[key] = true;
  }
  
  void markAsSkipped({DateTime? date}) {
    final key = _getDateKey(date ?? DateTime.now());
    takenLog[key] = false;
  }
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'dosage': dosage,
      'unit': unit.index,
      'frequency': frequency.index,
      'scheduleTimes': scheduleTimes.map((t) => t.toIso8601String()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.index,
      'prescribedBy': prescribedBy,
      'purpose': purpose,
      'sideEffects': sideEffects,
      'instructions': instructions,
      'refillsRemaining': refillsRemaining,
      'nextRefillDate': nextRefillDate?.toIso8601String(),
      'requiresFood': requiresFood,
      'isCritical': isCritical,
      'reminders': reminders,
      'takenLog': takenLog,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      dosage: json['dosage'].toDouble(),
      unit: DosageUnit.values[json['unit']],
      frequency: MedicationFrequency.values[json['frequency']],
      scheduleTimes: (json['scheduleTimes'] as List)
          .map((t) => DateTime.parse(t))
          .toList(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null 
        ? DateTime.parse(json['endDate']) 
        : null,
      status: MedicationStatus.values[json['status'] ?? 0],
      prescribedBy: json['prescribedBy'],
      purpose: json['purpose'],
      sideEffects: json['sideEffects'] != null 
        ? List<String>.from(json['sideEffects']) 
        : [],
      instructions: json['instructions'],
      refillsRemaining: json['refillsRemaining'],
      nextRefillDate: json['nextRefillDate'] != null 
        ? DateTime.parse(json['nextRefillDate']) 
        : null,
      requiresFood: json['requiresFood'] ?? false,
      isCritical: json['isCritical'] ?? false,
      reminders: json['reminders'] != null 
        ? List<String>.from(json['reminders']) 
        : [],
      takenLog: json['takenLog'] != null 
        ? Map<String, bool>.from(json['takenLog']) 
        : {},
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  Medication copyWith({
    String? description,
    double? dosage,
    DosageUnit? unit,
    MedicationFrequency? frequency,
    List<DateTime>? scheduleTimes,
    DateTime? endDate,
    MedicationStatus? status,
    String? prescribedBy,
    String? purpose,
    List<String>? sideEffects,
    String? instructions,
    int? refillsRemaining,
    DateTime? nextRefillDate,
    bool? requiresFood,
    bool? isCritical,
    List<String>? reminders,
    Map<String, bool>? takenLog,
    String? imageUrl,
  }) {
    return Medication(
      id: id,
      userId: userId,
      name: name,
      description: description ?? this.description,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      purpose: purpose ?? this.purpose,
      sideEffects: sideEffects ?? this.sideEffects,
      instructions: instructions ?? this.instructions,
      refillsRemaining: refillsRemaining ?? this.refillsRemaining,
      nextRefillDate: nextRefillDate ?? this.nextRefillDate,
      requiresFood: requiresFood ?? this.requiresFood,
      isCritical: isCritical ?? this.isCritical,
      reminders: reminders ?? this.reminders,
      takenLog: takenLog ?? this.takenLog,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 13;
  
  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String?,
      dosage: fields[4] as double,
      unit: DosageUnit.values[fields[5] as int],
      frequency: MedicationFrequency.values[fields[6] as int],
      scheduleTimes: (fields[7] as List).cast<DateTime>(),
      startDate: fields[8] as DateTime,
      endDate: fields[9] as DateTime?,
      status: MedicationStatus.values[fields[10] as int],
      prescribedBy: fields[11] as String?,
      purpose: fields[12] as String?,
      sideEffects: (fields[13] as List).cast<String>(),
      instructions: fields[14] as String?,
      refillsRemaining: fields[15] as int?,
      nextRefillDate: fields[16] as DateTime?,
      requiresFood: fields[17] as bool,
      isCritical: fields[18] as bool,
      reminders: (fields[19] as List).cast<String>(),
      takenLog: Map<String, bool>.from(fields[20] as Map),
      imageUrl: fields[21] as String?,
      createdAt: fields[22] as DateTime,
      updatedAt: fields[23] as DateTime,
    );
  }
  
  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.dosage)
      ..writeByte(5)
      ..write(obj.unit.index)
      ..writeByte(6)
      ..write(obj.frequency.index)
      ..writeByte(7)
      ..write(obj.scheduleTimes)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.endDate)
      ..writeByte(10)
      ..write(obj.status.index)
      ..writeByte(11)
      ..write(obj.prescribedBy)
      ..writeByte(12)
      ..write(obj.purpose)
      ..writeByte(13)
      ..write(obj.sideEffects)
      ..writeByte(14)
      ..write(obj.instructions)
      ..writeByte(15)
      ..write(obj.refillsRemaining)
      ..writeByte(16)
      ..write(obj.nextRefillDate)
      ..writeByte(17)
      ..write(obj.requiresFood)
      ..writeByte(18)
      ..write(obj.isCritical)
      ..writeByte(19)
      ..write(obj.reminders)
      ..writeByte(20)
      ..write(obj.takenLog)
      ..writeByte(21)
      ..write(obj.imageUrl)
      ..writeByte(22)
      ..write(obj.createdAt)
      ..writeByte(23)
      ..write(obj.updatedAt);
  }
  
  @override
  int get hashCode => typeId.hashCode;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}