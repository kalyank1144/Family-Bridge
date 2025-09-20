import 'package:hive/hive.dart';

class HiveDailyCheckin extends HiveObject {
  String id;
  String userId;
  String familyId;
  String mood;
  String sleepQuality;
  bool mealEaten;
  bool medicationTaken;
  bool physicalActivity;
  int painLevel;
  String? notes;
  String? voiceNoteUrl;
  DateTime createdAt;
  DateTime updatedAt;
  bool pendingSync;

  HiveDailyCheckin({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.mood,
    required this.sleepQuality,
    required this.mealEaten,
    required this.medicationTaken,
    required this.physicalActivity,
    required this.painLevel,
    this.notes,
    this.voiceNoteUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pendingSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'family_id': familyId,
        'mood': mood,
        'sleep_quality': sleepQuality,
        'meal_eaten': mealEaten,
        'medication_taken': medicationTaken,
        'physical_activity': physicalActivity,
        'pain_level': painLevel,
        'notes': notes,
        'voice_note_url': voiceNoteUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync,
      };

  factory HiveDailyCheckin.fromMap(Map<String, dynamic> map) =>
      HiveDailyCheckin(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        familyId: map['family_id'] as String,
        mood: map['mood'] as String? ?? 'neutral',
        sleepQuality: map['sleep_quality'] as String? ?? 'fair',
        mealEaten: map['meal_eaten'] as bool? ?? false,
        medicationTaken: map['medication_taken'] as bool? ?? false,
        physicalActivity: map['physical_activity'] as bool? ?? false,
        painLevel: map['pain_level'] as int? ?? 0,
        notes: map['notes'] as String?,
        voiceNoteUrl: map['voice_note_url'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        pendingSync: map['pending_sync'] as bool? ?? false,
      );

  String getMoodEmoji() {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'great':
        return '😊';
      case 'good':
      case 'okay':
        return '🙂';
      case 'neutral':
      case 'fair':
        return '😐';
      case 'sad':
      case 'not good':
        return '😔';
      case 'bad':
      case 'terrible':
        return '😢';
      default:
        return '😐';
    }
  }

  String getSleepEmoji() {
    switch (sleepQuality.toLowerCase()) {
      case 'excellent':
      case 'great':
        return '😴';
      case 'good':
        return '🛌';
      case 'fair':
        return '😪';
      case 'poor':
      case 'bad':
        return '😫';
      default:
        return '😪';
    }
  }

  int getWellnessScore() {
    int score = 0;
    
    // Mood scoring (0-30 points)
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'great':
        score += 30;
        break;
      case 'good':
        score += 20;
        break;
      case 'neutral':
        score += 10;
        break;
      case 'sad':
        score += 5;
        break;
    }
    
    // Sleep scoring (0-20 points)
    switch (sleepQuality.toLowerCase()) {
      case 'excellent':
        score += 20;
        break;
      case 'good':
        score += 15;
        break;
      case 'fair':
        score += 10;
        break;
      case 'poor':
        score += 5;
        break;
    }
    
    // Activities scoring (0-50 points)
    if (mealEaten) score += 15;
    if (medicationTaken) score += 20;
    if (physicalActivity) score += 15;
    
    // Pain adjustment (-20 to 0 points)
    score -= painLevel * 2;
    
    return score.clamp(0, 100);
  }
}

class HiveDailyCheckinAdapter extends TypeAdapter<HiveDailyCheckin> {
  @override
  final int typeId = 8;

  @override
  HiveDailyCheckin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveDailyCheckin(
      id: fields[0] as String,
      userId: fields[1] as String,
      familyId: fields[2] as String,
      mood: fields[3] as String,
      sleepQuality: fields[4] as String,
      mealEaten: fields[5] as bool,
      medicationTaken: fields[6] as bool,
      physicalActivity: fields[7] as bool,
      painLevel: fields[8] as int,
      notes: fields[9] as String?,
      voiceNoteUrl: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
      pendingSync: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HiveDailyCheckin obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.familyId)
      ..writeByte(3)
      ..write(obj.mood)
      ..writeByte(4)
      ..write(obj.sleepQuality)
      ..writeByte(5)
      ..write(obj.mealEaten)
      ..writeByte(6)
      ..write(obj.medicationTaken)
      ..writeByte(7)
      ..write(obj.physicalActivity)
      ..writeByte(8)
      ..write(obj.painLevel)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.voiceNoteUrl)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.pendingSync);
  }
}