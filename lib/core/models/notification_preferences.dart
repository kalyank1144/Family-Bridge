class QuietHours {
  final int startHour;
  final int endHour;
  final bool enabled;
  const QuietHours({this.startHour = 22, this.endHour = 7, this.enabled = false});
  factory QuietHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QuietHours();
    return QuietHours(
      startHour: json['start_hour'] as int? ?? 22,
      endHour: json['end_hour'] as int? ?? 7,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
        'start_hour': startHour,
        'end_hour': endHour,
        'enabled': enabled,
      };
}

class NotificationPreferences {
  final bool chat;
  final bool alerts;
  final bool appointments;
  final bool checkins;
  final bool achievements;
  final bool emergencyBypass;
  final QuietHours quietHours;
  final String? customSound;
  const NotificationPreferences({
    this.chat = true,
    this.alerts = true,
    this.appointments = true,
    this.checkins = true,
    this.achievements = true,
    this.emergencyBypass = true,
    this.quietHours = const QuietHours(),
    this.customSound,
  });
  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPreferences();
    return NotificationPreferences(
      chat: json['chat'] as bool? ?? true,
      alerts: json['alerts'] as bool? ?? true,
      appointments: json['appointments'] as bool? ?? true,
      checkins: json['checkins'] as bool? ?? true,
      achievements: json['achievements'] as bool? ?? true,
      emergencyBypass: json['emergency_bypass'] as bool? ?? true,
      quietHours: QuietHours.fromJson(json['quiet_hours'] as Map<String, dynamic>?),
      customSound: json['custom_sound'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'chat': chat,
        'alerts': alerts,
        'appointments': appointments,
        'checkins': checkins,
        'achievements': achievements,
        'emergency_bypass': emergencyBypass,
        'quiet_hours': quietHours.toJson(),
        'custom_sound': customSound,
      };
}
