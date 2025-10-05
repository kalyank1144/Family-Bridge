import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';

enum AuditEventType {
  // PHI Access Events
  phiAccess,
  phiView,
  phiExport,
  phiPrint,
  phiModification,
  phiDeletion,
  
  // Authentication Events
  login,
  logout,
  loginFailed,
  passwordChange,
  mfaEnabled,
  mfaDisabled,
  
  // System Events
  systemAccess,
  privilegeEscalation,
  configurationChange,
  securityAlert,
  
  // Data Events
  dataBackup,
  dataRestore,
  encryptionKeyAccess,
  
  // Compliance Events
  auditLogAccess,
  complianceReportGenerated,
  breachDetected,
  incidentResponse
}

enum AuditSeverity { low, medium, high, critical }

class AuditEvent {
  final String id;
  final DateTime timestamp;
  final AuditEventType eventType;
  final AuditSeverity severity;
  final String userId;
  final String? userRole;
  final String? ipAddress;
  final String? deviceId;
  final String? sessionId;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? phiIdentifier; // For PHI-related events
  final String? affectedResource;
  final bool success;
  final String? failureReason;
  final String checksum; // For integrity verification

  AuditEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.userId,
    this.userRole,
    this.ipAddress,
    this.deviceId,
    this.sessionId,
    required this.description,
    this.metadata,
    this.phiIdentifier,
    this.affectedResource,
    this.success = true,
    this.failureReason,
    required this.checksum,
  });

  factory AuditEvent.create({
    required AuditEventType eventType,
    required String userId,
    required String description,
    AuditSeverity? severity,
    String? userRole,
    String? ipAddress,
    String? deviceId,
    String? sessionId,
    Map<String, dynamic>? metadata,
    String? phiIdentifier,
    String? affectedResource,
    bool? success,
    String? failureReason,
  }) {
    final id = _generateId();
    final timestamp = DateTime.now().toUtc();
    final eventSeverity = severity ?? _getDefaultSeverity(eventType);
    
    final checksum = _generateChecksum(
      id: id,
      timestamp: timestamp,
      eventType: eventType,
      userId: userId,
      description: description,
    );

    return AuditEvent(
      id: id,
      timestamp: timestamp,
      eventType: eventType,
      severity: eventSeverity,
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      deviceId: deviceId,
      sessionId: sessionId,
      description: description,
      metadata: metadata,
      phiIdentifier: phiIdentifier,
      affectedResource: affectedResource,
      success: success ?? true,
      failureReason: failureReason,
      checksum: checksum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'userId': userId,
      'userRole': userRole,
      'ipAddress': ipAddress,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'description': description,
      'metadata': metadata,
      'phiIdentifier': phiIdentifier,
      'affectedResource': affectedResource,
      'success': success,
      'failureReason': failureReason,
      'checksum': checksum,
    };
  }

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      eventType: AuditEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['eventType'],
        orElse: () => AuditEventType.systemAccess,
      ),
      severity: AuditSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AuditSeverity.medium,
      ),
      userId: json['userId'],
      userRole: json['userRole'],
      ipAddress: json['ipAddress'],
      deviceId: json['deviceId'],
      sessionId: json['sessionId'],
      description: json['description'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      phiIdentifier: json['phiIdentifier'],
      affectedResource: json['affectedResource'],
      success: json['success'] ?? true,
      failureReason: json['failureReason'],
      checksum: json['checksum'],
    );
  }

  bool verifyIntegrity() {
    final expectedChecksum = _generateChecksum(
      id: id,
      timestamp: timestamp,
      eventType: eventType,
      userId: userId,
      description: description,
    );
    return checksum == expectedChecksum;
  }

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString() + 
           (1000 + (DateTime.now().millisecond % 9000)).toString();
  }

  static AuditSeverity _getDefaultSeverity(AuditEventType eventType) {
    switch (eventType) {
      case AuditEventType.phiAccess:
      case AuditEventType.phiView:
        return AuditSeverity.medium;
      case AuditEventType.phiExport:
      case AuditEventType.phiPrint:
      case AuditEventType.phiModification:
      case AuditEventType.phiDeletion:
        return AuditSeverity.high;
      case AuditEventType.loginFailed:
      case AuditEventType.privilegeEscalation:
      case AuditEventType.securityAlert:
      case AuditEventType.breachDetected:
        return AuditSeverity.critical;
      case AuditEventType.encryptionKeyAccess:
        return AuditSeverity.critical;
      default:
        return AuditSeverity.medium;
    }
  }

  static String _generateChecksum({
    required String id,
    required DateTime timestamp,
    required AuditEventType eventType,
    required String userId,
    required String description,
  }) {
    final content = '$id${timestamp.toIso8601String()}${eventType.toString()}$userId$description';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class HipaaAuditService {
  static final HipaaAuditService _instance = HipaaAuditService._internal();
  static HipaaAuditService get instance => _instance;
  HipaaAuditService._internal();

  final List<AuditEvent> _localBuffer = [];
  final int _maxBufferSize = 1000;
  String? _currentUserId;
  String? _currentUserRole;
  String? _currentSessionId;
  String? _deviceId;

  // Initialize the audit service
  Future<void> initialize({
    required String userId,
    required String userRole,
    required String sessionId,
    String? deviceId,
  }) async {
    _currentUserId = userId;
    _currentUserRole = userRole;
    _currentSessionId = sessionId;
    _deviceId = deviceId ?? await _getDeviceId();
    
    await logEvent(
      eventType: AuditEventType.systemAccess,
      description: 'HIPAA audit service initialized',
      metadata: {'service': 'HipaaAuditService', 'version': '1.0.0'},
    );
  }

  // Log an audit event
  Future<void> logEvent({
    required AuditEventType eventType,
    required String description,
    AuditSeverity? severity,
    String? userId,
    String? userRole,
    String? sessionId,
    Map<String, dynamic>? metadata,
    String? phiIdentifier,
    String? affectedResource,
    bool? success,
    String? failureReason,
  }) async {
    try {
      final event = AuditEvent.create(
        eventType: eventType,
        userId: userId ?? _currentUserId ?? 'unknown',
        userRole: userRole ?? _currentUserRole,
        sessionId: sessionId ?? _currentSessionId,
        description: description,
        severity: severity,
        ipAddress: await _getIpAddress(),
        deviceId: _deviceId,
        metadata: metadata,
        phiIdentifier: phiIdentifier,
        affectedResource: affectedResource,
        success: success,
        failureReason: failureReason,
      );

      _localBuffer.add(event);
      
      // Manage buffer size
      if (_localBuffer.length > _maxBufferSize) {
        await _flushBuffer();
      }

      // Critical events are immediately persisted
      if (event.severity == AuditSeverity.critical) {
        await _persistEvent(event);
        await _triggerSecurityAlert(event);
      }

      // Debug logging for development
      if (kDebugMode) {
        print('HIPAA Audit: ${event.eventType} - ${event.description}');
      }
    } catch (e) {
      // Audit logging should never fail silently
      debugPrint('CRITICAL: Audit logging failed - $e');
      await _logAuditFailure(e.toString());
    }
  }

  // Log PHI access events
  Future<void> logPhiAccess({
    required String phiIdentifier,
    required String accessType,
    required String resourcePath,
    Map<String, dynamic>? context,
  }) async {
    await logEvent(
      eventType: AuditEventType.phiAccess,
      description: 'PHI accessed: $accessType',
      severity: AuditSeverity.high,
      phiIdentifier: phiIdentifier,
      affectedResource: resourcePath,
      metadata: {
        'accessType': accessType,
        'resourcePath': resourcePath,
        ...?context,
      },
    );
  }

  // Log authentication events
  Future<void> logAuthenticationEvent({
    required AuditEventType eventType,
    required String userId,
    bool success = true,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      eventType: eventType,
      userId: userId,
      description: _getAuthEventDescription(eventType, success),
      success: success,
      failureReason: failureReason,
      metadata: metadata,
    );
  }

  // Get audit events for reporting
  Future<List<AuditEvent>> getAuditEvents({
    DateTime? startDate,
    DateTime? endDate,
    List<AuditEventType>? eventTypes,
    List<AuditSeverity>? severities,
    String? userId,
    String? phiIdentifier,
    int? limit,
  }) async {
    await _flushBuffer(); // Ensure all buffered events are included
    
    var events = List<AuditEvent>.from(_localBuffer);
    
    // Apply filters
    if (startDate != null) {
      events = events.where((e) => e.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      events = events.where((e) => e.timestamp.isBefore(endDate)).toList();
    }
    if (eventTypes != null) {
      events = events.where((e) => eventTypes.contains(e.eventType)).toList();
    }
    if (severities != null) {
      events = events.where((e) => severities.contains(e.severity)).toList();
    }
    if (userId != null) {
      events = events.where((e) => e.userId == userId).toList();
    }
    if (phiIdentifier != null) {
      events = events.where((e) => e.phiIdentifier == phiIdentifier).toList();
    }

    // Sort by timestamp (newest first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  // Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final events = await getAuditEvents(startDate: start, endDate: end);
    
    final phiAccessCount = events.where((e) => 
        e.eventType == AuditEventType.phiAccess ||
        e.eventType == AuditEventType.phiView).length;
    
    final failedLogins = events.where((e) => 
        e.eventType == AuditEventType.loginFailed).length;
    
    final criticalEvents = events.where((e) => 
        e.severity == AuditSeverity.critical).length;
    
    final uniqueUsers = events.map((e) => e.userId).toSet().length;
    
    return {
      'reportPeriod': {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
      'summary': {
        'totalEvents': events.length,
        'phiAccessEvents': phiAccessCount,
        'failedLogins': failedLogins,
        'criticalEvents': criticalEvents,
        'uniqueUsers': uniqueUsers,
      },
      'eventsByType': _groupEventsByType(events),
      'eventsBySeverity': _groupEventsBySeverity(events),
      'riskAssessment': _assessRisk(events),
      'integrityCheck': await _verifyLogIntegrity(events),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Verify audit log integrity
  Future<Map<String, dynamic>> _verifyLogIntegrity(List<AuditEvent> events) async {
    int validEvents = 0;
    int invalidEvents = 0;
    final List<String> corruptedEventIds = [];

    for (final event in events) {
      if (event.verifyIntegrity()) {
        validEvents++;
      } else {
        invalidEvents++;
        corruptedEventIds.add(event.id);
      }
    }

    return {
      'totalEvents': events.length,
      'validEvents': validEvents,
      'invalidEvents': invalidEvents,
      'corruptedEventIds': corruptedEventIds,
      'integrityPercentage': events.isEmpty ? 100.0 : (validEvents / events.length) * 100,
    };
  }

  // Private helper methods
  Future<void> _flushBuffer() async {
    if (_localBuffer.isNotEmpty) {
      // In a real implementation, this would save to secure storage/database
      final events = List<AuditEvent>.from(_localBuffer);
      _localBuffer.clear();
      
      for (final event in events) {
        await _persistEvent(event);
      }
    }
  }

  Future<void> _persistEvent(AuditEvent event) async {
    // In production, this would save to encrypted database or secure log storage
    // For now, we'll simulate persistence
    debugPrint('Persisting audit event: ${event.id}');
  }

  Future<void> _triggerSecurityAlert(AuditEvent event) async {
    // Trigger immediate security alerts for critical events
    debugPrint('SECURITY ALERT: ${event.description}');
    // In production: notify security team, escalate to incident response
  }

  Future<void> _logAuditFailure(String error) async {
    // Log audit system failures to a separate, highly available system
    debugPrint('AUDIT SYSTEM FAILURE: $error');
  }

  Future<String> _getIpAddress() async {
    try {
      // In a real app, get actual IP address
      return '127.0.0.1';
    } catch (e) {
      return 'unknown';
    }
  }

  Future<String> _getDeviceId() async {
    try {
      // Get device identifier - in production use device_info_plus
      return Platform.operatingSystem;
    } catch (e) {
      return 'unknown';
    }
  }

  String _getAuthEventDescription(AuditEventType eventType, bool success) {
    switch (eventType) {
      case AuditEventType.login:
        return success ? 'User login successful' : 'User login failed';
      case AuditEventType.logout:
        return 'User logout';
      case AuditEventType.loginFailed:
        return 'Failed login attempt';
      case AuditEventType.passwordChange:
        return 'Password changed';
      case AuditEventType.mfaEnabled:
        return 'Multi-factor authentication enabled';
      case AuditEventType.mfaDisabled:
        return 'Multi-factor authentication disabled';
      default:
        return 'Authentication event';
    }
  }

  Map<String, int> _groupEventsByType(List<AuditEvent> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      final type = event.eventType.toString().split('.').last;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, int> _groupEventsBySeverity(List<AuditEvent> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      final severity = event.severity.toString().split('.').last;
      grouped[severity] = (grouped[severity] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, dynamic> _assessRisk(List<AuditEvent> events) {
    final recentCritical = events.where((e) => 
        e.severity == AuditSeverity.critical &&
        e.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).length;
    
    final failedLogins = events.where((e) => 
        e.eventType == AuditEventType.loginFailed &&
        e.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).length;
    
    String riskLevel = 'low';
    if (recentCritical > 0 || failedLogins > 10) {
      riskLevel = 'critical';
    } else if (failedLogins > 5) {
      riskLevel = 'high';
    } else if (failedLogins > 2) {
      riskLevel = 'medium';
    }

    return {
      'level': riskLevel,
      'recentCriticalEvents': recentCritical,
      'recentFailedLogins': failedLogins,
      'lastAssessed': DateTime.now().toIso8601String(),
    };
  }

  Future<void> dispose() async {
    await _flushBuffer();
    await logEvent(
      eventType: AuditEventType.systemAccess,
      description: 'HIPAA audit service terminated',
    );
  }
}