import 'package:hive/hive.dart';

part 'medication_model.g.dart';

@HiveType(typeId: 2)
class MedicationModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String dosage;

  @HiveField(4)
  late List<String> times; // Times of day to take medication

  @HiveField(5)
  String? instructions;

  @HiveField(6)
  String? imageUrl;

  @HiveField(7)
  String? localImagePath;

  @HiveField(8)
  DateTime? startDate;

  @HiveField(9)
  DateTime? endDate;

  @HiveField(10)
  late bool isActive;

  @HiveField(11)
  List<String>? daysOfWeek; // For specific days only

  @HiveField(12)
  int? refillReminder; // Days before refill needed

  @HiveField(13)
  int? quantity;

  @HiveField(14)
  Map<String, bool>? todaysTaken; // time: taken status for today

  @HiveField(15)
  DateTime? lastTaken;

  @HiveField(16)
  DateTime? lastSynced;

  @HiveField(17)
  String? prescribedBy;

  @HiveField(18)
  String? pharmacy;

  @HiveField(19)
  List<DateTime>? missedDoses;

  @HiveField(20)
  Map<String, dynamic>? sideEffects;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.times,
    this.instructions,
    this.imageUrl,
    this.localImagePath,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.daysOfWeek,
    this.refillReminder,
    this.quantity,
    this.todaysTaken,
    this.lastTaken,
    this.lastSynced,
    this.prescribedBy,
    this.pharmacy,
    this.missedDoses,
    this.sideEffects,
  });

  bool shouldTakeToday() {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      final weekday = now.weekday;
      final dayName = _weekdayToString(weekday);
      return daysOfWeek!.contains(dayName);
    }
    
    return true;
  }

  String _weekdayToString(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  bool needsRefill() {
    if (quantity == null || refillReminder == null) return false;
    return quantity! <= refillReminder!;
  }

  void markTaken(String time) {
    todaysTaken ??= {};
    todaysTaken![time] = true;
    lastTaken = DateTime.now();
    if (quantity != null && quantity! > 0) {
      quantity = quantity! - 1;
    }
  }

  void markMissed(String time) {
    missedDoses ??= [];
    missedDoses!.add(DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'times': times,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'daysOfWeek': daysOfWeek,
      'refillReminder': refillReminder,
      'quantity': quantity,
      'todaysTaken': todaysTaken,
      'lastTaken': lastTaken?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'prescribedBy': prescribedBy,
      'pharmacy': pharmacy,
      'missedDoses': missedDoses?.map((d) => d.toIso8601String()).toList(),
      'sideEffects': sideEffects,
    };
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      dosage: json['dosage'],
      times: List<String>.from(json['times']),
      instructions: json['instructions'],
      imageUrl: json['imageUrl'],
      localImagePath: json['localImagePath'],
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      isActive: json['isActive'] ?? true,
      daysOfWeek: json['daysOfWeek'] != null 
          ? List<String>.from(json['daysOfWeek']) 
          : null,
      refillReminder: json['refillReminder'],
      quantity: json['quantity'],
      todaysTaken: json['todaysTaken'] != null 
          ? Map<String, bool>.from(json['todaysTaken']) 
          : null,
      lastTaken: json['lastTaken'] != null 
          ? DateTime.parse(json['lastTaken']) 
          : null,
      lastSynced: json['lastSynced'] != null 
          ? DateTime.parse(json['lastSynced']) 
          : null,
      prescribedBy: json['prescribedBy'],
      pharmacy: json['pharmacy'],
      missedDoses: json['missedDoses'] != null 
          ? (json['missedDoses'] as List).map((d) => DateTime.parse(d)).toList()
          : null,
      sideEffects: json['sideEffects'],
    );
  }
}