import 'package:flutter/material.dart';
import '../../../core/services/hipaa_audit_service.dart';
import '../../../core/services/access_control_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/breach_detection_service.dart';

class HipaaComplianceProvider extends ChangeNotifier {
  final HipaaAuditService _auditService = HipaaAuditService.instance;
  final AccessControlService _accessService = AccessControlService.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final BreachDetectionService _breachService = BreachDetectionService.instance;

  bool _isInitialized = false;
  Map<String, dynamic>? _complianceStatus;
  List<BreachIncident> _activeIncidents = [];
  Map<String, dynamic>? _encryptionStatus;
  String? _currentSessionId;
  UserSession? _currentSession;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get complianceStatus => _complianceStatus;
  List<BreachIncident> get activeIncidents => _activeIncidents;
  Map<String, dynamic>? get encryptionStatus => _encryptionStatus;
  UserSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveBreaches => _activeIncidents.isNotEmpty;
  int get criticalIncidentCount => _activeIncidents.where((i) => i.severity == BreachSeverity.critical).length;

  HipaaComplianceProvider() {
    _initialize();
    _subscribeToBreachAlerts();
  }

  /// Initialize HIPAA compliance systems
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize core services
      await _encryptionService.initialize();
      await _accessService.initialize();
      await _breachService.initialize();
      
      _isInitialized = true;
      await _loadComplianceData();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to initialize HIPAA compliance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticate user with HIPAA audit logging
  Future<AuthResult> authenticateUser({
    required String userId,
    required String password,
    required String ipAddress,
    required String deviceId,
    String? mfaCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _accessService.authenticate(
        userId: userId,
        password: password,
        ipAddress: ipAddress,
        deviceId: deviceId,
        mfaCode: mfaCode,
      );

      if (result.success && result.session != null) {
        _currentSession = result.session;
        _currentSessionId = result.session!.sessionId;
        
        // Initialize audit service with user context
        await _auditService.initialize(
          userId: userId,
          userRole: result.session!.role.toString().split('.').last,
          sessionId: result.session!.sessionId,
          deviceId: deviceId,
        );
      }

      return result;
      
    } catch (e) {
      _error = e.toString();
      return AuthResult.failure('Authentication failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log PHI access with proper audit trail
  Future<void> logPhiAccess({
    required String phiId,
    required String accessType,
    required String context,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSessionId == null) {
      throw Exception('No active session for PHI access');
    }

    // Check access permissions
    final canAccess = await _accessService.canAccessPhi(_currentSessionId!, phiId, context: context);
    if (!canAccess) {
      await _auditService.logEvent(
        eventType: AuditEventType.phiAccess,
        description: 'Unauthorized PHI access attempt blocked',
        success: false,
        failureReason: 'Insufficient permissions or invalid session',
        phiIdentifier: phiId,
        metadata: metadata,
      );
      throw Exception('Unauthorized PHI access');
    }

    // Log successful access
    await _auditService.logPhiAccess(
      phiIdentifier: phiId,
      accessType: accessType,
      resourcePath: context,
      context: metadata,
    );
  }

  /// Check if user has specific permission
  bool hasPermission(Permission permission) {
    if (_currentSessionId == null) return false;
    return _accessService.hasPermission(_currentSessionId!, permission);
  }

  /// Require elevated access for sensitive operations
  Future<bool> requireElevatedAccess(Permission permission) async {
    if (_currentSessionId == null) return false;
    return await _accessService.requireElevatedAccess(_currentSessionId!, permission);
  }

  /// Encrypt sensitive data
  Future<EncryptedData> encryptPhiData(String data, {Map<String, String>? metadata}) async {
    return await _encryptionService.encryptPhi(data, metadata: metadata);
  }

  /// Decrypt sensitive data
  Future<String> decryptPhiData(EncryptedData encryptedData) async {
    return await _encryptionService.decryptPhi(encryptedData);
  }

  /// Load compliance data and status
  Future<void> _loadComplianceData() async {
    try {
      // Load compliance report
      _complianceStatus = await _auditService.generateComplianceReport();
      
      // Load encryption status
      _encryptionStatus = _encryptionService.getEncryptionStatus();
      
      // Load active incidents
      _activeIncidents = _breachService.getIncidents(activeOnly: true);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Subscribe to real-time breach alerts
  void _subscribeToBreachAlerts() {
    _breachService.incidentStream.listen((incident) {
      _activeIncidents.add(incident);
      notifyListeners();
      
      // Show critical incident notification
      if (incident.requiresImmediateAttention) {
        _showCriticalIncidentNotification(incident);
      }
    });
  }

  /// Refresh compliance data
  Future<void> refresh() async {
    await _loadComplianceData();
  }

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final report = await _auditService.generateComplianceReport(
        startDate: startDate,
        endDate: endDate,
      );

      // Add breach statistics
      final breachStats = _breachService.getBreachStatistics(
        startDate: startDate,
        endDate: endDate,
      );
      
      final enhancedReport = Map<String, dynamic>.from(report);
      enhancedReport['breachStatistics'] = breachStats;
      enhancedReport['encryptionStatus'] = _encryptionService.getEncryptionStatus();
      
      // Log report generation
      await _auditService.logEvent(
        eventType: AuditEventType.complianceReportGenerated,
        description: 'HIPAA compliance report generated',
        metadata: {
          'reportPeriod': '${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
          'totalEvents': report['summary']['totalEvents'].toString(),
        },
      );

      return enhancedReport;
      
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update incident status
  Future<void> updateIncidentStatus({
    required String incidentId,
    required BreachStatus status,
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    await _breachService.updateIncidentStatus(
      incidentId: incidentId,
      status: status,
      assignedTo: assignedTo,
      resolutionNotes: resolutionNotes,
    );

    // Update local state
    final index = _activeIncidents.indexWhere((i) => i.incidentId == incidentId);
    if (index != -1) {
      _activeIncidents[index] = _activeIncidents[index].copyWith(
        status: status,
        assignedTo: assignedTo,
        resolvedAt: status == BreachStatus.resolved ? DateTime.now() : null,
        resolutionNotes: resolutionNotes,
      );
      
      // Remove from active list if resolved
      if (status == BreachStatus.resolved || status == BreachStatus.falsePositive) {
        _activeIncidents.removeAt(index);
      }
      
      notifyListeners();
    }
  }

  /// Rotate encryption keys
  Future<void> rotateEncryptionKeys() async {
    if (!hasPermission(Permission.manageEncryption)) {
      throw Exception('Insufficient permissions to rotate encryption keys');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _encryptionService.rotateKeys();
      _encryptionStatus = _encryptionService.getEncryptionStatus();
      
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (_currentSessionId != null) {
      await _accessService.logout(_currentSessionId!);
      _currentSessionId = null;
      _currentSession = null;
      notifyListeners();
    }
  }

  /// Force logout user (admin function)
  Future<void> forceLogoutUser(String targetSessionId) async {
    if (!hasPermission(Permission.manageUsers)) {
      throw Exception('Insufficient permissions to force logout users');
    }

    if (_currentSessionId != null) {
      await _accessService.forceLogout(_currentSessionId!, targetSessionId);
    }
  }

  /// Get all active sessions (admin function)
  Future<List<UserSession>> getAllActiveSessions() async {
    if (!hasPermission(Permission.manageUsers)) {
      throw Exception('Insufficient permissions to view active sessions');
    }

    if (_currentSessionId != null) {
      return await _accessService.getAllActiveSessions(_currentSessionId!);
    }
    
    return [];
  }

  /// Check if encryption keys need rotation
  bool shouldRotateKeys() {
    return _encryptionService.shouldRotateKeys();
  }

  /// Get compliance score (0-100)
  int getComplianceScore() {
    if (_complianceStatus == null) return 0;

    // Calculate compliance score based on various factors
    double score = 100.0;
    
    // Deduct for active critical incidents
    final criticalIncidents = _activeIncidents.where((i) => i.severity == BreachSeverity.critical).length;
    score -= criticalIncidents * 20;
    
    // Deduct for failed integrity checks
    final integrityCheck = _complianceStatus!['integrityCheck'] as Map<String, dynamic>?;
    if (integrityCheck != null) {
      final integrityPercentage = integrityCheck['integrityPercentage'] as double;
      if (integrityPercentage < 100) {
        score -= (100 - integrityPercentage) * 0.5;
      }
    }
    
    // Deduct for overdue key rotation
    if (shouldRotateKeys()) {
      score -= 10;
    }
    
    // Deduct for high risk assessment
    final riskAssessment = _complianceStatus!['riskAssessment'] as Map<String, dynamic>?;
    if (riskAssessment != null) {
      final riskLevel = riskAssessment['level'] as String;
      switch (riskLevel) {
        case 'critical':
          score -= 30;
          break;
        case 'high':
          score -= 20;
          break;
        case 'medium':
          score -= 10;
          break;
      }
    }

    return score.clamp(0, 100).toInt();
  }

  /// Get risk level based on current state
  String getRiskLevel() {
    final criticalIncidents = criticalIncidentCount;
    final complianceScore = getComplianceScore();
    
    if (criticalIncidents > 0 || complianceScore < 70) {
      return 'critical';
    } else if (complianceScore < 85) {
      return 'high';
    } else if (complianceScore < 95) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Get compliance recommendations
  List<String> getComplianceRecommendations() {
    final recommendations = <String>[];
    
    if (shouldRotateKeys()) {
      recommendations.add('Rotate encryption keys immediately - overdue by ${_getDaysOverdue()} days');
    }
    
    if (criticalIncidentCount > 0) {
      recommendations.add('Address $criticalIncidentCount critical security incidents immediately');
    }
    
    if (getComplianceScore() < 90) {
      recommendations.add('Review audit logs for compliance violations and take corrective actions');
    }
    
    final riskLevel = getRiskLevel();
    if (riskLevel == 'high' || riskLevel == 'critical') {
      recommendations.add('Conduct immediate security review and implement additional controls');
    }
    
    recommendations.add('Schedule regular compliance training for all staff');
    recommendations.add('Review and update security policies quarterly');
    
    return recommendations;
  }

  /// Export compliance data for external audits
  Future<Map<String, dynamic>> exportComplianceData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!hasPermission(Permission.manageCompliance)) {
      throw Exception('Insufficient permissions to export compliance data');
    }

    final complianceReport = await generateComplianceReport(
      startDate: startDate,
      endDate: endDate,
    );

    final breachStats = _breachService.getBreachStatistics(
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'exportMetadata': {
        'exportedAt': DateTime.now().toIso8601String(),
        'exportedBy': _currentSession?.userId ?? 'unknown',
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
      },
      'complianceReport': complianceReport,
      'breachStatistics': breachStats,
      'encryptionStatus': _encryptionStatus,
      'recommendations': getComplianceRecommendations(),
      'complianceScore': getComplianceScore(),
      'riskLevel': getRiskLevel(),
    };
  }

  /// Handle security incident
  Future<void> handleSecurityIncident({
    required String incidentId,
    required BreachStatus newStatus,
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    if (!hasPermission(Permission.manageCompliance)) {
      throw Exception('Insufficient permissions to handle security incidents');
    }

    await updateIncidentStatus(
      incidentId: incidentId,
      status: newStatus,
      assignedTo: assignedTo,
      resolutionNotes: resolutionNotes,
    );
  }

  /// Private helper methods

  void _showCriticalIncidentNotification(BreachIncident incident) {
    // In production: show system notification, alert security team
    debugPrint('CRITICAL INCIDENT: ${incident.description}');
  }

  int _getDaysOverdue() {
    if (_encryptionStatus == null || _encryptionStatus!['keyCreatedAt'] == null) {
      return 0;
    }
    
    final keyCreated = DateTime.parse(_encryptionStatus!['keyCreatedAt']);
    final rotationDue = keyCreated.add(const Duration(days: 90));
    final overdueDuration = DateTime.now().difference(rotationDue);
    
    return overdueDuration.inDays.clamp(0, 365);
  }

  @override
  void dispose() {
    _auditService.dispose();
    _breachService.dispose();
    super.dispose();
  }
}