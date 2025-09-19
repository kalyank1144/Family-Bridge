import 'dart:async';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:otp/otp.dart';
import '../audit/audit_logger.dart';

enum UserType { elder, caregiver, youth }

class User {
  final String id;
  final String email;
  final String? phone;
  final UserType userType;
  final String role;
  
  User({
    required this.id,
    required this.email,
    this.phone,
    required this.userType,
    required this.role,
  });
}

/// Authentication security service with MFA and biometric support
class AuthSecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuditLogger _auditLogger = AuditLogger();
  final SessionManager _sessionManager = SessionManager();
  
  static AuthSecurityService? _instance;
  
  AuthSecurityService._();
  
  factory AuthSecurityService() {
    _instance ??= AuthSecurityService._();
    return _instance!;
  }
  
  /// Setup multi-factor authentication based on user type
  Future<MFASetupResult> setupMFA(User user) async {
    try {
      if (user.userType == UserType.elder) {
        // SMS-based MFA for elderly users (simpler)
        return await _setupSMSMFA(user.phone ?? '');
      } else {
        // TOTP for caregivers and youth
        return await _setupTOTP(user.email);
      }
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: user.id,
        event: 'MFA_SETUP_FAILED',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }
  
  /// Setup SMS-based MFA
  Future<MFASetupResult> _setupSMSMFA(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw AuthException('Phone number required for SMS MFA');
    }
    
    // Generate and send OTP code
    final otpCode = _generateOTPCode();
    
    // In production, integrate with SMS service
    // await _sendSMS(phoneNumber, otpCode);
    
    return MFASetupResult(
      method: 'SMS',
      secret: otpCode,
      backupCodes: _generateBackupCodes(),
    );
  }
  
  /// Setup TOTP-based MFA
  Future<MFASetupResult> _setupTOTP(String email) async {
    final secret = _generateTOTPSecret();
    final qrCode = _generateQRCode(email, secret);
    
    return MFASetupResult(
      method: 'TOTP',
      secret: secret,
      qrCode: qrCode,
      backupCodes: _generateBackupCodes(),
    );
  }
  
  /// Verify MFA code
  Future<bool> verifyMFA(String userId, String code, String method) async {
    try {
      bool isValid = false;
      
      if (method == 'SMS') {
        isValid = await _verifySMSCode(userId, code);
      } else if (method == 'TOTP') {
        isValid = await _verifyTOTPCode(userId, code);
      }
      
      await _auditLogger.logSecurityEvent(
        userId: userId,
        event: isValid ? 'MFA_SUCCESS' : 'MFA_FAILED',
        details: {'method': method},
      );
      
      return isValid;
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: userId,
        event: 'MFA_ERROR',
        details: {'error': e.toString()},
      );
      return false;
    }
  }
  
  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticateBiometric({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometrics are available
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication not available',
        );
      }
      
      // Get available biometric types
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return BiometricAuthResult(
          success: false,
          error: 'No biometric methods configured',
        );
      }
      
      // Attempt authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: stickyAuth,
          useErrorDialogs: true,
        ),
      );
      
      return BiometricAuthResult(
        success: didAuthenticate,
        method: _getBiometricMethod(availableBiometrics),
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Cancel biometric authentication
  Future<void> cancelBiometricAuth() async {
    await _localAuth.stopAuthentication();
  }
  
  /// Start user session with appropriate timeout
  void startSession(User user) {
    _sessionManager.startSession(user.userType);
  }
  
  /// Refresh active session
  void refreshSession() {
    _sessionManager.refreshSession();
  }
  
  /// End user session
  Future<void> endSession(String userId) async {
    _sessionManager.endSession();
    await _auditLogger.logSecurityEvent(
      userId: userId,
      event: 'SESSION_ENDED',
      details: {},
    );
  }
  
  /// Check if session is active
  bool isSessionActive() {
    return _sessionManager.isActive();
  }
  
  // Helper methods
  String _generateOTPCode() {
    return OTP.randomSecret().substring(0, 6);
  }
  
  String _generateTOTPSecret() {
    return OTP.randomSecret();
  }
  
  String _generateQRCode(String email, String secret) {
    return 'otpauth://totp/FamilyBridge:$email?secret=$secret&issuer=FamilyBridge';
  }
  
  List<String> _generateBackupCodes() {
    return List.generate(10, (_) => OTP.randomSecret().substring(0, 8));
  }
  
  Future<bool> _verifySMSCode(String userId, String code) async {
    // Implement SMS code verification logic
    // This would check against stored code with expiry
    return true; // Placeholder
  }
  
  Future<bool> _verifyTOTPCode(String userId, String code) async {
    // Implement TOTP verification using user's secret
    // final secret = await getUserSecret(userId);
    // return OTP.verify(code, secret);
    return true; // Placeholder
  }
  
  String _getBiometricMethod(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }
}

/// Session management with user-type specific timeouts
class SessionManager {
  static const Duration elderTimeout = Duration(hours: 4);
  static const Duration caregiverTimeout = Duration(hours: 2);
  static const Duration youthTimeout = Duration(hours: 1);
  
  Timer? _sessionTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  UserType? _currentUserType;
  
  void startSession(UserType userType) {
    _currentUserType = userType;
    _lastActivity = DateTime.now();
    
    final timeout = _getTimeout(userType);
    
    // Warning 5 minutes before timeout
    final warningTime = timeout - const Duration(minutes: 5);
    _warningTimer = Timer(warningTime, _showTimeoutWarning);
    
    // Auto-logout on timeout
    _sessionTimer = Timer(timeout, _forceLogout);
  }
  
  void refreshSession() {
    if (_currentUserType == null) return;
    
    _lastActivity = DateTime.now();
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    startSession(_currentUserType!);
  }
  
  void endSession() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _sessionTimer = null;
    _warningTimer = null;
    _lastActivity = null;
    _currentUserType = null;
  }
  
  bool isActive() {
    if (_lastActivity == null) return false;
    
    final timeout = _getTimeout(_currentUserType ?? UserType.youth);
    final elapsed = DateTime.now().difference(_lastActivity!);
    
    return elapsed < timeout;
  }
  
  Duration _getTimeout(UserType userType) {
    switch (userType) {
      case UserType.elder:
        return elderTimeout;
      case UserType.caregiver:
        return caregiverTimeout;
      case UserType.youth:
        return youthTimeout;
    }
  }
  
  void _showTimeoutWarning() {
    // Implement warning notification
    print('Session will expire in 5 minutes');
  }
  
  void _forceLogout() {
    // Implement force logout
    endSession();
    print('Session expired - user logged out');
  }
}

/// Result classes
class MFASetupResult {
  final String method;
  final String secret;
  final String? qrCode;
  final List<String> backupCodes;
  
  MFASetupResult({
    required this.method,
    required this.secret,
    this.qrCode,
    required this.backupCodes,
  });
}

class BiometricAuthResult {
  final bool success;
  final String? method;
  final String? error;
  
  BiometricAuthResult({
    required this.success,
    this.method,
    this.error,
  });
}

/// Custom authentication exception
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}