import 'package:flutter/material.dart';

enum AlertPriority { critical, high, medium, low }

enum AlertType {
  missedMedication,
  abnormalVitals,
  missedCheckIn,
  appointmentReminder,
  emergencyContact,
  fallDetection,
  locationAlert,
  batteryLow,
  systemUpdate,
}

class Alert {
  final String id;
  final String familyMemberId;
  final String familyMemberName;
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final bool isAcknowledged;
  final String? actionRequired;
  final Map<String, dynamic>? metadata;

  Alert({
    required this.id,
    required this.familyMemberId,
    required this.familyMemberName,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.isAcknowledged = false,
    this.actionRequired,
    this.metadata,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      familyMemberId: json['family_member_id'] as String,
      familyMemberName: json['family_member_name'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.systemUpdate,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => AlertPriority.low,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      actionRequired: json['action_required'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_member_id': familyMemberId,
      'family_member_name': familyMemberName,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_acknowledged': isAcknowledged,
      'action_required': actionRequired,
      'metadata': metadata,
    };
  }

  Color get priorityColor {
    switch (priority) {
      case AlertPriority.critical:
        return const Color(0xFFEF4444);
      case AlertPriority.high:
        return const Color(0xFFFC8C03);
      case AlertPriority.medium:
        return const Color(0xFFF59E0B);
      case AlertPriority.low:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.missedMedication:
        return Icons.medication;
      case AlertType.abnormalVitals:
        return Icons.monitor_heart;
      case AlertType.missedCheckIn:
        return Icons.schedule;
      case AlertType.appointmentReminder:
        return Icons.event;
      case AlertType.emergencyContact:
        return Icons.emergency;
      case AlertType.fallDetection:
        return Icons.elderly;
      case AlertType.locationAlert:
        return Icons.location_on;
      case AlertType.batteryLow:
        return Icons.battery_alert;
      case AlertType.systemUpdate:
        return Icons.system_update;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case AlertPriority.critical:
        return 'CRITICAL';
      case AlertPriority.high:
        return 'HIGH';
      case AlertPriority.medium:
        return 'MEDIUM';
      case AlertPriority.low:
        return 'LOW';
    }
  }
}