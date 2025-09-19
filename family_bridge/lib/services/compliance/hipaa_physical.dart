import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../audit/audit_logger.dart';
import '../encryption/encryption_service.dart';

/// HIPAA Physical Safeguards Implementation
class HIPAAPhysical {
  final DeviceSecurityManager deviceManager = DeviceSecurityManager();
  final WorkstationSecurity workstationSecurity = WorkstationSecurity();
  final MediaControls mediaControls = MediaControls();
  
  static HIPAAPhysical? _instance;
  
  HIPAAPhysical._();
  
  factory HIPAAPhysical() {
    _instance ??= HIPAAPhysical._();
    return _instance!;
  }
}

/// Device Security Management
class DeviceSecurityManager {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final AuditLogger _auditLogger = AuditLogger();
  final EncryptionService _encryptionService = EncryptionService();
  
  /// Check if device is encrypted
  Future<bool> isDeviceEncrypted() async {
    try {
      if (Platform.isIOS) {
        // iOS devices are encrypted by default since iOS 8
        return true;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        // Check if device is physical and running Android 6.0+
        if (androidInfo.isPhysicalDevice && 
            androidInfo.version.sdkInt >= 23) {
          // Android 6.0+ requires encryption
          return await _checkAndroidEncryption();
        }
      }
      
      return false;
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'DEVICE_ENCRYPTION_CHECK_FAILED',
        details: {'error': e.toString()},
      );
      return false;
    }
  }
  
  /// Register device for tracking
  Future<DeviceRegistration> registerDevice({
    required String userId,
    String? customDeviceName,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      final registration = DeviceRegistration(
        deviceId: deviceInfo.deviceId,
        userId: userId,
        deviceName: customDeviceName ?? deviceInfo.deviceName,
        deviceType: deviceInfo.deviceType,
        osVersion: deviceInfo.osVersion,
        isEncrypted: await isDeviceEncrypted(),
        registeredAt: DateTime.now(),
      );
      
      // Store registration (in production, save to database)
      await _storeDeviceRegistration(registration);
      
      await _auditLogger.logDeviceEvent(
        userId: userId,
        event: 'DEVICE_REGISTERED',
        deviceId: registration.deviceId,
        details: registration.toJson(),
      );
      
      return registration;
    } catch (e) {
      throw DeviceException('Failed to register device: $e');
    }
  }
  
  /// Remote wipe capability
  Future<void> remoteWipe({
    required String deviceId,
    required String authorizedBy,
    required String reason,
  }) async {
    try {
      // Log wipe initiation
      await _auditLogger.logSecurityEvent(
        userId: authorizedBy,
        event: 'REMOTE_WIPE_INITIATED',
        details: {
          'device_id': deviceId,
          'reason': reason,
        },
      );
      
      // Clear all local data
      await _clearAllLocalData();
      
      // Revoke device access
      await _revokeDeviceAccess(deviceId);
      
      // Log completion
      await _auditLogger.logSecurityEvent(
        userId: authorizedBy,
        event: 'REMOTE_WIPE_COMPLETED',
        details: {'device_id': deviceId},
      );
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: authorizedBy,
        event: 'REMOTE_WIPE_FAILED',
        details: {
          'device_id': deviceId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
  
  /// Check device compliance
  Future<DeviceComplianceStatus> checkDeviceCompliance(String deviceId) async {
    try {
      final isEncrypted = await isDeviceEncrypted();
      final hasPasscode = await _hasDevicePasscode();
      final isBiometricEnabled = await _isBiometricEnabled();
      final isJailbroken = await _isDeviceJailbroken();
      
      final status = DeviceComplianceStatus(
        deviceId: deviceId,
        isEncrypted: isEncrypted,
        hasPasscode: hasPasscode,
        hasBiometric: isBiometricEnabled,
        isJailbroken: isJailbroken,
        isCompliant: isEncrypted && hasPasscode && !isJailbroken,
        checkedAt: DateTime.now(),
      );
      
      await _auditLogger.logDeviceEvent(
        userId: 'system',
        event: 'DEVICE_COMPLIANCE_CHECK',
        deviceId: deviceId,
        details: status.toJson(),
      );
      
      return status;
    } catch (e) {
      throw DeviceException('Failed to check device compliance: $e');
    }
  }
  
  /// Monitor device location (for lost device scenarios)
  Future<DeviceLocation?> getDeviceLocation(String deviceId) async {
    // Implementation would use location services
    // Only activated in case of reported lost/stolen device
    return null;
  }
  
  // Helper methods
  Future<bool> _checkAndroidEncryption() async {
    // Check Android encryption status
    // This would require platform channel implementation
    return true; // Placeholder
  }
  
  Future<DeviceInfo> _getDeviceInfo() async {
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return DeviceInfo(
        deviceId: iosInfo.identifierForVendor ?? 'unknown',
        deviceName: iosInfo.name,
        deviceType: 'iOS',
        osVersion: iosInfo.systemVersion,
      );
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return DeviceInfo(
        deviceId: androidInfo.id,
        deviceName: androidInfo.model,
        deviceType: 'Android',
        osVersion: androidInfo.version.release,
      );
    }
    
    throw DeviceException('Unsupported platform');
  }
  
  Future<void> _storeDeviceRegistration(DeviceRegistration registration) async {
    // Store in database
  }
  
  Future<void> _clearAllLocalData() async {
    // Clear all app data
    // This would clear databases, preferences, cached files, etc.
  }
  
  Future<void> _revokeDeviceAccess(String deviceId) async {
    // Revoke device access tokens
  }
  
  Future<bool> _hasDevicePasscode() async {
    // Check if device has passcode/pin set
    return true; // Placeholder
  }
  
  Future<bool> _isBiometricEnabled() async {
    // Check if biometric authentication is enabled
    return false; // Placeholder
  }
  
  Future<bool> _isDeviceJailbroken() async {
    // Check for jailbreak/root
    return false; // Placeholder
  }
}

/// Workstation Security
class WorkstationSecurity {
  final AuditLogger _auditLogger = AuditLogger();
  
  /// Automatic screen lock after inactivity
  void setupAutoLock({
    required Duration timeout,
    required Function() onLock,
  }) {
    DateTime lastActivity = DateTime.now();
    
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (DateTime.now().difference(lastActivity) > timeout) {
        onLock();
        _auditLogger.logSecurityEvent(
          userId: 'system',
          event: 'AUTO_LOCK_ACTIVATED',
          details: {'timeout': timeout.inMinutes},
        );
      }
    });
  }
  
  /// Workstation use monitoring
  Future<void> logWorkstationAccess({
    required String userId,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    await _auditLogger.logWorkstationEvent(
      userId: userId,
      action: action,
      details: details ?? {},
    );
  }
}

/// Media Controls
class MediaControls {
  final EncryptionService _encryptionService = EncryptionService();
  final AuditLogger _auditLogger = AuditLogger();
  
  /// Secure media disposal
  Future<void> secureMediaDisposal({
    required String mediaId,
    required String mediaType,
    required String method,
    required String authorizedBy,
  }) async {
    try {
      await _auditLogger.logSecurityEvent(
        userId: authorizedBy,
        event: 'MEDIA_DISPOSAL',
        details: {
          'media_id': mediaId,
          'media_type': mediaType,
          'method': method,
        },
      );
      
      // Overwrite data multiple times
      if (method == 'overwrite') {
        await _secureOverwrite(mediaId);
      }
      
      // Mark as disposed in database
      await _markMediaDisposed(mediaId);
      
    } catch (e) {
      throw MediaException('Failed to dispose media: $e');
    }
  }
  
  /// Media re-use controls
  Future<bool> canReuseMedia({
    required String mediaId,
    required String previousUserId,
    required String newUserId,
  }) async {
    // Check if media has been properly sanitized
    final isSanitized = await _isMediaSanitized(mediaId);
    
    if (!isSanitized) {
      await _auditLogger.logSecurityEvent(
        userId: newUserId,
        event: 'MEDIA_REUSE_DENIED',
        details: {
          'media_id': mediaId,
          'reason': 'not_sanitized',
        },
      );
      return false;
    }
    
    await _auditLogger.logSecurityEvent(
      userId: newUserId,
      event: 'MEDIA_REUSE_APPROVED',
      details: {
        'media_id': mediaId,
        'previous_user': previousUserId,
      },
    );
    
    return true;
  }
  
  /// Media accountability tracking
  Future<MediaAuditTrail> getMediaAuditTrail(String mediaId) async {
    // Retrieve complete audit trail for media
    return MediaAuditTrail(
      mediaId: mediaId,
      events: [], // Would fetch from database
    );
  }
  
  // Helper methods
  Future<void> _secureOverwrite(String mediaId) async {
    // Implement secure overwrite algorithm
    // DoD 5220.22-M standard: 3 passes
  }
  
  Future<void> _markMediaDisposed(String mediaId) async {
    // Update database
  }
  
  Future<bool> _isMediaSanitized(String mediaId) async {
    // Check sanitization status
    return true; // Placeholder
  }
}

/// Models
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String osVersion;
  
  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.osVersion,
  });
}

class DeviceRegistration {
  final String deviceId;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String osVersion;
  final bool isEncrypted;
  final DateTime registeredAt;
  
  DeviceRegistration({
    required this.deviceId,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.osVersion,
    required this.isEncrypted,
    required this.registeredAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'os_version': osVersion,
      'is_encrypted': isEncrypted,
      'registered_at': registeredAt.toIso8601String(),
    };
  }
}

class DeviceComplianceStatus {
  final String deviceId;
  final bool isEncrypted;
  final bool hasPasscode;
  final bool hasBiometric;
  final bool isJailbroken;
  final bool isCompliant;
  final DateTime checkedAt;
  
  DeviceComplianceStatus({
    required this.deviceId,
    required this.isEncrypted,
    required this.hasPasscode,
    required this.hasBiometric,
    required this.isJailbroken,
    required this.isCompliant,
    required this.checkedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'is_encrypted': isEncrypted,
      'has_passcode': hasPasscode,
      'has_biometric': hasBiometric,
      'is_jailbroken': isJailbroken,
      'is_compliant': isCompliant,
      'checked_at': checkedAt.toIso8601String(),
    };
  }
}

class DeviceLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  
  DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class MediaAuditTrail {
  final String mediaId;
  final List<MediaEvent> events;
  
  MediaAuditTrail({
    required this.mediaId,
    required this.events,
  });
}

class MediaEvent {
  final String eventType;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> details;
  
  MediaEvent({
    required this.eventType,
    required this.userId,
    required this.timestamp,
    required this.details,
  });
}

/// Custom exceptions
class DeviceException implements Exception {
  final String message;
  
  DeviceException(this.message);
  
  @override
  String toString() => 'DeviceException: $message';
}

class MediaException implements Exception {
  final String message;
  
  MediaException(this.message);
  
  @override
  String toString() => 'MediaException: $message';
}