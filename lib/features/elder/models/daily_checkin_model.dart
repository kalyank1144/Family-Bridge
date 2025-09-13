class DailyCheckin {
  final String? id;
  final String elderId;
  final String mood;
  final String sleepQuality;
  final bool mealEaten;
  final bool medicationTaken;
  final bool physicalActivity;
  final int painLevel;
  final String? notes;
  final String? voiceNoteUrl;
  final DateTime createdAt;

  DailyCheckin({
    this.id,
    required this.elderId,
    required this.mood,
    required this.sleepQuality,
    required this.mealEaten,
    required this.medicationTaken,
    required this.physicalActivity,
    required this.painLevel,
    this.notes,
    this.voiceNoteUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      id: json['id'],
      elderId: json['elder_id'] ?? '',
      mood: json['mood'] ?? 'neutral',
      sleepQuality: json['sleep_quality'] ?? 'fair',
      mealEaten: json['meal_eaten'] ?? false,
      medicationTaken: json['medication_taken'] ?? false,
      physicalActivity: json['physical_activity'] ?? false,
      painLevel: json['pain_level'] ?? 0,
      notes: json['notes'],
      voiceNoteUrl: json['voice_note_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'elder_id': elderId,
      'mood': mood,
      'sleep_quality': sleepQuality,
      'meal_eaten': mealEaten,
      'medication_taken': medicationTaken,
      'physical_activity': physicalActivity,
      'pain_level': painLevel,
      'notes': notes,
      'voice_note_url': voiceNoteUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

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