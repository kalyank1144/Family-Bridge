import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

@HiveType(typeId: 4)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late String title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  late DateTime dateTime;

  @HiveField(5)
  String? location;

  @HiveField(6)
  String? doctorName;

  @HiveField(7)
  String? doctorSpecialty;

  @HiveField(8)
  String? appointmentType; // checkup, followup, consultation, procedure

  @HiveField(9)
  int? duration; // in minutes

  @HiveField(10)
  String? notes;

  @HiveField(11)
  List<String>? reminders; // reminder times in minutes before appointment

  @HiveField(12)
  bool isCompleted = false;

  @HiveField(13)
  bool isCancelled = false;

  @HiveField(14)
  DateTime? completedAt;

  @HiveField(15)
  DateTime? cancelledAt;

  @HiveField(16)
  String? cancellationReason;

  @HiveField(17)
  Map<String, dynamic>? metadata;

  @HiveField(18)
  bool isSynced = false;

  @HiveField(19)
  DateTime? lastSynced;

  @HiveField(20)
  String? phoneNumber;

  @HiveField(21)
  String? address;

  @HiveField(22)
  List<String>? preparationInstructions;

  @HiveField(23)
  String? transportArrangement;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
    this.doctorName,
    this.doctorSpecialty,
    this.appointmentType,
    this.duration = 30,
    this.notes,
    this.reminders,
    this.isCompleted = false,
    this.isCancelled = false,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.metadata,
    this.isSynced = false,
    this.lastSynced,
    this.phoneNumber,
    this.address,
    this.preparationInstructions,
    this.transportArrangement,
  });

  bool get isUpcoming => 
      !isCompleted && !isCancelled && dateTime.isAfter(DateTime.now());

  bool get isPast => 
      dateTime.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year && 
           dateTime.month == tomorrow.month && 
           dateTime.day == tomorrow.day;
  }

  Duration get timeUntil => dateTime.difference(DateTime.now());

  String get displayDate {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String get displayTime {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  void markAsCancelled(String? reason) {
    isCancelled = true;
    cancelledAt = DateTime.now();
    cancellationReason = reason;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'appointmentType': appointmentType,
      'duration': duration,
      'notes': notes,
      'reminders': reminders,
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'metadata': metadata,
      'isSynced': isSynced,
      'lastSynced': lastSynced?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'address': address,
      'preparationInstructions': preparationInstructions,
      'transportArrangement': transportArrangement,
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'],
      doctorName: json['doctorName'],
      doctorSpecialty: json['doctorSpecialty'],
      appointmentType: json['appointmentType'],
      duration: json['duration'] ?? 30,
      notes: json['notes'],
      reminders: json['reminders'] != null 
          ? List<String>.from(json['reminders']) 
          : null,
      isCompleted: json['isCompleted'] ?? false,
      isCancelled: json['isCancelled'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      cancellationReason: json['cancellationReason'],
      metadata: json['metadata'],
      isSynced: json['isSynced'] ?? false,
      lastSynced: json['lastSynced'] != null 
          ? DateTime.parse(json['lastSynced']) 
          : null,
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      preparationInstructions: json['preparationInstructions'] != null 
          ? List<String>.from(json['preparationInstructions']) 
          : null,
      transportArrangement: json['transportArrangement'],
    );
  }
}