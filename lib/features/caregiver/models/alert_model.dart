import 'package:hive/hive.dart';

part 'alert_model.g.dart';

@HiveType(typeId: 30)
class Alert extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyId;

  @HiveField(2)
  String? userId;

  @HiveField(3)
  String? triggeredBy;

  @HiveField(4)
  AlertType type;

  @HiveField(5)
  AlertSeverity severity;

  @HiveField(6)
  String title;

  @HiveField(7)
  String message;

  @HiveField(8)
  Map<String, dynamic>? data;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? acknowledgedAt;

  @HiveField(11)
  String? acknowledgedBy;

  @HiveField(12)
  DateTime? resolvedAt;

  @HiveField(13)
  String? resolvedBy;

  @HiveField(14)
  AlertStatus status;

  @HiveField(15)
  List<String> notifiedUsers;

  @HiveField(16)
  int escalationLevel;

  @HiveField(17)
  DateTime? lastEscalatedAt;

  @HiveField(18)
  String? actionRequired;

  Alert({
    required this.id,
    required this.familyId,
    this.userId,
    this.triggeredBy,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.status = AlertStatus.active,
    this.notifiedUsers = const [],
    this.escalationLevel = 0,
    this.lastEscalatedAt,
    this.actionRequired,
  });

  bool get isActive => status == AlertStatus.active;
  bool get isAcknowledged => acknowledgedAt != null;
  bool get isResolved => status == AlertStatus.resolved;
  bool get isExpired => status == AlertStatus.expired;

  Duration get ageOfAlert => DateTime.now().difference(createdAt);

  bool get needsEscalation {
    if (isResolved || severity == AlertSeverity.info) return false;
    
    final escalationThreshold = switch (severity) {
      AlertSeverity.critical => const Duration(minutes: 5),
      AlertSeverity.high => const Duration(minutes: 15),
      AlertSeverity.medium => const Duration(hours: 1),
      AlertSeverity.low => const Duration(hours: 4),
      AlertSeverity.info => const Duration(days: 1),
    };
    
    final timeSinceLastEscalation = lastEscalatedAt != null 
        ? DateTime.now().difference(lastEscalatedAt!)
        : ageOfAlert;
        
    return timeSinceLastEscalation > escalationThreshold;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'triggered_by': triggeredBy,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'status': status.toString().split('.').last,
      'notified_users': notifiedUsers,
      'escalation_level': escalationLevel,
      'last_escalated_at': lastEscalatedAt?.toIso8601String(),
      'action_required': actionRequired,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String?,
      triggeredBy: json['triggered_by'] as String?,
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.general,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      status: AlertStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AlertStatus.active,
      ),
      notifiedUsers: List<String>.from(json['notified_users'] ?? []),
      escalationLevel: json['escalation_level'] as int? ?? 0,
      lastEscalatedAt: json['last_escalated_at'] != null
          ? DateTime.parse(json['last_escalated_at'] as String)
          : null,
      actionRequired: json['action_required'] as String?,
    );
  }

  Alert copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? triggeredBy,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    AlertStatus? status,
    List<String>? notifiedUsers,
    int? escalationLevel,
    DateTime? lastEscalatedAt,
    String? actionRequired,
  }) {
    return Alert(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      status: status ?? this.status,
      notifiedUsers: notifiedUsers ?? this.notifiedUsers,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      lastEscalatedAt: lastEscalatedAt ?? this.lastEscalatedAt,
      actionRequired: actionRequired ?? this.actionRequired,
    );
  }
}

@HiveType(typeId: 31)
enum AlertType {
  @HiveField(0)
  medicationMissed,
  
  @HiveField(1)
  medicationOverdue,
  
  @HiveField(2)
  emergencyContact,
  
  @HiveField(3)
  healthConcern,
  
  @HiveField(4)
  dailyCheckInMissed,
  
  @HiveField(5)
  inactivity,
  
  @HiveField(6)
  fallDetection,
  
  @HiveField(7)
  vitalsAbnormal,
  
  @HiveField(8)
  appointmentReminder,
  
  @HiveField(9)
  appointmentMissed,
  
  @HiveField(10)
  batteryLow,
  
  @HiveField(11)
  deviceOffline,
  
  @HiveField(12)
  geofenceViolation,
  
  @HiveField(13)
  socialIsolation,
  
  @HiveField(14)
  moodConcern,
  
  @HiveField(15)
  general,
}

@HiveType(typeId: 32)
enum AlertSeverity {
  @HiveField(0)
  critical,
  
  @HiveField(1)
  high,
  
  @HiveField(2)
  medium,
  
  @HiveField(3)
  low,
  
  @HiveField(4)
  info,
}

@HiveType(typeId: 33)
enum AlertStatus {
  @HiveField(0)
  active,
  
  @HiveField(1)
  acknowledged,
  
  @HiveField(2)
  resolved,
  
  @HiveField(3)
  expired,
  
  @HiveField(4)
  suppressed,
}

@HiveType(typeId: 34)
class AlertRule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyId;

  @HiveField(2)
  String? userId;

  @HiveField(3)
  AlertType alertType;

  @HiveField(4)
  Map<String, dynamic> conditions;

  @HiveField(5)
  AlertSeverity severity;

  @HiveField(6)
  bool isEnabled;

  @HiveField(7)
  List<String> notificationRecipients;

  @HiveField(8)
  Duration? escalationDelay;

  @HiveField(9)
  int maxEscalations;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  AlertRule({
    required this.id,
    required this.familyId,
    this.userId,
    required this.alertType,
    required this.conditions,
    required this.severity,
    this.isEnabled = true,
    this.notificationRecipients = const [],
    this.escalationDelay,
    this.maxEscalations = 3,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'alert_type': alertType.toString().split('.').last,
      'conditions': conditions,
      'severity': severity.toString().split('.').last,
      'is_enabled': isEnabled,
      'notification_recipients': notificationRecipients,
      'escalation_delay': escalationDelay?.inMinutes,
      'max_escalations': maxEscalations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String?,
      alertType: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['alert_type'],
        orElse: () => AlertType.general,
      ),
      conditions: json['conditions'] as Map<String, dynamic>,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      isEnabled: json['is_enabled'] as bool? ?? true,
      notificationRecipients: List<String>.from(json['notification_recipients'] ?? []),
      escalationDelay: json['escalation_delay'] != null
          ? Duration(minutes: json['escalation_delay'] as int)
          : null,
      maxEscalations: json['max_escalations'] as int? ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}