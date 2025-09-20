class HealthData {
  final DateTime timestamp;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? heartRate;
  final double? temperature;
  final double? oxygenLevel;
  final double? bloodSugar;
  final int? steps;
  final double? weight;
  final String? mood;
  final int? moodScore;
  final bool? medicationTaken;
  final String? notes;

  HealthData({
    required this.timestamp,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperature,
    this.oxygenLevel,
    this.bloodSugar,
    this.steps,
    this.weight,
    this.mood,
    this.moodScore,
    this.medicationTaken,
    this.notes,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      bloodPressureSystolic: (json['blood_pressure_systolic'] as num?)?.toDouble(),
      bloodPressureDiastolic: (json['blood_pressure_diastolic'] as num?)?.toDouble(),
      heartRate: (json['heart_rate'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      oxygenLevel: (json['oxygen_level'] as num?)?.toDouble(),
      bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
      steps: json['steps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      mood: json['mood'] as String?,
      moodScore: json['mood_score'] as int?,
      medicationTaken: json['medication_taken'] as bool?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'heart_rate': heartRate,
      'temperature': temperature,
      'oxygen_level': oxygenLevel,
      'blood_sugar': bloodSugar,
      'steps': steps,
      'weight': weight,
      'mood': mood,
      'mood_score': moodScore,
      'medication_taken': medicationTaken,
      'notes': notes,
    };
  }

  String get bloodPressureFormatted {
    if (bloodPressureSystolic != null && bloodPressureDiastolic != null) {
      return '${bloodPressureSystolic!.toInt()}/${bloodPressureDiastolic!.toInt()}';
    }
    return '--/--';
  }

  bool get isBloodPressureNormal {
    if (bloodPressureSystolic == null || bloodPressureDiastolic == null) {
      return true;
    }
    return bloodPressureSystolic! < 130 && bloodPressureDiastolic! < 80;
  }

  bool get isHeartRateNormal {
    if (heartRate == null) return true;
    return heartRate! >= 60 && heartRate! <= 100;
  }

  bool get isOxygenLevelNormal {
    if (oxygenLevel == null) return true;
    return oxygenLevel! >= 95;
  }

  bool get isTemperatureNormal {
    if (temperature == null) return true;
    return temperature! >= 97.0 && temperature! <= 99.0;
  }

  bool get isBloodSugarNormal {
    if (bloodSugar == null) return true;
    return bloodSugar! >= 70 && bloodSugar! <= 140;
  }
}

class MedicationRecord {
  final String id;
  final String name;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool isTaken;
  final String? notes;

  MedicationRecord({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduledTime,
    this.takenTime,
    this.isTaken = false,
    this.notes,
  });

  factory MedicationRecord.fromJson(Map<String, dynamic> json) {
    return MedicationRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      takenTime: json['taken_time'] != null 
          ? DateTime.parse(json['taken_time'] as String) 
          : null,
      isTaken: json['is_taken'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'is_taken': isTaken,
      'notes': notes,
    };
  }
}