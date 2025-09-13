import 'package:hive/hive.dart';

part 'health_data_model.g.dart';

@HiveType(typeId: 1)
class HealthDataModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late DateTime recordedAt;

  @HiveField(3)
  double? bloodPressureSystolic;

  @HiveField(4)
  double? bloodPressureDiastolic;

  @HiveField(5)
  double? heartRate;

  @HiveField(6)
  double? bloodSugar;

  @HiveField(7)
  double? weight;

  @HiveField(8)
  double? temperature;

  @HiveField(9)
  int? steps;

  @HiveField(10)
  double? oxygenSaturation;

  @HiveField(11)
  Map<String, dynamic>? additionalData;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  bool isSynced = false;

  @HiveField(14)
  DateTime? lastSynced;

  @HiveField(15)
  String? source; // manual, device, import

  HealthDataModel({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.bloodSugar,
    this.weight,
    this.temperature,
    this.steps,
    this.oxygenSaturation,
    this.additionalData,
    this.notes,
    this.isSynced = false,
    this.lastSynced,
    this.source = 'manual',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recordedAt': recordedAt.toIso8601String(),
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'bloodSugar': bloodSugar,
      'weight': weight,
      'temperature': temperature,
      'steps': steps,
      'oxygenSaturation': oxygenSaturation,
      'additionalData': additionalData,
      'notes': notes,
      'isSynced': isSynced,
      'lastSynced': lastSynced?.toIso8601String(),
      'source': source,
    };
  }

  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    return HealthDataModel(
      id: json['id'],
      userId: json['userId'],
      recordedAt: DateTime.parse(json['recordedAt']),
      bloodPressureSystolic: json['bloodPressureSystolic']?.toDouble(),
      bloodPressureDiastolic: json['bloodPressureDiastolic']?.toDouble(),
      heartRate: json['heartRate']?.toDouble(),
      bloodSugar: json['bloodSugar']?.toDouble(),
      weight: json['weight']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      steps: json['steps'],
      oxygenSaturation: json['oxygenSaturation']?.toDouble(),
      additionalData: json['additionalData'],
      notes: json['notes'],
      isSynced: json['isSynced'] ?? false,
      lastSynced: json['lastSynced'] != null 
          ? DateTime.parse(json['lastSynced']) 
          : null,
      source: json['source'] ?? 'manual',
    );
  }

  bool get hasBloodPressure => 
      bloodPressureSystolic != null && bloodPressureDiastolic != null;

  bool get hasVitals => 
      heartRate != null || temperature != null || oxygenSaturation != null;

  String get displayDate => 
      '${recordedAt.day}/${recordedAt.month}/${recordedAt.year}';
}