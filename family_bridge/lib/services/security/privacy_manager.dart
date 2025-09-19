import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../encryption/encryption_service.dart';
import '../audit/audit_logger.dart';

/// Comprehensive Privacy Management for HIPAA Compliance
class PrivacyManager {
  final ConsentManager consentManager = ConsentManager();
  final DataMinimization dataMinimization = DataMinimization();
  final DataSubjectRights dataSubjectRights = DataSubjectRights();
  final DataRetention dataRetention = DataRetention();
  
  static PrivacyManager? _instance;
  
  PrivacyManager._();
  
  factory PrivacyManager() {
    _instance ??= PrivacyManager._();
    return _instance!;
  }
}

/// Consent Management System
class ConsentManager {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditLogger _auditLogger = AuditLogger();
  
  /// Check if user has given consent for data processing
  Future<bool> hasConsent({
    required String userId,
    required String dataType,
    required String purpose,
  }) async {
    try {
      final response = await _supabase
          .from('consents')
          .select()
          .eq('user_id', userId)
          .eq('data_type', dataType)
          .eq('purpose', purpose)
          .eq('active', true)
          .single();
      
      if (response == null) return false;
      
      final consent = ConsentRecord.fromJson(response);
      
      // Check if consent is still valid
      if (consent.expiresAt != null && 
          consent.expiresAt!.isBefore(DateTime.now())) {
        return false;
      }
      
      return consent.granted;
    } catch (e) {
      await _auditLogger.logSecurityEvent(
        userId: userId,
        event: 'CONSENT_CHECK_FAILED',
        details: {'error': e.toString()},
      );
      return false;
    }
  }
  
  /// Record user consent
  Future<void> recordConsent({
    required String userId,
    required String dataType,
    required String purpose,
    required bool granted,
    String? ipAddress,
    Duration? validityPeriod,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final consentRecord = ConsentRecord(
        userId: userId,
        dataType: dataType,
        purpose: purpose,
        granted: granted,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        consentVersion: '1.0',
        expiresAt: validityPeriod != null 
            ? DateTime.now().add(validityPeriod)
            : null,
        additionalDetails: additionalDetails,
      );
      
      // Store consent record
      await _supabase.from('consents').insert(consentRecord.toJson());
      
      // Log consent event
      await _auditLogger.logConsentEvent(
        userId: userId,
        consentType: dataType,
        granted: granted,
        purpose: purpose,
        details: additionalDetails,
      );
    } catch (e) {
      throw PrivacyException('Failed to record consent: $e');
    }
  }
  
  /// Revoke consent
  Future<void> revokeConsent({
    required String userId,
    required String dataType,
    String? purpose,
  }) async {
    try {
      // Update consent status
      var query = _supabase
          .from('consents')
          .update({'active': false, 'revoked_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('data_type', dataType);
      
      if (purpose != null) {
        query = query.eq('purpose', purpose);
      }
      
      await query;
      
      // Log revocation
      await _auditLogger.logConsentEvent(
        userId: userId,
        consentType: dataType,
        granted: false,
        purpose: purpose,
      );
      
      // Trigger data deletion if required
      await _handleConsentRevocation(userId, dataType);
    } catch (e) {
      throw PrivacyException('Failed to revoke consent: $e');
    }
  }
  
  /// Get all consents for a user
  Future<List<ConsentRecord>> getUserConsents(String userId) async {
    try {
      final response = await _supabase
          .from('consents')
          .select()
          .eq('user_id', userId)
          .eq('active', true);
      
      return (response as List)
          .map((json) => ConsentRecord.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Handle consent revocation consequences
  Future<void> _handleConsentRevocation(String userId, String dataType) async {
    // Implement data handling based on consent revocation
    switch (dataType) {
      case 'health_data':
        // Stop processing health data
        await _stopHealthDataProcessing(userId);
        break;
      case 'location':
        // Delete location history
        await _deleteLocationData(userId);
        break;
      case 'analytics':
        // Opt out of analytics
        await _optOutAnalytics(userId);
        break;
    }
  }
  
  Future<void> _stopHealthDataProcessing(String userId) async {
    // Implementation to stop health data processing
  }
  
  Future<void> _deleteLocationData(String userId) async {
    // Implementation to delete location data
  }
  
  Future<void> _optOutAnalytics(String userId) async {
    // Implementation to opt out of analytics
  }
}

/// Data Minimization Controls
class DataMinimization {
  final EncryptionService _encryptionService = EncryptionService();
  
  /// Minimize collected health data to only necessary fields
  Map<String, dynamic> minimizeHealthData({
    required Map<String, dynamic> data,
    required String userRole,
  }) {
    final requiredFields = _getRequiredHealthFields(userRole);
    
    return Map.fromEntries(
      data.entries.where((entry) => requiredFields.contains(entry.key)),
    );
  }
  
  /// Minimize medication data
  Map<String, dynamic> minimizeMedicationData({
    required Map<String, dynamic> data,
    required String purpose,
  }) {
    final requiredFields = _getRequiredMedicationFields(purpose);
    
    return Map.fromEntries(
      data.entries.where((entry) => requiredFields.contains(entry.key)),
    );
  }
  
  /// Anonymize data for analytics
  Map<String, dynamic> anonymizeForAnalytics(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Remove identifiable fields
    final identifiableFields = [
      'user_id', 'name', 'email', 'phone', 'address',
      'ssn', 'medical_record_number', 'device_id'
    ];
    
    for (final field in identifiableFields) {
      anonymized.remove(field);
    }
    
    // Hash any remaining IDs
    if (anonymized.containsKey('id')) {
      anonymized['id'] = _encryptionService.generateHash(anonymized['id']);
    }
    
    return anonymized;
  }
  
  /// Pseudonymize data for research
  Map<String, dynamic> pseudonymizeData(Map<String, dynamic> data) {
    final pseudonymized = Map<String, dynamic>.from(data);
    
    // Replace identifiers with pseudonyms
    if (pseudonymized.containsKey('user_id')) {
      pseudonymized['pseudonym'] = _generatePseudonym(pseudonymized['user_id']);
      pseudonymized.remove('user_id');
    }
    
    // Remove direct identifiers
    final directIdentifiers = ['name', 'email', 'phone', 'ssn'];
    for (final identifier in directIdentifiers) {
      pseudonymized.remove(identifier);
    }
    
    return pseudonymized;
  }
  
  List<String> _getRequiredHealthFields(String userRole) {
    switch (userRole) {
      case 'elder':
        return ['heart_rate', 'blood_pressure', 'medication_taken'];
      case 'caregiver':
        return ['heart_rate', 'blood_pressure', 'glucose', 'weight', 
                'temperature', 'medication_taken', 'notes'];
      case 'youth':
        return ['heart_rate', 'temperature'];
      default:
        return [];
    }
  }
  
  List<String> _getRequiredMedicationFields(String purpose) {
    switch (purpose) {
      case 'reminder':
        return ['name', 'dosage', 'schedule', 'next_dose'];
      case 'refill':
        return ['name', 'prescription_number', 'pharmacy', 'refills_remaining'];
      case 'history':
        return ['name', 'start_date', 'end_date', 'prescriber'];
      default:
        return ['name', 'dosage'];
    }
  }
  
  String _generatePseudonym(String userId) {
    return 'USER_${_encryptionService.generateHash(userId).substring(0, 8)}';
  }
}

/// Data Subject Rights Implementation
class DataSubjectRights {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();
  final AuditLogger _auditLogger = AuditLogger();
  
  /// Export all user data (Right to Access)
  Future<UserDataExport> exportUserData(String userId) async {
    try {
      await _auditLogger.logDataAccess(
        userId: userId,
        dataType: 'full_export',
        action: 'export',
      );
      
      final data = <String, dynamic>{};
      
      // Collect all user data from various tables
      data['profile'] = await _getUserProfile(userId);
      data['health_data'] = await _getHealthData(userId);
      data['medications'] = await _getMedications(userId);
      data['appointments'] = await _getAppointments(userId);
      data['messages'] = await _getMessages(userId);
      data['emergency_contacts'] = await _getEmergencyContacts(userId);
      data['consent_records'] = await _getConsentRecords(userId);
      data['audit_logs'] = await _getAuditLogs(userId);
      
      // Encrypt the export
      final jsonData = jsonEncode(data);
      final encrypted = _encryptionService.encryptData(jsonData);
      
      return UserDataExport(
        userId: userId,
        encryptedData: encrypted,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    } catch (e) {
      throw PrivacyException('Failed to export user data: $e');
    }
  }
  
  /// Delete user data (Right to Erasure / Right to be Forgotten)
  Future<void> deleteUserData({
    required String userId,
    required String reason,
    bool immediate = false,
  }) async {
    try {
      await _auditLogger.logSecurityEvent(
        userId: userId,
        event: 'DATA_DELETION_REQUESTED',
        details: {'reason': reason, 'immediate': immediate},
      );
      
      if (immediate) {
        // Immediate deletion
        await _permanentDelete(userId);
      } else {
        // Soft delete with recovery period
        await _softDelete(userId);
        
        // Schedule permanent deletion after 30 days
        Timer(const Duration(days: 30), () async {
          await _permanentDelete(userId);
        });
      }
    } catch (e) {
      throw PrivacyException('Failed to delete user data: $e');
    }
  }
  
  /// Rectify user data (Right to Rectification)
  Future<void> rectifyUserData({
    required String userId,
    required Map<String, dynamic> corrections,
  }) async {
    try {
      await _auditLogger.logPHIModification(
        userId: userId,
        dataType: 'profile',
        action: 'rectify',
        recordId: userId,
        newValue: corrections,
      );
      
      // Apply corrections
      for (final entry in corrections.entries) {
        await _applyCorrection(userId, entry.key, entry.value);
      }
    } catch (e) {
      throw PrivacyException('Failed to rectify user data: $e');
    }
  }
  
  /// Restrict data processing (Right to Restriction)
  Future<void> restrictDataProcessing({
    required String userId,
    required List<String> dataTypes,
    required String reason,
  }) async {
    try {
      await _supabase.from('processing_restrictions').insert({
        'user_id': userId,
        'restricted_types': dataTypes,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await _auditLogger.logSecurityEvent(
        userId: userId,
        event: 'PROCESSING_RESTRICTED',
        details: {'data_types': dataTypes, 'reason': reason},
      );
    } catch (e) {
      throw PrivacyException('Failed to restrict processing: $e');
    }
  }
  
  /// Data portability (Right to Data Portability)
  Future<PortableDataExport> exportPortableData(String userId) async {
    try {
      final data = await exportUserData(userId);
      
      // Convert to standard format (e.g., JSON, CSV)
      final portableData = _convertToPortableFormat(data);
      
      return PortableDataExport(
        userId: userId,
        format: 'JSON',
        data: portableData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw PrivacyException('Failed to export portable data: $e');
    }
  }
  
  // Helper methods for data collection
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }
  
  Future<List<Map<String, dynamic>>> _getHealthData(String userId) async {
    final response = await _supabase
        .from('health_data')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getMedications(String userId) async {
    final response = await _supabase
        .from('medications')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getAppointments(String userId) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getMessages(String userId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,recipient_id.eq.$userId');
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getEmergencyContacts(String userId) async {
    final response = await _supabase
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getConsentRecords(String userId) async {
    final response = await _supabase
        .from('consents')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> _getAuditLogs(String userId) async {
    final response = await _supabase
        .from('audit_logs')
        .select()
        .eq('user_id', userId)
        .limit(1000);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> _softDelete(String userId) async {
    await _supabase
        .from('users')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
  
  Future<void> _permanentDelete(String userId) async {
    // Delete from all tables
    final tables = [
      'health_data', 'medications', 'appointments', 'messages',
      'emergency_contacts', 'consents', 'audit_logs', 'users'
    ];
    
    for (final table in tables) {
      await _supabase.from(table).delete().eq('user_id', userId);
    }
  }
  
  Future<void> _applyCorrection(String userId, String field, dynamic value) async {
    await _supabase
        .from('users')
        .update({field: value})
        .eq('id', userId);
  }
  
  String _convertToPortableFormat(UserDataExport export) {
    // Decrypt and convert to portable format
    final decrypted = _encryptionService.decryptData(export.encryptedData);
    return decrypted;
  }
}

/// Data Retention Management
class DataRetention {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditLogger _auditLogger = AuditLogger();
  
  // Retention periods
  static const Map<String, Duration> retentionPeriods = {
    'health_data': Duration(days: 2555), // 7 years for HIPAA
    'messages': Duration(days: 365),     // 1 year
    'appointments': Duration(days: 730),  // 2 years
    'audit_logs': Duration(days: 2555),  // 7 years for HIPAA
  };
  
  /// Enforce retention policies
  Future<void> enforceRetentionPolicies() async {
    for (final entry in retentionPeriods.entries) {
      await _deleteExpiredData(entry.key, entry.value);
    }
  }
  
  /// Delete expired data based on retention policy
  Future<void> _deleteExpiredData(String dataType, Duration retention) async {
    try {
      final cutoffDate = DateTime.now().subtract(retention);
      
      await _supabase
          .from(dataType)
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
      
      await _auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'RETENTION_POLICY_ENFORCED',
        details: {
          'data_type': dataType,
          'cutoff_date': cutoffDate.toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to enforce retention for $dataType: $e');
    }
  }
  
  /// Schedule automatic retention enforcement
  void scheduleRetentionEnforcement() {
    // Run daily at 2 AM
    Timer.periodic(const Duration(days: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 2 && now.minute == 0) {
        enforceRetentionPolicies();
      }
    });
  }
}

/// Models
class ConsentRecord {
  final String userId;
  final String dataType;
  final String purpose;
  final bool granted;
  final DateTime timestamp;
  final String? ipAddress;
  final String consentVersion;
  final DateTime? expiresAt;
  final Map<String, dynamic>? additionalDetails;
  
  ConsentRecord({
    required this.userId,
    required this.dataType,
    required this.purpose,
    required this.granted,
    required this.timestamp,
    this.ipAddress,
    required this.consentVersion,
    this.expiresAt,
    this.additionalDetails,
  });
  
  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      userId: json['user_id'],
      dataType: json['data_type'],
      purpose: json['purpose'],
      granted: json['granted'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ip_address'],
      consentVersion: json['consent_version'],
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'])
          : null,
      additionalDetails: json['additional_details'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'data_type': dataType,
      'purpose': purpose,
      'granted': granted,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'consent_version': consentVersion,
      'expires_at': expiresAt?.toIso8601String(),
      'additional_details': additionalDetails,
      'active': true,
    };
  }
}

class UserDataExport {
  final String userId;
  final String encryptedData;
  final DateTime generatedAt;
  final DateTime expiresAt;
  
  UserDataExport({
    required this.userId,
    required this.encryptedData,
    required this.generatedAt,
    required this.expiresAt,
  });
}

class PortableDataExport {
  final String userId;
  final String format;
  final String data;
  final DateTime generatedAt;
  
  PortableDataExport({
    required this.userId,
    required this.format,
    required this.data,
    required this.generatedAt,
  });
}

/// Custom exception for privacy operations
class PrivacyException implements Exception {
  final String message;
  
  PrivacyException(this.message);
  
  @override
  String toString() => 'PrivacyException: $message';
}