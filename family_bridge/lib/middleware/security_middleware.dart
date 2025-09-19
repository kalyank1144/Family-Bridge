import 'dart:async';
import 'package:flutter/material.dart';
import '../services/security/auth_security_service.dart';
import '../services/audit/audit_logger.dart';
import '../services/encryption/encryption_service.dart';
import '../services/compliance/hipaa_technical.dart';
import '../services/security/security_monitoring.dart';
import '../services/security/privacy_manager.dart';

/// Security Middleware for all app operations
class SecurityMiddleware {
  final AuthSecurityService _authService = AuthSecurityService();
  final AuditLogger _auditLogger = AuditLogger();
  final EncryptionService _encryptionService = EncryptionService();
  final IntrusionDetection _intrusionDetection = IntrusionDetection();
  final ConsentManager _consentManager = ConsentManager();
  
  static SecurityMiddleware? _instance;
  
  SecurityMiddleware._();
  
  factory SecurityMiddleware() {
    _instance ??= SecurityMiddleware._();
    return _instance!;
  }
  
  /// Wrap API calls with security checks
  Future<T> secureApiCall<T>({
    required User user,
    required String resource,
    required String action,
    required Future<T> Function() apiCall,
    bool requiresConsent = false,
    String? consentType,
  }) async {
    try {
      // 1. Check authentication
      if (!_authService.isSessionActive()) {
        throw SecurityException('Session expired');
      }
      
      // 2. Check authorization
      final authorized = await _checkAuthorization(user, resource, action);
      if (!authorized) {
        await _handleUnauthorizedAccess(user, resource, action);
        throw SecurityException('Unauthorized access');
      }
      
      // 3. Check consent if required
      if (requiresConsent && consentType != null) {
        final hasConsent = await _consentManager.hasConsent(
          userId: user.id,
          dataType: consentType,
          purpose: action,
        );
        
        if (!hasConsent) {
          throw SecurityException('Consent required for $consentType');
        }
      }
      
      // 4. Log access attempt
      await _auditLogger.logDataAccess(
        userId: user.id,
        dataType: resource,
        action: action,
      );
      
      // 5. Execute API call
      final startTime = DateTime.now();
      final result = await apiCall();
      final duration = DateTime.now().difference(startTime);
      
      // 6. Monitor for anomalies
      if (duration.inSeconds > 10) {
        await _intrusionDetection.monitorSuspiciousActivity(
          userId: user.id,
          activityType: 'slow_api_call',
          details: {
            'resource': resource,
            'action': action,
            'duration': duration.inSeconds,
          },
        );
      }
      
      // 7. Refresh session
      _authService.refreshSession();
      
      return result;
      
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: user.id,
        event: 'API_CALL_FAILED',
        details: {
          'resource': resource,
          'action': action,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
  
  /// Encrypt data before storage
  Future<Map<String, dynamic>> encryptForStorage({
    required Map<String, dynamic> data,
    required String dataType,
    required User user,
  }) async {
    try {
      // Apply data minimization
      final minimized = DataMinimization().minimizeHealthData(
        data: data,
        userRole: user.role,
      );
      
      // Encrypt data
      final encrypted = _encryptionService.encryptHealthData(minimized);
      
      // Log encryption
      await _auditLogger.logSecurityEvent(
        userId: user.id,
        event: 'DATA_ENCRYPTED',
        details: {
          'data_type': dataType,
          'fields': minimized.keys.toList(),
        },
      );
      
      return encrypted;
      
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: user.id,
        event: 'ENCRYPTION_FAILED',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }
  
  /// Decrypt data after retrieval
  Future<Map<String, dynamic>?> decryptFromStorage({
    required Map<String, dynamic> encryptedData,
    required String dataType,
    required User user,
  }) async {
    try {
      // Decrypt data
      final decrypted = _encryptionService.decryptHealthData(encryptedData);
      
      if (decrypted == null) {
        throw SecurityException('Failed to decrypt data');
      }
      
      // Log decryption
      await _auditLogger.logDataAccess(
        userId: user.id,
        dataType: dataType,
        action: 'decrypt',
      );
      
      return decrypted;
      
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: user.id,
        event: 'DECRYPTION_FAILED',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }
  
  /// Validate and sanitize user input
  Map<String, dynamic> sanitizeInput(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in input.entries) {
      final value = entry.value;
      
      if (value is String) {
        // Remove potential SQL injection attempts
        sanitized[entry.key] = _sanitizeString(value);
      } else if (value is Map) {
        // Recursively sanitize nested maps
        sanitized[entry.key] = sanitizeInput(value as Map<String, dynamic>);
      } else if (value is List) {
        // Sanitize list items
        sanitized[entry.key] = value.map((item) {
          if (item is String) return _sanitizeString(item);
          if (item is Map) return sanitizeInput(item as Map<String, dynamic>);
          return item;
        }).toList();
      } else {
        // Keep other types as-is
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Rate limiting for API calls
  Future<void> checkRateLimit({
    required String userId,
    required String endpoint,
    int maxRequests = 100,
    Duration window = const Duration(minutes: 1),
  }) async {
    final key = '$userId:$endpoint';
    final requests = await _getRequestCount(key, window);
    
    if (requests >= maxRequests) {
      await _intrusionDetection.monitorSuspiciousActivity(
        userId: userId,
        activityType: 'rate_limit_exceeded',
        details: {
          'endpoint': endpoint,
          'requests': requests,
          'limit': maxRequests,
        },
      );
      
      throw SecurityException('Rate limit exceeded');
    }
    
    await _incrementRequestCount(key);
  }
  
  /// Handle multi-factor authentication
  Future<bool> requireMFA({
    required User user,
    required String action,
  }) async {
    // Determine if MFA is required for this action
    final mfaRequired = _isMFARequired(action, user.userType);
    
    if (!mfaRequired) return true;
    
    // Check if user has MFA configured
    final mfaConfigured = await _checkMFAConfiguration(user.id);
    
    if (!mfaConfigured) {
      // Prompt to setup MFA
      await _authService.setupMFA(user);
      return false;
    }
    
    // Verify MFA
    // This would typically show a dialog to get the MFA code
    return true; // Placeholder
  }
  
  /// Handle emergency override access
  Future<bool> handleEmergencyAccess({
    required User requestingUser,
    required String patientId,
    required String reason,
  }) async {
    try {
      // Log emergency access
      await _auditLogger.logEmergencyAccess(
        userId: requestingUser.id,
        patientId: patientId,
        reason: reason,
      );
      
      // Send alerts
      await SecurityAlerts().sendAlert(
        severity: 'HIGH',
        title: 'Emergency Access Granted',
        description: 'User ${requestingUser.id} accessed patient $patientId data',
        userId: requestingUser.id,
      );
      
      // Grant temporary elevated access
      await _grantEmergencyAccess(requestingUser.id, patientId);
      
      return true;
      
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: requestingUser.id,
        event: 'EMERGENCY_ACCESS_FAILED',
        details: {'error': e.toString()},
      );
      return false;
    }
  }
  
  // Private helper methods
  Future<bool> _checkAuthorization(User user, String resource, String action) async {
    final accessControl = AccessControl();
    return await accessControl.authorizeAccess(
      user: user,
      resource: resource,
      action: action,
    );
  }
  
  Future<void> _handleUnauthorizedAccess(User user, String resource, String action) async {
    await _intrusionDetection.monitorSuspiciousActivity(
      userId: user.id,
      activityType: 'unauthorized_access',
      details: {
        'resource': resource,
        'action': action,
      },
    );
  }
  
  String _sanitizeString(String input) {
    // Remove common SQL injection patterns
    return input
        .replaceAll(RegExp(r'[<>\"\'%;()&+]'), '')
        .replaceAll(RegExp(r'(DROP|DELETE|INSERT|UPDATE|SELECT|UNION|EXEC|SCRIPT)', caseSensitive: false), '');
  }
  
  Future<int> _getRequestCount(String key, Duration window) async {
    // Implementation would check rate limit storage
    return 0; // Placeholder
  }
  
  Future<void> _incrementRequestCount(String key) async {
    // Implementation would update rate limit storage
  }
  
  bool _isMFARequired(String action, UserType userType) {
    // Define actions that require MFA
    final mfaActions = [
      'delete_health_data',
      'export_data',
      'change_permissions',
      'access_other_user_data',
    ];
    
    return mfaActions.contains(action);
  }
  
  Future<bool> _checkMFAConfiguration(String userId) async {
    // Check if user has MFA configured
    return true; // Placeholder
  }
  
  Future<void> _grantEmergencyAccess(String userId, String patientId) async {
    // Grant temporary access with automatic expiration
    Timer(const Duration(hours: 1), () async {
      await _revokeEmergencyAccess(userId, patientId);
    });
  }
  
  Future<void> _revokeEmergencyAccess(String userId, String patientId) async {
    await _auditLogger.logSecurityEvent(
      userId: userId,
      event: 'EMERGENCY_ACCESS_REVOKED',
      details: {'patient_id': patientId},
    );
  }
}

/// Security Exception
class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// Security Context for widget tree
class SecurityContext extends InheritedWidget {
  final User currentUser;
  final SecurityMiddleware securityMiddleware;
  
  const SecurityContext({
    Key? key,
    required this.currentUser,
    required this.securityMiddleware,
    required Widget child,
  }) : super(key: key, child: child);
  
  static SecurityContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SecurityContext>();
  }
  
  @override
  bool updateShouldNotify(SecurityContext oldWidget) {
    return currentUser.id != oldWidget.currentUser.id;
  }
}

/// Security wrapper widget
class SecureWidget extends StatefulWidget {
  final Widget child;
  final String resource;
  final String action;
  final Widget unauthorizedWidget;
  
  const SecureWidget({
    Key? key,
    required this.child,
    required this.resource,
    required this.action,
    this.unauthorizedWidget = const Text('Unauthorized'),
  }) : super(key: key);
  
  @override
  State<SecureWidget> createState() => _SecureWidgetState();
}

class _SecureWidgetState extends State<SecureWidget> {
  bool _authorized = false;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }
  
  Future<void> _checkAuthorization() async {
    final context = SecurityContext.of(this.context);
    if (context == null) {
      setState(() => _loading = false);
      return;
    }
    
    final accessControl = AccessControl();
    final authorized = await accessControl.authorizeAccess(
      user: context.currentUser,
      resource: widget.resource,
      action: widget.action,
    );
    
    setState(() {
      _authorized = authorized;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator();
    }
    
    return _authorized ? widget.child : widget.unauthorizedWidget;
  }
}