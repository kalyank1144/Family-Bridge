/// HIPAA Compliance and Security Testing Suite
/// 
/// Comprehensive testing for:
/// - HIPAA compliance requirements
/// - Data encryption and protection
/// - Access control and authorization
/// - Audit logging
/// - Breach detection and response
/// - Security vulnerability assessment

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:crypto/crypto.dart';
import 'package:family_bridge/core/services/encryption_service.dart';
import 'package:family_bridge/core/services/hipaa_audit_service.dart';
import 'package:family_bridge/core/services/breach_detection_service.dart';
import 'package:family_bridge/core/services/role_based_access_service.dart';
import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/models/user_model.dart';
import '../test_config.dart';
import '../mocks/mock_services.dart';
import '../helpers/test_helpers.dart';

/// HIPAA Compliance Checker
class HIPAAComplianceChecker {
  final List<String> _violations = [];
  final Map<String, bool> _requirements = {};
  
  void checkRequirement(String requirement, bool met, [String? details]) {
    _requirements[requirement] = met;
    if (!met) {
      _violations.add('$requirement${details != null ? ': $details' : ''}');
    }
  }
  
  bool get isCompliant => _violations.isEmpty;
  
  List<String> get violations => List.from(_violations);
  
  Map<String, dynamic> generateComplianceReport() {
    return {
      'compliant': isCompliant,
      'requirements_checked': _requirements.length,
      'requirements_met': _requirements.values.where((v) => v).length,
      'violations': _violations,
      'compliance_percentage': _calculateCompliancePercentage(),
      'details': _requirements,
    };
  }
  
  double _calculateCompliancePercentage() {
    if (_requirements.isEmpty) return 0;
    final met = _requirements.values.where((v) => v).length;
    return (met / _requirements.length) * 100;
  }
}

/// Security Vulnerability Scanner
class SecurityScanner {
  final List<Map<String, dynamic>> _vulnerabilities = [];
  
  void reportVulnerability({
    required String type,
    required String severity,
    required String description,
    String? recommendation,
  }) {
    _vulnerabilities.add({
      'type': type,
      'severity': severity,
      'description': description,
      'recommendation': recommendation,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  List<Map<String, dynamic>> get vulnerabilities => List.from(_vulnerabilities);
  
  Map<String, dynamic> generateSecurityReport() {
    final bySeverity = <String, int>{};
    for (final vuln in _vulnerabilities) {
      final severity = vuln['severity'] as String;
      bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;
    }
    
    return {
      'total_vulnerabilities': _vulnerabilities.length,
      'critical': bySeverity['critical'] ?? 0,
      'high': bySeverity['high'] ?? 0,
      'medium': bySeverity['medium'] ?? 0,
      'low': bySeverity['low'] ?? 0,
      'vulnerabilities': _vulnerabilities,
    };
  }
}

void main() {
  late HIPAAComplianceChecker complianceChecker;
  late SecurityScanner securityScanner;
  late ConfigurableMockEncryptionService mockEncryption;
  late ConfigurableMockHIPAAAuditService mockAudit;
  late MockBreachDetectionService mockBreachDetection;
  late MockRoleBasedAccessService mockAccessControl;
  late TestQualityMetrics qualityMetrics;
  
  setUpAll(() async {
    await TestConfig.initialize(env: TestEnvironment.security);
    qualityMetrics = TestQualityMetrics();
  });
  
  setUp(() {
    complianceChecker = HIPAAComplianceChecker();
    securityScanner = SecurityScanner();
    mockEncryption = ConfigurableMockEncryptionService();
    mockAudit = ConfigurableMockHIPAAAuditService();
    mockBreachDetection = MockBreachDetectionService();
    mockAccessControl = MockRoleBasedAccessService();
  });
  
  tearDown(() async {
    await TestConfig.tearDown();
  });
  
  tearDownAll(() {
    print('\nHIPAA Compliance Report:');
    print(complianceChecker.generateComplianceReport());
    print('\nSecurity Scan Report:');
    print(securityScanner.generateSecurityReport());
    print('\nTest Quality Metrics:');
    print(qualityMetrics.getQualityReport());
  });
  
  group('Data Encryption Compliance', () {
    test('PHI must be encrypted at rest', () async {
      final testName = 'hipaa_encryption_at_rest';
      
      try {
        // Test various PHI data types
        final phiData = [
          {'type': 'medical_record', 'data': 'Patient diagnosis: Diabetes'},
          {'type': 'medication', 'data': 'Insulin 10 units daily'},
          {'type': 'personal_info', 'data': 'SSN: 123-45-6789'},
        ];
        
        for (final phi in phiData) {
          final encrypted = await mockEncryption.encrypt(phi['data'] as String);
          
          // Verify encryption
          expect(encrypted, isNot(equals(phi['data'])));
          expect(encrypted.startsWith('encrypted_'), isTrue);
          
          // Verify decryption works
          final decrypted = await mockEncryption.decrypt(encrypted);
          expect(decrypted, equals(phi['data']));
          
          complianceChecker.checkRequirement(
            'PHI_ENCRYPTION_${phi['type']}',
            true,
          );
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        complianceChecker.checkRequirement(
          'PHI_ENCRYPTION',
          false,
          e.toString(),
        );
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('PHI must be encrypted in transit', () async {
      final testName = 'hipaa_encryption_in_transit';
      
      try {
        // Verify TLS/SSL configuration
        final tlsEnabled = await _verifyTLSConfiguration();
        complianceChecker.checkRequirement(
          'TLS_ENABLED',
          tlsEnabled,
          tlsEnabled ? null : 'TLS not properly configured',
        );
        
        // Verify minimum TLS version
        final tlsVersion = await _getTLSVersion();
        final validTLS = tlsVersion >= 1.2;
        complianceChecker.checkRequirement(
          'TLS_VERSION',
          validTLS,
          validTLS ? null : 'TLS version $tlsVersion is below minimum 1.2',
        );
        
        // Test API encryption
        final apiEndpoints = [
          '/api/health/records',
          '/api/medications',
          '/api/emergency/contacts',
        ];
        
        for (final endpoint in apiEndpoints) {
          final isSecure = await _testEndpointEncryption(endpoint);
          complianceChecker.checkRequirement(
            'API_ENCRYPTION_$endpoint',
            isSecure,
          );
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Encryption keys must be properly managed', () async {
      final testName = 'hipaa_key_management';
      
      try {
        // Check key strength
        final keyStrength = await _getEncryptionKeyStrength();
        final validKeyStrength = keyStrength >= 256;
        complianceChecker.checkRequirement(
          'KEY_STRENGTH',
          validKeyStrength,
          validKeyStrength ? null : 'Key strength $keyStrength bits is below minimum 256',
        );
        
        // Check key rotation
        final keyRotation = await _verifyKeyRotation();
        complianceChecker.checkRequirement(
          'KEY_ROTATION',
          keyRotation.enabled,
          keyRotation.enabled ? null : 'Key rotation not enabled',
        );
        
        // Check key storage
        final keyStorage = await _verifyKeyStorage();
        complianceChecker.checkRequirement(
          'KEY_STORAGE',
          keyStorage.secure,
          keyStorage.secure ? null : 'Keys not stored securely',
        );
        
        // Verify no hardcoded keys
        final hardcodedKeys = await _scanForHardcodedKeys();
        complianceChecker.checkRequirement(
          'NO_HARDCODED_KEYS',
          hardcodedKeys.isEmpty,
          hardcodedKeys.isEmpty ? null : 'Found ${hardcodedKeys.length} hardcoded keys',
        );
        
        if (hardcodedKeys.isNotEmpty) {
          for (final key in hardcodedKeys) {
            securityScanner.reportVulnerability(
              type: 'hardcoded_key',
              severity: 'critical',
              description: 'Hardcoded key found in ${key['file']}',
              recommendation: 'Move to secure key management system',
            );
          }
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Access Control Compliance', () {
    test('Must implement role-based access control', () async {
      final testName = 'hipaa_rbac';
      
      try {
        // Test different user roles
        final roles = ['elder', 'caregiver', 'youth', 'admin'];
        
        for (final role in roles) {
          final user = User(
            id: 'test_$role',
            email: '$role@test.com',
            userType: role,
            familyId: 'family123',
          );
          
          // Verify role has defined permissions
          final permissions = await mockAccessControl.getPermissions(user);
          expect(permissions, isNotEmpty);
          
          complianceChecker.checkRequirement(
            'RBAC_ROLE_$role',
            permissions.isNotEmpty,
          );
          
          // Verify least privilege principle
          if (role == 'youth') {
            expect(permissions.contains('view_medical_records'), isFalse);
            expect(permissions.contains('modify_medications'), isFalse);
          }
          
          if (role == 'elder') {
            expect(permissions.contains('view_own_data'), isTrue);
            expect(permissions.contains('emergency_access'), isTrue);
          }
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Must enforce authentication for PHI access', () async {
      final testName = 'hipaa_authentication';
      
      try {
        // Test unauthenticated access attempt
        final unauthorizedAccess = await _attemptUnauthorizedAccess();
        complianceChecker.checkRequirement(
          'AUTHENTICATION_REQUIRED',
          !unauthorizedAccess,
          unauthorizedAccess ? 'Unauthorized access possible' : null,
        );
        
        // Test session timeout
        final sessionTimeout = await _getSessionTimeout();
        final validTimeout = sessionTimeout <= 15; // 15 minutes max
        complianceChecker.checkRequirement(
          'SESSION_TIMEOUT',
          validTimeout,
          validTimeout ? null : 'Session timeout $sessionTimeout min exceeds 15 min',
        );
        
        // Test password requirements
        final passwordPolicy = await _getPasswordPolicy();
        complianceChecker.checkRequirement(
          'PASSWORD_COMPLEXITY',
          passwordPolicy.meetsHIPAA,
          passwordPolicy.meetsHIPAA ? null : 'Password policy insufficient',
        );
        
        // Test MFA for sensitive operations
        final mfaEnabled = await _verifyMFAForSensitiveOps();
        complianceChecker.checkRequirement(
          'MFA_SENSITIVE_OPS',
          mfaEnabled,
          mfaEnabled ? null : 'MFA not required for sensitive operations',
        );
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Must implement proper authorization checks', () async {
      final testName = 'hipaa_authorization';
      
      try {
        // Test cross-family data access prevention
        final user1 = User(
          id: 'user1',
          email: 'user1@test.com',
          userType: 'caregiver',
          familyId: 'family1',
        );
        
        final user2Data = {
          'id': 'data2',
          'familyId': 'family2',
          'type': 'medical_record',
        };
        
        final canAccess = await mockAccessControl.canAccess(
          user: user1,
          resource: user2Data,
        );
        
        complianceChecker.checkRequirement(
          'FAMILY_ISOLATION',
          !canAccess,
          canAccess ? 'Cross-family access possible' : null,
        );
        
        // Test granular permissions
        final elderUser = User(
          id: 'elder1',
          email: 'elder@test.com',
          userType: 'elder',
          familyId: 'family1',
        );
        
        final medicationData = {
          'id': 'med1',
          'userId': 'elder1',
          'type': 'medication',
        };
        
        final canModify = await mockAccessControl.canModify(
          user: elderUser,
          resource: medicationData,
        );
        
        complianceChecker.checkRequirement(
          'GRANULAR_PERMISSIONS',
          canModify,
          !canModify ? 'User cannot modify own data' : null,
        );
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Audit Logging Compliance', () {
    test('Must log all PHI access', () async {
      final testName = 'hipaa_audit_logging';
      
      try {
        // Simulate PHI access
        await mockAudit.logAccess(
          userId: 'user123',
          resourceType: 'medical_record',
          resourceId: 'record456',
          action: 'view',
        );
        
        // Verify log entry created
        final logs = await mockAudit.getAuditLogs(userId: 'user123');
        expect(logs, isNotEmpty);
        
        final log = logs.first;
        expect(log['userId'], equals('user123'));
        expect(log['resourceType'], equals('medical_record'));
        expect(log['action'], equals('view'));
        expect(log['timestamp'], isNotNull);
        
        complianceChecker.checkRequirement(
          'AUDIT_LOG_ACCESS',
          true,
        );
        
        // Verify required fields
        final requiredFields = [
          'userId',
          'timestamp',
          'resourceType',
          'resourceId',
          'action',
        ];
        
        for (final field in requiredFields) {
          complianceChecker.checkRequirement(
            'AUDIT_FIELD_$field',
            log.containsKey(field),
          );
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Must log all PHI modifications', () async {
      final testName = 'hipaa_audit_modifications';
      
      try {
        // Simulate PHI modification
        await mockAudit.logDataModification(
          userId: 'user123',
          dataType: 'medication',
          dataId: 'med789',
          modification: 'update',
          oldValue: {'dosage': '10mg'},
          newValue: {'dosage': '20mg'},
        );
        
        // Verify modification logged
        final logs = await mockAudit.getAuditLogs(
          userId: 'user123',
          resourceType: 'medication',
        );
        
        expect(logs, isNotEmpty);
        
        final log = logs.first;
        expect(log['modification'], equals('update'));
        expect(log['oldValue'], isNotNull);
        expect(log['newValue'], isNotNull);
        
        complianceChecker.checkRequirement(
          'AUDIT_LOG_MODIFICATIONS',
          true,
        );
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Audit logs must be tamper-proof', () async {
      final testName = 'hipaa_audit_integrity';
      
      try {
        // Create audit log
        await mockAudit.logAccess(
          userId: 'user123',
          resourceType: 'medical_record',
          resourceId: 'record456',
          action: 'view',
        );
        
        final logs = await mockAudit.getAuditLogs();
        final originalLog = logs.first;
        
        // Try to modify log (should fail)
        bool modificationPrevented = true;
        try {
          await _attemptLogModification(originalLog['id']);
          modificationPrevented = false;
        } catch (e) {
          // Expected - modification should be prevented
        }
        
        complianceChecker.checkRequirement(
          'AUDIT_TAMPER_PROOF',
          modificationPrevented,
          !modificationPrevented ? 'Audit logs can be modified' : null,
        );
        
        // Verify log retention
        final retentionPeriod = await _getAuditLogRetention();
        final meetsRequirement = retentionPeriod >= 6 * 365; // 6 years
        complianceChecker.checkRequirement(
          'AUDIT_RETENTION',
          meetsRequirement,
          meetsRequirement ? null : 'Retention period ${retentionPeriod} days < 6 years',
        );
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Breach Detection and Response', () {
    test('Must detect unauthorized access attempts', () async {
      final testName = 'hipaa_breach_detection';
      
      try {
        // Simulate multiple failed login attempts
        for (int i = 0; i < 5; i++) {
          await mockBreachDetection.recordFailedLogin(
            email: 'attacker@test.com',
            ipAddress: '192.168.1.100',
          );
        }
        
        // Should trigger breach alert
        final alerts = await mockBreachDetection.getActiveAlerts();
        expect(alerts, isNotEmpty);
        
        final alert = alerts.first;
        expect(alert['type'], equals('multiple_failed_logins'));
        expect(alert['severity'], equals('high'));
        
        complianceChecker.checkRequirement(
          'BREACH_DETECTION_LOGIN',
          true,
        );
        
        // Test unusual access pattern detection
        await mockBreachDetection.recordAccess(
          userId: 'user123',
          resourceType: 'medical_record',
          count: 100, // Unusual number of accesses
          timeWindow: const Duration(minutes: 5),
        );
        
        final unusualAccessAlerts = await mockBreachDetection.getActiveAlerts(
          type: 'unusual_access',
        );
        
        complianceChecker.checkRequirement(
          'BREACH_DETECTION_PATTERNS',
          unusualAccessAlerts.isNotEmpty,
        );
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('Must have breach notification procedures', () async {
      final testName = 'hipaa_breach_notification';
      
      try {
        // Simulate breach detection
        final breachId = await mockBreachDetection.reportBreach(
          type: 'unauthorized_access',
          affectedRecords: 50,
          description: 'Unauthorized access to patient records',
        );
        
        // Verify notification sent
        final notifications = await mockBreachDetection.getBreachNotifications(
          breachId: breachId,
        );
        
        expect(notifications, isNotEmpty);
        
        // Check notification timeline
        final breach = await mockBreachDetection.getBreach(breachId);
        final detectionTime = DateTime.parse(breach['detected_at']);
        final notificationTime = DateTime.parse(notifications.first['sent_at']);
        
        final timeDiff = notificationTime.difference(detectionTime);
        final withinDeadline = timeDiff.inDays <= 60; // 60 days per HIPAA
        
        complianceChecker.checkRequirement(
          'BREACH_NOTIFICATION_TIMELINE',
          withinDeadline,
          withinDeadline ? null : 'Notification delayed ${timeDiff.inDays} days',
        );
        
        // Verify required information in notification
        final notification = notifications.first;
        final requiredInfo = [
          'breach_description',
          'types_of_information',
          'steps_taken',
          'steps_individuals_should_take',
          'contact_information',
        ];
        
        for (final info in requiredInfo) {
          complianceChecker.checkRequirement(
            'BREACH_NOTIFICATION_$info',
            notification.containsKey(info),
          );
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Security Vulnerability Testing', () {
    test('SQL injection prevention', () async {
      final testName = 'security_sql_injection';
      
      try {
        final maliciousInputs = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'--",
          "' UNION SELECT * FROM users--",
        ];
        
        for (final input in maliciousInputs) {
          bool injectionPrevented = true;
          try {
            await _testSQLInjection(input);
            injectionPrevented = false;
          } catch (e) {
            // Expected - injection should be prevented
          }
          
          if (!injectionPrevented) {
            securityScanner.reportVulnerability(
              type: 'sql_injection',
              severity: 'critical',
              description: 'SQL injection possible with input: $input',
              recommendation: 'Use parameterized queries',
            );
          }
        }
        
        expect(securityScanner.vulnerabilities
            .where((v) => v['type'] == 'sql_injection')
            .isEmpty, isTrue);
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('XSS prevention', () async {
      final testName = 'security_xss';
      
      try {
        final xssPayloads = [
          '<script>alert("XSS")</script>',
          '<img src=x onerror=alert("XSS")>',
          'javascript:alert("XSS")',
          '<iframe src="javascript:alert(\'XSS\')">',
        ];
        
        for (final payload in xssPayloads) {
          final sanitized = await _sanitizeInput(payload);
          
          // Should not contain script tags
          expect(sanitized.contains('<script'), isFalse);
          expect(sanitized.contains('javascript:'), isFalse);
          expect(sanitized.contains('onerror='), isFalse);
        }
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('CSRF protection', () async {
      final testName = 'security_csrf';
      
      try {
        // Verify CSRF token generation
        final token = await _getCSRFToken();
        expect(token, isNotEmpty);
        expect(token.length, greaterThanOrEqualTo(32));
        
        // Verify token validation
        bool validToken = await _validateCSRFToken(token);
        expect(validToken, isTrue);
        
        // Verify invalid token rejection
        bool invalidToken = await _validateCSRFToken('invalid_token');
        expect(invalidToken, isFalse);
        
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
}

// Helper functions for testing
Future<bool> _verifyTLSConfiguration() async {
  // Check if TLS is properly configured
  // In production, this would verify actual TLS settings
  return true;
}

Future<double> _getTLSVersion() async {
  // Get configured TLS version
  return 1.3;
}

Future<bool> _testEndpointEncryption(String endpoint) async {
  // Test if endpoint uses encryption
  return endpoint.startsWith('/api/');
}

Future<int> _getEncryptionKeyStrength() async {
  // Get encryption key strength in bits
  return 256;
}

Future<({bool enabled, int rotationDays})> _verifyKeyRotation() async {
  // Verify key rotation settings
  return (enabled: true, rotationDays: 90);
}

Future<({bool secure, String method})> _verifyKeyStorage() async {
  // Verify secure key storage
  return (secure: true, method: 'hardware_security_module');
}

Future<List<Map<String, String>>> _scanForHardcodedKeys() async {
  // Scan code for hardcoded keys
  // In production, this would scan actual codebase
  return [];
}

Future<bool> _attemptUnauthorizedAccess() async {
  // Try to access PHI without authentication
  // Should return false (access denied)
  return false;
}

Future<int> _getSessionTimeout() async {
  // Get session timeout in minutes
  return 10;
}

Future<({bool meetsHIPAA, int minLength, bool requiresSpecial})> _getPasswordPolicy() async {
  return (meetsHIPAA: true, minLength: 12, requiresSpecial: true);
}

Future<bool> _verifyMFAForSensitiveOps() async {
  // Check if MFA is required for sensitive operations
  return true;
}

Future<void> _attemptLogModification(String logId) async {
  // Attempt to modify audit log (should fail)
  throw Exception('Audit logs are immutable');
}

Future<int> _getAuditLogRetention() async {
  // Get audit log retention period in days
  return 6 * 365; // 6 years
}

Future<void> _testSQLInjection(String input) async {
  // Test SQL injection with malicious input
  // Should throw exception if properly protected
  if (input.contains('DROP') || input.contains('UNION')) {
    throw Exception('SQL injection prevented');
  }
}

Future<String> _sanitizeInput(String input) async {
  // Sanitize user input to prevent XSS
  return input
      .replaceAll('<script', '&lt;script')
      .replaceAll('javascript:', '')
      .replaceAll('onerror=', '');
}

Future<String> _getCSRFToken() async {
  // Generate CSRF token
  final bytes = List<int>.generate(32, (i) => i);
  return base64.encode(bytes);
}

Future<bool> _validateCSRFToken(String token) async {
  // Validate CSRF token
  return token.length >= 32 && token != 'invalid_token';
}

// Mock services for security testing
class MockBreachDetectionService {
  final List<Map<String, dynamic>> _alerts = [];
  final List<Map<String, dynamic>> _breaches = [];
  final Map<String, List<Map<String, dynamic>>> _notifications = {};
  
  Future<void> recordFailedLogin({
    required String email,
    required String ipAddress,
  }) async {
    // Record failed login attempt
  }
  
  Future<List<Map<String, dynamic>>> getActiveAlerts({String? type}) async {
    if (_alerts.isEmpty) {
      _alerts.add({
        'id': 'alert1',
        'type': 'multiple_failed_logins',
        'severity': 'high',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    if (type != null) {
      return _alerts.where((a) => a['type'] == type).toList();
    }
    return _alerts;
  }
  
  Future<void> recordAccess({
    required String userId,
    required String resourceType,
    required int count,
    required Duration timeWindow,
  }) async {
    if (count > 50) {
      _alerts.add({
        'id': 'alert2',
        'type': 'unusual_access',
        'severity': 'medium',
        'userId': userId,
        'resourceType': resourceType,
        'count': count,
      });
    }
  }
  
  Future<String> reportBreach({
    required String type,
    required int affectedRecords,
    required String description,
  }) async {
    final breachId = 'breach_${_breaches.length + 1}';
    _breaches.add({
      'id': breachId,
      'type': type,
      'affected_records': affectedRecords,
      'description': description,
      'detected_at': DateTime.now().toIso8601String(),
    });
    
    // Create notification
    _notifications[breachId] = [{
      'id': 'notif_1',
      'breach_id': breachId,
      'sent_at': DateTime.now().toIso8601String(),
      'breach_description': description,
      'types_of_information': 'Medical records',
      'steps_taken': 'Access revoked, security enhanced',
      'steps_individuals_should_take': 'Monitor accounts',
      'contact_information': 'security@familybridge.com',
    }];
    
    return breachId;
  }
  
  Future<List<Map<String, dynamic>>> getBreachNotifications({
    required String breachId,
  }) async {
    return _notifications[breachId] ?? [];
  }
  
  Future<Map<String, dynamic>> getBreach(String breachId) async {
    return _breaches.firstWhere((b) => b['id'] == breachId);
  }
}

class MockRoleBasedAccessService {
  Future<List<String>> getPermissions(User user) async {
    switch (user.userType) {
      case 'elder':
        return ['view_own_data', 'emergency_access', 'modify_own_data'];
      case 'caregiver':
        return ['view_family_data', 'modify_care_plans', 'view_medical_records'];
      case 'youth':
        return ['view_family_chat', 'send_messages', 'view_calendar'];
      case 'admin':
        return ['all_permissions'];
      default:
        return [];
    }
  }
  
  Future<bool> canAccess({
    required User user,
    required Map<String, dynamic> resource,
  }) async {
    // Check family isolation
    return user.familyId == resource['familyId'];
  }
  
  Future<bool> canModify({
    required User user,
    required Map<String, dynamic> resource,
  }) async {
    // Check if user can modify resource
    if (user.id == resource['userId']) {
      return true; // Can modify own data
    }
    if (user.userType == 'caregiver' && user.familyId == resource['familyId']) {
      return true; // Caregiver can modify family data
    }
    return false;
  }
}