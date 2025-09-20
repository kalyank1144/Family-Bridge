class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime nextDoseTime;
  final String? instructions;
  final String? photoUrl;
  final bool requiresPhotoConfirmation;
  final List<String> times;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDoseTime,
    this.instructions,
    this.photoUrl,
    this.requiresPhotoConfirmation = false,
    required this.times,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? 'daily',
      nextDoseTime: DateTime.parse(json['next_dose_time'] ?? DateTime.now().toIso8601String()),
      instructions: json['instructions'],
      photoUrl: json['photo_url'],
      requiresPhotoConfirmation: json['requires_photo_confirmation'] ?? false,
      times: List<String>.from(json['times'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'next_dose_time': nextDoseTime.toIso8601String(),
      'instructions': instructions,
      'photo_url': photoUrl,
      'requires_photo_confirmation': requiresPhotoConfirmation,
      'times': times,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DateTime calculateNextDose() {
    final now = DateTime.now();
    DateTime nextDose = nextDoseTime;
    
    switch (frequency.toLowerCase()) {
      case 'daily':
        nextDose = nextDoseTime.add(const Duration(days: 1));
        break;
      case 'twice daily':
        nextDose = nextDoseTime.add(const Duration(hours: 12));
        break;
      case 'three times daily':
        nextDose = nextDoseTime.add(const Duration(hours: 8));
        break;
      case 'four times daily':
        nextDose = nextDoseTime.add(const Duration(hours: 6));
        break;
      case 'weekly':
        nextDose = nextDoseTime.add(const Duration(days: 7));
        break;
      default:
        nextDose = nextDoseTime.add(const Duration(days: 1));
    }
    
    // If the calculated time is in the past, move to next scheduled time
    if (nextDose.isBefore(now)) {
      final today = DateTime(now.year, now.month, now.day);
      for (String time in times) {
        final parts = time.split(':');
        final scheduledTime = today.add(Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
        ));
        if (scheduledTime.isAfter(now)) {
          return scheduledTime;
        }
      }
      // If no time today, use first time tomorrow
      final tomorrow = today.add(const Duration(days: 1));
      final parts = times.first.split(':');
      return tomorrow.add(Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
      ));
    }
    
    return nextDose;
  }

  bool isDue() {
    return DateTime.now().isAfter(nextDoseTime.subtract(const Duration(minutes: 15)));
  }

  String getTimeUntilNext() {
    final difference = nextDoseTime.difference(DateTime.now());
    if (difference.isNegative) {
      return 'Overdue';
    }
    if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    }
    return 'In ${difference.inMinutes} minutes';
  }
}