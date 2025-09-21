/// Mock Services for Testing
/// 
/// Comprehensive mock implementations of all services
/// with configurable responses and behavior tracking.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/core/services/storage_service.dart';
import 'package:family_bridge/core/services/encryption_service.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/services/audio_service.dart';
import 'package:family_bridge/core/services/hipaa_audit_service.dart';
import 'package:family_bridge/core/services/emergency_escalation_service.dart';
import 'package:family_bridge/core/services/health_analytics_service.dart';
import 'package:family_bridge/core/services/gamification_service.dart';
import 'package:family_bridge/core/services/care_coordination_service.dart';
import 'package:family_bridge/core/services/role_based_access_service.dart';
import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/core/models/family_model.dart';
import 'package:family_bridge/features/chat/services/chat_service.dart';
import 'package:family_bridge/features/elder/services/medication_service.dart';
import 'package:family_bridge/features/elder/services/emergency_contact_service.dart';
import 'package:family_bridge/features/caregiver/services/health_data_service.dart';
import 'package:family_bridge/features/caregiver/services/appointments_service.dart';
import 'package:family_bridge/services/sync/data_sync_service.dart';
import 'package:family_bridge/services/network/network_manager.dart';
import 'package:family_bridge/shared/services/api_service.dart';
import 'package:family_bridge/shared/services/analytics_service.dart';
import 'package:family_bridge/shared/services/performance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generate mocks using Mockito
@GenerateMocks([
  AuthService,
  NotificationService,
  StorageService,
  EncryptionService,
  VoiceService,
  AudioService,
  HIPAAAuditService,
  EmergencyEscalationService,
  HealthAnalyticsService,
  GamificationService,
  CareCoordinationService,
  RoleBasedAccessService,
  ChatService,
  MedicationService,
  EmergencyContactService,
  HealthDataService,
  AppointmentsService,
  DataSyncService,
  NetworkManager,
  ApiService,
  AnalyticsService,
  PerformanceService,
  SupabaseClient,
  GoTrueClient,
  SupabaseStorageClient,
  RealtimeClient,
])
void main() {}

/// Simple Mock Voice Service for basic tests
class MockVoiceService extends Mock implements VoiceService {
  @override
  bool get isInitialized => true;
  
  @override
  Future<void> initialize() async {}
  
  @override
  bool get isListening => false;
  
  @override
  Stream<String> get speechStream => const Stream.empty();
  
  @override
  Future<void> startListening() async {}
  
  @override
  Future<void> stopListening() async {}
  
  @override
  Future<void> speak(String text) async {}
}

/// Mock Auth Service with configurable behavior
class ConfigurableMockAuthService extends Mock implements AuthService {
  User? _currentUser;
  bool _isAuthenticated = false;
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();
  final Map<String, dynamic> _mockResponses = {};
  final List<String> _methodCalls = [];
  
  /// Configure mock user
  void setMockUser(User? user) {
    _currentUser = user;
    _isAuthenticated = user != null;
    _userStreamController.add(user);
  }
  
  /// Configure mock response for a method
  void setMockResponse(String method, dynamic response) {
    _mockResponses[method] = response;
  }
  
  /// Track method calls
  void _trackCall(String method) {
    _methodCalls.add(method);
  }
  
  /// Get method call history
  List<String> get methodCalls => List.from(_methodCalls);
  
  /// Clear call history
  void clearHistory() {
    _methodCalls.clear();
  }
  
  @override
  User? get currentUser {
    _trackCall('currentUser');
    return _currentUser;
  }
  
  @override
  bool get isAuthenticated {
    _trackCall('isAuthenticated');
    return _isAuthenticated;
  }
  
  @override
  Stream<User?> get userStream {
    _trackCall('userStream');
    return _userStreamController.stream;
  }
  
  @override
  Future<User?> signIn(String email, String password) async {
    _trackCall('signIn');
    if (_mockResponses.containsKey('signIn')) {
      final response = _mockResponses['signIn'];
      if (response is Exception) throw response;
      setMockUser(response as User?);
      return response;
    }
    return _currentUser;
  }
  
  @override
  Future<User?> signUp(String email, String password, Map<String, dynamic> metadata) async {
    _trackCall('signUp');
    if (_mockResponses.containsKey('signUp')) {
      final response = _mockResponses['signUp'];
      if (response is Exception) throw response;
      setMockUser(response as User?);
      return response;
    }
    return _currentUser;
  }
  
  @override
  Future<void> signOut() async {
    _trackCall('signOut');
    if (_mockResponses.containsKey('signOut')) {
      final response = _mockResponses['signOut'];
      if (response is Exception) throw response;
    }
    setMockUser(null);
  }
  
  void dispose() {
    _userStreamController.close();
  }
}

/// Mock Notification Service with behavior tracking
class ConfigurableMockNotificationService extends Mock implements NotificationService {
  final List<Map<String, dynamic>> _sentNotifications = [];
  final Map<String, dynamic> _mockResponses = {};
  bool _permissionsGranted = true;
  
  /// Configure permissions
  void setPermissionsGranted(bool granted) {
    _permissionsGranted = granted;
  }
  
  /// Configure mock response
  void setMockResponse(String method, dynamic response) {
    _mockResponses[method] = response;
  }
  
  /// Get sent notifications
  List<Map<String, dynamic>> get sentNotifications => List.from(_sentNotifications);
  
  /// Clear notification history
  void clearHistory() {
    _sentNotifications.clear();
  }
  
  @override
  Future<void> initialize() async {
    if (_mockResponses.containsKey('initialize')) {
      final response = _mockResponses['initialize'];
      if (response is Exception) throw response;
    }
  }
  
  @override
  Future<bool> requestPermissions() async {
    if (_mockResponses.containsKey('requestPermissions')) {
      final response = _mockResponses['requestPermissions'];
      if (response is Exception) throw response;
      return response as bool;
    }
    return _permissionsGranted;
  }
  
  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    _sentNotifications.add({
      'title': title,
      'body': body,
      'data': data,
      'userId': userId,
      'timestamp': DateTime.now(),
    });
    
    if (_mockResponses.containsKey('sendNotification')) {
      final response = _mockResponses['sendNotification'];
      if (response is Exception) throw response;
    }
  }
  
  @override
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    _sentNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'data': data,
      'timestamp': DateTime.now(),
    });
    
    if (_mockResponses.containsKey('scheduleNotification')) {
      final response = _mockResponses['scheduleNotification'];
      if (response is Exception) throw response;
    }
  }
}

/// Mock Network Manager for testing offline scenarios
class ConfigurableMockNetworkManager extends Mock implements NetworkManager {
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final List<String> _requestHistory = [];
  
  /// Set online/offline status
  void setOnlineStatus(bool online) {
    _isOnline = online;
    _connectivityController.add(online);
  }
  
  /// Get request history
  List<String> get requestHistory => List.from(_requestHistory);
  
  /// Clear history
  void clearHistory() {
    _requestHistory.clear();
  }
  
  @override
  bool get isOnline {
    _requestHistory.add('isOnline');
    return _isOnline;
  }
  
  @override
  Stream<bool> get connectivityStream {
    _requestHistory.add('connectivityStream');
    return _connectivityController.stream;
  }
  
  @override
  Future<bool> checkConnectivity() async {
    _requestHistory.add('checkConnectivity');
    return _isOnline;
  }
  
  void dispose() {
    _connectivityController.close();
  }
}

/// Mock Voice Service for testing voice features
class ConfigurableMockVoiceService extends Mock implements VoiceService {
  bool _isListening = false;
  String _lastSpokenText = '';
  final StreamController<String> _speechController = StreamController<String>.broadcast();
  final Map<String, dynamic> _mockResponses = {};
  
  /// Configure mock response
  void setMockResponse(String method, dynamic response) {
    _mockResponses[method] = response;
  }
  
  /// Simulate speech recognition
  void simulateSpeechRecognition(String text) {
    _speechController.add(text);
  }
  
  @override
  bool get isListening => _isListening;
  
  @override
  Stream<String> get speechStream => _speechController.stream;
  
  @override
  Future<void> startListening() async {
    if (_mockResponses.containsKey('startListening')) {
      final response = _mockResponses['startListening'];
      if (response is Exception) throw response;
    }
    _isListening = true;
  }
  
  @override
  Future<void> stopListening() async {
    if (_mockResponses.containsKey('stopListening')) {
      final response = _mockResponses['stopListening'];
      if (response is Exception) throw response;
    }
    _isListening = false;
  }
  
  @override
  Future<void> speak(String text) async {
    if (_mockResponses.containsKey('speak')) {
      final response = _mockResponses['speak'];
      if (response is Exception) throw response;
    }
    _lastSpokenText = text;
  }
  
  String get lastSpokenText => _lastSpokenText;
  
  void dispose() {
    _speechController.close();
  }
}

/// Mock Encryption Service for testing security features
class ConfigurableMockEncryptionService extends Mock implements EncryptionService {
  final Map<String, String> _encryptedData = {};
  bool _shouldFailEncryption = false;
  bool _shouldFailDecryption = false;
  
  /// Configure failure scenarios
  void setShouldFailEncryption(bool fail) {
    _shouldFailEncryption = fail;
  }
  
  void setShouldFailDecryption(bool fail) {
    _shouldFailDecryption = fail;
  }
  
  @override
  Future<String> encrypt(String plainText) async {
    if (_shouldFailEncryption) {
      throw Exception('Encryption failed');
    }
    final encrypted = 'encrypted_$plainText';
    _encryptedData[encrypted] = plainText;
    return encrypted;
  }
  
  @override
  Future<String> decrypt(String encryptedText) async {
    if (_shouldFailDecryption) {
      throw Exception('Decryption failed');
    }
    return _encryptedData[encryptedText] ?? encryptedText.replaceAll('encrypted_', '');
  }
  
  @override
  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    if (_shouldFailEncryption) {
      throw Exception('Encryption failed');
    }
    return Uint8List.fromList([...plainBytes, 1, 2, 3]); // Simple mock
  }
  
  @override
  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    if (_shouldFailDecryption) {
      throw Exception('Decryption failed');
    }
    if (encryptedBytes.length > 3) {
      return Uint8List.fromList(
        encryptedBytes.sublist(0, encryptedBytes.length - 3)
      );
    }
    return encryptedBytes;
  }
}

/// Mock HIPAA Audit Service for compliance testing
class ConfigurableMockHIPAAAuditService extends Mock implements HIPAAAuditService {
  final List<Map<String, dynamic>> _auditLogs = [];
  bool _complianceEnabled = true;
  
  /// Configure compliance status
  void setComplianceEnabled(bool enabled) {
    _complianceEnabled = enabled;
  }
  
  /// Get audit logs
  List<Map<String, dynamic>> get auditLogs => List.from(_auditLogs);
  
  /// Clear audit logs
  void clearLogs() {
    _auditLogs.clear();
  }
  
  @override
  Future<void> logAccess({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    _auditLogs.add({
      'userId': userId,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'action': action,
      'metadata': metadata,
      'timestamp': DateTime.now(),
      'compliant': _complianceEnabled,
    });
  }
  
  @override
  Future<void> logDataModification({
    required String userId,
    required String dataType,
    required String dataId,
    required String modification,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    _auditLogs.add({
      'userId': userId,
      'dataType': dataType,
      'dataId': dataId,
      'modification': modification,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': DateTime.now(),
      'compliant': _complianceEnabled,
    });
  }
  
  @override
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? resourceType,
  }) async {
    var filtered = _auditLogs;
    
    if (userId != null) {
      filtered = filtered.where((log) => log['userId'] == userId).toList();
    }
    
    if (startDate != null) {
      filtered = filtered.where((log) => 
        (log['timestamp'] as DateTime).isAfter(startDate)
      ).toList();
    }
    
    if (endDate != null) {
      filtered = filtered.where((log) => 
        (log['timestamp'] as DateTime).isBefore(endDate)
      ).toList();
    }
    
    if (resourceType != null) {
      filtered = filtered.where((log) => 
        log['resourceType'] == resourceType
      ).toList();
    }
    
    return filtered;
  }
  
  @override
  Future<bool> verifyCompliance() async {
    return _complianceEnabled;
  }
}