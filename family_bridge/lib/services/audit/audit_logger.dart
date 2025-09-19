import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../encryption/encryption_service.dart';

/// Comprehensive Audit Logger for HIPAA Compliance
class AuditLogger {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();
  
  static AuditLogger? _instance;
  static const String _tableName = 'audit_logs';
  
  // Audit log retention period (7 years for HIPAA)
  static const Duration _retentionPeriod = Duration(days: 2555);
  
  AuditLogger._();
  
  factory AuditLogger() {
    _instance ??= AuditLogger._();
    return _instance!;
  }
  
  /// Log user authentication events
  Future<void> logAuthEvent({
    required String userId,
    required String event,
    String? ipAddress,
    String? deviceId,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'AUTHENTICATION',
      userId: userId,
      event: event,
      ipAddress: ipAddress,
      deviceId: deviceId,
      details: details,
    );
  }
  
  /// Log data access events
  Future<void> logDataAccess({
    required String userId,
    required String dataType,
    required String action,
    String? recordId,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'DATA_ACCESS',
      userId: userId,
      event: '$action:$dataType',
      details: {
        'data_type': dataType,
        'action': action,
        'record_id': recordId,
        ...?details,
      },
    );
  }
  
  /// Log PHI modifications
  Future<void> logPHIModification({
    required String userId,
    required String dataType,
    required String action,
    required String recordId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    await _logEvent(
      category: 'PHI_MODIFICATION',
      userId: userId,
      event: '$action:$dataType',
      details: {
        'data_type': dataType,
        'action': action,
        'record_id': recordId,
        'old_value': oldValue != null ? _encryptionService.encryptJson(oldValue) : null,
        'new_value': newValue != null ? _encryptionService.encryptJson(newValue) : null,
      },
    );
  }
  
  /// Log security events
  Future<void> logSecurityEvent({
    required String userId,
    required String event,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'SECURITY',
      userId: userId,
      event: event,
      details: details,
      severity: _getSecurityEventSeverity(event),
    );
  }
  
  /// Log access attempts
  Future<void> logAccessAttempt({
    required String userId,
    required String resource,
    required String action,
    required bool granted,
    String? reason,
  }) async {
    await _logEvent(
      category: 'ACCESS_CONTROL',
      userId: userId,
      event: granted ? 'ACCESS_GRANTED' : 'ACCESS_DENIED',
      details: {
        'resource': resource,
        'action': action,
        'granted': granted,
        'reason': reason,
      },
      severity: granted ? 'INFO' : 'WARNING',
    );
  }
  
  /// Log consent events
  Future<void> logConsentEvent({
    required String userId,
    required String consentType,
    required bool granted,
    String? purpose,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'CONSENT',
      userId: userId,
      event: granted ? 'CONSENT_GRANTED' : 'CONSENT_REVOKED',
      details: {
        'consent_type': consentType,
        'granted': granted,
        'purpose': purpose,
        ...?details,
      },
    );
  }
  
  /// Log training events
  Future<void> logTrainingEvent({
    required String userId,
    required String trainingType,
    required double score,
    required DateTime completedAt,
  }) async {
    await _logEvent(
      category: 'TRAINING',
      userId: userId,
      event: 'TRAINING_COMPLETED',
      details: {
        'training_type': trainingType,
        'score': score,
        'completed_at': completedAt.toIso8601String(),
        'passed': score >= 80.0,
      },
    );
  }
  
  /// Log device events
  Future<void> logDeviceEvent({
    required String userId,
    required String event,
    required String deviceId,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'DEVICE',
      userId: userId,
      event: event,
      deviceId: deviceId,
      details: details,
    );
  }
  
  /// Log workstation events
  Future<void> logWorkstationEvent({
    required String userId,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'WORKSTATION',
      userId: userId,
      event: action,
      details: details,
    );
  }
  
  /// Log integrity checks
  Future<void> logIntegrityCheck({
    required String dataType,
    required bool success,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'INTEGRITY',
      userId: 'system',
      event: success ? 'INTEGRITY_VERIFIED' : 'INTEGRITY_FAILED',
      details: {
        'data_type': dataType,
        'success': success,
        ...?details,
      },
      severity: success ? 'INFO' : 'ERROR',
    );
  }
  
  /// Log electronic signatures
  Future<void> logElectronicSignature({
    required String userId,
    required String action,
    required Map<String, dynamic> signature,
  }) async {
    await _logEvent(
      category: 'SIGNATURE',
      userId: userId,
      event: 'ELECTRONIC_SIGNATURE',
      details: {
        'action': action,
        'signature': _encryptionService.encryptJson(signature),
      },
    );
  }
  
  /// Log emergency access
  Future<void> logEmergencyAccess({
    required String userId,
    required String patientId,
    required String reason,
    Map<String, dynamic>? details,
  }) async {
    await _logEvent(
      category: 'EMERGENCY',
      userId: userId,
      event: 'EMERGENCY_ACCESS',
      details: {
        'patient_id': patientId,
        'reason': reason,
        ...?details,
      },
      severity: 'WARNING',
    );
  }
  
  /// Query audit logs
  Future<List<AuditLogEntry>> queryLogs({
    String? userId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from(_tableName).select();
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }
      
      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => AuditLogEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('Failed to query audit logs: $e');
      return [];
    }
  }
  
  /// Generate audit report
  Future<AuditReport> generateAuditReport({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    final logs = await queryLogs(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      limit: 10000,
    );
    
    // Categorize events
    final categories = <String, List<AuditLogEntry>>{};
    for (final log in logs) {
      categories.putIfAbsent(log.category, () => []).add(log);
    }
    
    // Count by severity
    final severityCounts = <String, int>{};
    for (final log in logs) {
      severityCounts[log.severity] = (severityCounts[log.severity] ?? 0) + 1;
    }
    
    return AuditReport(
      startDate: startDate,
      endDate: endDate,
      totalEvents: logs.length,
      categories: categories.map((k, v) => MapEntry(k, v.length)),
      severityCounts: severityCounts,
      criticalEvents: logs.where((l) => l.severity == 'CRITICAL').toList(),
      generatedAt: DateTime.now(),
    );
  }
  
  /// Clean old audit logs (maintain retention policy)
  Future<void> cleanOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(_retentionPeriod);
      
      // Archive old logs before deletion
      final oldLogs = await queryLogs(
        endDate: cutoffDate,
        limit: 10000,
      );
      
      if (oldLogs.isNotEmpty) {
        await _archiveLogs(oldLogs);
        
        // Delete from main table
        await _supabase
            .from(_tableName)
            .delete()
            .lt('timestamp', cutoffDate.toIso8601String());
      }
    } catch (e) {
      print('Failed to clean old logs: $e');
    }
  }
  
  // Private helper methods
  Future<void> _logEvent({
    required String category,
    required String userId,
    required String event,
    String? ipAddress,
    String? deviceId,
    Map<String, dynamic>? details,
    String severity = 'INFO',
  }) async {
    try {
      final logEntry = {
        'id': _generateLogId(),
        'timestamp': DateTime.now().toIso8601String(),
        'category': category,
        'user_id': userId,
        'event': event,
        'severity': severity,
        'ip_address': ipAddress ?? await _getIpAddress(),
        'device_id': deviceId ?? await _getDeviceId(),
        'details': details != null ? jsonEncode(details) : null,
        'checksum': null, // Will be set after calculating
      };
      
      // Calculate checksum for tamper detection
      final checksum = _calculateChecksum(logEntry);
      logEntry['checksum'] = checksum;
      
      // Store in database
      await _supabase.from(_tableName).insert(logEntry);
      
      // For critical events, also store locally
      if (severity == 'CRITICAL' || severity == 'ERROR') {
        await _storeLocally(logEntry);
      }
    } catch (e) {
      // If database fails, store locally
      await _storeLocally({
        'error': 'Failed to log to database',
        'original_event': event,
        'details': e.toString(),
      });
    }
  }
  
  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }
  
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (i) => chars[DateTime.now().millisecond % chars.length]).join();
  }
  
  String _calculateChecksum(Map<String, dynamic> data) {
    final filtered = Map.from(data)..remove('checksum');
    final json = jsonEncode(filtered);
    return _encryptionService.generateHash(json);
  }
  
  String _getSecurityEventSeverity(String event) {
    if (event.contains('FAILED') || event.contains('DENIED')) {
      return 'WARNING';
    }
    if (event.contains('BREACH') || event.contains('ATTACK')) {
      return 'CRITICAL';
    }
    if (event.contains('ERROR')) {
      return 'ERROR';
    }
    return 'INFO';
  }
  
  Future<String?> _getIpAddress() async {
    // Implementation to get IP address
    return null;
  }
  
  Future<String?> _getDeviceId() async {
    // Implementation to get device ID
    return null;
  }
  
  Future<void> _storeLocally(Map<String, dynamic> logEntry) async {
    try {
      final file = File('audit_logs_local.json');
      final logs = <Map<String, dynamic>>[];
      
      if (await file.exists()) {
        final content = await file.readAsString();
        logs.addAll(List<Map<String, dynamic>>.from(jsonDecode(content)));
      }
      
      logs.add(logEntry);
      await file.writeAsString(jsonEncode(logs));
    } catch (e) {
      print('Failed to store log locally: $e');
    }
  }
  
  Future<void> _archiveLogs(List<AuditLogEntry> logs) async {
    // Archive to long-term storage
    final archiveData = logs.map((l) => l.toJson()).toList();
    final encrypted = _encryptionService.encryptJson({'logs': archiveData});
    
    // Store encrypted archive
    await _supabase.from('audit_archives').insert({
      'archive_date': DateTime.now().toIso8601String(),
      'log_count': logs.length,
      'encrypted_data': encrypted,
    });
  }
}

/// Audit Log Entry Model
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String category;
  final String userId;
  final String event;
  final String severity;
  final String? ipAddress;
  final String? deviceId;
  final Map<String, dynamic>? details;
  final String checksum;
  
  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.userId,
    required this.event,
    required this.severity,
    this.ipAddress,
    this.deviceId,
    this.details,
    required this.checksum,
  });
  
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
      userId: json['user_id'],
      event: json['event'],
      severity: json['severity'],
      ipAddress: json['ip_address'],
      deviceId: json['device_id'],
      details: json['details'] != null 
          ? jsonDecode(json['details']) 
          : null,
      checksum: json['checksum'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'user_id': userId,
      'event': event,
      'severity': severity,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'details': details,
      'checksum': checksum,
    };
  }
}

/// Audit Report Model
class AuditReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final Map<String, int> categories;
  final Map<String, int> severityCounts;
  final List<AuditLogEntry> criticalEvents;
  final DateTime generatedAt;
  
  AuditReport({
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.categories,
    required this.severityCounts,
    required this.criticalEvents,
    required this.generatedAt,
  });
}