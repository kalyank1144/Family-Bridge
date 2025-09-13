import 'package:flutter/material.dart';

enum HealthStatus { normal, warning, critical }

enum MemberType { elder, youth, caregiver }

class FamilyMember {
  final String id;
  final String name;
  final String? profileImageUrl;
  final MemberType type;
  final bool isOnline;
  final DateTime lastActivity;
  final HealthStatus healthStatus;
  final String? currentLocation;
  final List<String> activeAlerts;
  final Map<String, dynamic> vitals;
  final double medicationCompliance;
  final String? moodStatus;
  final bool hasCompletedDailyCheckIn;

  FamilyMember({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.type,
    required this.isOnline,
    required this.lastActivity,
    required this.healthStatus,
    this.currentLocation,
    this.activeAlerts = const [],
    this.vitals = const {},
    this.medicationCompliance = 1.0,
    this.moodStatus,
    this.hasCompletedDailyCheckIn = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      type: MemberType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MemberType.elder,
      ),
      isOnline: json['is_online'] as bool? ?? false,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      healthStatus: HealthStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['health_status'],
        orElse: () => HealthStatus.normal,
      ),
      currentLocation: json['current_location'] as String?,
      activeAlerts: List<String>.from(json['active_alerts'] ?? []),
      vitals: json['vitals'] as Map<String, dynamic>? ?? {},
      medicationCompliance: (json['medication_compliance'] as num?)?.toDouble() ?? 1.0,
      moodStatus: json['mood_status'] as String?,
      hasCompletedDailyCheckIn: json['has_completed_daily_check_in'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image_url': profileImageUrl,
      'type': type.toString().split('.').last,
      'is_online': isOnline,
      'last_activity': lastActivity.toIso8601String(),
      'health_status': healthStatus.toString().split('.').last,
      'current_location': currentLocation,
      'active_alerts': activeAlerts,
      'vitals': vitals,
      'medication_compliance': medicationCompliance,
      'mood_status': moodStatus,
      'has_completed_daily_check_in': hasCompletedDailyCheckIn,
    };
  }

  Color get statusColor {
    switch (healthStatus) {
      case HealthStatus.normal:
        return const Color(0xFF10B981);
      case HealthStatus.warning:
        return const Color(0xFFF59E0B);
      case HealthStatus.critical:
        return const Color(0xFFEF4444);
    }
  }

  IconData get statusIcon {
    switch (healthStatus) {
      case HealthStatus.normal:
        return Icons.check_circle;
      case HealthStatus.warning:
        return Icons.warning;
      case HealthStatus.critical:
        return Icons.error;
    }
  }

  String get lastActivityFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}