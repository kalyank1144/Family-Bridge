import 'package:hive/hive.dart';

part 'medication_model.g.dart';

@HiveType(typeId: 10)
class Medication extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String medicationName;

  @HiveField(3)
  String dosage;

  @HiveField(4)
  String frequency;

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  String? photoUrl;

  @HiveField(8)
  String? instructions;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  List<String> reminderTimes;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  Medication({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.photoUrl,
    this.instructions,
    this.isActive = true,
    required this.reminderTimes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'photo_url': photoUrl,
      'instructions': instructions,
      'is_active': isActive,
      'reminder_times': reminderTimes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      photoUrl: json['photo_url'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      reminderTimes: List<String>.from(json['reminder_times'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Medication copyWith({
    String? id,
    String? userId,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? photoUrl,
    String? instructions,
    bool? isActive,
    List<String>? reminderTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      photoUrl: photoUrl ?? this.photoUrl,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 11)
class MedicationReminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  DateTime scheduledTime;

  @HiveField(4)
  MedicationReminderStatus status;

  @HiveField(5)
  DateTime? takenTime;

  @HiveField(6)
  String? verificationPhotoUrl;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  int? notificationId;

  @HiveField(11)
  bool isRecurring;

  @HiveField(12)
  Duration? snoozeInterval;

  @HiveField(13)
  int snoozeCount;

  MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.userId,
    required this.scheduledTime,
    this.status = MedicationReminderStatus.pending,
    this.takenTime,
    this.verificationPhotoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.notificationId,
    this.isRecurring = true,
    this.snoozeInterval,
    this.snoozeCount = 0,
  });

  bool get isOverdue {
    if (status == MedicationReminderStatus.taken ||
        status == MedicationReminderStatus.skipped) {
      return false;
    }
    
    final now = DateTime.now();
    const overdueThreshold = Duration(hours: 1);
    return now.difference(scheduledTime) > overdueThreshold;
  }

  bool get isMissed {
    if (status == MedicationReminderStatus.taken ||
        status == MedicationReminderStatus.skipped) {
      return false;
    }
    
    final now = DateTime.now();
    const missedThreshold = Duration(hours: 4);
    return now.difference(scheduledTime) > missedThreshold;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'user_id': userId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'taken_time': takenTime?.toIso8601String(),
      'verification_photo_url': verificationPhotoUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notification_id': notificationId,
      'is_recurring': isRecurring,
      'snooze_interval': snoozeInterval?.inMinutes,
      'snooze_count': snoozeCount,
    };
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'] as String,
      medicationId: json['medication_id'] as String,
      userId: json['user_id'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      status: MedicationReminderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MedicationReminderStatus.pending,
      ),
      takenTime: json['taken_time'] != null
          ? DateTime.parse(json['taken_time'] as String)
          : null,
      verificationPhotoUrl: json['verification_photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notificationId: json['notification_id'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? true,
      snoozeInterval: json['snooze_interval'] != null
          ? Duration(minutes: json['snooze_interval'] as int)
          : null,
      snoozeCount: json['snooze_count'] as int? ?? 0,
    );
  }

  MedicationReminder copyWith({
    String? id,
    String? medicationId,
    String? userId,
    DateTime? scheduledTime,
    MedicationReminderStatus? status,
    DateTime? takenTime,
    String? verificationPhotoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? notificationId,
    bool? isRecurring,
    Duration? snoozeInterval,
    int? snoozeCount,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      userId: userId ?? this.userId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      takenTime: takenTime ?? this.takenTime,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationId: notificationId ?? this.notificationId,
      isRecurring: isRecurring ?? this.isRecurring,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }
}

@HiveType(typeId: 12)
enum MedicationReminderStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  taken,
  
  @HiveField(2)
  missed,
  
  @HiveField(3)
  skipped,
  
  @HiveField(4)
  snoozed,
  
  @HiveField(5)
  overdue,
}

@HiveType(typeId: 13)
class MedicationLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  DateTime scheduledTime;

  @HiveField(4)
  DateTime? takenTime;

  @HiveField(5)
  MedicationReminderStatus status;

  @HiveField(6)
  String? verificationPhotoUrl;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.userId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.verificationPhotoUrl,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'user_id': userId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'verification_photo_url': verificationPhotoUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medication_id'] as String,
      userId: json['user_id'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      takenTime: json['taken_time'] != null
          ? DateTime.parse(json['taken_time'] as String)
          : null,
      status: MedicationReminderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MedicationReminderStatus.pending,
      ),
      verificationPhotoUrl: json['verification_photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory MedicationLog.fromReminder(MedicationReminder reminder) {
    return MedicationLog(
      id: reminder.id,
      medicationId: reminder.medicationId,
      userId: reminder.userId,
      scheduledTime: reminder.scheduledTime,
      takenTime: reminder.takenTime,
      status: reminder.status,
      verificationPhotoUrl: reminder.verificationPhotoUrl,
      notes: reminder.notes,
      createdAt: DateTime.now(),
    );
  }
}