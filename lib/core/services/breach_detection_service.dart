import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'access_control_service.dart';
import 'hipaa_audit_service.dart';

enum BreachType {
  unauthorizedAccess,
  dataExfiltration,
  multipleFailedLogins,
  suspiciousActivity,
  privilegeEscalation,
  dataModification,
  systemIntrusion,
  malwareDetected,
  insiderThreat,
  configurationChange,
}

enum BreachSeverity { low, medium, high, critical }

enum BreachStatus { detected, investigating, contained, resolved, falsePositive }

class BreachIncident {
  final String incidentId;
  final BreachType type;
  final BreachSeverity severity;
  final DateTime detectedAt;
  final String description;
  final Map<String, dynamic> evidence;
  final List<String> affectedUsers;
  final List<String> affectedResources;
  final String? phiInvolved;
  final BreachStatus status;
  final List<String> recommendedActions;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final double riskScore; // 0-1

  BreachIncident({
    required this.incidentId,
    required this.type,
    required this.severity,
    required this.detectedAt,
    required this.description,
    required this.evidence,
    required this.affectedUsers,
    required this.affectedResources,
    this.phiInvolved,
    this.status = BreachStatus.detected,
    this.recommendedActions = const [],
    this.assignedTo,
    this.resolvedAt,
    this.resolutionNotes,
    required this.riskScore,
  });

  BreachIncident copyWith({
    BreachStatus? status,
    String? assignedTo,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) {
    return BreachIncident(
      incidentId: incidentId,
      type: type,
      severity: severity,
      detectedAt: detectedAt,
      description: description,
      evidence: evidence,
      affectedUsers: affectedUsers,
      affectedResources: affectedResources,
      phiInvolved: phiInvolved,
      status: status ?? this.status,
      recommendedActions: recommendedActions,
      assignedTo: assignedTo ?? this.assignedTo,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      riskScore: riskScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'detectedAt': detectedAt.toIso8601String(),
      'description': description,
      'evidence': evidence,
      'affectedUsers': affectedUsers,
      'affectedResources': affectedResources,
      'phiInvolved': phiInvolved,
      'status': status.toString().split('.').last,
      'recommendedActions': recommendedActions,
      'assignedTo': assignedTo,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'riskScore': riskScore,
    };
  }

  factory BreachIncident.fromJson(Map<String, dynamic> json) {
    return BreachIncident(
      incidentId: json['incidentId'],
      type: BreachType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BreachType.suspiciousActivity,
      ),
      severity: BreachSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => BreachSeverity.medium,
      ),
      detectedAt: DateTime.parse(json['detectedAt']),
      description: json['description'],
      evidence: Map<String, dynamic>.from(json['evidence']),
      affectedUsers: List<String>.from(json['affectedUsers']),
      affectedResources: List<String>.from(json['affectedResources']),
      phiInvolved: json['phiInvolved'],
      status: BreachStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BreachStatus.detected,
      ),
      recommendedActions: List<String>.from(json['recommendedActions']),
      assignedTo: json['assignedTo'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolutionNotes: json['resolutionNotes'],
      riskScore: json['riskScore']?.toDouble() ?? 0.0,
    );
  }

  bool get isActive => status != BreachStatus.resolved && status != BreachStatus.falsePositive;
  bool get requiresImmediateAttention => severity == BreachSeverity.critical || riskScore > 0.8;
  Duration get responseTime => DateTime.now().difference(detectedAt);
  bool get exceededSla => responseTime > const Duration(hours: 4) && severity == BreachSeverity.critical;
}

class BreachDetectionRule {
  final String ruleId;
  final String name;
  final BreachType breachType;
  final Map<String, dynamic> conditions;
  final int timeWindowMinutes;
  final int threshold;
  final bool enabled;
  final BreachSeverity defaultSeverity;

  BreachDetectionRule({
    required this.ruleId,
    required this.name,
    required this.breachType,
    required this.conditions,
    required this.timeWindowMinutes,
    required this.threshold,
    this.enabled = true,
    this.defaultSeverity = BreachSeverity.medium,
  });
}

class BreachDetectionService {
  static final BreachDetectionService _instance = BreachDetectionService._internal();
  static BreachDetectionService get instance => _instance;
  BreachDetectionService._internal();

  final HipaaAuditService _auditService = HipaaAuditService.instance;
  final AccessControlService _accessService = AccessControlService.instance;
  
  final List<BreachIncident> _incidents = [];
  final List<BreachDetectionRule> _detectionRules = [];
  final Map<String, DateTime> _userLoginAttempts = {};
  final Map<String, int> _userFailedAttempts = {};
  final Map<String, Set<String>> _userAccessPatterns = {};
  final Map<String, DateTime> _lastUserActivity = {};
  
  StreamController<BreachIncident>? _incidentController;
  Timer? _detectionTimer;
  bool _isInitialized = false;

  // Detection thresholds
  static const int _maxFailedLogins = 5;
  static const int _maxPhiAccessesPerHour = 100;
  static const Duration _suspiciousActivityWindow = Duration(minutes: 15);
  static const Duration _offHoursThreshold = Duration(hours: 18); // 6 PM
  static const Duration _morningThreshold = Duration(hours: 6);   // 6 AM

  Stream<BreachIncident> get incidentStream => _incidentController?.stream ?? const Stream.empty();

  /// Initialize breach detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _incidentController = StreamController<BreachIncident>.broadcast();
    _setupDetectionRules();
    _startContinuousMonitoring();
    
    await _auditService.logEvent(
      eventType: AuditEventType.systemAccess,
      description: 'Breach detection service initialized',
      metadata: {'service': 'BreachDetectionService'},
    );

    _isInitialized = true;
  }

  /// Analyze audit events for potential breaches
  Future<void> analyzeEvents(List<AuditEvent> events) async {
    for (final event in events) {
      await _analyzeEvent(event);
    }
  }

  /// Report a potential security incident
  Future<BreachIncident> reportIncident({
    required BreachType type,
    required String description,
    required Map<String, dynamic> evidence,
    List<String> affectedUsers = const [],
    List<String> affectedResources = const [],
    String? phiInvolved,
    BreachSeverity? severity,
  }) async {
    final incident = BreachIncident(
      incidentId: _generateIncidentId(),
      type: type,
      severity: severity ?? _calculateSeverity(type, evidence),
      detectedAt: DateTime.now(),
      description: description,
      evidence: evidence,
      affectedUsers: affectedUsers,
      affectedResources: affectedResources,
      phiInvolved: phiInvolved,
      recommendedActions: _generateRecommendedActions(type),
      riskScore: _calculateRiskScore(type, evidence, affectedUsers.length),
    );

    _incidents.add(incident);
    _incidentController?.add(incident);

    // Log the breach detection
    await _auditService.logEvent(
      eventType: AuditEventType.breachDetected,
      description: 'Security breach detected: ${incident.description}',
      severity: _mapSeverityToAudit(incident.severity),
      metadata: {
        'incidentId': incident.incidentId,
        'breachType': incident.type.toString().split('.').last,
        'severity': incident.severity.toString().split('.').last,
        'riskScore': incident.riskScore.toString(),
        'affectedUsers': affectedUsers.join(','),
        'phiInvolved': phiInvolved ?? 'none',
      },
    );

    // Trigger immediate notifications for critical incidents
    if (incident.requiresImmediateAttention) {
      await _triggerImmediateResponse(incident);
    }

    return incident;
  }

  /// Update incident status
  Future<void> updateIncidentStatus({
    required String incidentId,
    required BreachStatus status,
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    final index = _incidents.indexWhere((i) => i.incidentId == incidentId);
    if (index != -1) {
      final incident = _incidents[index];
      _incidents[index] = incident.copyWith(
        status: status,
        assignedTo: assignedTo,
        resolvedAt: status == BreachStatus.resolved ? DateTime.now() : null,
        resolutionNotes: resolutionNotes,
      );

      await _auditService.logEvent(
        eventType: AuditEventType.incidentResponse,
        description: 'Breach incident status updated: $status',
        metadata: {
          'incidentId': incidentId,
          'newStatus': status.toString().split('.').last,
          'assignedTo': assignedTo ?? 'unassigned',
        },
      );
    }
  }

  /// Get all incidents with filtering options
  List<BreachIncident> getIncidents({
    BreachStatus? status,
    BreachType? type,
    BreachSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    bool activeOnly = false,
  }) {
    var filtered = List<BreachIncident>.from(_incidents);

    if (status != null) {
      filtered = filtered.where((i) => i.status == status).toList();
    }

    if (type != null) {
      filtered = filtered.where((i) => i.type == type).toList();
    }

    if (severity != null) {
      filtered = filtered.where((i) => i.severity == severity).toList();
    }

    if (startDate != null) {
      filtered = filtered.where((i) => i.detectedAt.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((i) => i.detectedAt.isBefore(endDate)).toList();
    }

    if (activeOnly) {
      filtered = filtered.where((i) => i.isActive).toList();
    }

    // Sort by detection time (newest first)
    filtered.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    return filtered;
  }

  /// Get breach statistics
  Map<String, dynamic> getBreachStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final incidents = getIncidents(startDate: start, endDate: end);
    
    final byType = <String, int>{};
    final bySeverity = <String, int>{};
    final byStatus = <String, int>{};
    
    double totalRiskScore = 0;
    int resolvedCount = 0;
    int activeCount = 0;
    Duration totalResponseTime = Duration.zero;
    int criticalCount = 0;

    for (final incident in incidents) {
      // Count by type
      final typeKey = incident.type.toString().split('.').last;
      byType[typeKey] = (byType[typeKey] ?? 0) + 1;
      
      // Count by severity
      final severityKey = incident.severity.toString().split('.').last;
      bySeverity[severityKey] = (bySeverity[severityKey] ?? 0) + 1;
      
      // Count by status
      final statusKey = incident.status.toString().split('.').last;
      byStatus[statusKey] = (byStatus[statusKey] ?? 0) + 1;
      
      totalRiskScore += incident.riskScore;
      
      if (incident.status == BreachStatus.resolved) {
        resolvedCount++;
        if (incident.resolvedAt != null) {
          totalResponseTime += incident.resolvedAt!.difference(incident.detectedAt);
        }
      }
      
      if (incident.isActive) {
        activeCount++;
      }
      
      if (incident.severity == BreachSeverity.critical) {
        criticalCount++;
      }
    }

    final averageResponseTime = resolvedCount > 0 
        ? totalResponseTime.inMinutes / resolvedCount 
        : 0.0;

    return {
      'totalIncidents': incidents.length,
      'activeIncidents': activeCount,
      'resolvedIncidents': resolvedCount,
      'criticalIncidents': criticalCount,
      'averageRiskScore': incidents.isNotEmpty ? totalRiskScore / incidents.length : 0.0,
      'averageResponseTimeMinutes': averageResponseTime,
      'byType': byType,
      'bySeverity': bySeverity,
      'byStatus': byStatus,
      'resolutionRate': incidents.isNotEmpty ? (resolvedCount / incidents.length) : 0.0,
    };
  }

  /// Private methods
  Future<void> _analyzeEvent(AuditEvent event) async {
    // Multiple failed login attempts
    if (event.eventType == AuditEventType.loginFailed) {
      await _checkFailedLogins(event);
    }

    // Suspicious PHI access patterns
    if (event.eventType == AuditEventType.phiAccess) {
      await _checkPhiAccessPatterns(event);
    }

    // Off-hours access
    if (_isOffHours(event.timestamp)) {
      await _checkOffHoursAccess(event);
    }

    // Privilege escalation attempts
    if (event.eventType == AuditEventType.privilegeEscalation) {
      await _checkPrivilegeEscalation(event);
    }

    // Data modification patterns
    if (event.eventType == AuditEventType.phiModification || 
        event.eventType == AuditEventType.phiDeletion) {
      await _checkSuspiciousDataChanges(event);
    }

    // Track user activity patterns
    _trackUserActivity(event);
  }

  Future<void> _checkFailedLogins(AuditEvent event) async {
    final userId = event.userId;
    _userFailedAttempts[userId] = (_userFailedAttempts[userId] ?? 0) + 1;

    if (_userFailedAttempts[userId]! >= _maxFailedLogins) {
      await reportIncident(
        type: BreachType.multipleFailedLogins,
        description: 'Multiple failed login attempts detected for user $userId',
        evidence: {
          'userId': userId,
          'failedAttempts': _userFailedAttempts[userId],
          'ipAddress': event.ipAddress,
          'timeWindow': '15 minutes',
        },
        affectedUsers: [userId],
        severity: BreachSeverity.high,
      );

      // Reset counter after reporting
      _userFailedAttempts[userId] = 0;
    }
  }

  Future<void> _checkPhiAccessPatterns(AuditEvent event) async {
    final userId = event.userId;
    final currentHour = DateTime.now().hour;
    final hourKey = '$userId:$currentHour';
    
    // Track PHI accesses per hour
    _userAccessPatterns[hourKey] ??= <String>{};
    if (event.phiIdentifier != null) {
      _userAccessPatterns[hourKey]!.add(event.phiIdentifier!);
    }

    // Check if user is accessing too much PHI in a short time
    if (_userAccessPatterns[hourKey]!.length > _maxPhiAccessesPerHour) {
      await reportIncident(
        type: BreachType.dataExfiltration,
        description: 'Excessive PHI access detected for user $userId',
        evidence: {
          'userId': userId,
          'accessCount': _userAccessPatterns[hourKey]!.length,
          'timeWindow': '1 hour',
          'uniquePhiRecords': _userAccessPatterns[hourKey]!.toList(),
        },
        affectedUsers: [userId],
        phiInvolved: 'Multiple records',
        severity: BreachSeverity.critical,
      );
    }
  }

  Future<void> _checkOffHoursAccess(AuditEvent event) async {
    if (event.eventType == AuditEventType.phiAccess ||
        event.eventType == AuditEventType.phiModification) {
      
      await reportIncident(
        type: BreachType.suspiciousActivity,
        description: 'Off-hours PHI access detected for user ${event.userId}',
        evidence: {
          'userId': event.userId,
          'accessTime': event.timestamp.toIso8601String(),
          'eventType': event.eventType.toString().split('.').last,
          'ipAddress': event.ipAddress,
        },
        affectedUsers: [event.userId],
        phiInvolved: event.phiIdentifier,
        severity: BreachSeverity.medium,
      );
    }
  }

  Future<void> _checkPrivilegeEscalation(AuditEvent event) async {
    await reportIncident(
      type: BreachType.privilegeEscalation,
      description: 'Privilege escalation attempt detected for user ${event.userId}',
      evidence: {
        'userId': event.userId,
        'eventType': event.eventType.toString().split('.').last,
        'timestamp': event.timestamp.toIso8601String(),
        'success': event.success,
        'metadata': event.metadata,
      },
      affectedUsers: [event.userId],
      severity: event.success ? BreachSeverity.critical : BreachSeverity.high,
    );
  }

  Future<void> _checkSuspiciousDataChanges(AuditEvent event) async {
    // Check for rapid data modifications
    final userId = event.userId;
    final lastActivity = _lastUserActivity[userId];
    
    if (lastActivity != null) {
      final timeDiff = event.timestamp.difference(lastActivity);
      if (timeDiff < const Duration(seconds: 30)) {
        await reportIncident(
          type: BreachType.dataModification,
          description: 'Rapid data modification pattern detected for user $userId',
          evidence: {
            'userId': userId,
            'modificationInterval': '${timeDiff.inSeconds} seconds',
            'eventType': event.eventType.toString().split('.').last,
            'phiIdentifier': event.phiIdentifier,
          },
          affectedUsers: [userId],
          phiInvolved: event.phiIdentifier,
          severity: BreachSeverity.medium,
        );
      }
    }
  }

  void _trackUserActivity(AuditEvent event) {
    _lastUserActivity[event.userId] = event.timestamp;
  }

  bool _isOffHours(DateTime timestamp) {
    final hour = timestamp.hour;
    return hour >= _offHoursThreshold.inHours || hour < _morningThreshold.inHours;
  }

  void _setupDetectionRules() {
    _detectionRules.addAll([
      BreachDetectionRule(
        ruleId: 'failed_logins',
        name: 'Multiple Failed Logins',
        breachType: BreachType.multipleFailedLogins,
        conditions: {'maxAttempts': _maxFailedLogins},
        timeWindowMinutes: 15,
        threshold: _maxFailedLogins,
        defaultSeverity: BreachSeverity.high,
      ),
      BreachDetectionRule(
        ruleId: 'phi_mass_access',
        name: 'Excessive PHI Access',
        breachType: BreachType.dataExfiltration,
        conditions: {'maxAccesses': _maxPhiAccessesPerHour},
        timeWindowMinutes: 60,
        threshold: _maxPhiAccessesPerHour,
        defaultSeverity: BreachSeverity.critical,
      ),
      BreachDetectionRule(
        ruleId: 'off_hours_access',
        name: 'Off-Hours System Access',
        breachType: BreachType.suspiciousActivity,
        conditions: {'startHour': 18, 'endHour': 6},
        timeWindowMinutes: 0,
        threshold: 1,
        defaultSeverity: BreachSeverity.medium,
      ),
    ]);
  }

  void _startContinuousMonitoring() {
    // Monitor for patterns every 5 minutes
    _detectionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performPatternAnalysis();
    });
  }

  void _performPatternAnalysis() {
    // Clean up old tracking data
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _userAccessPatterns.removeWhere((key, value) {
      final hour = int.parse(key.split(':')[1]);
      final currentHour = DateTime.now().hour;
      return (currentHour - hour).abs() > 1;
    });
    
    // Reset failed attempts after 15 minutes of no activity
    _userFailedAttempts.removeWhere((userId, attempts) {
      final lastActivity = _lastUserActivity[userId];
      return lastActivity != null && 
             DateTime.now().difference(lastActivity) > const Duration(minutes: 15);
    });
  }

  BreachSeverity _calculateSeverity(BreachType type, Map<String, dynamic> evidence) {
    switch (type) {
      case BreachType.dataExfiltration:
      case BreachType.privilegeEscalation:
      case BreachType.systemIntrusion:
        return BreachSeverity.critical;
      
      case BreachType.unauthorizedAccess:
      case BreachType.multipleFailedLogins:
      case BreachType.dataModification:
        return BreachSeverity.high;
      
      case BreachType.suspiciousActivity:
      case BreachType.insiderThreat:
        return BreachSeverity.medium;
      
      default:
        return BreachSeverity.low;
    }
  }

  double _calculateRiskScore(BreachType type, Map<String, dynamic> evidence, int affectedUserCount) {
    double baseScore = _getBaseRiskScore(type);
    
    // Adjust based on evidence
    if (evidence.containsKey('phiInvolved') && evidence['phiInvolved'] != null) {
      baseScore += 0.2;
    }
    
    if (evidence.containsKey('success') && evidence['success'] == true) {
      baseScore += 0.3;
    }
    
    // Adjust based on affected users
    baseScore += min(0.2, affectedUserCount * 0.05);
    
    return min(1.0, baseScore);
  }

  double _getBaseRiskScore(BreachType type) {
    switch (type) {
      case BreachType.dataExfiltration:
      case BreachType.systemIntrusion:
        return 0.9;
      case BreachType.privilegeEscalation:
      case BreachType.unauthorizedAccess:
        return 0.8;
      case BreachType.dataModification:
      case BreachType.multipleFailedLogins:
        return 0.7;
      case BreachType.insiderThreat:
      case BreachType.suspiciousActivity:
        return 0.6;
      default:
        return 0.5;
    }
  }

  List<String> _generateRecommendedActions(BreachType type) {
    switch (type) {
      case BreachType.multipleFailedLogins:
        return [
          'Lock user account immediately',
          'Investigate source IP address',
          'Review recent login patterns',
          'Contact user to verify legitimate access attempts',
        ];
      
      case BreachType.dataExfiltration:
        return [
          'Immediately revoke user access',
          'Review all PHI accessed by user',
          'Check for data export activities',
          'Notify security team and management',
          'Consider law enforcement involvement',
        ];
      
      case BreachType.privilegeEscalation:
        return [
          'Revoke elevated privileges',
          'Review access control configurations',
          'Audit recent administrative actions',
          'Check for unauthorized configuration changes',
        ];
      
      case BreachType.suspiciousActivity:
        return [
          'Monitor user activity closely',
          'Review access patterns',
          'Verify user identity through additional authentication',
          'Document all observations',
        ];
      
      default:
        return [
          'Investigate incident details',
          'Document findings',
          'Take appropriate containment actions',
          'Notify relevant stakeholders',
        ];
    }
  }

  AuditSeverity _mapSeverityToAudit(BreachSeverity breachSeverity) {
    switch (breachSeverity) {
      case BreachSeverity.low:
        return AuditSeverity.low;
      case BreachSeverity.medium:
        return AuditSeverity.medium;
      case BreachSeverity.high:
        return AuditSeverity.high;
      case BreachSeverity.critical:
        return AuditSeverity.critical;
    }
  }

  Future<void> _triggerImmediateResponse(BreachIncident incident) async {
    // In production: notify security team, send alerts, etc.
    debugPrint('CRITICAL SECURITY INCIDENT: ${incident.description}');
    
    await _auditService.logEvent(
      eventType: AuditEventType.incidentResponse,
      description: 'Critical security incident - immediate response triggered',
      severity: AuditSeverity.critical,
      metadata: {
        'incidentId': incident.incidentId,
        'breachType': incident.type.toString().split('.').last,
        'riskScore': incident.riskScore.toString(),
      },
    );
  }

  String _generateIncidentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'INC-$timestamp-$random';
  }

  Future<void> dispose() async {
    _detectionTimer?.cancel();
    await _incidentController?.close();
    _isInitialized = false;
  }
}