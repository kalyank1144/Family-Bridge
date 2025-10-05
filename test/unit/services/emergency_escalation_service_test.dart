/// Unit Tests for Emergency Escalation Service
/// 
/// Testing critical emergency features including:
/// - Emergency detection and triggering
/// - Escalation chains
/// - Notification dispatch
/// - Response tracking
/// - Fallback mechanisms

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:family_bridge/core/services/emergency_escalation_service.dart';
import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/core/services/hipaa_audit_service.dart';
import 'package:family_bridge/features/elder/models/emergency_contact_model.dart';
import '../../test_config.dart';
import '../../mocks/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late EmergencyEscalationService emergencyService;
  late ConfigurableMockNotificationService mockNotification;
  late ConfigurableMockHIPAAAuditService mockAudit;
  late TestPerformanceTracker performanceTracker;
  late TestQualityMetrics qualityMetrics;
  
  setUpAll(() async {
    await TestConfig.initialize(env: TestEnvironment.unit);
    performanceTracker = TestPerformanceTracker();
    qualityMetrics = TestQualityMetrics();
  });
  
  setUp(() {
    mockNotification = ConfigurableMockNotificationService();
    mockAudit = ConfigurableMockHIPAAAuditService();
    
    emergencyService = EmergencyEscalationService(
      notificationService: mockNotification,
      auditService: mockAudit,
    );
  });
  
  tearDown(() async {
    mockNotification.clearHistory();
    mockAudit.clearLogs();
    await TestConfig.tearDown();
  });
  
  tearDownAll(() {
    print('\nEmergency Escalation Service Test Results:');
    print(qualityMetrics.getQualityReport());
    print('\nPerformance Metrics:');
    print(performanceTracker.getReport());
  });
  
  group('Emergency Triggering', () {
    test('should trigger emergency for fall detection', () async {
      final testName = 'emergency_fall_detection';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final emergencyData = {
          'type': 'fall_detected',
          'userId': 'elder123',
          'location': 'Living Room',
          'severity': 'high',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Act
        final emergencyId = await emergencyService.triggerEmergency(
          userId: 'elder123',
          type: EmergencyType.fall,
          data: emergencyData,
        );
        
        // Assert
        expect(emergencyId, isNotNull);
        expect(mockNotification.sentNotifications, isNotEmpty);
        expect(
          mockNotification.sentNotifications.first['title'],
          contains('Emergency'),
        );
        expect(mockAudit.auditLogs, isNotEmpty);
        expect(
          mockAudit.auditLogs.first['action'],
          equals('emergency_triggered'),
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should trigger emergency for missed medication', () async {
      final testName = 'emergency_missed_medication';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final emergencyData = {
          'type': 'missed_medication',
          'userId': 'elder123',
          'medicationName': 'Heart Medication',
          'missedDoses': 2,
          'critical': true,
        };
        
        // Act
        final emergencyId = await emergencyService.triggerEmergency(
          userId: 'elder123',
          type: EmergencyType.missedMedication,
          data: emergencyData,
        );
        
        // Assert
        expect(emergencyId, isNotNull);
        expect(mockNotification.sentNotifications.length, greaterThan(1));
        
        // Should notify multiple contacts for critical medication
        final notifications = mockNotification.sentNotifications;
        expect(
          notifications.any((n) => n['body'].contains('Heart Medication')),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should trigger emergency for unresponsive status', () async {
      final testName = 'emergency_unresponsive';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final emergencyData = {
          'type': 'unresponsive',
          'userId': 'elder123',
          'lastActivity': DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String(),
          'expectedCheckIn': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        };
        
        // Act
        final emergencyId = await emergencyService.triggerEmergency(
          userId: 'elder123',
          type: EmergencyType.unresponsive,
          data: emergencyData,
        );
        
        // Assert
        expect(emergencyId, isNotNull);
        expect(mockNotification.sentNotifications, isNotEmpty);
        
        // Should escalate to emergency contacts
        final notifications = mockNotification.sentNotifications;
        expect(
          notifications.any((n) => n['title'].contains('URGENT')),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should handle SOS button press', () async {
      final testName = 'emergency_sos_button';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final emergencyData = {
          'type': 'sos',
          'userId': 'elder123',
          'message': 'I need help!',
          'location': 'Bedroom',
        };
        
        // Act
        final emergencyId = await emergencyService.triggerSOS(
          userId: 'elder123',
          message: 'I need help!',
          location: 'Bedroom',
        );
        
        // Assert
        expect(emergencyId, isNotNull);
        
        // SOS should immediately notify all contacts
        expect(
          mockNotification.sentNotifications.length,
          greaterThanOrEqualTo(3),
        );
        
        // Should include location in notifications
        expect(
          mockNotification.sentNotifications.first['body'],
          contains('Bedroom'),
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Escalation Chain', () {
    test('should follow escalation hierarchy', () async {
      final testName = 'escalation_hierarchy';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final contacts = [
          EmergencyContact(
            id: 'contact1',
            name: 'Primary Caregiver',
            phone: '1111111111',
            relationship: 'Daughter',
            priority: 1,
            userId: 'elder123',
          ),
          EmergencyContact(
            id: 'contact2',
            name: 'Secondary Contact',
            phone: '2222222222',
            relationship: 'Son',
            priority: 2,
            userId: 'elder123',
          ),
          EmergencyContact(
            id: 'contact3',
            name: 'Doctor',
            phone: '3333333333',
            relationship: 'Healthcare Provider',
            priority: 3,
            userId: 'elder123',
          ),
        ];
        
        await emergencyService.setEmergencyContacts('elder123', contacts);
        
        // Act
        await emergencyService.startEscalationChain(
          userId: 'elder123',
          emergencyId: 'emergency123',
          reason: 'No response to check-in',
        );
        
        // Simulate time passing and no response
        await Future.delayed(const Duration(seconds: 1));
        
        // Assert
        // Should notify contacts in priority order
        final notifications = mockNotification.sentNotifications;
        expect(notifications.length, greaterThanOrEqualTo(1));
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should escalate to next contact if no response', () async {
      final testName = 'escalation_no_response';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final contacts = [
          EmergencyContact(
            id: 'contact1',
            name: 'Primary',
            phone: '1111111111',
            relationship: 'Daughter',
            priority: 1,
            userId: 'elder123',
          ),
          EmergencyContact(
            id: 'contact2',
            name: 'Secondary',
            phone: '2222222222',
            relationship: 'Son',
            priority: 2,
            userId: 'elder123',
          ),
        ];
        
        await emergencyService.setEmergencyContacts('elder123', contacts);
        
        // Simulate no response from first contact
        mockNotification.setMockResponse('sendNotification', null);
        
        // Act
        await emergencyService.startEscalationChain(
          userId: 'elder123',
          emergencyId: 'emergency123',
          reason: 'Emergency',
        );
        
        // Simulate escalation timeout
        await emergencyService.checkEscalationTimeout('emergency123');
        
        // Assert
        // Should have notified both contacts
        expect(
          mockNotification.sentNotifications.length,
          greaterThanOrEqualTo(2),
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should call emergency services as last resort', () async {
      final testName = 'escalation_emergency_services';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange - no emergency contacts configured
        await emergencyService.setEmergencyContacts('elder123', []);
        
        // Act
        final emergencyId = await emergencyService.triggerEmergency(
          userId: 'elder123',
          type: EmergencyType.critical,
          data: {'severity': 'critical'},
        );
        
        // Should automatically escalate to emergency services
        await emergencyService.escalateToEmergencyServices(
          emergencyId: emergencyId,
          userId: 'elder123',
          reason: 'No emergency contacts available',
        );
        
        // Assert
        expect(mockAudit.auditLogs, isNotEmpty);
        expect(
          mockAudit.auditLogs.any(
            (log) => log['action'] == 'emergency_services_called',
          ),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Response Tracking', () {
    test('should track emergency acknowledgment', () async {
      final testName = 'response_acknowledgment';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        const emergencyId = 'emergency123';
        const responderId = 'caregiver456';
        
        // Act
        await emergencyService.acknowledgeEmergency(
          emergencyId: emergencyId,
          responderId: responderId,
          responseType: ResponseType.acknowledged,
        );
        
        // Assert
        final status = await emergencyService.getEmergencyStatus(emergencyId);
        expect(status['acknowledged'], isTrue);
        expect(status['responderId'], equals(responderId));
        expect(status['responseTime'], isNotNull);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should track emergency resolution', () async {
      final testName = 'response_resolution';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        const emergencyId = 'emergency123';
        const responderId = 'caregiver456';
        
        // Act
        await emergencyService.resolveEmergency(
          emergencyId: emergencyId,
          resolvedBy: responderId,
          resolution: 'Elder is safe, false alarm',
        );
        
        // Assert
        final status = await emergencyService.getEmergencyStatus(emergencyId);
        expect(status['resolved'], isTrue);
        expect(status['resolution'], equals('Elder is safe, false alarm'));
        expect(status['resolvedBy'], equals(responderId));
        expect(status['resolvedAt'], isNotNull);
        
        // Should audit the resolution
        expect(
          mockAudit.auditLogs.any(
            (log) => log['action'] == 'emergency_resolved',
          ),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should calculate response time metrics', () async {
      final testName = 'response_time_metrics';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        final emergencyTime = DateTime.now();
        const emergencyId = 'emergency123';
        
        // Create emergency
        await emergencyService.createEmergency(
          id: emergencyId,
          userId: 'elder123',
          type: EmergencyType.fall,
          timestamp: emergencyTime,
        );
        
        // Simulate response after 2 minutes
        await Future.delayed(const Duration(milliseconds: 100));
        final responseTime = DateTime.now();
        
        await emergencyService.acknowledgeEmergency(
          emergencyId: emergencyId,
          responderId: 'caregiver456',
          responseType: ResponseType.onTheWay,
          timestamp: responseTime,
        );
        
        // Act
        final metrics = await emergencyService.getResponseMetrics(emergencyId);
        
        // Assert
        expect(metrics['responseTime'], isNotNull);
        expect(metrics['responseTime'], greaterThan(0));
        expect(metrics['responder'], equals('caregiver456'));
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Fallback Mechanisms', () {
    test('should use SMS fallback when push notifications fail', () async {
      final testName = 'fallback_sms';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        mockNotification.setMockResponse(
          'sendNotification',
          Exception('Push notification failed'),
        );
        
        // Act
        await emergencyService.notifyWithFallback(
          userId: 'elder123',
          title: 'Emergency',
          message: 'Help needed',
          contactPhone: '1234567890',
        );
        
        // Assert
        // Should attempt SMS after push fails
        expect(mockAudit.auditLogs, isNotEmpty);
        expect(
          mockAudit.auditLogs.any(
            (log) => log['action'] == 'fallback_sms_sent',
          ),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should use phone call fallback for critical emergencies', () async {
      final testName = 'fallback_phone_call';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        mockNotification.setMockResponse(
          'sendNotification',
          Exception('All notifications failed'),
        );
        
        // Act
        await emergencyService.triggerCriticalEmergency(
          userId: 'elder123',
          type: EmergencyType.critical,
          phoneNumbers: ['1234567890', '0987654321'],
        );
        
        // Assert
        // Should attempt phone calls for critical emergencies
        expect(mockAudit.auditLogs, isNotEmpty);
        expect(
          mockAudit.auditLogs.any(
            (log) => log['action'] == 'emergency_call_initiated',
          ),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    test('should handle network failures gracefully', () async {
      final testName = 'fallback_network_failure';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        mockNotification.setMockResponse(
          'sendNotification',
          Exception('Network error'),
        );
        
        // Act
        final result = await emergencyService.triggerEmergencyWithRetry(
          userId: 'elder123',
          type: EmergencyType.fall,
          maxRetries: 3,
        );
        
        // Assert
        expect(result['attempted'], equals(3));
        expect(result['queued'], isTrue);
        
        // Should queue for later when network is available
        expect(
          mockAudit.auditLogs.any(
            (log) => log['action'] == 'emergency_queued_offline',
          ),
          isTrue,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
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