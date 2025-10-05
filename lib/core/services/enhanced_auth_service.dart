import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'hipaa_audit_service.dart';
import 'package:family_bridge/core/models/family_model.dart';
import 'package:family_bridge/core/models/user_model.dart';

/// Device information for authentication
class DeviceInfo {
  final String deviceId;
  final String? deviceName;
  final String deviceType;
  final String? platform;
  final String? osVersion;
  final bool isTrusted;
  final bool biometricEnabled;
  final DateTime? lastUsedAt;

  DeviceInfo({
    required this.deviceId,
    this.deviceName,
    required this.deviceType,
    this.platform,
    this.osVersion,
    this.isTrusted = false,
    this.biometricEnabled = false,
    this.lastUsedAt,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'device_type': deviceType,
        'platform': platform,
        'os_version': osVersion,
        'is_trusted': isTrusted,
        'biometric_enabled': biometricEnabled,
        'last_used_at': lastUsedAt?.toIso8601String(),
      };
}

/// Multi-factor authentication settings
class MfaSettings {
  final bool enabled;
  final bool sms;
  final bool email;
  final bool authenticator;
  final bool biometric;
  final bool hardwareToken;
  final bool requireForSensitiveOps;

  MfaSettings({
    this.enabled = false,
    this.sms = false,
    this.email = false,
    this.authenticator = false,
    this.biometric = false,
    this.hardwareToken = false,
    this.requireForSensitiveOps = true,
  });

  factory MfaSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MfaSettings();
    final methods = json['methods'] as Map<String, dynamic>? ?? {};
    return MfaSettings(
      enabled: json['mfa_enabled'] ?? false,
      sms: methods['sms'] ?? false,
      email: methods['email'] ?? false,
      authenticator: methods['authenticator'] ?? false,
      biometric: methods['biometric'] ?? false,
      hardwareToken: methods['hardware_token'] ?? false,
      requireForSensitiveOps: json['require_mfa_for_sensitive_ops'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'mfa_enabled': enabled,
        'methods': {
          'sms': sms,
          'email': email,
          'authenticator': authenticator,
          'biometric': biometric,
          'hardware_token': hardwareToken,
        },
        'require_mfa_for_sensitive_ops': requireForSensitiveOps,
      };
}

/// User session information
class UserSession {
  final String sessionId;
  final String sessionToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool isActive;
  final bool mfaVerified;
  final DateTime lastActivity;

  UserSession({
    required this.sessionId,
    required this.sessionToken,
    required this.refreshToken,
    required this.expiresAt,
    this.isActive = true,
    this.mfaVerified = false,
    required this.lastActivity,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Emergency access grant
class EmergencyAccess {
  final String id;
  final String elderId;
  final String caregiverId;
  final String accessType;
  final String reason;
  final DateTime grantedAt;
  final DateTime expiresAt;

  EmergencyAccess({
    required this.id,
    required this.elderId,
    required this.caregiverId,
    required this.accessType,
    required this.reason,
    required this.grantedAt,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);
}

/// Enhanced authentication service with comprehensive security features
class EnhancedAuthService {
  EnhancedAuthService._();
  static final EnhancedAuthService instance = EnhancedAuthService._();

  final _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _deviceInfo = DeviceInfoPlugin();
  final _auditService = HipaaAuditService.instance;

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kLastEmail = 'last_email';
  static const _kOfflineUnlock = 'offline_unlock';
  static const _kDeviceId = 'device_id';
  static const _kSessionToken = 'session_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kTrustedDevices = 'trusted_devices';
  static const _kMfaBackupCodes = 'mfa_backup_codes';

  Timer? _sessionTimer;
  UserSession? _currentSession;
  DeviceInfo? _currentDevice;
  MfaSettings? _mfaSettings;

  Future<void> initialize() async {
    await _initializeDevice();
    await _restoreSession();
    _startSessionMonitor();
  }

  Future<void> _initializeDevice() async {
    try {
      String? deviceId = await _storage.read(key: _kDeviceId);
      if (deviceId == null) {
        deviceId = _generateDeviceId();
        await _storage.write(key: _kDeviceId, value: deviceId);
      }

      final deviceType = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'mobile'
              : Platform.isIOS
                  ? 'mobile'
                  : 'desktop';

      String? platform;
      String? osVersion;
      String? deviceName;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          platform = 'android';
          osVersion = androidInfo.version.release;
          deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          platform = 'ios';
          osVersion = iosInfo.systemVersion;
          deviceName = iosInfo.name;
        }
      }

      _currentDevice = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        platform: platform,
        osVersion: osVersion,
      );

      await _registerDevice();
    } catch (e) {
      debugPrint('Error initializing device: $e');
    }
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString() + (UniqueKey().toString());
    return sha256.convert(utf8.encode(random)).toString();
  }

  Future<void> _registerDevice() async {
    if (_currentDevice == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('user_devices').upsert({
          'user_id': user.id,
          'device_id': _currentDevice!.deviceId,
          'device_name': _currentDevice!.deviceName,
          'device_type': _currentDevice!.deviceType,
          'platform': _currentDevice!.platform,
          'os_version': _currentDevice!.osVersion,
          'last_used_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error registering device: $e');
    }
  }

  Future<void> _restoreSession() async {
    try {
      final sessionToken = await _storage.read(key: _kSessionToken);
      final refreshToken = await _storage.read(key: _kRefreshToken);

      if (sessionToken != null && refreshToken != null) {
        // Validate session with backend
        final response = await _supabase
            .from('user_sessions')
            .select()
            .eq('session_token', sessionToken)
            .eq('is_active', true)
            .maybeSingle();

        if (response != null) {
          _currentSession = UserSession(
            sessionId: response['id'],
            sessionToken: sessionToken,
            refreshToken: refreshToken,
            expiresAt: DateTime.parse(response['expires_at']),
            isActive: response['is_active'],
            mfaVerified: response['mfa_verified'] ?? false,
            lastActivity: DateTime.parse(response['last_activity']),
          );

          if (!_currentSession!.isExpired) {
            await _updateSessionActivity();
          } else {
            await _refreshSession();
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  void _startSessionMonitor() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkSessionHealth(),
    );
  }

  Future<void> _checkSessionHealth() async {
    if (_currentSession == null) return;

    if (_currentSession!.isExpired) {
      await _refreshSession();
    } else {
      await _updateSessionActivity();
    }
  }

  Future<void> _updateSessionActivity() async {
    if (_currentSession == null) return;

    try {
      await _supabase
          .from('user_sessions')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('id', _currentSession!.sessionId);
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }

  Future<void> _refreshSession() async {
    if (_currentSession == null) return;

    try {
      // Use refresh token to get new session
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        await _createSession();
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      _currentSession = null;
      await _clearSessionData();
    }
  }

  Future<void> _createSession() async {
    if (_currentDevice == null) return;

    try {
      final result = await _supabase.rpc('create_user_session', params: {
        'p_device_id': _currentDevice!.deviceId,
        'p_ip_address': null, // Would need to get actual IP
        'p_user_agent': null, // Would need to get actual user agent
      });

      if (result['success'] == true) {
        final sessionToken = result['session_token'];
        final refreshToken = result['refresh_token'];

        _currentSession = UserSession(
          sessionId: result['session_id'],
          sessionToken: sessionToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          lastActivity: DateTime.now(),
        );

        await _storage.write(key: _kSessionToken, value: sessionToken);
        await _storage.write(key: _kRefreshToken, value: refreshToken);
      }
    } catch (e) {
      debugPrint('Error creating session: $e');
    }
  }

  Future<void> _clearSessionData() async {
    await _storage.delete(key: _kSessionToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kOfflineUnlock);
  }

  // Enhanced sign up with device registration
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    DateTime? dateOfBirth,
    String? phone,
    List<String>? medicalConditions,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    // Audit log the sign-up attempt
    await _auditService.logAuthEvent(
      action: 'signup_attempt',
      metadata: {'email': email, 'role': role.name},
    );

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role.name,
          'name': name,
          'phone': phone,
        },
      );

      await _storage.write(key: _kLastEmail, value: email);

      final user = res.user;
      if (user != null) {
        // Create user record
        await _supabase.from('users').upsert({
          'id': user.id,
          'name': name,
          'role': role.name,
          'phone': phone,
          'date_of_birth': dateOfBirth?.toIso8601String(),
        });

        // Create extended profile
        await _supabase.from('user_profiles').upsert({
          'user_id': user.id,
          'medical_conditions': medicalConditions ?? [],
          'accessibility': {
            'large_text': role == UserRole.elder,
            'high_contrast': role == UserRole.elder,
            'voice_guidance': role == UserRole.elder,
            'biometric_enabled': false,
          },
          'consent': {
            'terms_accepted_at': DateTime.now().toIso8601String(),
            'privacy_accepted_at': DateTime.now().toIso8601String(),
            'share_health_with_caregivers': true,
          },
        });

        // Set security question if provided
        if (securityQuestion != null && securityAnswer != null) {
          await _supabase.rpc('set_security_question', params: {
            'p_question': securityQuestion,
            'p_answer': securityAnswer,
          });
        }

        // Register device
        await _registerDevice();

        // Create session
        await _createSession();

        await _auditService.logAuthEvent(
          action: 'signup_success',
          metadata: {'user_id': user.id, 'role': role.name},
        );
      }

      return res;
    } catch (e) {
      await _auditService.logAuthEvent(
        action: 'signup_failed',
        metadata: {'email': email, 'error': e.toString()},
      );
      rethrow;
    }
  }

  // Enhanced sign in with MFA and device trust
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
    String? mfaCode,
  }) async {
    await _auditService.logAuthEvent(
      action: 'signin_attempt',
      metadata: {'email': email, 'device_id': _currentDevice?.deviceId},
    );

    try {
      // Log login attempt
      await _logLoginAttempt(email, success: false);

      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _storage.write(key: _kLastEmail, value: email);

      if (res.user != null) {
        // Check if MFA is required
        final mfaSettings = await getMfaSettings();
        if (mfaSettings.enabled && mfaCode == null) {
          // Would trigger MFA challenge here
          throw Exception('MFA code required');
        }

        if (mfaCode != null) {
          final isValid = await _verifyMfaCode(mfaCode);
          if (!isValid) {
            throw Exception('Invalid MFA code');
          }
        }

        // Register/update device
        await _registerDevice();

        // Create session
        await _createSession();

        // Update login attempt as successful
        await _logLoginAttempt(email, success: true);

        await _auditService.logAuthEvent(
          action: 'signin_success',
          metadata: {
            'user_id': res.user!.id,
            'device_id': _currentDevice?.deviceId,
            'mfa_used': mfaCode != null,
          },
        );
      }

      return res;
    } catch (e) {
      await _auditService.logAuthEvent(
        action: 'signin_failed',
        metadata: {'email': email, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> _logLoginAttempt(String email, {required bool success}) async {
    try {
      await _supabase.from('login_attempts').insert({
        'email': email,
        'device_id': _currentDevice?.deviceId,
        'success': success,
        'failure_reason': success ? null : 'invalid_credentials',
      });
    } catch (e) {
      debugPrint('Error logging login attempt: $e');
    }
  }

  Future<bool> _verifyMfaCode(String code) async {
    // Implement MFA verification logic
    // This would check against TOTP, SMS code, etc.
    return true; // Placeholder
  }

  // Biometric authentication with enhanced security
  Future<bool> authenticateWithBiometrics({
    required String reason,
    bool checkOnly = false,
  }) async {
    try {
      final isSupported = await isBiometricSupported();
      if (!isSupported) return false;

      if (checkOnly) {
        return await getBiometricEnabled();
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        await _storage.write(key: _kOfflineUnlock, value: '1');

        // Update device biometric status
        if (_currentDevice != null) {
          await _supabase
              .from('user_devices')
              .update({'biometric_enabled': true})
              .eq('device_id', _currentDevice!.deviceId);
        }

        await _auditService.logAuthEvent(
          action: 'biometric_auth_success',
          metadata: {'device_id': _currentDevice?.deviceId},
        );
      }

      return didAuth;
    } catch (e) {
      await _auditService.logAuthEvent(
        action: 'biometric_auth_failed',
        metadata: {'error': e.toString()},
      );
      return false;
    }
  }

  // Trust device for future logins
  Future<void> trustDevice({String? deviceName}) async {
    if (_currentDevice == null) return;

    try {
      await _supabase.from('user_devices').update({
        'is_trusted': true,
        'device_name': deviceName ?? _currentDevice!.deviceName,
      }).eq('device_id', _currentDevice!.deviceId);

      // Store in local trusted devices list
      final trustedDevices =
          await _storage.read(key: _kTrustedDevices) ?? '[]';
      final devices = jsonDecode(trustedDevices) as List;
      devices.add(_currentDevice!.deviceId);
      await _storage.write(key: _kTrustedDevices, value: jsonEncode(devices));

      await _auditService.logAuthEvent(
        action: 'device_trusted',
        metadata: {'device_id': _currentDevice!.deviceId},
      );
    } catch (e) {
      debugPrint('Error trusting device: $e');
    }
  }

  // Remove device trust
  Future<void> removeTrustedDevice(String deviceId) async {
    try {
      await _supabase
          .from('user_devices')
          .update({'is_trusted': false})
          .eq('device_id', deviceId);

      // Remove from local list
      final trustedDevices =
          await _storage.read(key: _kTrustedDevices) ?? '[]';
      final devices = jsonDecode(trustedDevices) as List;
      devices.remove(deviceId);
      await _storage.write(key: _kTrustedDevices, value: jsonEncode(devices));

      await _auditService.logAuthEvent(
        action: 'device_trust_removed',
        metadata: {'device_id': deviceId},
      );
    } catch (e) {
      debugPrint('Error removing trusted device: $e');
    }
  }

  // Get list of user's devices
  Future<List<DeviceInfo>> getUserDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final devices = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .order('last_used_at', ascending: false);

      return (devices as List).map((d) {
        return DeviceInfo(
          deviceId: d['device_id'],
          deviceName: d['device_name'],
          deviceType: d['device_type'],
          platform: d['platform'],
          osVersion: d['os_version'],
          isTrusted: d['is_trusted'] ?? false,
          biometricEnabled: d['biometric_enabled'] ?? false,
          lastUsedAt: d['last_used_at'] != null
              ? DateTime.parse(d['last_used_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user devices: $e');
      return [];
    }
  }

  // Configure MFA settings
  Future<void> configureMfa(MfaSettings settings) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_mfa_settings').upsert({
        'user_id': user.id,
        ...settings.toJson(),
      });

      _mfaSettings = settings;

      await _auditService.logAuthEvent(
        action: 'mfa_configured',
        metadata: settings.toJson(),
      );
    } catch (e) {
      debugPrint('Error configuring MFA: $e');
    }
  }

  // Get MFA settings
  Future<MfaSettings> getMfaSettings() async {
    if (_mfaSettings != null) return _mfaSettings!;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return MfaSettings();

      final settings = await _supabase
          .from('user_mfa_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      _mfaSettings = MfaSettings.fromJson(settings);
      return _mfaSettings!;
    } catch (e) {
      debugPrint('Error getting MFA settings: $e');
      return MfaSettings();
    }
  }

  // Generate MFA backup codes
  Future<List<String>> generateMfaBackupCodes() async {
    try {
      final codes = List.generate(
        10,
        (_) => _generateBackupCode(),
      );

      // Store hashed codes in database
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final hashedCodes = codes
            .map((c) => sha256.convert(utf8.encode(c)).toString())
            .toList();

        await _supabase
            .from('user_mfa_settings')
            .update({'backup_codes': hashedCodes}).eq('user_id', user.id);

        // Store plaintext codes securely on device
        await _storage.write(
          key: _kMfaBackupCodes,
          value: jsonEncode(codes),
        );
      }

      await _auditService.logAuthEvent(
        action: 'mfa_backup_codes_generated',
        metadata: {'count': codes.length},
      );

      return codes;
    } catch (e) {
      debugPrint('Error generating backup codes: $e');
      return [];
    }
  }

  String _generateBackupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
      (i) => chars[(random + i) % chars.length],
    ).join();
  }

  // Request emergency access
  Future<EmergencyAccess?> requestEmergencyAccess({
    required String elderId,
    required String reason,
    String accessType = 'view_only',
  }) async {
    try {
      final result = await _supabase.rpc('request_emergency_access', params: {
        'p_elder_id': elderId,
        'p_reason': reason,
        'p_access_type': accessType,
      });

      if (result['success'] == true) {
        await _auditService.logAuthEvent(
          action: 'emergency_access_requested',
          metadata: {
            'elder_id': elderId,
            'reason': reason,
            'access_type': accessType,
          },
          phiAccessed: true,
        );

        return EmergencyAccess(
          id: result['access_id'],
          elderId: elderId,
          caregiverId: _supabase.auth.currentUser!.id,
          accessType: accessType,
          reason: reason,
          grantedAt: DateTime.now(),
          expiresAt: DateTime.parse(result['expires_at']),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error requesting emergency access: $e');
      return null;
    }
  }

  // Check active emergency access
  Future<List<EmergencyAccess>> getActiveEmergencyAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final accesses = await _supabase
          .from('emergency_access')
          .select()
          .or('elder_id.eq.${user.id},caregiver_id.eq.${user.id}')
          .is_('revoked_at', null)
          .gt('expires_at', DateTime.now().toIso8601String());

      return (accesses as List).map((a) {
        return EmergencyAccess(
          id: a['id'],
          elderId: a['elder_id'],
          caregiverId: a['caregiver_id'],
          accessType: a['access_type'],
          reason: a['reason'],
          grantedAt: DateTime.parse(a['granted_at']),
          expiresAt: DateTime.parse(a['expires_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting emergency access: $e');
      return [];
    }
  }

  // Enhanced sign out with session cleanup
  Future<void> signOut({bool allDevices = false}) async {
    try {
      await _auditService.logAuthEvent(
        action: 'signout',
        metadata: {
          'all_devices': allDevices,
          'device_id': _currentDevice?.deviceId,
        },
      );

      // Invalidate current session
      if (_currentSession != null) {
        await _supabase
            .from('user_sessions')
            .update({'is_active': false})
            .eq('id', _currentSession!.sessionId);
      }

      if (allDevices) {
        // Invalidate all sessions for this user
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase
              .from('user_sessions')
              .update({'is_active': false})
              .eq('user_id', user.id);
        }
      }

      await _supabase.auth.signOut(
        scope: allDevices ? SignOutScope.global : SignOutScope.local,
      );

      await _clearSessionData();
      _currentSession = null;
      _mfaSettings = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Helper methods from original service
  Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == '1';
  }

  Future<String?> getLastEmail() async => _storage.read(key: _kLastEmail);

  Future<bool> hasOfflineUnlock() async {
    return (await _storage.read(key: _kOfflineUnlock)) == '1';
  }

  // Dispose method to clean up
  void dispose() {
    _sessionTimer?.cancel();
  }
}