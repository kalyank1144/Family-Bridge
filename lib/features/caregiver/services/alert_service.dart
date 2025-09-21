import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_model.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/logging_service.dart';

/// Service for managing caregiver alerts, notifications, and emergency escalation
/// Implements HIPAA-compliant alert handling with offline-first functionality
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  final LoggingService _logger = LoggingService();
  final Uuid _uuid = const Uuid();

  final StreamController<List<Alert>> _alertsController =
      StreamController<List<Alert>>.broadcast();
  final StreamController<Alert> _newAlertController =
      StreamController<Alert>.broadcast();

  // Cache for offline functionality
  final Map<String, Alert> _alertsCache = {};
  final List<Alert> _pendingAlerts = [];
  bool _isInitialized = false;

  /// Stream of all alerts for the current family
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  /// Stream of new alerts as they are created
  Stream<Alert> get newAlertStream => _newAlertController.stream;

  /// Initialize the alert service
  Future<void> initialize(String familyId) async {
    try {
      if (_isInitialized) return;

      await _loadAlertsFromCache(familyId);
      await _subscribeToRealtimeAlerts(familyId);
      await _processPendingAlerts();
      
      _isInitialized = true;
      _logger.info('AlertService initialized for family: $familyId');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AlertService: $e', stackTrace);
      throw AlertServiceException('Initialization failed: $e');
    }
  }

  /// Create a new alert
  Future<Alert> createAlert({
    required String familyId,
    String? userId,
    String? triggeredBy,
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionRequired,
  }) async {
    try {
      final alert = Alert(
        id: _uuid.v4(),
        familyId: familyId,
        userId: userId,
        triggeredBy: triggeredBy,
        type: type,
        severity: severity,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime.now(),
        actionRequired: actionRequired,
      );

      // Store in cache immediately
      _alertsCache[alert.id] = alert;
      
      try {
        // Attempt to save to database
        await _supabase.from('alerts').insert(alert.toJson());
        
        // Send notifications
        await _sendAlertNotifications(alert);
        
        _logger.info('Alert created: ${alert.id} - Type: ${alert.type}');
      } catch (e) {
        // If database save fails, add to pending queue
        _pendingAlerts.add(alert);
        _logger.warning('Alert saved to pending queue due to network error: $e');
      }

      // Update streams
      _newAlertController.add(alert);
      await _refreshAlertsList(familyId);

      return alert;
    } catch (e, stackTrace) {
      _logger.error('Failed to create alert: $e', stackTrace);
      throw AlertServiceException('Failed to create alert: $e');
    }
  }

  /// Get all active alerts for a family
  Future<List<Alert>> getAlerts({
    required String familyId,
    AlertStatus? status,
    AlertSeverity? severity,
    AlertType? type,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('alerts')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }
      if (severity != null) {
        query = query.eq('severity', severity.toString().split('.').last);
      }
      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      final response = await query;
      final alerts = (response as List)
          .map((json) => Alert.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      for (final alert in alerts) {
        _alertsCache[alert.id] = alert;
      }

      return alerts;
    } catch (e) {
      _logger.warning('Failed to fetch alerts from database, using cache: $e');
      
      // Return cached alerts as fallback
      return _alertsCache.values
          .where((alert) => alert.familyId == familyId)
          .where((alert) => status == null || alert.status == status)
          .where((alert) => severity == null || alert.severity == severity)
          .where((alert) => type == null || alert.type == type)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId, String acknowledgedBy) async {
    try {
      final alert = _alertsCache[alertId];
      if (alert == null) {
        throw AlertServiceException('Alert not found: $alertId');
      }

      final updatedAlert = alert.copyWith(
        acknowledgedAt: DateTime.now(),
        acknowledgedBy: acknowledgedBy,
        status: AlertStatus.acknowledged,
      );

      _alertsCache[alertId] = updatedAlert;

      try {
        await _supabase.from('alerts').update({
          'acknowledged_at': updatedAlert.acknowledgedAt!.toIso8601String(),
          'acknowledged_by': acknowledgedBy,
          'status': 'acknowledged',
        }).eq('id', alertId);
      } catch (e) {
        _logger.warning('Failed to update alert acknowledgment in database: $e');
      }

      await _refreshAlertsList(alert.familyId);
      _logger.info('Alert acknowledged: $alertId by $acknowledgedBy');
    } catch (e, stackTrace) {
      _logger.error('Failed to acknowledge alert: $e', stackTrace);
      throw AlertServiceException('Failed to acknowledge alert: $e');
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId, String resolvedBy, [String? resolution]) async {
    try {
      final alert = _alertsCache[alertId];
      if (alert == null) {
        throw AlertServiceException('Alert not found: $alertId');
      }

      final updatedData = Map<String, dynamic>.from(alert.data ?? {});
      if (resolution != null) {
        updatedData['resolution'] = resolution;
      }

      final updatedAlert = alert.copyWith(
        resolvedAt: DateTime.now(),
        resolvedBy: resolvedBy,
        status: AlertStatus.resolved,
        data: updatedData,
      );

      _alertsCache[alertId] = updatedAlert;

      try {
        await _supabase.from('alerts').update({
          'resolved_at': updatedAlert.resolvedAt!.toIso8601String(),
          'resolved_by': resolvedBy,
          'status': 'resolved',
          'data': updatedData,
        }).eq('id', alertId);
      } catch (e) {
        _logger.warning('Failed to update alert resolution in database: $e');
      }

      await _refreshAlertsList(alert.familyId);
      _logger.info('Alert resolved: $alertId by $resolvedBy');
    } catch (e, stackTrace) {
      _logger.error('Failed to resolve alert: $e', stackTrace);
      throw AlertServiceException('Failed to resolve alert: $e');
    }
  }

  /// Check for alerts that need escalation
  Future<void> processEscalations(String familyId) async {
    try {
      final alerts = await getAlerts(familyId: familyId, status: AlertStatus.active);
      
      for (final alert in alerts) {
        if (alert.needsEscalation && alert.escalationLevel < 3) {
          await _escalateAlert(alert);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to process alert escalations: $e', stackTrace);
    }
  }

  /// Create medication-related alerts
  Future<Alert> createMedicationAlert({
    required String familyId,
    required String userId,
    required String medicationId,
    required AlertType type,
    required String medicationName,
    String? notes,
  }) async {
    final title = switch (type) {
      AlertType.medicationMissed => 'Medication Missed',
      AlertType.medicationOverdue => 'Medication Overdue',
      _ => 'Medication Alert',
    };

    final message = switch (type) {
      AlertType.medicationMissed => 'Missed dose of $medicationName',
      AlertType.medicationOverdue => '$medicationName is overdue',
      _ => 'Alert for medication: $medicationName',
    };

    return createAlert(
      familyId: familyId,
      userId: userId,
      type: type,
      severity: AlertSeverity.medium,
      title: title,
      message: message,
      data: {
        'medication_id': medicationId,
        'medication_name': medicationName,
        'notes': notes,
      },
      actionRequired: 'Check on medication compliance',
    );
  }

  /// Create health concern alert
  Future<Alert> createHealthConcernAlert({
    required String familyId,
    required String userId,
    required String concern,
    required AlertSeverity severity,
    Map<String, dynamic>? healthData,
  }) async {
    return createAlert(
      familyId: familyId,
      userId: userId,
      type: AlertType.healthConcern,
      severity: severity,
      title: 'Health Concern Detected',
      message: concern,
      data: healthData,
      actionRequired: severity == AlertSeverity.critical 
          ? 'Immediate medical attention may be required'
          : 'Monitor health status closely',
    );
  }

  /// Create emergency contact alert
  Future<Alert> createEmergencyAlert({
    required String familyId,
    required String userId,
    required String emergencyType,
    String? location,
    Map<String, dynamic>? emergencyData,
  }) async {
    return createAlert(
      familyId: familyId,
      userId: userId,
      type: AlertType.emergencyContact,
      severity: AlertSeverity.critical,
      title: 'Emergency Alert',
      message: emergencyType,
      data: {
        'location': location,
        'emergency_type': emergencyType,
        ...?emergencyData,
      },
      actionRequired: 'Respond immediately to emergency situation',
    );
  }

  /// Get alert statistics for dashboard
  Future<Map<String, int>> getAlertStatistics(String familyId) async {
    try {
      final alerts = await getAlerts(familyId: familyId);
      
      final stats = <String, int>{
        'total': alerts.length,
        'active': 0,
        'acknowledged': 0,
        'resolved': 0,
        'critical': 0,
        'high': 0,
        'medium': 0,
        'low': 0,
      };

      for (final alert in alerts) {
        switch (alert.status) {
          case AlertStatus.active:
            stats['active'] = (stats['active'] ?? 0) + 1;
            break;
          case AlertStatus.acknowledged:
            stats['acknowledged'] = (stats['acknowledged'] ?? 0) + 1;
            break;
          case AlertStatus.resolved:
            stats['resolved'] = (stats['resolved'] ?? 0) + 1;
            break;
          default:
            break;
        }

        switch (alert.severity) {
          case AlertSeverity.critical:
            stats['critical'] = (stats['critical'] ?? 0) + 1;
            break;
          case AlertSeverity.high:
            stats['high'] = (stats['high'] ?? 0) + 1;
            break;
          case AlertSeverity.medium:
            stats['medium'] = (stats['medium'] ?? 0) + 1;
            break;
          case AlertSeverity.low:
            stats['low'] = (stats['low'] ?? 0) + 1;
            break;
          default:
            break;
        }
      }

      return stats;
    } catch (e, stackTrace) {
      _logger.error('Failed to get alert statistics: $e', stackTrace);
      return {'total': 0};
    }
  }

  // Private helper methods

  Future<void> _loadAlertsFromCache(String familyId) async {
    // In a real implementation, this would load from local storage
    // For now, we'll start with an empty cache
  }

  Future<void> _subscribeToRealtimeAlerts(String familyId) async {
    try {
      _supabase
          .from('alerts')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .listen((data) {
            final alerts = data
                .map((json) => Alert.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Update cache
            for (final alert in alerts) {
              _alertsCache[alert.id] = alert;
            }
            
            _alertsController.add(alerts);
          });
    } catch (e) {
      _logger.warning('Failed to subscribe to realtime alerts: $e');
    }
  }

  Future<void> _processPendingAlerts() async {
    final pendingCopy = List<Alert>.from(_pendingAlerts);
    _pendingAlerts.clear();

    for (final alert in pendingCopy) {
      try {
        await _supabase.from('alerts').insert(alert.toJson());
        await _sendAlertNotifications(alert);
        _logger.info('Processed pending alert: ${alert.id}');
      } catch (e) {
        // Re-add to pending if still failing
        _pendingAlerts.add(alert);
        _logger.warning('Failed to process pending alert: ${alert.id} - $e');
      }
    }
  }

  Future<void> _sendAlertNotifications(Alert alert) async {
    try {
      // Get family members to notify
      final recipients = await _getFamilyMembers(alert.familyId);
      
      for (final recipient in recipients) {
        await _notificationService.sendPushNotification(
          userId: recipient.userId,
          title: alert.title,
          message: alert.message,
          data: {
            'alert_id': alert.id,
            'alert_type': alert.type.toString(),
            'severity': alert.severity.toString(),
          },
        );
      }

      // Update notified users list
      final updatedAlert = alert.copyWith(
        notifiedUsers: recipients.map((r) => r.userId).toList(),
      );
      _alertsCache[alert.id] = updatedAlert;

    } catch (e) {
      _logger.warning('Failed to send alert notifications: $e');
    }
  }

  Future<void> _escalateAlert(Alert alert) async {
    try {
      final escalatedAlert = alert.copyWith(
        escalationLevel: alert.escalationLevel + 1,
        lastEscalatedAt: DateTime.now(),
      );

      _alertsCache[alert.id] = escalatedAlert;

      await _supabase.from('alerts').update({
        'escalation_level': escalatedAlert.escalationLevel,
        'last_escalated_at': escalatedAlert.lastEscalatedAt!.toIso8601String(),
      }).eq('id', alert.id);

      // Send escalation notifications
      await _sendEscalationNotifications(escalatedAlert);
      
      _logger.info('Alert escalated: ${alert.id} to level ${escalatedAlert.escalationLevel}');
    } catch (e) {
      _logger.error('Failed to escalate alert: ${alert.id} - $e');
    }
  }

  Future<void> _sendEscalationNotifications(Alert alert) async {
    // Send escalated notifications to additional recipients
    // This would include emergency contacts or healthcare providers
  }

  Future<List<FamilyMember>> _getFamilyMembers(String familyId) async {
    try {
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true);

      return (response as List)
          .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.warning('Failed to get family members for notifications: $e');
      return [];
    }
  }

  Future<void> _refreshAlertsList(String familyId) async {
    try {
      final alerts = _alertsCache.values
          .where((alert) => alert.familyId == familyId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _alertsController.add(alerts);
    } catch (e) {
      _logger.error('Failed to refresh alerts list: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _alertsController.close();
    _newAlertController.close();
  }
}

/// Custom exception for alert service errors
class AlertServiceException implements Exception {
  final String message;
  AlertServiceException(this.message);
  
  @override
  String toString() => 'AlertServiceException: $message';
}

// Import statements for models that need to be created
class FamilyMember {
  final String userId;
  const FamilyMember({required this.userId});
  
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(userId: json['user_id'] as String);
  }
}