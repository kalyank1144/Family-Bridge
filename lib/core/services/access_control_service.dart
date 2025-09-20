import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'hipaa_audit_service.dart';
import 'encryption_service.dart';

enum UserRole {
  patient,        // Family members (elders, youth)
  caregiver,      // Family caregivers
  professional,   // Healthcare professionals
  admin,          // System administrators
  superAdmin,     // Super administrators
}

enum Permission {
  // PHI Permissions
  readPhi,
  writePhi,
  exportPhi,
  deletePhi,
  
  // System Permissions
  manageUsers,
  manageRoles,
  viewAuditLogs,
  manageCompliance,
  
  // Clinical Permissions
  prescribeMedications,
  viewMedicalHistory,
  createCarePlans,
  generateReports,
  
  // Administrative Permissions
  configureSystem,
  manageEncryption,
  accessAllData,
  emergencyOverride,
}

enum MfaMethod {
  none,
  sms,
  email,
  authenticatorApp,
  biometric,
  hardwareToken,
}

class UserSession {
  final String sessionId;
  final String userId;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String ipAddress;
  final String deviceId;
  final bool mfaVerified;
  final MfaMethod mfaMethod;
  final Set<Permission> permissions;
  final Map<String, dynamic> metadata;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.lastActivity,
    required this.ipAddress,
    required this.deviceId,
    required this.mfaVerified,
    required this.mfaMethod,
    required this.permissions,
    this.metadata = const {},
  });

  UserSession copyWith({
    DateTime? lastActivity,
    bool? mfaVerified,
    MfaMethod? mfaMethod,
    Set<Permission>? permissions,
    Map<String, dynamic>? metadata,
  }) {
    return UserSession(
      sessionId: sessionId,
      userId: userId,
      role: role,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      ipAddress: ipAddress,
      deviceId: deviceId,
      mfaVerified: mfaVerified ?? this.mfaVerified,
      mfaMethod: mfaMethod ?? this.mfaMethod,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    const sessionTimeout = Duration(hours: 8); // HIPAA recommended
    return DateTime.now().difference(lastActivity) > sessionTimeout;
  }

  bool get requiresMfaRefresh {
    const mfaTimeout = Duration(hours: 1); // Sensitive operations require recent MFA
    return DateTime.now().difference(lastActivity) > mfaTimeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'ipAddress': ipAddress,
      'deviceId': deviceId,
      'mfaVerified': mfaVerified,
      'mfaMethod': mfaMethod.toString().split('.').last,
      'permissions': permissions.map((p) => p.toString().split('.').last).toList(),
      'metadata': metadata,
    };
  }
}

class MfaChallenge {
  final String challengeId;
  final String userId;
  final MfaMethod method;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? code; // For SMS/Email
  final String? qrCodeData; // For authenticator apps
  final bool isVerified;

  MfaChallenge({
    required this.challengeId,
    required this.userId,
    required this.method,
    required this.createdAt,
    required this.expiresAt,
    this.code,
    this.qrCodeData,
    this.isVerified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AccessControlService {
  static final AccessControlService _instance = AccessControlService._internal();
  static AccessControlService get instance => _instance;
  AccessControlService._internal();

  final Map<String, UserSession> _activeSessions = {};
  final Map<String, MfaChallenge> _mfaChallenges = {};
  final HipaaAuditService _auditService = HipaaAuditService.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;

  // Session timeout configuration
  static const Duration _sessionTimeout = Duration(hours: 8);
  static const Duration _mfaTimeout = Duration(minutes: 5);
  static const int _maxFailedAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 30);

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockedUntil = {};

  // Role-based permissions mapping
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.patient: {
      Permission.readPhi,
      Permission.writePhi,
    },
    UserRole.caregiver: {
      Permission.readPhi,
      Permission.writePhi,
      Permission.viewMedicalHistory,
      Permission.createCarePlans,
    },
    UserRole.professional: {
      Permission.readPhi,
      Permission.writePhi,
      Permission.exportPhi,
      Permission.prescribeMedications,
      Permission.viewMedicalHistory,
      Permission.createCarePlans,
      Permission.generateReports,
    },
    UserRole.admin: {
      Permission.readPhi,
      Permission.writePhi,
      Permission.exportPhi,
      Permission.manageUsers,
      Permission.manageRoles,
      Permission.viewAuditLogs,
      Permission.manageCompliance,
      Permission.configureSystem,
    },
    UserRole.superAdmin: {
      ...Permission.values, // All permissions
    },
  };

  /// Initialize access control service
  Future<void> initialize() async {
    // Clean up expired sessions periodically
    _startSessionCleanup();
    
    await _auditService.logEvent(
      eventType: AuditEventType.systemAccess,
      description: 'Access control service initialized',
      metadata: {'service': 'AccessControlService'},
    );
  }

  /// Authenticate user with credentials
  Future<AuthResult> authenticate({
    required String userId,
    required String password,
    required String ipAddress,
    required String deviceId,
    String? mfaCode,
  }) async {
    try {
      // Check if user is locked out
      if (_isUserLockedOut(userId)) {
        await _auditService.logAuthenticationEvent(
          eventType: AuditEventType.loginFailed,
          userId: userId,
          success: false,
          failureReason: 'Account locked due to excessive failed attempts',
          metadata: {'ipAddress': ipAddress, 'deviceId': deviceId},
        );
        return AuthResult.failure('Account temporarily locked due to failed attempts');
      }

      // Verify credentials (simplified - in production use proper password hashing)
      final isValidCredential = await _verifyCredentials(userId, password);
      if (!isValidCredential) {
        await _handleFailedAttempt(userId, ipAddress, deviceId);
        return AuthResult.failure('Invalid credentials');
      }

      // Get user role and permissions
      final userRole = await _getUserRole(userId);
      final permissions = _getRolePermissions(userRole);

      // Check if MFA is required
      final mfaRequired = await _isMfaRequired(userId, userRole);
      if (mfaRequired && mfaCode == null) {
        final mfaChallenge = await _initiateMfaChallenge(userId);
        return AuthResult.mfaRequired(mfaChallenge);
      }

      // Verify MFA if provided
      if (mfaCode != null) {
        final mfaResult = await _verifyMfaCode(userId, mfaCode);
        if (!mfaResult.success) {
          await _handleFailedAttempt(userId, ipAddress, deviceId);
          return AuthResult.failure(mfaResult.error ?? 'MFA verification failed');
        }
      }

      // Create session
      final session = await _createSession(
        userId: userId,
        role: userRole,
        ipAddress: ipAddress,
        deviceId: deviceId,
        mfaVerified: mfaCode != null || !mfaRequired,
        mfaMethod: mfaCode != null ? MfaMethod.sms : MfaMethod.none, // Simplified
        permissions: permissions,
      );

      // Clear failed attempts
      _failedAttempts.remove(userId);
      _lockedUntil.remove(userId);

      await _auditService.logAuthenticationEvent(
        eventType: AuditEventType.login,
        userId: userId,
        success: true,
        metadata: {
          'ipAddress': ipAddress,
          'deviceId': deviceId,
          'mfaMethod': mfaCode != null ? 'sms' : 'none',
          'sessionId': session.sessionId,
        },
      );

      return AuthResult.success(session);
      
    } catch (e) {
      await _auditService.logAuthenticationEvent(
        eventType: AuditEventType.loginFailed,
        userId: userId,
        success: false,
        failureReason: 'Authentication error: $e',
        metadata: {'ipAddress': ipAddress, 'deviceId': deviceId},
      );
      return AuthResult.failure('Authentication failed');
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String sessionId, Permission permission) {
    final session = _activeSessions[sessionId];
    if (session == null || session.isExpired) {
      return false;
    }

    // Update last activity
    _activeSessions[sessionId] = session.copyWith(lastActivity: DateTime.now());

    return session.permissions.contains(permission);
  }

  /// Check if user can access PHI
  Future<bool> canAccessPhi(String sessionId, String phiId, {String? context}) async {
    final session = _activeSessions[sessionId];
    if (session == null || session.isExpired) {
      await _auditService.logEvent(
        eventType: AuditEventType.phiAccess,
        userId: 'unknown',
        description: 'PHI access denied - invalid session',
        success: false,
        failureReason: 'Invalid or expired session',
        phiIdentifier: phiId,
      );
      return false;
    }

    // Check minimum necessary access principle
    if (!_hasMinimumNecessaryAccess(session, phiId, context)) {
      await _auditService.logEvent(
        eventType: AuditEventType.phiAccess,
        userId: session.userId,
        description: 'PHI access denied - minimum necessary violation',
        success: false,
        failureReason: 'Does not meet minimum necessary access requirements',
        phiIdentifier: phiId,
        metadata: {'context': context},
      );
      return false;
    }

    // Log PHI access
    await _auditService.logPhiAccess(
      phiIdentifier: phiId,
      accessType: 'read',
      resourcePath: context ?? 'unknown',
      context: {
        'sessionId': sessionId,
        'userId': session.userId,
        'role': session.role.toString().split('.').last,
      },
    );

    return session.permissions.contains(Permission.readPhi);
  }

  /// Require elevated privileges for sensitive operations
  Future<bool> requireElevatedAccess(String sessionId, Permission permission) async {
    final session = _activeSessions[sessionId];
    if (session == null || session.isExpired) {
      return false;
    }

    // Check if MFA refresh is needed for sensitive operations
    if (_isSensitivePermission(permission) && session.requiresMfaRefresh) {
      await _auditService.logEvent(
        eventType: AuditEventType.privilegeEscalation,
        userId: session.userId,
        description: 'Elevated access denied - MFA refresh required',
        success: false,
        metadata: {'requiredPermission': permission.toString().split('.').last},
      );
      return false;
    }

    return session.permissions.contains(permission);
  }

  /// Logout user and invalidate session
  Future<void> logout(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session != null) {
      _activeSessions.remove(sessionId);
      
      await _auditService.logAuthenticationEvent(
        eventType: AuditEventType.logout,
        userId: session.userId,
        success: true,
        metadata: {'sessionId': sessionId},
      );
    }
  }

  /// Get current user session
  UserSession? getCurrentSession(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null || session.isExpired) {
      return null;
    }

    // Update last activity
    _activeSessions[sessionId] = session.copyWith(lastActivity: DateTime.now());
    return _activeSessions[sessionId];
  }

  /// Get all active sessions (for admin)
  Future<List<UserSession>> getAllActiveSessions(String adminSessionId) async {
    if (!hasPermission(adminSessionId, Permission.manageUsers)) {
      throw AccessControlException('Insufficient permissions to view active sessions');
    }

    await _auditService.logEvent(
      eventType: AuditEventType.privilegeEscalation,
      userId: _activeSessions[adminSessionId]?.userId ?? 'unknown',
      description: 'Active sessions accessed by administrator',
    );

    return _activeSessions.values.where((s) => !s.isExpired).toList();
  }

  /// Force logout user (admin function)
  Future<void> forceLogout(String adminSessionId, String targetSessionId) async {
    if (!hasPermission(adminSessionId, Permission.manageUsers)) {
      throw AccessControlException('Insufficient permissions to force logout');
    }

    final targetSession = _activeSessions[targetSessionId];
    if (targetSession != null) {
      _activeSessions.remove(targetSessionId);
      
      await _auditService.logEvent(
        eventType: AuditEventType.privilegeEscalation,
        userId: _activeSessions[adminSessionId]?.userId ?? 'unknown',
        description: 'Forced logout of user session',
        metadata: {
          'targetUserId': targetSession.userId,
          'targetSessionId': targetSessionId,
        },
      );
    }
  }

  // Private helper methods
  Future<bool> _verifyCredentials(String userId, String password) async {
    // In production: verify against secure password hash stored in database
    // This is a simplified implementation
    return true; // Placeholder
  }

  Future<UserRole> _getUserRole(String userId) async {
    // In production: fetch from database
    // This is a simplified implementation
    if (userId.startsWith('admin')) return UserRole.admin;
    if (userId.startsWith('doc')) return UserRole.professional;
    if (userId.startsWith('care')) return UserRole.caregiver;
    return UserRole.patient;
  }

  Set<Permission> _getRolePermissions(UserRole role) {
    return Set<Permission>.from(_rolePermissions[role] ?? {});
  }

  Future<bool> _isMfaRequired(String userId, UserRole role) async {
    // MFA required for healthcare professionals and admins
    return role == UserRole.professional || 
           role == UserRole.admin || 
           role == UserRole.superAdmin;
  }

  Future<MfaChallenge> _initiateMfaChallenge(String userId) async {
    final challengeId = _generateChallengeId();
    final code = _generateMfaCode();
    
    final challenge = MfaChallenge(
      challengeId: challengeId,
      userId: userId,
      method: MfaMethod.sms, // Simplified
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_mfaTimeout),
      code: code,
    );

    _mfaChallenges[challengeId] = challenge;
    
    // In production: send SMS/email with code
    debugPrint('MFA Code for $userId: $code');
    
    await _auditService.logEvent(
      eventType: AuditEventType.mfaEnabled,
      userId: userId,
      description: 'MFA challenge initiated',
      metadata: {'method': 'sms', 'challengeId': challengeId},
    );

    return challenge;
  }

  Future<MfaResult> _verifyMfaCode(String userId, String code) async {
    final challenge = _mfaChallenges.values.firstWhere(
      (c) => c.userId == userId && !c.isExpired && !c.isVerified,
      orElse: () => throw StateError('No active MFA challenge'),
    );

    if (challenge.code == code) {
      _mfaChallenges[challenge.challengeId] = MfaChallenge(
        challengeId: challenge.challengeId,
        userId: challenge.userId,
        method: challenge.method,
        createdAt: challenge.createdAt,
        expiresAt: challenge.expiresAt,
        code: challenge.code,
        isVerified: true,
      );

      await _auditService.logEvent(
        eventType: AuditEventType.mfaEnabled,
        userId: userId,
        description: 'MFA verification successful',
        success: true,
      );

      return MfaResult.success();
    } else {
      await _auditService.logEvent(
        eventType: AuditEventType.mfaEnabled,
        userId: userId,
        description: 'MFA verification failed',
        success: false,
        failureReason: 'Invalid MFA code',
      );

      return MfaResult.failure('Invalid MFA code');
    }
  }

  Future<UserSession> _createSession({
    required String userId,
    required UserRole role,
    required String ipAddress,
    required String deviceId,
    required bool mfaVerified,
    required MfaMethod mfaMethod,
    required Set<Permission> permissions,
  }) async {
    final sessionId = _generateSessionId();
    
    final session = UserSession(
      sessionId: sessionId,
      userId: userId,
      role: role,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      ipAddress: ipAddress,
      deviceId: deviceId,
      mfaVerified: mfaVerified,
      mfaMethod: mfaMethod,
      permissions: permissions,
    );

    _activeSessions[sessionId] = session;
    return session;
  }

  void _handleFailedAttempt(String userId, String ipAddress, String deviceId) async {
    _failedAttempts[userId] = (_failedAttempts[userId] ?? 0) + 1;
    
    if (_failedAttempts[userId]! >= _maxFailedAttempts) {
      _lockedUntil[userId] = DateTime.now().add(_lockoutDuration);
      
      await _auditService.logEvent(
        eventType: AuditEventType.securityAlert,
        userId: userId,
        description: 'Account locked due to excessive failed login attempts',
        severity: AuditSeverity.high,
        metadata: {
          'ipAddress': ipAddress,
          'deviceId': deviceId,
          'failedAttempts': _failedAttempts[userId].toString(),
        },
      );
    }

    await _auditService.logAuthenticationEvent(
      eventType: AuditEventType.loginFailed,
      userId: userId,
      success: false,
      failureReason: 'Invalid credentials',
      metadata: {
        'ipAddress': ipAddress,
        'deviceId': deviceId,
        'attemptNumber': _failedAttempts[userId].toString(),
      },
    );
  }

  bool _isUserLockedOut(String userId) {
    final lockoutTime = _lockedUntil[userId];
    if (lockoutTime == null) return false;
    
    if (DateTime.now().isAfter(lockoutTime)) {
      _lockedUntil.remove(userId);
      _failedAttempts.remove(userId);
      return false;
    }
    
    return true;
  }

  bool _hasMinimumNecessaryAccess(UserSession session, String phiId, String? context) {
    // Implement minimum necessary access principle
    // In production: check if user has legitimate need to access this specific PHI
    return true; // Simplified implementation
  }

  bool _isSensitivePermission(Permission permission) {
    const sensitivePermissions = {
      Permission.deletePhi,
      Permission.exportPhi,
      Permission.manageUsers,
      Permission.manageEncryption,
      Permission.accessAllData,
      Permission.emergencyOverride,
    };
    return sensitivePermissions.contains(permission);
  }

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateChallengeId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateMfaCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }

  void _startSessionCleanup() {
    // Clean up expired sessions every 15 minutes
    Stream.periodic(const Duration(minutes: 15)).listen((_) {
      final expiredSessions = <String>[];
      
      for (final entry in _activeSessions.entries) {
        if (entry.value.isExpired) {
          expiredSessions.add(entry.key);
        }
      }

      for (final sessionId in expiredSessions) {
        final session = _activeSessions.remove(sessionId);
        if (session != null) {
          _auditService.logEvent(
            eventType: AuditEventType.logout,
            userId: session.userId,
            description: 'Session expired and cleaned up',
            metadata: {'sessionId': sessionId},
          );
        }
      }

      // Clean up expired MFA challenges
      _mfaChallenges.removeWhere((_, challenge) => challenge.isExpired);
    });
  }
}

// Result classes
class AuthResult {
  final bool success;
  final UserSession? session;
  final MfaChallenge? mfaChallenge;
  final String? error;

  AuthResult._({
    required this.success,
    this.session,
    this.mfaChallenge,
    this.error,
  });

  factory AuthResult.success(UserSession session) {
    return AuthResult._(success: true, session: session);
  }

  factory AuthResult.mfaRequired(MfaChallenge challenge) {
    return AuthResult._(success: false, mfaChallenge: challenge);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}

class MfaResult {
  final bool success;
  final String? error;

  MfaResult._({required this.success, this.error});

  factory MfaResult.success() => MfaResult._(success: true);
  factory MfaResult.failure(String error) => MfaResult._(success: false, error: error);
}

// Custom exception
class AccessControlException implements Exception {
  final String message;
  AccessControlException(this.message);
  
  @override
  String toString() => 'AccessControlException: $message';
}